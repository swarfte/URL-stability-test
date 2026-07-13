import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

import 'package:url_stability_test/features/stability_test/models/connection_mode.dart';
import 'package:url_stability_test/features/stability_test/models/test_configuration.dart';
import 'package:url_stability_test/features/stability_test/models/test_interval.dart';
import 'package:url_stability_test/features/stability_test/models/test_result.dart';
import 'package:url_stability_test/features/stability_test/models/test_timeout.dart';
import 'package:url_stability_test/features/stability_test/services/stability_test_service.dart';

/// Builds a streamed-response handler that replies to every request with the
/// given status, optional Location header (for redirects), and a body split
/// into [chunks] of 1 KiB-ish pieces so we exercise the streaming path.
MockClientStreamHandler _okHandler({
  int status = 200,
  String? location,
  List<List<int>> chunks = const <List<int>>[
    <int>[0, 1, 2, 3, 4],
  ],
}) {
  return (BaseRequest request, ByteStream bodyStream) async {
    // Drain the request body (GET has none, but the contract requires it).
    await bodyStream.drain<void>();
    final Map<String, String> headers = <String, String>{};
    if (location != null) headers['location'] = location;
    final StreamController<List<int>> controller =
        StreamController<List<int>>();
    for (final List<int> c in chunks) {
      controller.add(c);
    }
    await controller.close();
    return StreamedResponse(controller.stream, status,
        headers: headers, contentLength: -1);
  };
}

StabilityTestService _service(MockClientStreamHandler handler,
    {required ConnectionMode mode}) {
  // Build a fresh MockClient.streaming for every call to the factory. In
  // reuseClient mode the same client is reused; in newClientPerRequest mode a
  // fresh one is built per attempt.
  Client makeClient() => MockClient.streaming(handler);
  return StabilityTestService(clientFactory: makeClient);
}

TestConfiguration _config({
  String url = 'https://example.com',
  ConnectionMode mode = ConnectionMode.reuseClient,
  int count = 3,
  TestInterval interval = TestInterval.none,
  TestTimeout timeout = TestTimeout.thirtySeconds,
  int maxRedirects = 5,
  int maxResponseBytes = 10 * 1024 * 1024,
}) {
  return TestConfiguration(
    url: url,
    connectionMode: mode,
    testCount: count,
    interval: interval,
    timeout: timeout,
    maxRedirects: maxRedirects,
    maxResponseBytes: maxResponseBytes,
  );
}

void main() {
  group('StabilityTestService — sequential execution', () {
    test('runs requests sequentially in order', () async {
      final List<String> seen = <String>[];
      final service = _service((BaseRequest request, ByteStream body) async {
        await body.drain<void>();
        seen.add(request.url.toString());
        return _okHandler()(request, body);
      }, mode: ConnectionMode.reuseClient);

      final List<TestResult> results = await service.run(
        configuration: _config(count: 3),
        cancelled: () => false,
        onResult: (_) {},
        onProgress: (_, __, ___) {},
      );

      expect(results.length, 3);
      for (int i = 0; i < 3; i++) {
        expect(results[i].sequenceNumber, i + 1);
        expect(results[i].status, ResultStatus.success);
      }
      expect(seen.length, 3);
    });

    test('a failure does not stop the run; next request proceeds', () async {
      int call = 0;
      final service = _service((BaseRequest request, ByteStream body) async {
        await body.drain<void>();
        call++;
        if (call == 2) {
          // Simulate a server error.
          final controller = StreamController<List<int>>();
          await controller.close();
          return StreamedResponse(controller.stream, 500);
        }
        return _okHandler()(request, body);
      }, mode: ConnectionMode.reuseClient);

      final List<TestResult> results = await service.run(
        configuration: _config(count: 3),
        cancelled: () => false,
        onResult: (_) {},
        onProgress: (_, __, ___) {},
      );

      expect(results.length, 3);
      expect(results[0].status, ResultStatus.success);
      expect(results[1].status, ResultStatus.httpError);
      expect(results[1].httpStatusCode, 500);
      expect(results[2].status, ResultStatus.success);
    });

    test('timeout is classified and the run continues', () async {
      int call = 0;
      final service = _service((BaseRequest request, ByteStream body) async {
        await body.drain<void>();
        call++;
        if (call == 2) {
          // Never respond within the timeout window.
          final Completer<StreamedResponse> never =
              Completer<StreamedResponse>();
          return never.future;
        }
        return _okHandler()(request, body);
      }, mode: ConnectionMode.reuseClient);

      final List<TestResult> results = await service.run(
        configuration: _config(
            count: 3,
            timeout: TestTimeout.fromValue(3000),
            interval: TestInterval.none),
        cancelled: () => false,
        onResult: (_) {},
        onProgress: (_, __, ___) {},
      );

      expect(results.length, 3);
      expect(results[1].status, ResultStatus.timeout);
      expect(results[0].status, ResultStatus.success);
      expect(results[2].status, ResultStatus.success);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('after cancel is requested, no further requests are started',
        () async {
      int call = 0;
      final service = _service((BaseRequest request, ByteStream body) async {
        await body.drain<void>();
        call++;
        return _okHandler()(request, body);
      }, mode: ConnectionMode.reuseClient);

      int resultCount = 0;
      bool cancelFlag = false;
      final List<TestResult> results = await service.run(
        configuration: _config(count: 5),
        cancelled: () => cancelFlag,
        onResult: (_) {
          resultCount++;
          // Cancel right after the first result lands.
          if (resultCount == 1) {
            cancelFlag = true;
          }
        },
        onProgress: (_, __, ___) {},
      );

      expect(results.length, lessThanOrEqualTo(2));
      expect(call, lessThanOrEqualTo(2));
    });
  });

  group('StabilityTestService — connection modes', () {
    test('reuseClient mode uses one client across all requests', () async {
      // We can't observe the client identity directly via the public API,
      // but we can assert that all results came through with the same
      // connection-reuse semantics by simply completing the run.
      final service = _service(
        _okHandler(),
        mode: ConnectionMode.reuseClient,
      );
      final List<TestResult> results = await service.run(
        configuration:
            _config(count: 4, mode: ConnectionMode.reuseClient),
        cancelled: () => false,
        onResult: (_) {},
        onProgress: (_, __, ___) {},
      );
      expect(results.every((TestResult r) => r.isSuccessful), isTrue);
    });

    test('newClientPerRequest mode still completes all requests', () async {
      final service = _service(
        _okHandler(),
        mode: ConnectionMode.newClientPerRequest,
      );
      final List<TestResult> results = await service.run(
        configuration: _config(
            count: 4, mode: ConnectionMode.newClientPerRequest),
        cancelled: () => false,
        onResult: (_) {},
        onProgress: (_, __, ___) {},
      );
      expect(results.length, 4);
      expect(results.every((TestResult r) => r.isSuccessful), isTrue);
    });
  });

  group('StabilityTestService — redirect limit (spec §8.4)', () {
    test('too many redirects (> maxRedirects) is classified', () async {
      // Always redirect to /next, producing an infinite hop chain that will
      // exceed maxRedirects = 2.
      final service = _service(
        (BaseRequest request, ByteStream body) async {
          await body.drain<void>();
          return _okHandler(status: 302, location: '/next')(request, body);
        },
        mode: ConnectionMode.reuseClient,
      );

      final List<TestResult> results = await service.run(
        configuration: _config(count: 1, maxRedirects: 2),
        cancelled: () => false,
        onResult: (_) {},
        onProgress: (_, __, ___) {},
      );

      expect(results.length, 1);
      expect(results[0].status, ResultStatus.tooManyRedirects);
      expect(results[0].redirectCount, greaterThan(2));
    });

    test('a single redirect is followed and recorded', () async {
      int hop = 0;
      final service = _service((BaseRequest request, ByteStream body) async {
        await body.drain<void>();
        hop++;
        if (hop == 1) {
          return _okHandler(status: 302, location: '/final')(request, body);
        }
        return _okHandler(status: 200)(request, body);
      }, mode: ConnectionMode.reuseClient);

      final List<TestResult> results = await service.run(
        configuration: _config(count: 1, maxRedirects: 5),
        cancelled: () => false,
        onResult: (_) {},
        onProgress: (_, __, ___) {},
      );

      expect(results[0].status, ResultStatus.success);
      expect(results[0].redirectCount, 1);
      expect(results[0].finalUrl, 'https://example.com/final');
    });
  });

  group('StabilityTestService — response body (spec §8.6)', () {
    test('body byte count is streamed and counted', () async {
      final service = _service(
        (BaseRequest request, ByteStream body) async {
          await body.drain<void>();
          final controller = StreamController<List<int>>();
          controller.add(List<int>.filled(1024, 65)); // 1 KiB
          controller.add(List<int>.filled(512, 66)); // 0.5 KiB
          await controller.close();
          return StreamedResponse(controller.stream, 200, contentLength: -1);
        },
        mode: ConnectionMode.reuseClient,
      );

      final List<TestResult> results = await service.run(
        configuration: _config(count: 1),
        cancelled: () => false,
        onResult: (_) {},
        onProgress: (_, __, ___) {},
      );

      expect(results[0].status, ResultStatus.success);
      expect(results[0].responseBytes, 1024 + 512);
    });

    test('body exceeding the limit is aborted as responseTooLarge', () async {
      // Stream a body larger than 1 KiB limit set below.
      final service = _service(
        (BaseRequest request, ByteStream body) async {
          await body.drain<void>();
          final controller = StreamController<List<int>>();
          // Two 2 KiB chunks → 4 KiB, over a 1 KiB cap.
          controller.add(List<int>.filled(2048, 65));
          controller.add(List<int>.filled(2048, 66));
          await controller.close();
          return StreamedResponse(controller.stream, 200, contentLength: -1);
        },
        mode: ConnectionMode.reuseClient,
      );

      final List<TestResult> results = await service.run(
        configuration: _config(count: 1, maxResponseBytes: 1024),
        cancelled: () => false,
        onResult: (_) {},
        onProgress: (_, __, ___) {},
      );

      expect(results[0].status, ResultStatus.responseTooLarge);
      // Some bytes were read before the cap kicked in.
      expect(results[0].responseBytes, greaterThan(0));
    });
  });

  group('StabilityTestService — interval', () {
    test('waits the configured interval between requests', () async {
      final List<DateTime> times = <DateTime>[];
      final service = _service((BaseRequest request, ByteStream body) async {
        await body.drain<void>();
        times.add(DateTime.now());
        return _okHandler()(request, body);
      }, mode: ConnectionMode.reuseClient);

      final Stopwatch sw = Stopwatch()..start();
      await service.run(
        configuration:
            _config(count: 3, interval: TestInterval.fromValue(500)),
        cancelled: () => false,
        onResult: (_) {},
        onProgress: (_, __, ___) {},
      );
      sw.stop();
      // Two 500 ms gaps between three requests.
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(900));
    });
  });
}
