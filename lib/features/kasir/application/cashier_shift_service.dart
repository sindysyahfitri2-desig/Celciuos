import '../../../data/transaction_store.dart';

class CashierShiftData {
  const CashierShiftData({required this.cashier, required this.openingCash});

  final String cashier;
  final double openingCash;
}

/// Coordinates shift validation and persistence for the cashier UI.
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

    await TransactionStore.startShift(
      cashier: cleanName,
      openingCash: openingCash,
    );
    return CashierShiftData(cashier: cleanName, openingCash: openingCash);
  }

  static Future<Map<String, dynamic>> closeShift() async {
    return TransactionStore.closeActiveShift();
  }
}
