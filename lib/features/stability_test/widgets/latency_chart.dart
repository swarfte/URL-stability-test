import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';

import '../../../shared/accessibility/semantics.dart';
import '../models/test_result.dart';

/// Line chart of per-request latency. Spec §11.4.
///
/// Points are colour-coded by status, and the legend / tooltips add a textual
/// symbol so colour is not the sole cue (spec §11.4, §15). Touch (Android)
/// and hover (desktop) reveal a tooltip.
class LatencyChart extends StatelessWidget {
  const LatencyChart({required this.results, super.key});

  /// Results in their original run order. Cancelled results are skipped per
  /// spec §11.4 ("被取消的 request：不顯示").
  final List<TestResult> results;

  @override
  Widget build(BuildContext context) {
    // Index of every non-cancelled result on the X axis.
    final List<TestResult> plottable = results
        .where((TestResult r) => r.status != ResultStatus.cancelled)
        .toList(growable: false);
    final List<TestResult> successes = plottable
        .where(
          (TestResult r) => r.isSuccessful && r.elapsedMilliseconds != null,
        )
        .toList(growable: false);

    final bool hasSuccess = successes.isNotEmpty;
    final String semanticsSummary = _semanticsSummary(plottable, successes);

    return labelled(
      Container(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: hasSuccess
            ? _chart(context, plottable, successes)
            : const _NoData(),
      ),
      label: semanticsSummary,
    );
  }

  Widget _chart(
    BuildContext context,
    List<TestResult> plottable,
    List<TestResult> successes,
  ) {
    final double maxY = successes
        .map((TestResult r) => r.elapsedMilliseconds!.toDouble())
        .reduce((double a, double b) => a > b ? a : b);
    final double paddedMaxY = (maxY * 1.15).clamp(1.0, double.infinity);

    // Map fl_chart spot index → original result, for tooltip + dot colour.
    final Map<int, TestResult> spotIndex = <int, TestResult>{};
    final List<FlSpot> lineSpots = <FlSpot>[];
    for (int i = 0; i < successes.length; i++) {
      final int xOnAxis = plottable.indexOf(successes[i]);
      spotIndex[i] = successes[i];
      lineSpots.add(
        FlSpot(
          xOnAxis.toDouble(),
          successes[i].elapsedMilliseconds!.toDouble(),
        ),
      );
    }
    // Assign colours per spot: only success points lie on the line, but we
    // still vary colour in case of future extension.
    final Map<int, Color> spotColors = <int, Color>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            '延遲走勢',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (plottable.length - 1).toDouble().clamp(0, double.infinity),
              minY: 0,
              maxY: paddedMaxY,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((LineBarSpot spot) {
                      final TestResult r = spotIndex[spot.spotIndex]!;
                      final ResultStatusPresentation p =
                          ResultStatusPresentation.forStatus(r.status);
                      return LineTooltipItem(
                        '#${r.sequenceNumber}  ${p.label}\n'
                        '${r.elapsedMilliseconds} ms',
                        const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList();
                  },
                ),
                getTouchedSpotIndicator:
                    (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((int index) {
                        return TouchedSpotIndicatorData(
                          const FlLine(
                            color: CupertinoColors.activeBlue,
                            strokeWidth: 1,
                          ),
                          const FlDotData(show: false),
                        );
                      }).toList();
                    },
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _niceInterval(paddedMaxY),
                getDrawingHorizontalLine: (double value) => FlLine(
                  color: CupertinoColors.separator.resolveFrom(context),
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      '測試序號',
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (double value, TitleMeta meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        // X axis is 0-based internally (list index); display as
                        // 1-based so it matches the run's sequence numbers.
                        (value.toInt() + 1).toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text(
                      '延遲（ms）',
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: _niceInterval(paddedMaxY),
                    getTitlesWidget: (double value, TitleMeta meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: <LineChartBarData>[
                LineChartBarData(
                  spots: lineSpots,
                  isCurved: false,
                  barWidth: 2,
                  color: CupertinoColors.activeBlue,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter:
                        (
                          FlSpot spot,
                          double percent,
                          LineChartBarData barData,
                          int index,
                        ) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color:
                                spotColors[index] ?? CupertinoColors.activeBlue,
                            strokeColor: CupertinoColors.systemBackground
                                .resolveFrom(context),
                            strokeWidth: 1,
                          );
                        },
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _Legend(
          present: <ResultStatus>{
            for (final TestResult r in plottable) r.status,
          },
        ),
      ],
    );
  }

  double _niceInterval(double maxY) {
    if (maxY <= 0) return 1;
    const List<double> steps = <double>[10, 20, 50, 100, 200, 500, 1000, 2000];
    for (final double s in steps) {
      if (maxY <= s) return (s / 4).clamp(1.0, double.infinity);
    }
    return (maxY / 4).roundToDouble().clamp(1.0, double.infinity);
  }

  String _semanticsSummary(
    List<TestResult> plottable,
    List<TestResult> successes,
  ) {
    if (plottable.isEmpty) return '沒有可顯示的延遲資料';
    return '延遲走勢圖，共 ${plottable.length} 次已嘗試測試，'
        '當中 ${successes.length} 次成功。';
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Center(
        child: Text(
          '沒有可顯示的延遲資料',
          style: TextStyle(color: CupertinoColors.secondaryLabel),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.present});

  final Set<ResultStatus> present;

  static const Map<ResultStatus, (Color, String)> defs =
      <ResultStatus, (Color, String)>{
        ResultStatus.success: (CupertinoColors.activeBlue, '成功 ●'),
        ResultStatus.httpError: (CupertinoColors.systemOrange, 'HTTP 錯誤 ▲'),
        ResultStatus.timeout: (CupertinoColors.systemRed, '超時 ✕'),
        ResultStatus.connectionError: (CupertinoColors.systemRed, '網絡錯誤 ■'),
        ResultStatus.dnsError: (CupertinoColors.systemRed, 'DNS 錯誤 ■'),
        ResultStatus.tlsError: (CupertinoColors.systemRed, 'TLS 錯誤 ■'),
        ResultStatus.tooManyRedirects: (CupertinoColors.systemRed, '重新導向過多 ■'),
        ResultStatus.responseTooLarge: (CupertinoColors.systemRed, '回應過大 ■'),
        ResultStatus.unknownError: (CupertinoColors.systemRed, '未知錯誤 ■'),
      };

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[];
    for (final MapEntry<ResultStatus, (Color, String)> e in defs.entries) {
      if (present.contains(e.key)) {
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: e.value.$1,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(e.value.$2, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        );
      }
    }
    return Wrap(children: chips);
  }
}
