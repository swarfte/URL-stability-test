import 'package:flutter_test/flutter_test.dart';
import 'package:url_stability_test/features/stability_test/models/test_result.dart';
import 'package:url_stability_test/features/stability_test/services/statistics_service.dart';

TestResult _success(int seq, int ms, {int bytes = 100}) {
  return TestResult(
    sequenceNumber: seq,
    startedAt: DateTime(2026, 1, 1),
    completedAt: DateTime(2026, 1, 1),
    elapsedMicroseconds: ms * 1000,
    status: ResultStatus.success,
    httpStatusCode: 200,
    responseBytes: bytes,
    redirectCount: 0,
    originalUrl: 'https://example.com',
    finalUrl: 'https://example.com',
    errorType: null,
    errorMessage: null,
  );
}

TestResult _other(int seq, ResultStatus status) {
  return TestResult(
    sequenceNumber: seq,
    startedAt: DateTime(2026, 1, 1),
    completedAt: DateTime(2026, 1, 1),
    elapsedMicroseconds: 50 * 1000,
    status: status,
    httpStatusCode: status == ResultStatus.httpError ? 503 : null,
    responseBytes: 0,
    redirectCount: 0,
    originalUrl: 'https://example.com',
    finalUrl: 'https://example.com',
    errorType: null,
    errorMessage: null,
  );
}

void main() {
  const StatisticsService service = StatisticsService();

  group('StatisticsService — Average', () {
    test('simple average of successes only', () {
      final LatencyStatistics s = service.compute(<TestResult>[
        _success(1, 100),
        _success(2, 200),
        _success(3, 300),
      ]);
      expect(s.averageMs, 200);
      expect(s.successCount, 3);
    });

    test('failure latencies are excluded from average', () {
      final LatencyStatistics s = service.compute(<TestResult>[
        _success(1, 100),
        _success(2, 200),
        _other(3, ResultStatus.timeout),
      ]);
      expect(s.averageMs, 150);
      expect(s.successCount, 2);
      expect(s.timeoutCount, 1);
    });
  });

  group('StatisticsService — Min / Max', () {
    test('min and max over successes', () {
      final LatencyStatistics s = service.compute(<TestResult>[
        _success(1, 62),
        _success(2, 241),
        _success(3, 100),
      ]);
      expect(s.minimumMs, 62);
      expect(s.maximumMs, 241);
    });
  });

  group('StatisticsService — Median', () {
    test('odd count → middle value', () {
      final LatencyStatistics s = service.compute(<TestResult>[
        _success(1, 60),
        _success(2, 200),
        _success(3, 100),
      ]);
      // sorted: 60, 100, 200 → median 100
      expect(s.medianMs, 100);
    });

    test('even count → mean of middle two', () {
      final LatencyStatistics s = service.compute(<TestResult>[
        _success(1, 60),
        _success(2, 200),
        _success(3, 100),
        _success(4, 70),
      ]);
      // sorted: 60, 70, 100, 200 → median (70 + 100) / 2 = 85
      expect(s.medianMs, 85);
    });
  });

  group('StatisticsService — P95 (nearest rank, spec §10.5)', () {
    test('rank = ceil(0.95 * N)', () {
      // 20 samples → rank = ceil(19) = 19 → 19th value of ascending list.
      final List<TestResult> results = <TestResult>[
        for (int i = 1; i <= 20; i++) _success(i, i * 10),
      ];
      final LatencyStatistics s = service.compute(results);
      expect(s.p95Ms, 190); // 19th smallest = 190
    });

    test('single success → P95 equals that result', () {
      final LatencyStatistics s =
          service.compute(<TestResult>[_success(1, 77)]);
      expect(s.p95Ms, 77);
    });

    test('10 samples → rank = ceil(9.5) = 10 → max', () {
      final List<TestResult> results = <TestResult>[
        for (int i = 1; i <= 10; i++) _success(i, i * 10),
      ];
      final LatencyStatistics s = service.compute(results);
      expect(s.p95Ms, 100);
    });
  });

  group('StatisticsService — Jitter (spec §10.6)', () {
    test('mean of abs adjacent differences over successes in order', () {
      // ordered successes: 100, 150, 120 → diffs 50, 30 → mean 40
      final LatencyStatistics s = service.compute(<TestResult>[
        _success(1, 100),
        _success(2, 150),
        _success(3, 120),
      ]);
      expect(s.jitterMs, 40);
    });

    test('failures removed, jitter recomputed across remaining gaps', () {
      // ordered successes: 100, 200 (failure between, ignored) → 200,180
      // diffs: |200-100|=100, |180-200|=20 → mean 60
      final LatencyStatistics s = service.compute(<TestResult>[
        _success(1, 100),
        _other(2, ResultStatus.timeout),
        _success(3, 200),
        _success(4, 180),
      ]);
      expect(s.jitterMs, 60);
    });
  });

  group('StatisticsService — Success rate (spec §10.7)', () {
    test('successes / completed (failures counted in denominator)', () {
      final LatencyStatistics s = service.compute(<TestResult>[
        _success(1, 100),
        _success(2, 100),
        _other(3, ResultStatus.timeout),
        _other(4, ResultStatus.httpError),
        _other(5, ResultStatus.connectionError),
      ]);
      // 2 successes / 5 completed = 40%
      expect(s.successRate, closeTo(0.4, 1e-9));
      expect(s.successRatePercent, 40);
    });
  });

  group('StatisticsService — no successes (spec §10.8)', () {
    test('everything N/A, never 0', () {
      final LatencyStatistics s = service.compute(<TestResult>[
        _other(1, ResultStatus.timeout),
        _other(2, ResultStatus.httpError),
      ]);
      expect(s.averageMs, isNull);
      expect(s.medianMs, isNull);
      expect(s.minimumMs, isNull);
      expect(s.maximumMs, isNull);
      expect(s.p95Ms, isNull);
      expect(s.jitterMs, isNull);
      expect(s.successRatePercent, 0);
    });

    test('empty input → completedCount 0 → successRate N/A', () {
      final LatencyStatistics s =
          service.compute(const <TestResult>[]);
      expect(s.completedCount, 0);
      expect(s.successRate, isNull);
      expect(s.successRatePercent, isNull);
    });
  });

  group('StatisticsService — single success', () {
    test('jitter N/A (fewer than two successes)', () {
      final LatencyStatistics s =
          service.compute(<TestResult>[_success(1, 100)]);
      // Spec §10.6: fewer than two successes → Jitter = N/A.
      expect(s.jitterMs, isNull);
      expect(s.averageMs, 100);
    });
  });

  group('StatisticsService — status counting', () {
    test('timeout and HTTP error and other error tallied', () {
      final LatencyStatistics s = service.compute(<TestResult>[
        _success(1, 100),
        _other(2, ResultStatus.timeout),
        _other(3, ResultStatus.httpError),
        _other(4, ResultStatus.dnsError),
        _other(5, ResultStatus.tlsError),
      ]);
      expect(s.timeoutCount, 1);
      expect(s.httpErrorCount, 1);
      expect(s.otherErrorCount, 2);
    });
  });
}
