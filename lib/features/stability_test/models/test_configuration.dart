import 'connection_mode.dart';
import 'test_interval.dart';
import 'test_timeout.dart';

/// Everything the user can configure before starting a test run. Spec §17.1.
class TestConfiguration {
  const TestConfiguration({
    this.url = '',
    this.connectionMode = ConnectionMode.reuseClient,
    this.testCount = defaultTestCount,
    this.interval = TestInterval.defaultValue,
    this.timeout = TestTimeout.defaultValue,
    this.maxRedirects = defaultMaxRedirects,
    this.maxResponseBytes = defaultMaxResponseBytes,
  });

  /// Selectable test counts (spec §6.3).
  static const List<int> selectableTestCounts = <int>[5, 10, 20, 50];
  static const int defaultTestCount = 10;

  static const int defaultMaxRedirects = 5; // spec §8.4

  /// 10 MiB = 10 × 1024 × 1024 bytes. Spec §8.6.
  static const int defaultMaxResponseBytes = 10 * 1024 * 1024;

  /// What the user typed (already trimmed + auto-https-ified by the validation
  /// service before a configuration is created).
  final String url;
  final ConnectionMode connectionMode;
  final int testCount;
  final TestInterval interval;
  final TestTimeout timeout;
  final int maxRedirects;
  final int maxResponseBytes;

  TestConfiguration copyWith({
    String? url,
    ConnectionMode? connectionMode,
    int? testCount,
    TestInterval? interval,
    TestTimeout? timeout,
  }) {
    return TestConfiguration(
      url: url ?? this.url,
      connectionMode: connectionMode ?? this.connectionMode,
      testCount: testCount ?? this.testCount,
      interval: interval ?? this.interval,
      timeout: timeout ?? this.timeout,
    );
  }

  /// Serialise the user-editable subset for local storage (spec §16).
  Map<String, Object?> toJson() => <String, Object?>{
        'url': url,
        'connectionMode': connectionMode.storageKey,
        'testCount': testCount,
        'interval': interval.value,
        'timeout': timeout.value,
      };

  /// Inverse of [toJson]. Unrecognised values fall back to the spec defaults.
  factory TestConfiguration.fromJson(Map<String, Object?> json) {
    final int? testCount = json['testCount'] as int?;
    return TestConfiguration(
      url: (json['url'] as String?) ?? '',
      connectionMode:
          ConnectionMode.fromStorageKey(json['connectionMode'] as String?),
      testCount: selectableTestCounts.contains(testCount)
          ? testCount!
          : defaultTestCount,
      interval: TestInterval.fromValue(json['interval'] as int?),
      timeout: TestTimeout.fromValue(json['timeout'] as int?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestConfiguration &&
          url == other.url &&
          connectionMode == other.connectionMode &&
          testCount == other.testCount &&
          interval == other.interval &&
          timeout == other.timeout;

  @override
  int get hashCode => Object.hash(
        url,
        connectionMode,
        testCount,
        interval,
        timeout,
      );

  @override
  String toString() => 'TestConfiguration($url, $connectionMode, '
      'count=$testCount, interval=$interval, timeout=$timeout)';
}
