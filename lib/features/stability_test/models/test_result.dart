/// Outcome classification for a single request. Each result belongs to exactly
/// one category. Spec §9 and §17.4.
enum ResultStatus {
  success,
  httpError,
  timeout,
  dnsError,
  connectionError,
  tlsError,
  tooManyRedirects,
  responseTooLarge,
  cancelled,
  unknownError,
}

/// Whether a status contributes to the "success" latency statistics.
///
/// Only [ResultStatus.success] does (spec §10). All other statuses are
/// excluded from avg/median/min/max/p95/jitter but still counted in the
/// success-rate denominator (§10.7) — except [ResultStatus.cancelled], which
/// does not count as a completed attempt at all.
bool isSuccessfulStatus(ResultStatus status) =>
    status == ResultStatus.success;

/// The recorded outcome of a single GET request within a test run.
///
/// Spec §17.3. [elapsedMicroseconds] is nullable: for instance, a request that
/// was cancelled before it was sent has no elapsed time.
class TestResult {
  TestResult({
    required this.sequenceNumber,
    required this.startedAt,
    required this.completedAt,
    required this.elapsedMicroseconds,
    required this.status,
    required this.httpStatusCode,
    required this.responseBytes,
    required this.redirectCount,
    required this.originalUrl,
    required this.finalUrl,
    required this.errorType,
    required this.errorMessage,
  });

  /// 1-based index within the test run.
  final int sequenceNumber;

  /// When the request was dispatched (wall clock, for display only).
  final DateTime startedAt;

  /// When the result was finalised (wall clock, for display only).
  final DateTime completedAt;

  /// Monotonic elapsed time measured by a Stopwatch (spec §8.5), in
  /// microseconds. Null means no measurement was taken (e.g. cancelled before
  /// sending).
  final int? elapsedMicroseconds;

  final ResultStatus status;

  /// HTTP status code if a response was received, otherwise null.
  final int? httpStatusCode;

  /// Number of response-body bytes read (streamed, never buffered wholesale).
  final int responseBytes;

  /// Number of redirects followed.
  final int redirectCount;

  /// The URL the user supplied.
  final String originalUrl;

  /// The URL actually fetched (after redirects). Equals [originalUrl] when no
  /// redirect occurred.
  final String finalUrl;

  /// Safe, coarse error category string (e.g. 'SocketException'), nullable.
  final String? errorType;

  /// Plain-language summary safe to show end users (spec §21). Nullable.
  final String? errorMessage;

  /// Latency in milliseconds rounded to the nearest integer for display.
  /// Returns null when there is no elapsed time.
  int? get elapsedMilliseconds => elapsedMicroseconds == null
      ? null
      : (elapsedMicroseconds! / 1000).round();

  /// Whether this result counts as a successful measurement.
  bool get isSuccessful => isSuccessfulStatus(status);

  @override
  String toString() =>
      'TestResult(#$sequenceNumber $status ${elapsedMilliseconds ?? '-'}ms)';
}
