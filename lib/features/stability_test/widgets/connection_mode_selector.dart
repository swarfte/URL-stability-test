import '../models/connection_mode.dart';

/// The user-facing description text for a connection mode (spec §6.2.1/6.2.2).
String connectionModeDescription(ConnectionMode mode) {
  switch (mode) {
    case ConnectionMode.reuseClient:
      return '整個測試共用同一個 HTTP Client，允許重用連線，較接近日常 App 或 API 使用情況。';
    case ConnectionMode.newClientPerRequest:
      return '每次測試建立新的 HTTP Client，完成後立即關閉，盡量重新建立連線。'
          '此模式不保證清除作業系統 DNS 快取。';
  }
}

/// Short label for summary rows and the option picker (spec §6.2, §7.2, §11.2).
String connectionModeShortLabel(ConnectionMode mode) {
  switch (mode) {
    case ConnectionMode.reuseClient:
      return '正常連線';
    case ConnectionMode.newClientPerRequest:
      return '每次新連線';
  }
}
