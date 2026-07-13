import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../../app/routes.dart';
import '../../../shared/formatting/formatting.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../controllers/stability_test_controller.dart';
import '../models/test_configuration.dart';
import '../models/test_session.dart';
import '../services/statistics_service.dart';
import '../widgets/connection_mode_selector.dart';
import '../widgets/latency_chart.dart';
import '../widgets/result_list.dart';
import '../widgets/statistics_cards.dart';

/// Page 3 — test results. Spec §11.
class TestResultScreen extends StatefulWidget {
  const TestResultScreen({required this.controller, super.key});

  final StabilityTestController controller;

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  late final LatencyStatistics _stats;

  @override
  void initState() {
    super.initState();
    final StatisticsService stats = const StatisticsService();
    _stats = stats.compute(
      widget.controller.session?.results.toList() ?? const <Never>[],
    );
  }

  bool get _isCancelled =>
      widget.controller.session?.status == SessionStatus.cancelled;

  Future<void> _retest() async {
    final TestSession? session = widget.controller.session;
    if (session == null) return;
    // Re-run with the exact same configuration (spec §11.6).
    final cfg = session.configuration;
    widget.controller.reset();
    // Start the new run after navigating; the progress screen kicks it off.
    if (!mounted) return;
    // Push to progress and start. We can't await start from here safely
    // because the progress screen also calls start; to avoid double-start,
    // we pre-seed the controller by having the progress screen begin it.
    // Simplest: replace route to progress, which will start from its
    // postFrameCallback using the controller — but it needs a config. The
    // progress screen starts only if session is null OR not running. We
    // reset() above, so it will be null; we need to hand it the config.
    // To keep things simple and robust, start synchronously here before
    // navigating.
    unawaited(widget.controller.start(cfg));
    if (!mounted) return;
    await Navigator.of(context).pushReplacementNamed(AppRoutes.progress);
  }

  void _editSettings() {
    // Pop back to setup; the setup screen keeps its own state via the
    // restored configuration in storage. Spec §11.6.
    Navigator.of(context).popUntil(
      (Route<dynamic> route) => route.settings.name == AppRoutes.setup,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TestSession? session = widget.controller.session;
    final bool empty = session == null || session.results.isEmpty;
    final String title = _isCancelled ? '未完成的測試' : '測試結果';

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        automaticallyImplyLeading: false,
      ),
      child: ResponsiveContentBox(
        wideMaxWidth: 1200,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: empty ? _emptyState() : _body(context, session),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Text(
          '測試已取消，沒有可用結果。',
          style: TextStyle(color: CupertinoColors.secondaryLabel),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, TestSession session) {
    final bool wide = isWideViewport(context);
    final Widget summary = _summary(session);
    final Widget primaryCards = PrimaryStatisticsCards(statistics: _stats);
    final Widget secondary = SecondaryStatisticsTable(statistics: _stats);
    final Widget chart = LatencyChart(results: session.results.toList());
    final Widget list = ResultList(results: session.results.toList());
    final Widget actions = _actions();

    final Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        summary,
        const SizedBox(height: 16),
        primaryCards,
        const SizedBox(height: 16),
        secondary,
        const SizedBox(height: 16),
        chart,
      ],
    );

    final Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '詳細結果',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 13,
            ),
          ),
        ),
        list,
      ],
    );

    if (wide) {
      // Two-column layout on wide viewports (spec §12.2).
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 3, child: leftColumn),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: rightColumn),
            ],
          ),
          const SizedBox(height: 16),
          actions,
        ],
      );
    }

    // Single column on narrow viewports (spec §12.1).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        leftColumn,
        const SizedBox(height: 16),
        rightColumn,
        const SizedBox(height: 16),
        actions,
      ],
    );
  }

  Widget _summary(TestSession session) {
    final TestConfiguration config = session.configuration;
    final String status = _isCancelled ? '已取消' : '已完成';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            config.url,
            style: const TextStyle(
              color: CupertinoColors.label,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${connectionModeShortLabel(config.connectionMode)} · '
            '$status ${session.completedCount} / ${config.testCount} 次',
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 13,
            ),
          ),
          if (session.completedAt != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              formatDateTime(session.completedAt!),
              style: const TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 52,
                child: CupertinoButton.filled(
                  onPressed: _retest,
                  child: const Text('再次測試'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: CupertinoButton(
                  color: CupertinoColors.secondarySystemGroupedBackground,
                  onPressed: _editSettings,
                  child: const Text(
                    '修改設定',
                    style: TextStyle(color: CupertinoColors.label),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
