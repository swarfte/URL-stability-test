import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../../features/stability_test/models/test_result.dart';

/// Centralised mapping from [ResultStatus] to a short Traditional-Chinese
/// label and a non-colour symbol. Used by the progress and result screens,
/// and as part of Semantics labels (spec §15: not relying on colour alone).
class ResultStatusPresentation {
  const ResultStatusPresentation._(this.label, this.symbol);

  final String label;

  /// A short textual symbol so colour is not the only differentiator
  /// (spec §11.4 / §15).
  final String symbol;

  static const ResultStatusPresentation success =
      ResultStatusPresentation._('成功', '●');
  static const ResultStatusPresentation httpError =
      ResultStatusPresentation._('HTTP 錯誤', '▲');
  static const ResultStatusPresentation timeout =
      ResultStatusPresentation._('超時', '✕');
  static const ResultStatusPresentation dnsError =
      ResultStatusPresentation._('DNS 錯誤', '■');
  static const ResultStatusPresentation connectionError =
      ResultStatusPresentation._('連線錯誤', '■');
  static const ResultStatusPresentation tlsError =
      ResultStatusPresentation._('TLS 錯誤', '■');
  static const ResultStatusPresentation tooManyRedirects =
      ResultStatusPresentation._('重新導向過多', '■');
  static const ResultStatusPresentation responseTooLarge =
      ResultStatusPresentation._('回應過大', '■');
  static const ResultStatusPresentation cancelled =
      ResultStatusPresentation._('已取消', '○');
  static const ResultStatusPresentation unknownError =
      ResultStatusPresentation._('未知錯誤', '■');

  static ResultStatusPresentation forStatus(ResultStatus status) {
    switch (status) {
      case ResultStatus.success:
        return success;
      case ResultStatus.httpError:
        return httpError;
      case ResultStatus.timeout:
        return timeout;
      case ResultStatus.dnsError:
        return dnsError;
      case ResultStatus.connectionError:
        return connectionError;
      case ResultStatus.tlsError:
        return tlsError;
      case ResultStatus.tooManyRedirects:
        return tooManyRedirects;
      case ResultStatus.responseTooLarge:
        return responseTooLarge;
      case ResultStatus.cancelled:
        return cancelled;
      case ResultStatus.unknownError:
        return unknownError;
    }
  }
}

/// Convenience for tagging a widget with a semantic label (spec §15).
Widget labelled(Widget widget, {required String label}) {
  return Semantics(
    container: true,
    label: label,
    textField: false,
    button: false,
    child: widget,
  );
}

/// Builds a polite Semantics announcement for the test-progress Live region
/// (spec §15: "進度更新提供合理 semantics").
SemanticsProperties progressAnnouncement(
    int done, int total, String statusText) {
  return SemanticsProperties(
    liveRegion: true,
    label: '已完成 $done / $total。$statusText',
  );
}
