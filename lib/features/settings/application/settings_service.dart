import 'package:kasir_celcious_coffe/data/transaction_store.dart';

/// Validates and persists application settings that affect cashier totals.
class SettingsService {
  SettingsService._();

  static Future<double> saveTaxRate(String percentText) async {
    final percent = double.tryParse(percentText.trim());
    if (percent == null || !percent.isFinite || percent < 0 || percent > 100) {
      throw const FormatException(
        'PPN harus berupa angka antara 0 sampai 100.',
      );
    }

    await TransactionStore.savePpnRate(percent / 100);
    return percent;
  }
}
