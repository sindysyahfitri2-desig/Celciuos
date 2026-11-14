import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/produk_data.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/ui/pages/ProdukPage.dart' as catalog;
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaProduk.dart'
    as owner;
import 'package:kasir_celcious_coffe/features/kasir/presentation/kasir_page.dart'
    as cashier;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiService.clientForTesting = MockClient((request) async {
      if (request.url.path.endsWith('/kategori')) {
        return http.Response(
          '{"data":[{"id_kategori":1,"nama_kategori":"Coffee"}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.method == 'POST' && request.url.path.endsWith('/produk')) {
        return http.Response(
          '{"data":{"id_produk":999,"nama_produk":"Produk Sinkron"}}',
          201,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response(
        '{"message":"ok"}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  });

  tearDown(ApiService.resetClientForTesting);

  test(
    'product catalog changes are shared and persist across initialization',
    () async {
      SharedPreferences.setMockInitialValues({});
      await ProdukData.initialize();
      final originalProducts = List<Map<String, dynamic>>.from(
        ProdukData.produk.value,
      );
      final addedProduct = {
        'name': 'Produk Uji',
        'price': 15000,
        'category': 'Coffee',
        'image': null,
      };

      await ProdukData.saveProducts([...originalProducts, addedProduct]);
      expect(
        ProdukData.produk.value.any(
          (product) => product['name'] == 'Produk Uji',
        ),
        isTrue,
      );

      await ProdukData.initialize();
      expect(
        ProdukData.produk.value.any(
          (product) => product['name'] == 'Produk Uji',
        ),
        isTrue,
      );

      final editedProducts = ProdukData.produk.value.map((product) {
        if (product['name'] == 'Produk Uji') {
          return {...product, 'price': 18000};
        }
        return product;
      }).toList();
      await ProdukData.saveProducts(editedProducts);
      expect(
        ProdukData.produk.value.firstWhere(
          (product) => product['name'] == 'Produk Uji',
        )['price'],
        18000,
      );

      final deletedProducts = ProdukData.produk.value
          .where((product) => product['name'] != 'Produk Uji')
          .toList();
      await ProdukData.saveProducts(deletedProducts);
      expect(
        ProdukData.produk.value.any(
          (product) => product['name'] == 'Produk Uji',
        ),
        isFalse,
      );
      await ProdukData.saveProducts(originalProducts);
    },
  );

  testWidgets('owner product changes appear in read-only catalog', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await ProdukData.initialize();
    final originalProducts = List<Map<String, dynamic>>.from(
      ProdukData.produk.value,
    );
    final previousShift = TransactionStore.activeShift.value;
    TransactionStore.activeShift.value = {
      'id': 'test-shift',
      'cashier': 'Kasir Uji',
      'openingCash': 0,
      'status': 'open',
    };
    addTearDown(() async {
      TransactionStore.activeShift.value = previousShift;
      await ProdukData.saveProducts(originalProducts);
    });
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(child: owner.ProdukPage()),
              Expanded(child: catalog.ProdukPage()),
              Expanded(child: cashier.kasirPage()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dine In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == 'Nama Produk',
      ),
      'Produk Sinkron',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == 'Harga',
      ),
      '15000',
    );
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coffee').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Produk Sinkron'), findsAtLeastNWidgets(1));
    final cashierSearch = find
        .byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.hintText == 'Cari menu',
        )
        .last;
    await tester.enterText(cashierSearch, 'Produk Sinkron');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Nonaktifkan Produk Sinkron'), findsNothing);
    expect(find.text('Nonaktif di kasir'), findsNothing);
    expect(find.text('Aktif di kasir'), findsNothing);

    final ownerSearch = find
        .byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.hintText == 'Cari menu',
        )
        .first;
    await tester.enterText(ownerSearch, 'Produk Sinkron');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit Produk Sinkron'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find
          .descendant(
            of: find.byType(Dialog).last,
            matching: find.byType(TextField),
          )
          .first,
      'Produk Diedit',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan').last);
    await tester.pumpAndSettle();

    await tester.enterText(ownerSearch, 'Produk Diedit');
    await tester.pumpAndSettle();
    expect(find.text('Produk Diedit'), findsAtLeastNWidgets(1));
    await tester.tap(find.byTooltip('Hapus Produk Diedit'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
    await tester.pumpAndSettle();

    await tester.enterText(ownerSearch, '');
    await tester.pumpAndSettle();
    expect(find.text('Produk Diedit'), findsNothing);
  });

  testWidgets(
    'product category filters remain visible while scrolling products',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await ProdukData.initialize();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: catalog.ProdukPage())),
      );
      await tester.pumpAndSettle();

      final filter = find.text('Semua Menu');
      expect(filter, findsOneWidget);
      await tester.drag(find.byType(GridView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(filter, findsOneWidget);
    },
  );
}
