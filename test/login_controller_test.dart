import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kasir_celcious_coffe/features/auth/application/login_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registration stays local and persists a cashier account', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = LoginController();
    addTearDown(controller.dispose);
    controller.setLoginMode(false);

    final result = await controller.submit('kasir_baru', 'rahasia123');

    expect(result.status, LoginSubmissionStatus.registered);
    expect(controller.isLogin, isTrue);
    expect(controller.isVerifying, isFalse);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('celcious_accounts'),
      contains('"username":"kasir_baru"'),
    );
  });

  test('invalid credentials are rejected before contacting the backend', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = LoginController();
    addTearDown(controller.dispose);

    final result = await controller.submit('abc', 'short');

    expect(result.status, LoginSubmissionStatus.invalid);
    expect(result.message, contains('Username harus'));
    expect(controller.isVerifying, isFalse);
  });
}
