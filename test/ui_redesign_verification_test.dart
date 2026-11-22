import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kasir_celcious_coffe/data/owner_profile_store.dart';
import 'package:kasir_celcious_coffe/data/payment_methods_store.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/Transaksi_Berhasil.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/checkout_page.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/Dashboard.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaLaporan.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaProduk.dart'
    as owner_products;
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaStaf.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/PengaturanPage.dart';
import 'package:kasir_celcious_coffe/ui/widgets/product_cart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    OwnerProfileStore.ownerName.value = 'Owner';
    OwnerProfileStore.ownerUsername.value = '';
    OwnerProfileStore.photoBytes.value = null;
    OwnerProfileStore.photoUrl.value = null;
    OwnerProfileStore.requiresTextPasswordLogin.value = false;
    await PaymentMethodsStore.initialize();
  });

  testWidgets(
    'KelolaLaporan shows formal report with direct PDF and Excel download buttons',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KelolaLaporanContent(
              judulLaporan: 'Laporan Laba Rugi & Keuangan Harian',
              tanggalLaporan: '11 November 2026',
              previewData: LaporanPreviewData(
                namaKasir: 'Nadiyah',
                namaOwner: 'Agung',
                rows: [
                  LaporanPreviewRow(
                    tanggal: '11/11/2026 09:30',
                    keterangan: 'TRX-001 - Nadiyah',
                    metode: 'QRIS',
                    nominal: 160000,
                  ),
                ],
                pendapatanItems: [
                  LaporanNominalItem(
                    label: 'Penjualan Kopi & Minuman',
                    nominal: 160000,
                  ),
                  LaporanNominalItem(
                    label: 'Penjualan Makanan / Snack',
                    nominal: 45000,
                  ),
                ],
                bebanItems: [
                  LaporanNominalItem(
                    label: 'Beban Operasional / Perlengkapan Bar',
                    nominal: 25000,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kelola Laporan'), findsOneWidget);
      expect(find.text('CELCIOUS COFFEE INDONESIA'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.open_in_new_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Unduh PDF'), findsOneWidget);
      expect(find.text('Unduh Excel'), findsOneWidget);
      expect(find.text('LABA BERSIH SETELAH PAJAK (NET INCOME)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Owner navigation profile click opens styled Pengaturan Profil', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: DashboardOwner(namaOwner: 'Agung')),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('Buka Pengaturan Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan Profil'), findsOneWidget);
    expect(find.text('OWNER • CELCIOUS COFFEE'), findsOneWidget);
    expect(find.text('Profil Owner'), findsOneWidget);
    expect(find.text('Ganti Password'), findsAtLeastNWidgets(1));
    expect(find.text('Konfirmasi Password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Pengaturan uses dropdown + navy plus popup for payment methods without barcode box and shows Langkat address in receipt settings',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PengaturanPage())),
      );
      await tester.pumpAndSettle();

      // Pastikan tidak ada ikon barcode kecil di baris Pengaturan Pembayaran
      expect(find.byIcon(Icons.qr_code_2), findsNothing);
      // Dropdown pembayaran tampil & tombol plus navy tampil
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      expect(find.byTooltip('Tambah Metode Pembayaran'), findsOneWidget);

      // Klik tombol plus navy -> muncul popup dialog
      await tester.tap(find.byTooltip('Tambah Metode Pembayaran'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Metode Pembayaran'), findsOneWidget);

      // Ketik metode pembayaran baru di dalam popup lalu klik Tambah
      await tester.enterText(
        find.widgetWithText(TextField, 'Contoh: Dana, OVO, GoPay...'),
        'Dana',
      );
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      expect(find.text('Dana'), findsAtLeastNWidgets(1));
      expect(PaymentMethodsStore.methods.value.contains('Dana'), isTrue);

      // Tutup popup
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // Cek alamat toko di Pengaturan Struk
      await tester.ensureVisible(find.text('Pengaturan Struk'));
      await tester.tap(find.text('Pengaturan Struk'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Dusun vak111 kampun, Mekar Sawit'),
        findsAtLeastNWidgets(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'OwnerProfileStore persists photo & genuinely changes login password/PIN',
    () async {
      SharedPreferences.setMockInitialValues({});
      OwnerProfileStore.photoBytes.value = null;
      OwnerProfileStore.ownerName.value = 'Owner';

      await OwnerProfileStore.recordAuthenticatedSecret('123456');

      final fakePhoto = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3, 4]);
      await OwnerProfileStore.updateProfile(
        name: 'Bos Agung',
        newPhotoBytes: fakePhoto,
        photoFileName: 'owner.png',
      );

      expect(OwnerProfileStore.ownerName.value, 'Bos Agung');
      expect(OwnerProfileStore.photoBytes.value, isNotNull);

      // Simulasikan restart aplikasi -> foto & nama tetap tersimpan
      OwnerProfileStore.photoBytes.value = null;
      OwnerProfileStore.ownerName.value = 'Owner';
      await OwnerProfileStore.initialize();
      expect(OwnerProfileStore.ownerName.value, 'Bos Agung');
      expect(OwnerProfileStore.photoBytes.value, equals(fakePhoto));

      // Password lama salah harus ditolak
      expect(
        () => OwnerProfileStore.updatePassword(
          oldPassword: '000000',
          newPassword: '654321',
          confirmPassword: '654321',
        ),
        throwsA(isA<FormatException>()),
      );

      // Ganti password dari 123456 ke 654321
      await OwnerProfileStore.updatePassword(
        oldPassword: '123456',
        newPassword: '654321',
        confirmPassword: '654321',
      );

      // PIN lama harus ditolak, PIN baru diterima
      final oldCheck = await OwnerProfileStore.resolveOwnerSecretForLogin('123456');
      expect(oldCheck.allowed, isFalse);

      final newCheck = await OwnerProfileStore.resolveOwnerSecretForLogin('654321');
      expect(newCheck.allowed, isTrue);
      expect(newCheck.primarySecretToTry, '654321');
      expect(newCheck.fallbackBackendSecret, '123456');
    },
  );

  testWidgets(
    'TransaksiBerhasil displays both Struk Customer and Struk Dapur cleanly across all sizes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final receipt = {
        'orderId': 'CC-1122-001',
        'customerName': 'Meja 101',
        'cashierName': 'Nadiyah',
        'orderType': 'Dine In',
        'paymentMethod': 'QRIS',
        'orderedAt': DateTime(2026, 11, 22, 14, 30),
        'items': [
          {
            'name': 'Celcious Aren Latte',
            'price': 26000,
            'quantity': 2,
            'catatan': 'Less sugar',
          },
        ],
        'subtotal': 52000,
        'tax': 5720,
        'discount': 0,
        'total': 57720,
      };

      for (final size in const [
        Size(360, 800),
        Size(768, 1024),
        Size(1366, 900),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          MaterialApp(
            home: TransaksiBerhasilPage(
              onSelesai: () {},
              receiptData: receipt,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 800));

        expect(find.text('STRUK CUSTOMER'), findsOneWidget);
        expect(find.text('STRUK DAPUR'), findsOneWidget);
        expect(find.text('Pesanan'), findsOneWidget);
        expect(find.text('Jlh Pesanan'), findsOneWidget);
        expect(find.text('Cetak Struk Customer'), findsOneWidget);
        expect(find.text('Cetak Struk Dapur'), findsOneWidget);
        expect(
          find.textContaining('Dusun vak111 kampun, Mekar Sawit'),
          findsOneWidget,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'TransaksiBerhasil overflowed at ${size.width}x${size.height}',
        );
      }
    },
  );

  testWidgets('Redesigned screens fit Phone, Tablet, and Laptop widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sizes = <Size>[
      const Size(360, 800), // HP
      const Size(768, 1024), // Tablet
      const Size(1366, 900), // Laptop
    ];

    final widgets = <String, Widget Function()>{
      'DashboardOwner': () => const DashboardOwner(namaOwner: 'Agung'),
      'KelolaLaporan': () => const KelolaLaporanContent(),
      'KelolaProduk': () => const owner_products.ProdukPage(),
      'KelolaStaf': () => const KontrolStafPage(),
      'PengaturanProfil': () => const PengaturanPage(initialOpenProfile: true),
      'ProductCardEmpty': () => Center(
        child: SizedBox(
          width: 320,
          height: 104,
          child: ProductCard(
            name: 'Celcious Aren Latte',
            price: 26000,
            image: null,
            category: 'Latte',
            quantity: 0,
            onAdd: () {},
            onMinus: () {},
            onDelete: () {},
          ),
        ),
      ),
      'ProductCardWithQty': () => Center(
        child: SizedBox(
          width: 320,
          height: 104,
          child: ProductCard(
            name: 'Celcious Aren Latte',
            price: 26000,
            image: null,
            category: 'Latte',
            quantity: 2,
            onAdd: () {},
            onMinus: () {},
            onDelete: () {},
          ),
        ),
      ),
      'CheckoutPage': () => CheckoutPage(
        cart: [
          {
            'name': 'Celcious Aren Latte',
            'price': 26000,
            'quantity': 2,
            'category': 'Latte',
          },
        ],
        jenisPesanan: 'Dine In',
        rupiah: (v) => 'Rp ${v.toInt()}',
        onBack: () {},
        onLanjutPembayaran: () {},
      ),
    };

    for (final size in sizes) {
      tester.view.physicalSize = size;
      for (final entry in widgets.entries) {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: entry.value())),
        );
        await tester.pump(const Duration(milliseconds: 450));
        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} threw exception at ${size.width}x${size.height}',
        );
      }
    }
  });
}
