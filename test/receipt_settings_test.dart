import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kasir_celcious_coffe/data/receipt_settings_store.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/PengaturanPage.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/Transaksi_Berhasil.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin can open receipt settings and preview saved options', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ReceiptSettingsStore.options.value = Map<String, bool>.from(
      ReceiptSettingsStore.defaults,
    );
    tester.view.physicalSize = const Size(1366, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PengaturanPage())),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Pengaturan Struk'));
    await tester.tap(find.text('Pengaturan Struk'));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan Pengelolaan Struk'), findsOneWidget);
    expect(find.text('Order #C001'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('receipt-option-orderNumber')));
    await tester.pumpAndSettle();

    expect(find.text('Order #C001'), findsNothing);
    expect(ReceiptSettingsStore.options.value['orderNumber'], isFalse);
    await ReceiptSettingsStore.initialize();
    expect(ReceiptSettingsStore.options.value['orderNumber'], isFalse);

    await tester.tap(find.byTooltip('Kembali ke Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan Struk'), findsOneWidget);
  });

  testWidgets('completed order displays its receipt and readable order ID', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ReceiptSettingsStore.options.value = Map<String, bool>.from(
      ReceiptSettingsStore.defaults,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TransaksiBerhasilPage(
          onSelesai: () {},
          receiptData: {
            'orderId': 'CC-1105-001',
            'customerName': 'Nadia',
            'cashierName': 'Kasir Uji',
            'orderType': 'Dine In',
            'paymentMethod': 'Cash',
            'orderedAt': DateTime(2026, 11, 5, 14, 30),
            'items': [
              {'name': 'Americano', 'price': 20000, 'quantity': 1},
            ],
            'subtotal': 20000,
            'tax': 2200,
            'discount': 0,
            'total': 22200,
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('CC-1105-001'), findsOneWidget);
    expect(find.textContaining('Americano'), findsOneWidget);
    expect(find.text('Total Bayar'), findsOneWidget);
  });
}
