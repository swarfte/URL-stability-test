/// Outcome of validating a user-supplied URL. Spec §6.1.5.
class UrlValidationResult {
  const UrlValidationResult({
    required this.isValid,
    required this.normalizedUrl,
    this.error,
    this.isHttpWarning = false,
  });

  const UrlValidationResult._({
    required this.isValid,
    required this.normalizedUrl,
    this.error,
    this.isHttpWarning = false,
  });

  /// Whether the URL is acceptable to start a test with.
  final bool isValid;

  /// The URL with whitespace trimmed and `https://` auto-prepended when the
  /// user omitted a scheme. Equals the original (trimmed) input when already
  /// valid and complete. Null when [isValid] is false.
  final String? normalizedUrl;

  /// Localized error message when invalid; null otherwise.
  final String? error;

  /// True when the URL is valid but uses an unencrypted `http://` scheme,
  /// which earns a non-blocking warning (spec §6.1.6).
  final bool isHttpWarning;

  /// A passing result.
  factory UrlValidationResult.ok(String normalizedUrl,
      {bool isHttp = false}) {
    return UrlValidationResult._(
      isValid: true,
      normalizedUrl: normalizedUrl,
      isHttpWarning: isHttp,
    );
  }

  /// A failing result with the given user-facing message.
  factory UrlValidationResult.invalid(String error) {
    return UrlValidationResult._(isValid: false, normalizedUrl: null, error: error);
  }

  @override
  String toString() =>
      isValid ? 'UrlValidationResult(ok: $normalizedUrl)' : 'UrlValidationResult(invalid: $error)';
}

/// Pure-function URL validation. Has no Flutter or storage dependencies, so it
/// is straightforward to unit test (spec §18, §22.1).
class UrlValidationService {
  const UrlValidationService();

  /// Accepted URL schemes. Everything else is rejected (spec §6.1.5).
  static const Set<String> _acceptedSchemes = <String>{'http', 'https'};

  /// Validates and normalises a raw user input string. The rules implement
  /// spec §6.1.5 and the auto-https behaviour from §6.1.4.
  UrlValidationResult validate(String rawInput) {
    final String trimmed = rawInput.trim();

    if (trimmed.isEmpty) {
      return UrlValidationResult.invalid('請輸入測試 URL');
    }

    // Auto-prepend https:// when no scheme is present (spec §6.1.4). If the
    // user already wrote http:// we leave it untouched.
    String working = trimmed;
    final bool hasScheme =
        working.contains('://') || working.startsWith('mailto:');
    if (!hasScheme) {
      working = 'https://$working';
    }

    Uri uri;
    try {
      uri = Uri.parse(working);
    } on FormatException {
      return UrlValidationResult.invalid('URL 格式不正確');
    }

    // Uri.parse is very permissive; require an explicit parse success.
    if (uri.toString().isEmpty) {
      return UrlValidationResult.invalid('URL 格式不正確');
    }

    // Reject userinfo (username/password) for privacy (spec §6.1.5).
    if (uri.userInfo.isNotEmpty) {
      return UrlValidationResult.invalid('URL 不應包含帳號或密碼');
    }

    if (!_acceptedSchemes.contains(uri.scheme)) {
      return UrlValidationResult.invalid('目前只支援 HTTP 和 HTTPS URL');
    }

    if (uri.host.trim().isEmpty) {
      return UrlValidationResult.invalid('請輸入完整 URL，例如 https://example.com');
    }

    final bool isHttp = uri.scheme == 'http';
    return UrlValidationResult.ok(uri.toString(), isHttp: isHttp);
  }
}
