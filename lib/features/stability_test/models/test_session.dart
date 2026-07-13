import 'dart:collection';

import 'test_configuration.dart';
import 'test_result.dart';

/// Lifecycle state of a test run. Spec §17.2.
enum SessionStatus {
  running,
  completed,
  cancelled,
}

/// A single end-to-end test run against one URL. Spec §17.2.
///
/// [results] is the ordered record of every completed request. It is an
/// unmodifiable view so callers can iterate freely without worrying about
/// concurrent mutation by the runner.
class TestSession {
  TestSession({
    required this.id,
    required this.configuration,
    required this.startedAt,
  }) : _status = SessionStatus.running;

  final String id;
  final TestConfiguration configuration;

  /// Wall clock; for display only, not used in latency math.
  final DateTime startedAt;
  DateTime? completedAt;

  SessionStatus _status;
  SessionStatus get status => _status;

  /// Marks the session as finished (either completed or cancelled) and stamps
  /// [completedAt]. Intended for the controller/service only.
  void markCompleted(SessionStatus finalStatus) {
    assert(finalStatus != SessionStatus.running);
    _status = finalStatus;
    completedAt ??= DateTime.now();
  }

  final List<TestResult> _results = <TestResult>[];
  List<TestResult> get results => UnmodifiableListView(_results);

  void appendResult(TestResult result) {
    assert(_status == SessionStatus.running,
        'Results cannot be added to a finished session.');
    _results.add(result);
  }

  /// Convenience: number of recorded results (== completed attempts).
  int get completedCount => _results.length;

  int get configuredCount => configuration.testCount;

  @override
  String toString() =>
      'TestSession($id ${_status.name} $completedCount/$configuredCount)';
}
