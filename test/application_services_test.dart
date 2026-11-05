import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/kasir/application/cashier_checkout_pricing.dart';
import 'package:kasir_celcious_coffe/features/kasir/application/cashier_transaction_service.dart';
import 'package:kasir_celcious_coffe/features/settings/application/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CashierCheckoutPricing', () {
    test('calculates tax, percentage discount, and item count', () {
      final pricing = CashierCheckoutPricing.calculate(
        cart: [
          {'price': 5000, 'quantity': 2},
        ],
        existingOrder: null,
        defaultTaxRate: 0.11,
        discount: 10,
        discountType: '%',
      );

      expect(pricing.subtotal, 10000);
      expect(pricing.tax, 1100);
      expect(pricing.discountAmount, 1110);
      expect(pricing.total, 9990);
      expect(pricing.itemCount, 2);
    });

    test('order IDs use a readable store-date-sequence format', () {
      SharedPreferences.setMockInitialValues({});
      TransactionStore.unfinishedOrders.value = [];
      TransactionStore.transactions.value = [];
      final order = CashierTransactionService.createOrderCode(
        cart: [
          {'category': 'Food'},
          {'category': 'Snack'},
        ],
        time: DateTime(2026, 11, 5),
      );

      expect(order['id'], 'CC-20261105-001');
      expect(order['display'], order['id']);
    });

    test('reuses saved checkout amounts for an existing order', () {
      final pricing = CashierCheckoutPricing.calculate(
        cart: [
          {'price': 5000, 'quantity': 1},
        ],
        existingOrder: {'subtotal': 12000, 'ppnRate': 0.05, 'ppn': 600},
        defaultTaxRate: 0.11,
        discount: 1000,
        discountType: 'Rp',
      );

      expect(pricing.subtotal, 12000);
      expect(pricing.taxRate, 0.05);
      expect(pricing.tax, 600);
      expect(pricing.total, 11600);
      expect(pricing.itemCount, 1);
    });
  });

  group('SettingsService', () {
    test('persists PPN percentage as a transaction tax rate', () async {
      SharedPreferences.setMockInitialValues({});
      final previousRate = TransactionStore.ppnRate.value;
      addTearDown(() => TransactionStore.ppnRate.value = previousRate);

      final percent = await SettingsService.saveTaxRate('12.5');

      expect(percent, 12.5);
      expect(TransactionStore.ppnRate.value, 0.125);
    });

    test('rejects invalid tax percentages', () async {
      for (final input in ['abc', '-1', '101', 'NaN']) {
        await expectLater(
          SettingsService.saveTaxRate(input),
          throwsFormatException,
        );
      }
    });
  });
}
