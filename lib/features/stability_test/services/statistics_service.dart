import '../models/test_result.dart';

/// Summary statistics over a set of test results. All latency values are
/// stored internally in microseconds to avoid premature rounding (spec §10)
/// and exposed as nullable milliseconds rounded to the nearest integer — null
/// means "no successful measurement, display N/A" (spec §10.8).
class LatencyStatistics {
  const LatencyStatistics({
    required this.successCount,
    required this.completedCount,
    required this.averageMs,
    required this.minimumMs,
    required this.maximumMs,
    required this.medianMs,
    required this.p95Ms,
    required this.jitterMs,
    required this.timeoutCount,
    required this.httpErrorCount,
    required this.otherErrorCount,
  });

  /// Number of results with status `success` (the latency-statistics base).
  final int successCount;

  /// Number of completed attempts, i.e. everything except cancelled attempts.
  /// Spec §10.7 denominator.
  final int completedCount;

  final int? averageMs;
  final int? minimumMs;
  final int? maximumMs;
  final int? medianMs;
  final int? p95Ms;
  final int? jitterMs;

  final int timeoutCount;
  final int httpErrorCount;
  final int otherErrorCount;

  /// Success rate as a fraction in [0, 1]. Null when no completed results.
  double? get successRate =>
      completedCount == 0 ? null : successCount / completedCount;

  /// Success rate as a rounded percentage (0–100). Null when no completed
  /// results.
  int? get successRatePercent {
    final double? rate = successRate;
    return rate == null ? null : (rate * 100).round();
  }
}

/// Pure functions that compute [LatencyStatistics] from a list of results.
///
/// Only `success` results contribute to latency stats (spec §10). The
/// implementation has no Flutter dependency and is exhaustively unit-tested
/// (spec §22.1).
class StatisticsService {
  const StatisticsService();

  LatencyStatistics compute(List<TestResult> results) {
    final List<int> successLatenciesUs = <int>[];
    final List<TestResult> orderedSuccesses = <TestResult>[];
    int timeoutCount = 0;
    int httpErrorCount = 0;
    int otherErrorCount = 0;
    int successCount = 0;

    for (final TestResult r in results) {
      switch (r.status) {
        case ResultStatus.success:
          successCount++;
          if (r.elapsedMicroseconds != null) {
            successLatenciesUs.add(r.elapsedMicroseconds!);
            orderedSuccesses.add(r);
          }
        case ResultStatus.httpError:
          httpErrorCount++;
        case ResultStatus.timeout:
          timeoutCount++;
        case ResultStatus.cancelled:
          // Cancelled attempts do not count toward completedCount at all.
          continue;
        default:
          // dnsError, connectionError, tlsError, tooManyRedirects,
          // responseTooLarge, unknownError.
          otherErrorCount++;
      }
    }

    final int completedCount =
        successCount + timeoutCount + httpErrorCount + otherErrorCount;

    if (successLatenciesUs.isEmpty) {
      return LatencyStatistics(
        successCount: 0,
        completedCount: completedCount,
        averageMs: null,
        minimumMs: null,
        maximumMs: null,
        medianMs: null,
        p95Ms: null,
        jitterMs: null,
        timeoutCount: timeoutCount,
        httpErrorCount: httpErrorCount,
        otherErrorCount: otherErrorCount,
      );
    }

    final List<int> sorted = List<int>.of(successLatenciesUs)..sort();

    return LatencyStatistics(
      successCount: successCount,
      completedCount: completedCount,
      averageMs: _usToRoundedMs(_average(successLatenciesUs)),
      minimumMs: _usToRoundedMs(sorted.first.toDouble()),
      maximumMs: _usToRoundedMs(sorted.last.toDouble()),
      medianMs: _usToRoundedMs(_median(sorted)),
      p95Ms: _usToRoundedMs(_p95(sorted)),
      jitterMs: _usToRoundedMs(_jitter(orderedSuccesses
          .map((TestResult r) => r.elapsedMicroseconds!)
          .toList(growable: false))),
      timeoutCount: timeoutCount,
      httpErrorCount: httpErrorCount,
      otherErrorCount: otherErrorCount,
    );
  }

  /// Sum / n.
  static double _average(List<int> values) {
    if (values.isEmpty) return 0;
    int sum = 0;
    for (final int v in values) {
      sum += v;
    }
    return sum / values.length;
  }

  /// Middle value (odd) or mean of the two middle values (even). [sorted] must
  /// be sorted ascending and non-empty. Spec §10.4.
  static double _median(List<int> sorted) {
    final int n = sorted.length;
    if (n % 2 == 1) {
      return sorted[n ~/ 2].toDouble();
    }
    final int left = sorted[(n ~/ 2) - 1];
    final int right = sorted[n ~/ 2];
    return (left + right) / 2;
  }

  /// Nearest-rank percentile: rank = ceil(0.95 * N), then take the value at
  /// that 1-based rank. Spec §10.5. [sorted] must be ascending and non-empty.
  static double _p95(List<int> sorted) {
    final int n = sorted.length;
    if (n == 1) return sorted[0].toDouble();
    final int rank = (0.95 * n).ceil();
    // rank is in [1, n] because 0.95 ∈ (0, 1).
    final int clampedRank = rank.clamp(1, n);
    return sorted[clampedRank - 1].toDouble();
  }

  /// Mean of the absolute differences between adjacent *successful* results in
  /// their original run order. Spec §10.6. Returns 0 when fewer than two
  /// values.
  static double _jitter(List<int> ordered) {
    if (ordered.length < 2) return 0;
    int sumDiffs = 0;
    for (int i = 1; i < ordered.length; i++) {
      sumDiffs += (ordered[i] - ordered[i - 1]).abs();
    }
    return sumDiffs / (ordered.length - 1);
  }

  static int? _usToRoundedMs(double microseconds) {
    if (microseconds.isNaN) return null;
    return (microseconds / 1000).round();
  }
}
