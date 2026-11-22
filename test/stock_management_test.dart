import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/features/owner/application/stock_management_service.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/stok/manajemen_stok_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'celcious_auth_token': 'dummy-token'});
    ApiService.resetClientForTesting();
  });

  tearDown(() {
    ApiService.resetClientForTesting();
  });

  test('StockManagementService parses dashboard, bahan baku, and mutasi correctly', () async {
    ApiService.clientForTesting = MockClient((request) async {
      if (request.url.path.endsWith('stok/dashboard')) {
        return http.Response(
          '{"data":{"total_jenis_bahan":5,"stok_aman":3,"stok_menipis":1,"stok_habis":1,"nilai_persediaan":150000}}',
          200,
        );
      }
      if (request.url.path.endsWith('bahan-baku')) {
        return http.Response(
          '{"data":[{"id_bahan_baku":1,"nama_bahan_baku":"Biji Kopi","satuan":"gram","stok":1000,"stok_minimum":200,"status_stok":"aman"}]}',
          200,
        );
      }
      return http.Response('{"message":"Not found"}', 404);
    });

    final dash = await StockManagementService.getDashboard();
    expect(dash['total_jenis_bahan'], 5);
    expect(dash['stok_menipis'], 1);

    final bahan = await StockManagementService.getBahanBaku();
    expect(bahan.length, 1);
    expect(bahan.first['nama_bahan_baku'], 'Biji Kopi');
  });

  testWidgets('ManajemenStokPage renders header and all stock tabs', (WidgetTester tester) async {
    ApiService.clientForTesting = MockClient((request) async {
      if (request.url.path.endsWith('stok/dashboard')) {
        return http.Response(
          '{"data":{"total_jenis_bahan":2,"stok_aman":2,"stok_menipis":0,"stok_habis":0,"nilai_persediaan":50000,"peringatan":[],"mutasi_terakhir":[]}}',
          200,
        );
      }
      return http.Response('{"data":[]}', 200);
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ManajemenStokPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Manajemen Stok Celcious Coffee'), findsOneWidget);
    expect(find.text('Ringkasan'), findsOneWidget);
    expect(find.text('Bahan Baku'), findsOneWidget);
    expect(find.text('Stok Masuk'), findsOneWidget);
    expect(find.text('Stok Keluar'), findsOneWidget);
    expect(find.text('Resep Produk'), findsOneWidget);
    expect(find.text('Riwayat Stok'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
  });
}
