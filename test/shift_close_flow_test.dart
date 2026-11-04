import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/kasir_page.dart';
import 'package:kasir_celcious_coffe/ui/pages/LaporanPage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'reports no longer expose shift filter, shift closing, or cash input actions',
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

      expect(find.text('Filter Shift'), findsNothing);
      expect(find.text('Input Kas'), findsNothing);
      expect(find.text('Tutup Shift'), findsNothing);
      expect(TransactionStore.activeShift.value?['status'], 'open');
    },
  );

  testWidgets('report tables fit phone, tablet, and desktop widths', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await TransactionStore.initialize();

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final size in [
      const Size(360, 800),
      const Size(768, 1024),
      const Size(1366, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const MaterialApp(home: LaporanPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.takeException(),
        isNull,
        reason: 'Laporan page overflows at ${size.width}px',
      );
    }
  });
}
