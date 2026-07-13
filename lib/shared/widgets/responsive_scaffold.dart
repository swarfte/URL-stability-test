import 'package:flutter/cupertino.dart';

/// Wraps page content in a centered, max-width-constrained scroll view that
/// adapts to narrow vs wide windows. Spec §12.
///
/// Below [narrowThreshold] logical pixels (default 720, per spec §12.1/§12.2)
/// the content fills the width (single column, touch-friendly). At or above
/// the threshold the content is centered with [wideMaxWidth].
class ResponsiveContentBox extends StatelessWidget {
  const ResponsiveContentBox({
    required this.child,
    super.key,
    this.narrowThreshold = 720,
    this.wideMaxWidth = 720,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  });

  final Widget child;
  final double narrowThreshold;
  final double wideMaxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWide = constraints.maxWidth >= narrowThreshold;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? wideMaxWidth : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: padding,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Breakpoint helper used by the result screen to switch between the single
/// and two-column layout (spec §12.1/§12.2).
bool isWideViewport(BuildContext context, {double threshold = 720}) {
  return MediaQuery.sizeOf(context).width >= threshold;
}
