import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:url_stability_test/features/stability_test/models/connection_mode.dart';
import 'package:url_stability_test/features/stability_test/models/test_configuration.dart';
import 'package:url_stability_test/features/stability_test/models/test_interval.dart';
import 'package:url_stability_test/features/stability_test/models/test_timeout.dart';
import 'package:url_stability_test/features/stability_test/services/stability_test_service.dart';

void main() {
  test('debug single success', () async {
    final client = MockClient.streaming((BaseRequest request, ByteStream body) async {
      await body.drain<void>();
      final c = StreamController<List<int>>();
      c.add([1,2,3]);
      await c.close();
      return StreamedResponse(c.stream, 200);
    });
    final service = StabilityTestService(clientFactory: () => client);
    final results = await service.run(
      configuration: const TestConfiguration(url: 'https://example.com', testCount: 1),
      cancelled: () => false,
      onResult: (r) => print('RESULT: ${r.status} err=${r.errorType} msg=${r.errorMessage}'),
      onProgress: (c,t,p) => print('PROGRESS $c/$t ${p.name}'),
    );
    print('FINAL: ${results.first.status} ${results.first.errorType}');
  });
}
