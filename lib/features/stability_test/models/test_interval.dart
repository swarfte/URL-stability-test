/// Predefined wait time between two sequential requests (spec §6.4).
///
/// The interval is the time waited *after* one request completes and *before*
/// the next request starts — not a fixed clock cadence.
class TestInterval {
  const TestInterval._(this.value, this.label);

  /// Value in milliseconds. Stored so the runner can await it directly.
  final int value;

  /// Human readable label shown in the picker (Traditional Chinese).
  final String label;

  static const TestInterval none = TestInterval._(0, '無間隔');
  static const TestInterval halfSecond = TestInterval._(500, '0.5 秒');
  static const TestInterval oneSecond = TestInterval._(1000, '1 秒');
  static const TestInterval twoSeconds = TestInterval._(2000, '2 秒');
  static const TestInterval fiveSeconds = TestInterval._(5000, '5 秒');

  /// All selectable options in display order (spec §6.4).
  static const List<TestInterval> options = <TestInterval>[
    none,
    halfSecond,
    oneSecond,
    twoSeconds,
    fiveSeconds,
  ];

  /// Default per spec §6.4.
  static const TestInterval defaultValue = oneSecond;

  Duration get duration => Duration(milliseconds: value);

  /// Round-trip to local storage by millisecond value.
  static TestInterval fromValue(int? value) {
    for (final TestInterval option in options) {
      if (option.value == value) {
        return option;
      }
    }
    return defaultValue;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestInterval && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TestInterval(${value}ms)';
}
