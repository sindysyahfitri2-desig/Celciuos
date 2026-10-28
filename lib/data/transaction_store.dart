import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionStore {
  static const _ppnKey = 'ppn_rate';
  static const _shiftCashierKey = 'shift_cashier';
  static const _shiftOpeningCashKey = 'shift_opening_cash';
  static const _transactionsKey = 'transactions';
  static const _unfinishedOrdersKey = 'unfinished_orders';
  static const _shiftsKey = 'cashier_shifts';
  static const _activeShiftKey = 'active_cashier_shift';
  static const _cashDrawerEntriesKey = 'cash_drawer_entries';

  static final ValueNotifier<double> ppnRate = ValueNotifier<double>(0.11);
  static final ValueNotifier<String> shiftCashier = ValueNotifier<String>('');
  static final ValueNotifier<double> shiftOpeningCash = ValueNotifier<double>(
    0,
  );
  static final ValueNotifier<Map<String, dynamic>?> activeShift =
      ValueNotifier<Map<String, dynamic>?>(null);
  static final ValueNotifier<List<Map<String, dynamic>>> shiftHistory =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  static final ValueNotifier<List<Map<String, dynamic>>> transactions =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  static final ValueNotifier<List<Map<String, dynamic>>> unfinishedOrders =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  static final ValueNotifier<List<Map<String, dynamic>>> cashDrawerEntries =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static List<Map<String, dynamic>> _uniqueById(
    Iterable<Map<String, dynamic>> items,
  ) {
    final seenIds = <String>{};
    return items.where((item) {
      final id = item['id']?.toString();
      return id == null || id.isEmpty || seenIds.add(id);
    }).toList();
  }

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final savedRate = preferences.getDouble(_ppnKey);
    if (savedRate != null && savedRate >= 0 && savedRate <= 1) {
      ppnRate.value = savedRate;
    }
    shiftCashier.value = preferences.getString(_shiftCashierKey) ?? '';
    shiftOpeningCash.value = preferences.getDouble(_shiftOpeningCashKey) ?? 0;

    final savedShifts = preferences.getString(_shiftsKey);
    if (savedShifts != null) {
      final decoded = jsonDecode(savedShifts);
      if (decoded is List) {
        shiftHistory.value = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    final savedActiveShift = preferences.getString(_activeShiftKey);
    if (savedActiveShift != null) {
      final decoded = jsonDecode(savedActiveShift);
      if (decoded is Map) {
        activeShift.value = Map<String, dynamic>.from(decoded);
      }
    } else if (shiftCashier.value.trim().isNotEmpty) {
      final legacyShift = <String, dynamic>{
        'id': 'legacy-${DateTime.now().microsecondsSinceEpoch}',
        'cashier': shiftCashier.value,
        'openingCash': shiftOpeningCash.value,
        'openedAt': DateTime.now().toIso8601String(),
        'status': 'open',
      };
      activeShift.value = legacyShift;
      shiftHistory.value = [legacyShift, ...shiftHistory.value];
      await preferences.setString(_activeShiftKey, jsonEncode(legacyShift));
      await preferences.setString(_shiftsKey, jsonEncode(shiftHistory.value));
    }

    final savedTransactions = preferences.getString(_transactionsKey);
    if (savedTransactions != null) {
      final decoded = jsonDecode(savedTransactions);
      if (decoded is List) {
        final loaded = decoded.whereType<Map>().map(
          (item) => Map<String, dynamic>.from(item),
        );
        transactions.value = _uniqueById(loaded);
      }
    }

    final savedOrders = preferences.getString(_unfinishedOrdersKey);
    if (savedOrders != null) {
      final decoded = jsonDecode(savedOrders);
      if (decoded is List) {
        final loaded = decoded.whereType<Map>().map(
          (item) => Map<String, dynamic>.from(item),
        );
        unfinishedOrders.value = _uniqueById(loaded);
      }
    }

    final savedCashDrawerEntries = preferences.getString(_cashDrawerEntriesKey);
    if (savedCashDrawerEntries != null) {
      final decoded = jsonDecode(savedCashDrawerEntries);
      if (decoded is List) {
        cashDrawerEntries.value = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
  }

  static Future<void> savePpnRate(double rate) async {
    if (!rate.isFinite || rate < 0 || rate > 1) {
      throw ArgumentError.value(
        rate,
        'rate',
        'PPN must be between 0 and 100%.',
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setDouble(_ppnKey, rate);
    if (!saved) {
      throw StateError('Gagal menyimpan pengaturan PPN.');
    }
    ppnRate.value = rate;
  }

  static Future<void> startShift({
    required String cashier,
    required double openingCash,
  }) async {
    if (cashier.trim().isEmpty || !openingCash.isFinite || openingCash < 0) {
      throw ArgumentError('Nama kasir dan kas awal harus valid.');
    }
    if (activeShift.value?['status'] == 'open') {
      throw StateError('Shift aktif harus ditutup sebelum memulai shift baru.');
    }

    final preferences = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final shift = <String, dynamic>{
      'id': 'shift-${now.microsecondsSinceEpoch}',
      'cashier': cashier.trim(),
      'openingCash': openingCash,
      'openedAt': now.toIso8601String(),
      'status': 'open',
    };
    final updatedHistory = [shift, ...shiftHistory.value];
    final savedHistory = await preferences.setString(
      _shiftsKey,
      jsonEncode(updatedHistory),
    );
    final savedActiveShift = await preferences.setString(
      _activeShiftKey,
      jsonEncode(shift),
    );
    final savedCashier = await preferences.setString(
      _shiftCashierKey,
      cashier.trim(),
    );
    final savedCash = await preferences.setDouble(
      _shiftOpeningCashKey,
      openingCash,
    );
    if (!savedHistory || !savedActiveShift || !savedCashier || !savedCash) {
      throw StateError('Gagal menyimpan data awal shift.');
    }

    shiftCashier.value = cashier.trim();
    shiftOpeningCash.value = openingCash;
    shiftHistory.value = updatedHistory;
    activeShift.value = shift;
  }

  static Future<Map<String, dynamic>> closeActiveShift() async {
    final current = activeShift.value;
    if (current == null || current['status'] != 'open') {
      throw StateError('Tidak ada shift aktif untuk ditutup.');
    }

    final id = current['id']?.toString();
    if (id == null || id.isEmpty) {
      throw StateError('ID shift aktif tidak valid.');
    }

    final summary = activeShiftSummary();
    final closed = <String, dynamic>{
      ...current,
      ...summary,
      'status': 'closed',
      'closedAt': DateTime.now().toIso8601String(),
    };
    final updatedHistory = shiftHistory.value
        .map((item) => item['id']?.toString() == id ? closed : item)
        .toList();
    final preferences = await SharedPreferences.getInstance();
    final savedHistory = await preferences.setString(
      _shiftsKey,
      jsonEncode(updatedHistory),
    );
    final removedActive = await preferences.remove(_activeShiftKey);
    final removedCashier = await preferences.remove(_shiftCashierKey);
    final removedOpeningCash = await preferences.remove(_shiftOpeningCashKey);
    if (!savedHistory ||
        !removedActive ||
        !removedCashier ||
        !removedOpeningCash) {
      throw StateError('Gagal menyimpan penutupan shift.');
    }

    shiftHistory.value = updatedHistory;
    activeShift.value = null;
    shiftCashier.value = '';
    shiftOpeningCash.value = 0;
    return closed;
  }

  static Map<String, dynamic> activeShiftSummary() {
    final current = activeShift.value;
    if (current == null || current['status'] != 'open') {
      throw StateError('Tidak ada shift aktif.');
    }

    final id = current['id']?.toString();
    if (id == null || id.isEmpty) {
      throw StateError('ID shift aktif tidak valid.');
    }

    final shiftTransactions = transactions.value.where(
      (item) => item['shiftId']?.toString() == id,
    );
    final transactionIds = shiftTransactions
        .map((item) => item['id']?.toString())
        .whereType<String>()
        .toSet();
    final paidOrders = unfinishedOrders.value.where(
      (item) =>
          item['shiftId']?.toString() == id &&
          item['bayar']?.toString().toLowerCase() == 'lunas' &&
          !transactionIds.contains(item['id']?.toString()),
    );

    var cashSales = 0.0;
    var qrisSales = 0.0;
    for (final item in [...shiftTransactions, ...paidOrders]) {
      if (item['bayar']?.toString().toLowerCase() == 'pending') continue;
      final total = (item['total'] as num?)?.toDouble() ?? 0;
      final method = item['pembayaran']?.toString().toLowerCase();
      if (method == 'cash' || method == 'tunai') {
        cashSales += total;
      } else if (method == 'qris') {
        qrisSales += total;
      }
    }

    final cashAdjustments = cashDrawerEntries.value
        .where((item) => item['shiftId']?.toString() == id)
        .fold<double>(0, (total, item) {
          final amount = (item['amount'] as num?)?.toDouble() ?? 0;
          return total +
              (item['jenis']?.toString() == 'keluar' ? -amount : amount);
        });
    final openingCash = (current['openingCash'] as num?)?.toDouble() ?? 0;
    return {
      'openingCash': openingCash,
      'cashSales': cashSales,
      'qrisSales': qrisSales,
      'cashAdjustments': cashAdjustments,
      'totalSales': cashSales + qrisSales,
      'expectedCash': openingCash + cashSales + cashAdjustments,
      'transactionCount':
          shiftTransactions
              .where(
                (item) => item['bayar']?.toString().toLowerCase() != 'pending',
              )
              .length +
          paidOrders.length,
    };
  }

  static Future<void> addCashDrawerEntry({
    required String type,
    required double amount,
    required String description,
  }) async {
    if (type != 'masuk' && type != 'keluar') {
      throw ArgumentError.value(type, 'type', 'Jenis kas tidak valid.');
    }
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Nominal harus lebih dari 0.',
      );
    }
    final shift = activeShift.value;
    final id = shift?['id']?.toString();
    if (shift?['status'] != 'open' || id == null || id.isEmpty) {
      throw StateError('Buka shift sebelum mencatat kas laci.');
    }

    final entry = <String, dynamic>{
      'id': 'cash-${DateTime.now().microsecondsSinceEpoch}',
      'shiftId': id,
      'kasir': shift?['cashier']?.toString() ?? '',
      'tanggal': DateTime.now().toIso8601String(),
      'jenis': type,
      'amount': amount,
      'keterangan': description.trim().isEmpty
          ? (type == 'masuk' ? 'Pemasukan' : 'Pengeluaran')
          : description.trim(),
    };
    final updated = [entry, ...cashDrawerEntries.value];
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _cashDrawerEntriesKey,
      jsonEncode(updated),
    );
    if (!saved) throw StateError('Gagal menyimpan transaksi kas laci.');
    cashDrawerEntries.value = updated;
  }

  static Map<String, dynamic> withActiveShift(
    Map<String, dynamic> value, {
    String? cashier,
  }) {
    final shift = activeShift.value;
    return {
      ...value,
      if (shift != null) 'shiftId': shift['id'],
      if (shift != null) 'shiftOpenedAt': shift['openedAt'],
      if (cashier?.trim().isNotEmpty == true)
        'kasir': cashier!.trim()
      else if (shift != null)
        'kasir': shift['cashier'],
    };
  }

  static Future<void> addTransaction(Map<String, dynamic> transaction) async {
    final transactionWithShift = withActiveShift(transaction);
    final id = transactionWithShift['id']?.toString();
    if (id != null &&
        id.isNotEmpty &&
        transactions.value.any((item) => item['id']?.toString() == id)) {
      return;
    }
    final updated = _uniqueById([transactionWithShift, ...transactions.value]);
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _transactionsKey,
      jsonEncode(updated),
    );
    if (!saved) {
      throw StateError('Gagal menyimpan transaksi.');
    }
    transactions.value = updated;
  }

  static Future<void> clearTransactions() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_transactionsKey, jsonEncode([]));
    if (!saved) {
      throw StateError('Gagal mengosongkan data laporan.');
    }
    transactions.value = [];
  }

  static Future<void> addPaidOrder({
    required Map<String, dynamic> order,
    required Map<String, dynamic> transaction,
  }) async {
    final paidOrder = withActiveShift({...transaction, ...order});
    final id = paidOrder['id']?.toString();
    final orderExists =
        id != null &&
        unfinishedOrders.value.any((item) => item['id']?.toString() == id);
    final updatedOrders = orderExists
        ? unfinishedOrders.value
        : _uniqueById([paidOrder, ...unfinishedOrders.value]);
    final preferences = await SharedPreferences.getInstance();

    final savedOrders = await preferences.setString(
      _unfinishedOrdersKey,
      jsonEncode(updatedOrders),
    );
    if (!savedOrders) {
      throw StateError('Gagal menyimpan pesanan yang sudah dibayar.');
    }

    unfinishedOrders.value = updatedOrders;
  }

  static Future<void> addUnfinishedOrder(Map<String, dynamic> order) async {
    final orderWithShift = withActiveShift(order);
    final id = orderWithShift['id']?.toString();
    if (id != null &&
        id.isNotEmpty &&
        unfinishedOrders.value.any((item) => item['id']?.toString() == id)) {
      return;
    }
    final updated = _uniqueById([orderWithShift, ...unfinishedOrders.value]);
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _unfinishedOrdersKey,
      jsonEncode(updated),
    );
    if (!saved) {
      throw StateError('Gagal menyimpan pesanan belum selesai.');
    }
    unfinishedOrders.value = updated;
  }

  static Future<void> markUnfinishedOrderPaid({
    required String id,
    required String paymentMethod,
    required Map<String, dynamic> transaction,
  }) async {
    final orderIndex = unfinishedOrders.value.indexWhere(
      (order) => order['id']?.toString() == id,
    );
    if (orderIndex < 0) {
      throw StateError('Pesanan yang akan dibayar tidak ditemukan.');
    }

    final currentOrder = unfinishedOrders.value[orderIndex];
    final updatedOrder = withActiveShift(<String, dynamic>{
      ...currentOrder,
      ...transaction,
      'bayar': 'Lunas',
      'pembayaran': paymentMethod,
      'subtotal': transaction['subtotal'],
      'ppnRate': transaction['ppnRate'],
      'ppn': transaction['ppn'],
      'diskon': transaction['diskon'],
      'total': transaction['total'],
    });
    final updatedOrders = [...unfinishedOrders.value]
      ..[orderIndex] = updatedOrder;
    final updatedTransactions = transactions.value
        .where((item) => item['id']?.toString() != id)
        .toList();

    final preferences = await SharedPreferences.getInstance();
    final savedOrders = await preferences.setString(
      _unfinishedOrdersKey,
      jsonEncode(updatedOrders),
    );
    if (!savedOrders) {
      throw StateError('Gagal memperbarui status pembayaran pesanan.');
    }

    unfinishedOrders.value = updatedOrders;
    if (updatedTransactions.length != transactions.value.length) {
      final savedTransactions = await preferences.setString(
        _transactionsKey,
        jsonEncode(updatedTransactions),
      );
      if (!savedTransactions) {
        throw StateError(
          'Gagal menghapus transaksi yang belum selesai dari laporan.',
        );
      }
      transactions.value = updatedTransactions;
    }
  }

  static Future<void> completeUnfinishedOrder(String id) async {
    final orderIndex = unfinishedOrders.value.indexWhere(
      (order) => order['id']?.toString() == id,
    );
    if (orderIndex < 0) return;

    final order = unfinishedOrders.value[orderIndex];
    final updatedOrders = [...unfinishedOrders.value]..removeAt(orderIndex);
    Map<String, dynamic>? existingTransaction;
    for (final transaction in transactions.value) {
      if (transaction['id']?.toString() == id) {
        existingTransaction = transaction;
        break;
      }
    }
    final completedTransaction = <String, dynamic>{
      if (existingTransaction != null) ...existingTransaction,
      ...order,
      'kasir': order['kasir'] ?? 'Kasir',
      'pembayaran': order['pembayaran'] ?? order['bayar'] ?? 'Belum Bayar',
    };
    final updatedTransactions = _uniqueById([
      completedTransaction,
      ...transactions.value.where((item) => item['id']?.toString() != id),
    ]);

    final preferences = await SharedPreferences.getInstance();
    final savedTransactions = await preferences.setString(
      _transactionsKey,
      jsonEncode(updatedTransactions),
    );
    if (!savedTransactions) {
      throw StateError('Gagal memindahkan pesanan ke laporan harian.');
    }

    final savedOrders = await preferences.setString(
      _unfinishedOrdersKey,
      jsonEncode(updatedOrders),
    );
    if (!savedOrders) {
      throw StateError('Gagal menghapus pesanan yang sudah selesai.');
    }

    unfinishedOrders.value = updatedOrders;
    transactions.value = updatedTransactions;
  }
}
