import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kasir_celcious_coffe/main.dart';
import 'package:kasir_celcious_coffe/features/auth/application/login_controller.dart';
import 'package:kasir_celcious_coffe/features/auth/presentation/login_page.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/checkout_page.dart';
import 'package:kasir_celcious_coffe/ui/pages/home_page.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/kasir_page.dart';
import 'package:kasir_celcious_coffe/ui/pages/LaporanPage.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/PengaturanPage.dart';
import 'package:kasir_celcious_coffe/ui/pages/ProdukPage.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/Transaksi.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/Dashboard.dart';

void main() {
  testWidgets(
    'owner sidebar opens reports without profile or cash drawer pages',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: DashboardOwner()));
      expect(find.text('Profil'), findsNothing);
      expect(find.text('Kas Laci'), findsNothing);

      await tester.tap(find.text('Kelola Laporan'));
      await tester.pumpAndSettle();

      expect(find.text('Kelola Laporan'), findsOneWidget);
      expect(find.text('Unduh Laporan'), findsOneWidget);
    },
  );

  testWidgets('owner mobile drawer opens the owner reports page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DashboardOwner()));
    expect(find.text('Laporan'), findsNothing);
    await tester.tap(find.byTooltip('Buka menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kelola Laporan'));
    await tester.pumpAndSettle();

    expect(find.text('Kelola Laporan'), findsOneWidget);
    expect(find.text('Unduh Laporan'), findsOneWidget);
    expect(find.text('Laporan Kas Laci'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
    final controller = LoginController(
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/login') {
          return http.Response(
            '{"token":"test-token","pengguna":{"role":"owner","nama":"Daniel"}}',
            200,
          );
        }
        if (request.url.path == '/api/user') {
          expect(request.headers['authorization'], 'Bearer test-token');
          return http.Response('{"user":{"nama":"Daniel"}}', 200);
        }
        return http.Response('{"message":"Endpoint tidak ditemukan"}', 404);
      }),
    );
    addTearDown(controller.dispose);

    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: LoginPage(controller: controller)),
    );
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

    await tester.tap(find.text('Produk').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Cari menu'), findsOneWidget);

    await tester.tap(find.text('Beranda').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Halo Bos Daniel'), findsOneWidget);
  });

  testWidgets('main screens fit phone, tablet, and laptop widths', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
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

    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text('Pilih Mode'), findsOneWidget);
    await tester.tap(find.text('Pilih Mode'));
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
