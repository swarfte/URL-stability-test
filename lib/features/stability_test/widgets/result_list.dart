import 'package:flutter/cupertino.dart';

import '../../../shared/accessibility/semantics.dart';
import '../../../shared/formatting/formatting.dart';
import '../models/test_result.dart';

/// Expandable list of per-request results. Spec §11.5.
class ResultList extends StatefulWidget {
  const ResultList({required this.results, super.key});

  final List<TestResult> results;

  @override
  State<ResultList> createState() => _ResultListState();
}

class _ResultListState extends State<ResultList> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            '測試已取消，沒有可用結果。',
            style: TextStyle(color: CupertinoColors.secondaryLabel),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < widget.results.length; i++) {
      rows.add(_ResultRow(
        result: widget.results[i],
        expanded: _expandedIndex == i,
        onToggle: () => setState(() =>
            _expandedIndex = (_expandedIndex == i ? null : i)),
      ));
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: rows),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.result,
    required this.expanded,
    required this.onToggle,
  });

  final TestResult result;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ResultStatusPresentation p =
        ResultStatusPresentation.forStatus(result.status);
    return Semantics(
      label: '第 ${result.sequenceNumber} 次測試，${p.label}'
          '${result.httpStatusCode == null ? "" : "，HTTP ${result.httpStatusCode}"}'
          '${result.elapsedMilliseconds == null ? "" : "，${result.elapsedMilliseconds} 毫秒"}',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0,
            ),
          ),
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: CupertinoColors.transparent,
          minimumSize: Size.zero,
          onPressed: onToggle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 36,
                    child: Text('#${result.sequenceNumber}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label)),
                  ),
                  Expanded(
                    child: Text(p.label,
                        style: const TextStyle(
                            color: CupertinoColors.label, fontSize: 15)),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      result.httpStatusCode?.toString() ?? '—',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: CupertinoColors.secondaryLabel,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures()
                          ]),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      result.isSuccessful && result.elapsedMilliseconds != null
                          ? '${result.elapsedMilliseconds} ms'
                          : '—',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: CupertinoColors.label,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures()
                          ]),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded
                        ? CupertinoIcons.chevron_down
                        : CupertinoIcons.chevron_right,
                    size: 14,
                    color: CupertinoColors.tertiaryLabel,
                  ),
                ],
              ),
              if (expanded) _detail(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(BuildContext context) {
    final TestResult r = result;
    final ResultStatusPresentation p =
        ResultStatusPresentation.forStatus(r.status);
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4, right: 4, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DetailRow(label: '測試序號', value: '#${r.sequenceNumber}'),
          _DetailRow(
              label: '開始時間', value: formatDateTime(r.startedAt)),
          _DetailRow(
              label: '結束時間', value: formatDateTime(r.completedAt)),
          _DetailRow(
              label: '經過時間',
              value: r.elapsedMilliseconds == null
                  ? '—'
                  : '${r.elapsedMilliseconds} ms'),
          _DetailRow(label: '結果分類', value: p.label),
          _DetailRow(
              label: 'HTTP Status Code',
              value: r.httpStatusCode?.toString() ?? '—'),
          _DetailRow(
              label: 'Response Size', value: formatBytes(r.responseBytes)),
          _DetailRow(
              label: 'Redirect 次數', value: '${r.redirectCount}'),
          _DetailRow(label: '最終 URL', value: r.finalUrl),
          if (r.errorMessage != null)
            _DetailRow(label: '錯誤摘要', value: r.errorMessage!),
          if (r.errorType != null)
            _DetailRow(label: '技術錯誤訊息', value: r.errorType!),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: CupertinoColors.secondaryLabel, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: CupertinoColors.label, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
