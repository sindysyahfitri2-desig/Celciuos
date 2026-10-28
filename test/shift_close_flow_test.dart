import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/pages/kasir_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'closing shift from cash drawer report returns to cashier name and cash form',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await TransactionStore.initialize();
      await TransactionStore.startShift(
        cashier: 'Kasir Uji',
        openingCash: 50000,
      );

      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: kasirPage())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tutup Shift'), findsNothing);
      await tester.tap(find.text('Laporan keuangan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laporan Kas Laci'));
      await tester.pumpAndSettle();

      expect(find.text('Input Kas'), findsOneWidget);
      expect(find.text('Tutup Shift'), findsOneWidget);
      await tester.tap(find.text('Tutup Shift'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tutup & Simpan'));
      await tester.pumpAndSettle();

      expect(TransactionStore.activeShift.value, isNull);
      expect(find.text('Selamat Datang !'), findsOneWidget);
      expect(find.text('Masukkan Nama Kasir :'), findsOneWidget);
      expect(find.text('Masukkan Kas Kasir :'), findsOneWidget);
    },
  );
}
