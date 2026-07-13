import 'package:flutter/cupertino.dart';

/// A Cupertino form row that shows the current value as a tappable trailing
/// affordance and opens a modal [CupertinoPicker] bottom sheet to change it.
/// Used for the test interval and timeout selectors (spec §6.4, §6.5).
class OptionPickerRow<T> extends StatelessWidget {
  const OptionPickerRow({
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.prefix = '›',
    super.key,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  /// Small visual cue shown before the trailing label.
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return CupertinoFormRow(
      prefix: Text(label),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        // Keyboard-accessible: it is a real button with focus support (§14).
        onPressed: () => _openPicker(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              labelOf(value),
              style: const TextStyle(
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.tertiaryLabel,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final int initialItem = options.indexOf(value).clamp(0, options.length - 1);
    final T? selected = await showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext sheetContext) {
        return _OptionPickerSheet<T>(
          label: label,
          options: options,
          initialItem: initialItem,
          labelOf: labelOf,
        );
      },
    );
    if (selected != null && selected != value) {
      onChanged(selected);
    }
  }
}

class _OptionPickerSheet<T> extends StatefulWidget {
  const _OptionPickerSheet({
    required this.label,
    required this.options,
    required this.initialItem,
    required this.labelOf,
  });

  final String label;
  final List<T> options;
  final int initialItem;
  final String Function(T) labelOf;

  @override
  State<_OptionPickerSheet<T>> createState() => _OptionPickerSheetState<T>();
}

class _OptionPickerSheetState<T> extends State<_OptionPickerSheet<T>> {
  late int _selected = widget.initialItem;

  @override
  Widget build(BuildContext context) {
    return CupertinoPopupSurface(
      isSurfacePainted: true,
      child: Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: <Widget>[
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                    width: 0,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        Navigator.of(context).pop(widget.options[_selected]),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: widget.initialItem,
                ),
                itemExtent: 34,
                selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(),
                onSelectedItemChanged: (int index) => _selected = index,
                children: <Widget>[
                  for (final T option in widget.options)
                    Text(widget.labelOf(option)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
