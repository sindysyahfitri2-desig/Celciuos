import '../../../data/api_service.dart';
import '../../../data/transaction_store.dart';

class CashierShiftData {
  const CashierShiftData({required this.cashier, required this.openingCash});

  final String cashier;
  final double openingCash;
}

/// Shift & kas laci: backend jadi sumber utama, TransactionStore lokal
/// tetap diisi supaya layar lain yang masih membaca data lokal tidak rusak.
class CashierShiftService {
  CashierShiftService._();

  static CashierShiftData? activeShift() {
    final shift = TransactionStore.activeShift.value;
    if (shift?['status'] != 'open') return null;
    return CashierShiftData(
      cashier: shift?['cashier']?.toString() ?? '',
      openingCash: (shift?['openingCash'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Ambil shift aktif dari backend. Isinya: {shift, shift_ke, ringkasan}.
  static Future<Map<String, dynamic>?> fetchAktif() async {
    final res = await ApiService.get('shift/aktif');
    final data = res['data'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  /// Samakan data lokal dengan backend (dipanggil setelah login kasir).
  static Future<void> syncFromBackend() async {
    final data = await fetchAktif();
    final localOpen = TransactionStore.activeShift.value?['status'] == 'open';

    if (data == null) {
      if (localOpen) await TransactionStore.closeActiveShift();
      return;
    }
    if (!localOpen) {
      final shift = Map<String, dynamic>.from(data['shift'] as Map);
      final kasir1 = shift['kasir1'] as Map?;
      await TransactionStore.startShift(
        cashier: kasir1?['nama']?.toString() ?? 'Kasir',
        openingCash: double.tryParse(shift['kas_awal'].toString()) ?? 0,
      );
    }
  }

  static Future<CashierShiftData> startShift({
    required String cashier,
    required String openingCashText,
  }) async {
    final cleanName = cashier.trim();
    final cashText = openingCashText.replaceAll('.', '').replaceAll(',', '');
    final openingCash = double.tryParse(cashText);
    if (cleanName.isEmpty || openingCash == null || openingCash < 0) {
      throw const FormatException(
        'Nama kasir dan kas awal wajib diisi dengan benar.',
      );
    }

    await ApiService.post('shift/buka', {'kas_awal': openingCash});
    await TransactionStore.startShift(
      cashier: cleanName,
      openingCash: openingCash,
    );
    return CashierShiftData(cashier: cleanName, openingCash: openingCash);
  }

  /// Dipanggil SETELAH token kasir baru tersimpan (login-pin sukses).
  static Future<void> gantiShift() async {
    await ApiService.post('shift/ganti', {});
  }

  static Future<Map<String, dynamic>> closeShift() async {
    await ApiService.post('shift/tutup', {});
    return TransactionStore.closeActiveShift();
  }

  static Future<void> addCashDrawerEntry({
    required String type, // 'masuk' / 'keluar'
    required double amount,
    required String description,
  }) async {
    await ApiService.post('shift/kas-laci', {
      'jenis': type,
      'jumlah': amount,
      'keterangan': description,
    });
    await TransactionStore.addCashDrawerEntry(
      type: type,
      amount: amount,
      description: description,
    );
  }
}