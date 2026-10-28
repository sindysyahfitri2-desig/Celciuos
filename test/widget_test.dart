import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kasir_celcious_coffe/main.dart';
import 'package:kasir_celcious_coffe/pages/Login.dart';
import 'package:kasir_celcious_coffe/pages/checkout_page.dart';
import 'package:kasir_celcious_coffe/pages/home_page.dart';
import 'package:kasir_celcious_coffe/pages/kasir_page.dart';
import 'package:kasir_celcious_coffe/pages/LaporanPage.dart';
import 'package:kasir_celcious_coffe/pages/PengaturanPage.dart';
import 'package:kasir_celcious_coffe/pages/ProdukPage.dart';
import 'package:kasir_celcious_coffe/pages/Transaksi.dart';

void main() {
  testWidgets('app builds and shows a scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('legacy owner account can log in and opens owner dashboard', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'celcious_accounts':
          '[{"username":"danielowner","password":"daniel1109",'
          '"role":"Owner","Username":"Daniel"}]',
    });

    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField).at(0), 'danielowner');
    await tester.enterText(find.byType(TextField).at(1), 'daniel1109');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Daniel'), findsOneWidget);
    expect(find.text('Role Owner'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Konfirmasi'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Halo Bos Daniel'), findsOneWidget);

    await tester.tap(find.text('Kelola Produk').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('Halaman ini siap disambungkan ke fitur dan data backend.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Dashboard').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Halo Bos Daniel'), findsOneWidget);
  });

  testWidgets('main screens fit phone, tablet, and laptop widths', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final screenBuilders = <String, Widget Function()>{
      'Kasir': () => const kasirPage(),
      'Pilihan jenis pesanan': () => HomePage(
        selectedOrderType: null,
        onOrderTypeSelected: (_) {},
        onContinue: () {},
      ),
      'Checkout': () => CheckoutPage(
        cart: [
          {
            'name': 'Americano',
            'price': 20000,
            'quantity': 1,
            'category': 'Coffee',
          },
        ],
        jenisPesanan: 'Dine In',
        rupiah: (amount) => 'Rp ${amount.toInt()}',
        onBack: () {},
        onLanjutPembayaran: () {},
      ),
      'Transaksi': () => const PesananBelumSelesaiPage(),
      'Laporan': () => const LaporanPage(),
      'Produk': () => const ProdukPage(),
      'Pengaturan': () => const PengaturanPage(),
    };
    final screenSizes = <Size>[
      const Size(360, 800),
      const Size(768, 1024),
      const Size(1366, 900),
    ];

    for (final size in screenSizes) {
      tester.view.physicalSize = size;
      for (final entry in screenBuilders.entries) {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: entry.value())),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} overflows at ${size.width}px',
        );
      }
    }
  });

  testWidgets('checkout exposes one payment mode selector and price details', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckoutPage(
            cart: [
              {
                'name': 'Americano',
                'price': 20000,
                'quantity': 1,
                'category': 'Coffee',
              },
            ],
            jenisPesanan: 'Dine In',
            rupiah: (amount) => 'Rp ${amount.toInt()}',
            onBack: () {},
            onLanjutPembayaran: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilih mode pembayaran'), findsOneWidget);
    await tester.tap(find.text('Pilih mode pembayaran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Langsung Bayar').last);
    await tester.pumpAndSettle();
    expect(find.text('Langsung Bayar'), findsOneWidget);
    expect(find.text('Bayar'), findsOneWidget);

    await tester.tap(find.text('Total :'));
    await tester.pumpAndSettle();
    expect(find.text('Rincian Pembayaran'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.textContaining('PPN'), findsOneWidget);
    expect(find.text('Diskon'), findsOneWidget);
  });
}
