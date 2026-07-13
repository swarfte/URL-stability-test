import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/test_configuration.dart';
import '../models/test_result.dart';
import '../models/test_session.dart';
import '../services/stability_test_service.dart';
import '../services/statistics_service.dart';

/// High-level state machine that owns the live [TestSession], drives the
/// [StabilityTestService], and exposes reactive state to the UI via
/// [ChangeNotifier]. Spec §18 (controllers) and §19 (state management).
///
/// Responsibilities (spec §19):
/// - Single, unambiguous session state.
/// - Prevents two concurrent sessions (§23.2).
/// - Forwards every completed result to the UI in real time.
/// - Supports cancellation; pending timer + client are released.
/// - Never notifies after [dispose] (no setState-after-dispose).
class StabilityTestController extends ChangeNotifier {
  StabilityTestController({
    StabilityTestService? service,
    StatisticsService? statisticsService,
  })  : _service = service ?? StabilityTestService(),
        _statistics = statisticsService ?? const StatisticsService();

  final StabilityTestService _service;
  final StatisticsService _statistics;

  TestSession? _session;
  TestRunnerPhase _phase = TestRunnerPhase.preparing;
  LatencyStatistics? _statisticsSnapshot;

  /// Flipped to true by [cancel]; read by the runner on every poll.
  bool _cancelRequested = false;
  bool _isDisposed = false;

  /// True while a run is in progress (running session exists).
  bool get isRunning =>
      _session != null && _session!.status == SessionStatus.running;

  TestSession? get session => _session;

  TestRunnerPhase get phase => _phase;

  /// Latest statistics computed from the results recorded so far. Updated
  /// after every result so the progress screen can show interim numbers.
  LatencyStatistics? get statisticsSnapshot => _statisticsSnapshot;

  /// The list of results recorded so far this session (read-only view).
  List<TestResult> get results =>
      _session?.results ?? const <TestResult>[];

  /// Begins a new run. Throws [StateError] if a run is already in progress
  /// (defensive: the UI should also disable the start button).
  Future<void> start(TestConfiguration configuration) async {
    if (isRunning) {
      throw StateError('A test session is already running.');
    }

    _cancelRequested = false;
    _statisticsSnapshot = null;
    _session = TestSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      configuration: configuration,
      startedAt: DateTime.now(),
    );
    _phase = TestRunnerPhase.preparing;
    _safeNotify();

    await _service.run(
      configuration: configuration,
      cancelled: () => _cancelRequested,
      onProgress: (int current, int total, TestRunnerPhase phase) {
        _phase = phase;
        _safeNotify();
      },
      onResult: (TestResult result) {
        // The session may have been replaced/nulled by dispose; guard.
        final TestSession? s = _session;
        if (s == null || s.status != SessionStatus.running) return;
        s.appendResult(result);
        _statisticsSnapshot = _statistics.compute(s.results.toList());
        _safeNotify();
      },
    );

    // The run has ended. Mark the session completed or cancelled.
    final TestSession? s = _session;
    if (s != null && s.status == SessionStatus.running) {
      s.markCompleted(
          _cancelRequested ? SessionStatus.cancelled : SessionStatus.completed);
      _statisticsSnapshot =
          _statistics.compute(s.results.toList());
      _phase = TestRunnerPhase.finished;
      _safeNotify();
    }
  }

  /// Requests cancellation of an in-flight run. Safe to call multiple times
  /// and safe to call when nothing is running. Spec §7.4.
  void cancel() {
    if (!isRunning) return;
    _cancelRequested = true;
    _phase = TestRunnerPhase.cancelled;
    _safeNotify();
  }

  /// Resets back to the idle state (no session). Used when leaving the result
  /// screen so a fresh run can begin.
  void reset() {
    _session = null;
    _statisticsSnapshot = null;
    _cancelRequested = false;
    _phase = TestRunnerPhase.preparing;
    _safeNotify();
  }

  void _safeNotify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Best-effort cancel so the runner unwinds rather than notifying a dead
    // listener. The service releases its own client/timer resources.
    _cancelRequested = true;
    super.dispose();
  }
}
