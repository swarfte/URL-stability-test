import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../../shared/storage/settings_storage.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../controllers/stability_test_controller.dart';
import '../models/connection_mode.dart';
import '../models/test_configuration.dart';
import '../models/test_interval.dart';
import '../models/test_timeout.dart';
import '../services/url_validation_service.dart';
import '../widgets/connection_mode_selector.dart';
import '../widgets/option_picker_row.dart';
import '../../../app/routes.dart';

/// Page 1 — test configuration. Spec §6.1.
class TestSetupScreen extends StatefulWidget {
  const TestSetupScreen({
    required this.controller,
    required this.storage,
    required this.initialConfiguration,
    super.key,
  });

  final StabilityTestController controller;
  final SettingsStorage storage;
  final TestConfiguration initialConfiguration;

  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  late final TextEditingController _urlController;
  late final FocusNode _urlFocusNode;

  late ConnectionMode _connectionMode;
  late int _testCount;
  late TestInterval _interval;
  late TestTimeout _timeout;

  UrlValidationResult _validation =
      const UrlValidationResult(isValid: false, normalizedUrl: null);
  bool _edited = false;

  static const UrlValidationService _validator = UrlValidationService();

  @override
  void initState() {
    super.initState();
    final TestConfiguration c = widget.initialConfiguration;
    _urlController = TextEditingController(text: c.url);
    _urlFocusNode = FocusNode();
    _connectionMode = c.connectionMode;
    _testCount = c.testCount;
    _interval = c.interval;
    _timeout = c.timeout;
    // Validate the restored URL so the button state is correct on launch.
    _validation = _validator.validate(c.url);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _onUrlChanged(String value) {
    setState(() {
      _edited = true;
      _validation = _validator.validate(value);
    });
  }

  bool get _canStart =>
      _validation.isValid && !widget.controller.isRunning;

  Future<void> _startTest() async {
    // Collapse the keyboard and re-validate (spec §6.6).
    _urlFocusNode.unfocus();
    final UrlValidationResult result = _validator.validate(_urlController.text);
    setState(() => _validation = result);
    if (!result.isValid || result.normalizedUrl == null) return;

    final TestConfiguration config = TestConfiguration(
      url: result.normalizedUrl!,
      connectionMode: _connectionMode,
      testCount: _testCount,
      interval: _interval,
      timeout: _timeout,
    );

    // Persist settings for next launch (spec §16). Fire-and-forget; failures
    // are non-fatal.
    widget.storage.saveConfiguration(config).catchError((_) {});

    if (!mounted) return;
    // Start the run before navigating. The progress screen detects an
    // already-running session and shows progress immediately; if it found the
    // session null (as it did previously) it would pop right back to this
    // screen, producing the "nothing happens" symptom.
    unawaited(widget.controller.start(config));
    await Navigator.of(context).pushNamed(AppRoutes.progress);
  }

  void _showInfoDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: const Text('關於此 App'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            '• 本 App 使用 HTTP GET 對指定 URL 發出 request。\n'
            '• 顯示的 Delay 是「完整 HTTP 回應時間」，由送出 request 到完整接收回應 '
            'body 的總時間。\n'
            '• 本 App 非 ICMP Ping 工具，亦非 Traceroute。\n'
            '• 測試會對目標伺服器產生實際 request，請勿對不屬於你的伺服器進行壓力測試。',
            textAlign: TextAlign.left,
          ),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('好'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('URL 穩定性測試'),
        // Android back button naturally pops; here we are at root so it's a
        // no-op, which is correct.
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showInfoDialog,
          child: const Icon(CupertinoIcons.info_circle),
        ),
      ),
      child: ResponsiveContentBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _targetSection(),
            const SizedBox(height: 20),
            _connectionSettingsSection(),
            const SizedBox(height: 24),
            _startButton(),
            const SizedBox(height: 16),
            if (_validation.isValid && _validation.isHttpWarning)
              _httpWarningBanner(),
          ],
        ),
      ),
    );
  }

  // ----- Sections ---------------------------------------------------------

  Widget _targetSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('測試目標'),
      children: <Widget>[
        CupertinoFormRow(
          prefix: const Text('測試 URL'),
          error: _edited && !_validation.isValid
              ? Text(_validation.error ?? 'URL 無效')
              : null,
          child: CupertinoTextField(
            controller: _urlController,
            focusNode: _urlFocusNode,
            placeholder: 'https://example.com/health',
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onChanged: _onUrlChanged,
            onSubmitted: (_) {
              if (_canStart) _startTest();
            },
            suffixMode: OverlayVisibilityMode.editing,
            suffix: _urlController.text.isEmpty
                ? null
                : GestureDetector(
                    onTap: () {
                      _urlController.clear();
                      _onUrlChanged('');
                    },
                    child: const Icon(CupertinoIcons.xmark_circle_fill,
                        size: 18, color: CupertinoColors.tertiaryLabel),
                  ),
            decoration: BoxDecoration(
              color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _connectionSettingsSection() {
    return CupertinoFormSection.insetGrouped(
      header: const Text('連線設定'),
      children: <Widget>[
        CupertinoFormRow(
          prefix: const Text('連線模式'),
          child: ConnectionModeSelector(
            value: _connectionMode,
            onChanged: (ConnectionMode mode) =>
                setState(() => _connectionMode = mode),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            connectionModeDescription(_connectionMode),
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('測試次數'),
          child: _TestCountSelector(
            value: _testCount,
            onChanged: (int c) => setState(() => _testCount = c),
          ),
        ),
        OptionPickerRow<TestInterval>(
          label: '測試間隔',
          value: _interval,
          options: TestInterval.options,
          labelOf: (TestInterval i) => i.label,
          onChanged: (TestInterval i) => setState(() => _interval = i),
        ),
        OptionPickerRow<TestTimeout>(
          label: 'Timeout',
          value: _timeout,
          options: TestTimeout.options,
          labelOf: (TestTimeout t) => t.label,
          onChanged: (TestTimeout t) => setState(() => _timeout = t),
        ),
      ],
    );
  }

  Widget _startButton() {
    final bool enabled = _canStart;
    return SizedBox(
      height: 48,
      child: CupertinoButton(
        // Filled style when enabled; disabled appearance otherwise. Spec §6.6,
        // §24.3 (Enabled/Disabled states).
        color: enabled
            ? CupertinoColors.activeBlue
            : CupertinoColors.quaternarySystemFill,
        disabledColor: CupertinoColors.quaternarySystemFill,
        onPressed: enabled ? _startTest : null,
        child: Text(
          '開始測試',
          style: TextStyle(
            color: enabled
                ? CupertinoColors.white
                : CupertinoColors.tertiaryLabel,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _httpWarningBanner() {
    // Non-blocking warning for http:// URLs. Spec §6.1.6.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const CupertinoDynamicColor.withBrightness(
          color: Color(0x1FF08C00),
          darkColor: Color(0x33F08C00),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const CupertinoDynamicColor.withBrightness(
            color: Color(0x80F08C00),
            darkColor: Color(0x99F08C00),
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(CupertinoIcons.exclamationmark_triangle_fill,
              size: 18, color: CupertinoColors.systemOrange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '此 URL 使用未加密 HTTP 連線。部分平台或網絡可能會阻擋此連線。',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestCountSelector extends StatelessWidget {
  const _TestCountSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '測試次數選擇器',
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: value,
        onValueChanged: (int? v) {
          if (v != null) onChanged(v);
        },
        children: <int, Widget>{
          for (final int count in TestConfiguration.selectableTestCounts)
            count: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text('$count'),
            ),
        },
      ),
    );
  }
}
