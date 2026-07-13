import 'package:flutter/cupertino.dart';

/// Shows "done / total", a progress bar and the current status text. Spec §7.2.
class ProgressSummary extends StatelessWidget {
  const ProgressSummary({
    required this.done,
    required this.total,
    required this.statusText,
    super.key,
  });

  final int done;
  final int total;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final double t = total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '$done / $total',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFeatures: <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              if (total > 0)
                Text(
                  '${(t * 100).round()}%',
                  style: const TextStyle(
                    color: CupertinoColors.secondaryLabel,
                    fontFeatures: <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            container: true,
            liveRegion: true,
            label: '已完成 $done / $total。$statusText',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _LinearBar(
                progress: t,
                backgroundColor: CupertinoColors.tertiarySystemFill
                    .resolveFrom(context),
                foregroundColor:
                    CupertinoColors.activeBlue.resolveFrom(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: const TextStyle(
              color: CupertinoColors.label,
              fontSize: 15,
            ),
          ),
          // Activity indicator while the run is ongoing (and not waiting or
          // finished).
          if (statusText.contains('……'))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: CupertinoActivityIndicator(),
            ),
        ],
      ),
    );
  }
}

/// A minimal Cupertino-style linear progress bar. Built inline to avoid
/// pulling in the Material [LinearProgressIndicator].
class _LinearBar extends StatelessWidget {
  const _LinearBar({
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final double clamped = progress.clamp(0.0, 1.0);
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: foregroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
