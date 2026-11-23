import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';

/// Validasi dan simpan pengaturan tarif toko (PPN & Biaya Layanan) ke backend Laravel & store lokal.
class SettingsService {
  SettingsService._();

  static double _parsePercent(String percentText, String label) {
    final normalized = percentText.trim().replaceAll(',', '.');
    final percent = double.tryParse(normalized);
    if (percent == null || !percent.isFinite || percent < 0 || percent > 100) {
      throw FormatException('$label harus berupa angka antara 0 sampai 100.');
    }
    return percent;
  }

  static Future<double> saveTaxRate(String percentText) async {
    final percent = _parsePercent(percentText, 'PPN');
    await ApiService.put('pengaturan-toko', {'ppn_persen': percent});
    await TransactionStore.savePpnRate(percent / 100);
    return percent;
  }

  static Future<double> saveServiceFeeRate(String percentText) async {
    final percent = _parsePercent(percentText, 'Biaya pelayanan');
    await ApiService.put('pengaturan-toko', {'biaya_layanan_persen': percent});
    await TransactionStore.saveServiceFeeRate(percent / 100);
    return percent;
  }
}
