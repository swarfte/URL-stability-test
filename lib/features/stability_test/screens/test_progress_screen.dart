import 'package:flutter/cupertino.dart';

import '../../../app/routes.dart';
import '../../../shared/accessibility/semantics.dart';
import '../../../shared/formatting/formatting.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../controllers/stability_test_controller.dart';
import '../models/test_configuration.dart';
import '../models/test_result.dart';
import '../models/test_session.dart';
import '../services/statistics_service.dart';
import '../services/stability_test_service.dart';
import '../widgets/connection_mode_selector.dart';
import '../widgets/progress_summary.dart';

/// Page 2 — live progress. Spec §7.
///
/// On entering it kicks off the test (the setup screen navigated here after the
/// configuration was validated but before starting). When the run ends
/// (completed or cancelled) it auto-redirects to the result screen.
class TestProgressScreen extends StatefulWidget {
  const TestProgressScreen({required this.controller, super.key});

  final StabilityTestController controller;

  @override
  State<TestProgressScreen> createState() => _TestProgressScreenState();
}

class _TestProgressScreenState extends State<TestProgressScreen> {
  bool _didStart = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    // Defer the first start to after the first frame so the route transition
    // is not janky.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    final TestSession? s = widget.controller.session;
    if (s != null && s.status != SessionStatus.running && mounted) {
      // Run ended — go to the result screen, replacing this route so back from
      // the result screen lands on setup rather than here.
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.result);
    }
  }

  Future<void> _maybeStart() async {
    if (_didStart) return;
    _didStart = true;
    final TestSession? s = widget.controller.session;
    if (s == null || s.status != SessionStatus.running) {
      // The controller hasn't been given a configuration yet. Read the session
      // config; if missing, pop back to setup.
      if (widget.controller.session == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      await widget.controller.start(widget.controller.session!.configuration);
    }
  }

  Future<bool> _confirmCancel() async {
    final bool? result = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: const Text('取消測試？'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('目前測試尚未完成。已完成的結果仍可保留。'),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('繼續測試'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('取消測試'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onCancelPressed() async {
    final bool shouldCancel = await _confirmCancel();
    if (shouldCancel && mounted) {
      widget.controller.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final StabilityTestController c = widget.controller;
    final TestSession? session = c.session;
    final int done = session?.completedCount ?? 0;
    final int total = session?.configuredCount ?? 0;
    final String statusText = _phaseText(c.phase, done);
    final List<TestResult> recent = session?.results.reversed.toList() ??
        const <TestResult>[];

    // Intercept Android back / navigator back via PopScope (spec §7.1).
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (await _confirmCancel()) {
          c.cancel();
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('測試進行中'),
          // No automatic back button during a run (spec §7.1). Provide a
          // manual cancel affordance via the trailing button instead.
          automaticallyImplyLeading: false,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _onCancelPressed,
            child: const Text(
              '取消',
              style: TextStyle(color: CupertinoColors.destructiveRed),
            ),
          ),
        ),
        child: ResponsiveContentBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _summaryHeader(session),
              const SizedBox(height: 16),
              ProgressSummary(
                done: done,
                total: total,
                statusText: statusText,
              ),
              const SizedBox(height: 16),
              _interimStats(c.statisticsSnapshot),
              const SizedBox(height: 16),
              _recentResultsSection(recent),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: CupertinoButton(
                  color: CupertinoColors.destructiveRed,
                  onPressed: _onCancelPressed,
                  child: const Text(
                    '取消測試',
                    style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- Pieces -----------------------------------------------------------

  Widget _summaryHeader(TestSession? session) {
    if (session == null) {
      return const SizedBox.shrink();
    }
    final TestConfiguration config = session.configuration;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            config.url,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${connectionModeShortLabel(config.connectionMode)} · '
            '${config.testCount} 次 · 超時 ${config.timeout.label}',
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _interimStats(LatencyStatistics? stats) {
    if (stats == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '暫時結果',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          _StatRow(
              label: '平均', value: formatLatencyMs(stats.averageMs)),
          _StatRow(
              label: '最快', value: formatLatencyMs(stats.minimumMs)),
          _StatRow(
              label: '最慢', value: formatLatencyMs(stats.maximumMs)),
          _StatRow(
              label: '成功率',
              value: formatSuccessRate(stats.successRatePercent)),
        ],
      ),
    );
  }

  Widget _recentResultsSection(List<TestResult> recent) {
    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }
    final List<Widget> rows = <Widget>[];
    for (final TestResult r in recent.take(5)) {
      final ResultStatusPresentation p =
          ResultStatusPresentation.forStatus(r.status);
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 28,
              child: Text('#${r.sequenceNumber}',
                  style: const TextStyle(
                      color: CupertinoColors.secondaryLabel)),
            ),
            Expanded(
              child: Text(
                r.httpStatusCode?.toString() ?? p.symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                r.isSuccessful && r.elapsedMilliseconds != null
                    ? '${r.elapsedMilliseconds} ms'
                    : '—',
                textAlign: TextAlign.right,
                style: const TextStyle(),
              ),
            ),
            const SizedBox(width: 12),
            Text(p.label,
                style: const TextStyle(
                    color: CupertinoColors.secondaryLabel, fontSize: 13)),
          ],
        ),
      ));
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '最近測試',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  String _phaseText(TestRunnerPhase phase, int done) {
    switch (phase) {
      case TestRunnerPhase.preparing:
        return '準備測試……';
      case TestRunnerPhase.request:
        return done == 0 ? '正在執行第 1 次測試……' : '正在執行第 ${done + 1} 次測試……';
      case TestRunnerPhase.waiting:
        return '等待下一次測試……';
      case TestRunnerPhase.cancelled:
        return '正在取消……';
      case TestRunnerPhase.finished:
        return '測試完成';
    }
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: const TextStyle(color: CupertinoColors.secondaryLabel)),
          // tabular-ish via fixed alignment; numbers right-aligned.
          Text(value,
              style: const TextStyle(fontFeatures: <FontFeature>[])),
        ],
      ),
    );
  }
}
