import 'package:flutter/cupertino.dart';

import '../../../shared/formatting/formatting.dart';
import '../services/statistics_service.dart';

/// The four primary metric cards. Spec §11.3.
class PrimaryStatisticsCards extends StatelessWidget {
  const PrimaryStatisticsCards({required this.statistics, super.key});

  final LatencyStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: <Widget>[
        _MetricCard(
          label: '平均延遲',
          value: formatLatencyMs(statistics.averageMs),
        ),
        _MetricCard(
          label: '成功率',
          value: formatSuccessRate(statistics.successRatePercent),
        ),
        _MetricCard(
          label: '最快',
          value: formatLatencyMs(statistics.minimumMs),
        ),
        _MetricCard(
          label: '最慢',
          value: formatLatencyMs(statistics.maximumMs),
        ),
      ],
    );
  }
}

/// The secondary metrics block. Spec §11.3.
class SecondaryStatisticsTable extends StatelessWidget {
  const SecondaryStatisticsTable({required this.statistics, super.key});

  final LatencyStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          _StatRow(label: '中位數（Median）', value: formatLatencyMs(statistics.medianMs)),
          _StatRow(label: '第 95 百分位（P95）', value: formatLatencyMs(statistics.p95Ms)),
          _StatRow(label: '抖動（Jitter）', value: formatLatencyMs(statistics.jitterMs)),
          const _Divider(),
          _StatRow(
              label: '成功',
              value: '${statistics.successCount} / '
                  '${statistics.completedCount}'),
          _StatRow(
              label: 'HTTP 錯誤', value: '${statistics.httpErrorCount}'),
          _StatRow(label: '超時', value: '${statistics.timeoutCount}'),
          _StatRow(
              label: '其他錯誤', value: '${statistics.otherErrorCount}'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style:
                  const TextStyle(color: CupertinoColors.secondaryLabel)),
          Text(
            value,
            style: const TextStyle(
              color: CupertinoColors.label,
              fontWeight: FontWeight.w500,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: CupertinoColors.separator.resolveFrom(context),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  color: CupertinoColors.label,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
