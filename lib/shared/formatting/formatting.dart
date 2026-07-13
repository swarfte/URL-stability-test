/// Display-only formatting helpers.
library;

/// Formats a latency in milliseconds. Null → "N/A" (spec §10.8). Never shows
/// "0 ms" for a missing measurement.
String formatLatencyMs(int? milliseconds) {
  if (milliseconds == null) return 'N/A';
  return '$milliseconds ms';
}

/// Formats a percentage in 0–100. Null → "N/A".
String formatSuccessRate(int? percent) {
  if (percent == null) return 'N/A';
  return '$percent%';
}

/// Formats a whole-byte count with KiB/MiB suffixes.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const int kib = 1024;
  const int mib = kib * 1024;
  if (bytes < mib) {
    final double v = bytes / kib;
    return '${v.toStringAsFixed(v >= 100 ? 0 : 1)} KiB';
  }
  final double v = bytes / mib;
  return '${v.toStringAsFixed(v >= 100 ? 0 : 2)} MiB';
}

/// Local-time formatter for result timestamps (spec §11.2). Pads each field.
String formatDateTime(DateTime time) {
  String p2(int v) => v.toString().padLeft(2, '0');
  return '${time.year}-${p2(time.month)}-${p2(time.day)} '
      '${p2(time.hour)}:${p2(time.minute)}:${p2(time.second)}';
}
