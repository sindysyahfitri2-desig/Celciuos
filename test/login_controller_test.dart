import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kasir_celcious_coffe/features/auth/application/login_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('login authenticates using only the backend login endpoint', () async {
    final controller = LoginController(
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/login');
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {
          'username': 'kasir_baru',
          'password': 'rahasia123',
        });
        return http.Response(
          '{"token":"test-token","pengguna":{"role":"kasir","nama":"Kasir"}}',
          200,
        );
      }),
    );
    addTearDown(controller.dispose);

    final result = await controller.submit('kasir_baru', 'rahasia123');

    expect(result.status, LoginSubmissionStatus.authenticated);
    expect(result.role, 'Kasir');
    expect(controller.isVerifying, isFalse);
  });

  test(
    'invalid credentials are rejected before contacting the backend',
    () async {
      final controller = LoginController(
        httpClient: MockClient((_) async {
          fail('Invalid credentials must not contact the backend.');
        }),
      );
      addTearDown(controller.dispose);

      final result = await controller.submit('abc', 'short');

      expect(result.status, LoginSubmissionStatus.invalid);
      expect(result.message, contains('Username harus'));
      expect(controller.isVerifying, isFalse);
    },
  );
}
