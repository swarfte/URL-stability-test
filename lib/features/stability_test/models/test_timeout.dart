/// Predefined per-request timeout (spec §6.5).
///
/// The timeout applies to each individual request, not the whole run. On
/// timeout the current request is recorded as `timeout`, the client for that
/// request is closed, and the run continues with the next request.
class TestTimeout {
  const TestTimeout._(this.value, this.label);

  /// Value in milliseconds.
  final int value;

  /// Human readable label shown in the picker (Traditional Chinese).
  final String label;

  static const TestTimeout threeSeconds = TestTimeout._(3000, '3 秒');
  static const TestTimeout fiveSeconds = TestTimeout._(5000, '5 秒');
  static const TestTimeout tenSeconds = TestTimeout._(10000, '10 秒');
  static const TestTimeout thirtySeconds = TestTimeout._(30000, '30 秒');

  /// All selectable options in display order (spec §6.5).
  static const List<TestTimeout> options = <TestTimeout>[
    threeSeconds,
    fiveSeconds,
    tenSeconds,
    thirtySeconds,
  ];

  /// Default per spec §6.5.
  static const TestTimeout defaultValue = tenSeconds;

  Duration get duration => Duration(milliseconds: value);

  static TestTimeout fromValue(int? value) {
    for (final TestTimeout option in options) {
      if (option.value == value) {
        return option;
      }
    }
    return defaultValue;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestTimeout && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TestTimeout(${value}ms)';
}
