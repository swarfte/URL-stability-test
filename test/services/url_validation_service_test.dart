import 'package:flutter_test/flutter_test.dart';
import 'package:url_stability_test/features/stability_test/services/url_validation_service.dart';

void main() {
  const UrlValidationService service = UrlValidationService();

  group('UrlValidationService', () {
    test('empty input is invalid', () {
      final UrlValidationResult r = service.validate('');
      expect(r.isValid, isFalse);
      expect(r.error, '請輸入測試 URL');
    });

    test('whitespace-only input is invalid (treated as empty)', () {
      final UrlValidationResult r = service.validate('   ');
      expect(r.isValid, isFalse);
      expect(r.error, '請輸入測試 URL');
    });

    test('auto-prepends https:// when scheme is missing (spec §6.1.4)', () {
      final UrlValidationResult r = service.validate('example.com');
      expect(r.isValid, isTrue);
      expect(r.normalizedUrl, 'https://example.com');
      expect(r.isHttpWarning, isFalse);
    });

    test('auto-prepends https:// and preserves path', () {
      final UrlValidationResult r = service.validate('example.com/health');
      expect(r.isValid, isTrue);
      expect(r.normalizedUrl, 'https://example.com/health');
    });

    test('does NOT convert an explicit http:// to https (spec §6.1.4)', () {
      final UrlValidationResult r = service.validate('http://example.com');
      expect(r.isValid, isTrue);
      expect(r.normalizedUrl, 'http://example.com');
      expect(r.isHttpWarning, isTrue);
    });

    test('keeps an explicit https:// URL as-is', () {
      final UrlValidationResult r =
          service.validate('https://example.com/health');
      expect(r.isValid, isTrue);
      expect(r.normalizedUrl, 'https://example.com/health');
      expect(r.isHttpWarning, isFalse);
    });

    test('trims surrounding whitespace', () {
      final UrlValidationResult r = service.validate('  https://x.com  ');
      expect(r.isValid, isTrue);
      expect(r.normalizedUrl, 'https://x.com');
    });

    test('rejects an unsupported scheme', () {
      final UrlValidationResult r = service.validate('ftp://example.com');
      expect(r.isValid, isFalse);
      expect(r.error, '目前只支援 HTTP 和 HTTPS URL');
    });

    test('rejects file:// scheme', () {
      final UrlValidationResult r = service.validate('file:///etc/passwd');
      expect(r.isValid, isFalse);
    });

    test('rejects data: scheme', () {
      final UrlValidationResult r =
          service.validate('data:text/plain;base64,SGVsbG8=');
      expect(r.isValid, isFalse);
    });

    test('rejects userinfo (account/password) — spec §6.1.5', () {
      final UrlValidationResult r =
          service.validate('https://user:pass@example.com');
      expect(r.isValid, isFalse);
      expect(r.error, 'URL 不應包含帳號或密碼');
    });

    test('rejects a URL with no host', () {
      final UrlValidationResult r = service.validate('https://');
      expect(r.isValid, isFalse);
      expect(r.error, '請輸入完整 URL，例如 https://example.com');
    });

    test('HTTP URL sets the warning flag (spec §6.1.6)', () {
      final UrlValidationResult r = service.validate('http://example.com');
      expect(r.isValid, isTrue);
      expect(r.isHttpWarning, isTrue);
    });
  });
}
