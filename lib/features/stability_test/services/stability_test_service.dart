import 'dart:async';
import 'dart:io' show HandshakeException, SocketException;

import 'package:http/http.dart';

import '../models/connection_mode.dart';
import '../models/test_configuration.dart';
import '../models/test_result.dart';

/// Callback fired whenever a single request completes (success or failure).
/// The [TestResult] is fully classified and ready to display.
typedef ResultCallback = void Function(TestResult result);

/// Callback fired when the runner's loop transitions between attempts, e.g. to
/// let the UI show "正在執行第 N 次測試" or "等待下一次測試". Spec §7.3.
typedef ProgressCallback = void Function(
    int currentRequest, int totalRequests, TestRunnerPhase phase);

/// Coarse phases the runner reports. Spec §7.3.
enum TestRunnerPhase {
  preparing,
  request,
  waiting,
  cancelled,
  finished,
}

/// Signal type used internally to abort streaming once the body exceeds the
/// safety limit. Never escapes the runner.
class _ResponseTooLarge implements Exception {
  const _ResponseTooLarge();
}

/// The sequential HTTP GET test runner. Spec §6.2, §8.x.
///
/// This service owns no state between runs. A new instance is used per test
/// session by the controller, and all HTTP access goes through the injectable
/// [clientFactory], which makes the runner fully unit-testable with
/// [MockClient] (spec §22.2).
class StabilityTestService {
  StabilityTestService({
    Client Function()? clientFactory,
  }) : _clientFactory = clientFactory ?? Client.new;

  final Client Function() _clientFactory;

  /// Runs the configured number of sequential requests, emitting a result for
  /// each attempt and reporting progress between attempts.
  ///
  /// Cancellation: pass a [cancelled] getter that returns true to stop the
  /// loop. The currently in-flight request is aborted via its [Client] close.
  /// The function returns once the loop has unwound.
  ///
  /// Returns the list of recorded results (which is the same list passed to
  /// [onResult], in order).
  Future<List<TestResult>> run({
    required TestConfiguration configuration,
    required bool Function() cancelled,
    required ResultCallback onResult,
    required ProgressCallback onProgress,
  }) async {
    final List<TestResult> results = <TestResult>[];
    final Uri baseUri = Uri.parse(configuration.url);
    const Map<String, String> headers = <String, String>{
      'Accept': '*/*',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };

    onProgress(0, configuration.testCount, TestRunnerPhase.preparing);

    // The shared client for reuse mode. Created lazily so an immediate cancel
    // never leaks a client. Spec §6.2.1.
    Client? sharedClient;

    try {
      for (int i = 1; i <= configuration.testCount; i++) {
        if (cancelled()) {
          onProgress(i, configuration.testCount, TestRunnerPhase.cancelled);
          break;
        }

        onProgress(i, configuration.testCount, TestRunnerPhase.request);

        // Decide which client to use for this attempt. Spec §6.2.
        final Client requestClient;
        final bool ownsClient;
        if (configuration.connectionMode == ConnectionMode.reuseClient) {
          sharedClient ??= _clientFactory();
          requestClient = sharedClient;
          ownsClient = false;
        } else {
          requestClient = _clientFactory();
          ownsClient = true;
        }

        final TestResult result = await _executeAttempt(
          client: requestClient,
          sequenceNumber: i,
          baseUri: baseUri,
          headers: headers,
          configuration: configuration,
          cancelled: cancelled,
        );

        // Cancelled mid-flight attempts do not count as completed (spec §9.9).
        if (result.status != ResultStatus.cancelled) {
          results.add(result);
          onResult(result);
        }

        if (ownsClient) {
          requestClient.close();
        }

        if (cancelled()) {
          onProgress(i, configuration.testCount, TestRunnerPhase.cancelled);
          break;
        }

        // Wait between attempts — but only if more attempts remain. Spec §6.4.
        if (i < configuration.testCount &&
            configuration.interval.value > 0 &&
            !cancelled()) {
          onProgress(i, configuration.testCount, TestRunnerPhase.waiting);
          await _cancellableWait(configuration.interval.duration, cancelled);
        }
      }

      onProgress(
          results.length, configuration.testCount, TestRunnerPhase.finished);
    } finally {
      // Always release the shared client, run or cancel. Spec §6.2.1 / DoD §6.
      sharedClient?.close();
    }

    return results;
  }

  /// Performs exactly one request, classifies the outcome and returns a
  /// [TestResult]. Never throws: every failure path produces a result.
  Future<TestResult> _executeAttempt({
    required Client client,
    required int sequenceNumber,
    required Uri baseUri,
    required Map<String, String> headers,
    required TestConfiguration configuration,
    required bool Function() cancelled,
  }) async {
    final DateTime startedAt = DateTime.now();
    final Stopwatch stopwatch = Stopwatch()..start();
    Uri currentUri = baseUri;
    int redirectCount = 0;
    int responseBytes = 0;
    final int maxBytes = configuration.maxResponseBytes;

    TestResult buildResult(
      ResultStatus status, {
      int? statusCode,
      String? errorType,
      String? errorMessage,
    }) {
      stopwatch.stop();
      return TestResult(
        sequenceNumber: sequenceNumber,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        elapsedMicroseconds: stopwatch.elapsedMicroseconds,
        status: status,
        httpStatusCode: statusCode,
        responseBytes: responseBytes,
        redirectCount: redirectCount,
        originalUrl: baseUri.toString(),
        finalUrl: currentUri.toString(),
        errorType: errorType,
        errorMessage: errorMessage,
      );
    }

    try {
      // Follow redirects manually so we can enforce the 5-redirect cap
      // uniformly (spec §8.4) regardless of the underlying client default.
      for (;;) {
        if (cancelled()) {
          return buildResult(ResultStatus.cancelled,
              errorType: 'Cancelled', errorMessage: '測試已取消');
        }

        final StreamedResponse streamed;
        try {
          final Request request =
              Request('GET', currentUri)..headers.addAll(headers);
          streamed = await client.send(request).timeout(
                configuration.timeout.duration,
                onTimeout: () =>
                    throw TimeoutException('request timeout'),
              );
        } on TimeoutException {
          return buildResult(ResultStatus.timeout,
              errorType: 'Timeout', errorMessage: '連線超過設定的 Timeout');
        } on HandshakeException {
          return buildResult(ResultStatus.tlsError,
              errorType: 'HandshakeException',
              errorMessage: '無法建立安全連線，目標憑證可能無效');
        } on SocketException catch (e) {
          return buildResult(_classifySocketException(e.message),
              errorType: 'SocketException',
              errorMessage: _socketMessageFor(e.message));
        }

        final int code = streamed.statusCode;

        // Manually follow 3xx redirects (spec §8.4). The streamed response is
        // drained before each hop so nothing stays buffered.
        if (code >= 300 && code < 400) {
          redirectCount++;
          await _drainStreamedResponse(streamed);
          if (redirectCount > configuration.maxRedirects) {
            return buildResult(ResultStatus.tooManyRedirects,
                statusCode: code,
                errorType: 'TooManyRedirects',
                errorMessage: 'URL 重新導向次數過多');
          }
          final String? location = streamed.headers['location'];
          if (location == null) {
            // No Location header: treat as terminal response.
            responseBytes +=
                await _consumeStream(streamed.stream, maxBytes);
            return _terminalResult(
              code: code,
              sequenceNumber: sequenceNumber,
              startedAt: startedAt,
              stopwatch: stopwatch,
              responseBytes: responseBytes,
              redirectCount: redirectCount,
              baseUri: baseUri,
              finalUri: currentUri,
            );
          }
          currentUri = currentUri.resolve(location);
          continue;
        }

        // Non-redirect: stream the body, enforcing the 10 MiB safety cap
        // (spec §8.6). We never buffer the whole body.
        try {
          responseBytes = await _consumeStream(streamed.stream, maxBytes);
        } on _ResponseTooLarge {
          await _drainStreamedResponse(streamed);
          return buildResult(ResultStatus.responseTooLarge,
              statusCode: code,
              errorType: 'ResponseTooLarge',
              errorMessage:
                  '回應內容超過 10 MiB 安全限制。建議使用輕量的 health-check URL。');
        }

        return _terminalResult(
          code: code,
          sequenceNumber: sequenceNumber,
          startedAt: startedAt,
          stopwatch: stopwatch,
          responseBytes: responseBytes,
          redirectCount: redirectCount,
          baseUri: baseUri,
          finalUri: currentUri,
        );
      }
    } catch (e) {
      // Last-resort classification. Never leak a stack trace to the user
      // (spec §21, §9.10). Keep a safe technical description for the detail
      // view.
      return buildResult(ResultStatus.unknownError,
          errorType: e.runtimeType.toString(),
          errorMessage: '測試時發生未預期錯誤');
    }
  }

  TestResult _terminalResult({
    required int code,
    required int sequenceNumber,
    required DateTime startedAt,
    required Stopwatch stopwatch,
    required int responseBytes,
    required int redirectCount,
    required Uri baseUri,
    required Uri finalUri,
  }) {
    stopwatch.stop();
    final ResultStatus status = (code >= 200 && code < 400)
        ? ResultStatus.success
        : ResultStatus.httpError;
    return TestResult(
      sequenceNumber: sequenceNumber,
      startedAt: startedAt,
      completedAt: DateTime.now(),
      elapsedMicroseconds: stopwatch.elapsedMicroseconds,
      status: status,
      httpStatusCode: code,
      responseBytes: responseBytes,
      redirectCount: redirectCount,
      originalUrl: baseUri.toString(),
      finalUrl: finalUri.toString(),
      errorType: null,
      errorMessage: null,
    );
  }

  /// Drains a [StreamedResponse] (used when we are about to redirect or abort)
  /// without accumulating it in memory.
  Future<void> _drainStreamedResponse(StreamedResponse response) async {
    try {
      await response.stream.drain<void>();
    } catch (_) {
      // Best-effort drain; the outcome classification is already decided.
    }
  }

  /// Reads [stream] to completion, counting bytes. Throws [_ResponseTooLarge]
  /// as soon as the cumulative byte count exceeds [maxBytes]. Spec §8.6.
  Future<int> _consumeStream(Stream<List<int>> stream, int maxBytes) async {
    int total = 0;
    await for (final List<int> chunk in stream) {
      total += chunk.length;
      if (total > maxBytes) {
        throw const _ResponseTooLarge();
      }
    }
    return total;
  }

  /// A wait that returns early if [cancelled] becomes true. Spec §7.4
  /// (cancel pending Timer).
  Future<void> _cancellableWait(
      Duration duration, bool Function() cancelled) async {
    final Completer<void> completer = Completer<void>();
    final Timer timer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete();
    });
    // Polling is cheap (a few times per second) and keeps the runner decoupled
    // from any platform-specific cancellation signal.
    final Timer poll = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (cancelled() && !completer.isCompleted) {
        completer.complete();
      }
    });
    try {
      await completer.future;
    } finally {
      timer.cancel();
      poll.cancel();
    }
  }

  /// Distinguishes DNS resolution failures from generic connection errors
  /// using the exception message text emitted by `dart:io`. Spec §9.4/§9.5.
  static ResultStatus _classifySocketException(String message) {
    final String lower = message.toLowerCase();
    const Set<String> dnsHints = <String>{
      'failed host lookup',
      'lookup failed',
      'name or service not known',
      'nodename nor servname provided',
      'no address associated with hostname',
      'unable to resolve host',
    };
    for (final String hint in dnsHints) {
      if (lower.contains(hint)) {
        return ResultStatus.dnsError;
      }
    }
    return ResultStatus.connectionError;
  }

  /// Picks an end-user message for socket failures. Spec §21.
  static String _socketMessageFor(String message) {
    if (_classifySocketException(message) == ResultStatus.dnsError) {
      return '無法解析網域名稱，請檢查 URL 或 DNS 連線';
    }
    final String lower = message.toLowerCase();
    if (lower.contains('refused')) {
      return '目標伺服器拒絕連線';
    }
    if (lower.contains('network is unreachable') ||
        lower.contains('no network') ||
        lower.contains('software caused connection abort')) {
      return '目前沒有可用的網絡連線';
    }
    return '無法連線到目標伺服器';
  }
}
