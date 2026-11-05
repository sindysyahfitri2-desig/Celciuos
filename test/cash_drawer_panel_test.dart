import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/kasir_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cash drawer is available from the navigation drawer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    TransactionStore.activeShift.value = null;
    TransactionStore.shiftHistory.value = [];
    TransactionStore.cashDrawerEntries.value = [];
    await TransactionStore.initialize();
    await TransactionStore.startShift(cashier: 'Kasir Uji', openingCash: 50000);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: kasirPage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Buka menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kas Laci').last);
    await tester.pumpAndSettle();

    expect(find.text('Saldo kas yang diharapkan'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsWidgets);
    expect(find.text('Pilih :'), findsOneWidget);
  });

  testWidgets('order type is chosen directly from the menu screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    TransactionStore.activeShift.value = null;
    TransactionStore.shiftHistory.value = [];
    TransactionStore.cashDrawerEntries.value = [];
    await TransactionStore.initialize();
    await TransactionStore.startShift(cashier: 'Kasir Uji', openingCash: 50000);

    tester.view.physicalSize = const Size(1366, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: kasirPage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Jenis Pesanan'), findsOneWidget);
    expect(find.text('Dine In'), findsOneWidget);
    expect(find.text('Take Away'), findsOneWidget);
    await tester.tap(find.text('Take Away'));
    await tester.pump();
    expect(find.text('Jenis Pesanan'), findsOneWidget);
    expect(find.text('Cari menu'), findsOneWidget);
  });

  testWidgets('cash drawer supports refund and records it as cash out', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    TransactionStore.activeShift.value = null;
    TransactionStore.shiftHistory.value = [];
    TransactionStore.cashDrawerEntries.value = [];
    await TransactionStore.initialize();
    await TransactionStore.startShift(cashier: 'Kasir Uji', openingCash: 50000);

    tester.view.physicalSize = const Size(1366, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: kasirPage())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Kas Laci').first);
    await tester.pumpAndSettle();
    expect(find.text('Pilih :'), findsOneWidget);

    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(find.text('Pilih jenis kas terlebih dahulu.'), findsOneWidget);

    await tester.tap(find.text('Refund'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Radio && widget.value == widget.groupValue,
      ),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(find.text('ID Pesanan'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'ORD-001');
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(find.text('Masukkan Nominal :'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '25000');
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(TransactionStore.cashDrawerEntries.value, hasLength(1));
    expect(TransactionStore.cashDrawerEntries.value.single['jenis'], 'keluar');
    expect(TransactionStore.cashDrawerEntries.value.single['amount'], 25000);
    expect(
      TransactionStore.cashDrawerEntries.value.single['keterangan'],
      'Refund ORD-001',
    );
    expect(find.text('Rp 25.000'), findsWidgets);
    expect(find.text('Pilih :'), findsOneWidget);
  });
}
