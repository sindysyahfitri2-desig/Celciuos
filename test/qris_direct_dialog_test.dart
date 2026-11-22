import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/widgets/qris_direct_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'celcious_auth_token': 'dummy-token'});
    ApiService.resetClientForTesting();
  });

  tearDown(() {
    ApiService.resetClientForTesting();
  });

  testWidgets('QrisDirectDialog displays QRIS info and detects payment', (WidgetTester tester) async {
    int checkCount = 0;
    bool successCalled = false;

    ApiService.clientForTesting = MockClient((request) async {
      if (request.url.path.endsWith('transaksi/qris')) {
        return http.Response(
          '{"message":"Pembayaran QRIS berhasil dibuat.","data":{"id_transaksi":999},"payment":{"qr_url":"https://api.sandbox.midtrans.com/v2/qris/dummy/qr-code","order_id":"CC-Q-TEST","gross_amount":17760}}',
          201,
        );
      }
      if (request.url.path.endsWith('transaksi/999')) {
        checkCount++;
        final status = checkCount >= 2 ? 'lunas' : 'belum_lunas';
        return http.Response(
          '{"message":"Detail transaksi.","data":{"id_transaksi":999,"status_bayar":"$status","kode":"CC-Q-TEST","total":"17760.00","detail_transaksi":[]}}',
          200,
        );
      }
      return http.Response('{"message":"Not found"}', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QrisDirectDialog(
            customerName: 'Budi',
            cashierName: 'Zara',
            orderType: 'Dine In',
            total: 17760,
            subtotal: 16000,
            tax: 1760,
            taxRate: 11,
            discount: 0,
            discountInput: 0,
            discountType: 'Rp',
            itemCount: 1,
            cart: const [
              {'name': 'Kopi', 'price': 16000, 'quantity': 1}
            ],
            rupiah: (val) => 'Rp ${val.toInt()}',
            onSuccess: (_) {
              successCalled = true;
            },
          ),
        ),
      ),
    );

    // Initial pump
    await tester.pump();
    expect(find.text('QRIS Celcious Coffee'), findsOneWidget);
    expect(find.text('Rp 17760'), findsOneWidget);

    // Pump to process future
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Menunggu pembayaran di-scan...'), findsOneWidget);

    // Trigger timer tick 1
    await tester.pump(const Duration(seconds: 2));
    // Trigger timer tick 2 -> returns lunas
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Pembayaran Berhasil Diterima!'), findsOneWidget);

    // Wait delay
    await tester.pump(const Duration(milliseconds: 900));
    expect(successCalled, isTrue);
  });
}
