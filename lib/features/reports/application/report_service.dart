import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';

/// Mengubah data transaksi bersama menjadi baris yang dipakai layar laporan.
class ReportService {
  ReportService._();

  static ReportSnapshot load({required String cashierFallback}) {
    final unfinishedById = <String, Map<String, dynamic>>{};
    for (final order in TransactionStore.unfinishedOrders.value) {
      final id = order['id']?.toString();
      if (id != null && id.isNotEmpty) unfinishedById[id] = order;
    }

    final transactionsById = <String, Map<String, dynamic>>{};
    final transactionsWithoutId = <Map<String, dynamic>>[];
    for (final transaction in TransactionStore.transactions.value) {
      final id = transaction['id']?.toString();
      final unfinished = id == null ? null : unfinishedById[id];
      if (unfinished != null) {
        if (!_isPaid(unfinished)) continue;
        transactionsById[id!] = {...transaction, ...unfinished};
      } else if (id == null || id.isEmpty) {
        transactionsWithoutId.add(transaction);
      } else {
        transactionsById.putIfAbsent(id, () => transaction);
      }
    }

    for (final entry in unfinishedById.entries) {
      if (_isPaid(entry.value)) {
        transactionsById.putIfAbsent(entry.key, () => entry.value);
      }
    }

    final transactions = [...transactionsById.values, ...transactionsWithoutId];
    final openingCash = TransactionStore.shiftOpeningCash.value;
    final cashier = TransactionStore.shiftCashier.value.trim().isEmpty
        ? cashierFallback
        : TransactionStore.shiftCashier.value;
    final cashTransactions = transactions
        .where(
          (transaction) =>
              transaction['pembayaran']?.toString().toLowerCase() == 'cash' &&
              _isPaid(transaction),
        )
        .toList();
    final activeShiftId = TransactionStore.activeShift.value?['id']?.toString();
    final activeCashSales = cashTransactions
        .where(
          (transaction) => transaction['shiftId']?.toString() == activeShiftId,
        )
        .fold<double>(
          0,
          (total, transaction) =>
              total + ((transaction['total'] as num?)?.toDouble() ?? 0),
        );
    final activeCashAdjustments = TransactionStore.cashDrawerEntries.value
        .where((entry) => entry['shiftId']?.toString() == activeShiftId)
        .fold<double>(0, (total, entry) {
          final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
          return total +
              (entry['jenis']?.toString() == 'keluar' ? -amount : amount);
        });

    final drawerRows = <Map<String, String>>[
      ...TransactionStore.shiftHistory.value.map((shift) {
        final openedAt = shift['openedAt']?.toString() ?? '';
        final shiftOpeningCash =
            (shift['openingCash'] as num?)?.toDouble() ?? 0;
        return {
          'kasir': shift['cashier']?.toString() ?? cashier,
          'tanggal': openedAt,
          'jam': _timeFromDate(openedAt),
          'nominal': '+${_formatAmount(shiftOpeningCash)}',
          'keterangan': 'Kas awal shift',
          'jenis': 'masuk',
          'shiftId': shift['id']?.toString() ?? '',
        };
      }),
      ...cashTransactions.map((transaction) {
        final rawDate = transaction['tanggal']?.toString() ?? '';
        final date = DateTime.tryParse(rawDate);
        final amount = (transaction['total'] as num?)?.toDouble() ?? 0;
        return {
          'tanggal': rawDate,
          'kasir': transaction['kasir']?.toString().trim().isNotEmpty == true
              ? transaction['kasir'].toString()
              : cashier,
          'jam':
              transaction['jam']?.toString() ??
              (date == null
                  ? '--:--'
                  : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'),
          'nominal': '+${_formatAmount(amount)}',
          'keterangan': 'Penjualan Cash',
          'jenis': 'masuk',
          'shiftId': transaction['shiftId']?.toString() ?? '',
        };
      }),
      ...TransactionStore.cashDrawerEntries.value.map((entry) {
        final rawDate = entry['tanggal']?.toString() ?? '';
        final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
        final type = entry['jenis']?.toString() ?? 'masuk';
        return {
          'tanggal': rawDate,
          'kasir': entry['kasir']?.toString() ?? cashier,
          'jam': _timeFromDate(rawDate),
          'nominal': '${type == 'keluar' ? '-' : '+'}${_formatAmount(amount)}',
          'keterangan': entry['keterangan']?.toString() ?? '',
          'jenis': type,
          'shiftId': entry['shiftId']?.toString() ?? '',
        };
      }),
    ];

    final currentCash = TransactionStore.activeShift.value == null
        ? 0.0
        : openingCash + activeCashSales + activeCashAdjustments;
    final transactionRows = transactions.map((transaction) {
      final rawDate = transaction['tanggal']?.toString() ?? '';
      final date = DateTime.tryParse(rawDate);
      final amount = (transaction['total'] as num?)?.toDouble() ?? 0;
      return {
        'id': transaction['id']?.toString() ?? '-',
        'tanggal': rawDate,
        'jam':
            transaction['jam']?.toString() ??
            (date == null
                ? '-'
                : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'),
        'shiftId': transaction['shiftId']?.toString() ?? '',
        'kasir': transaction['kasir']?.toString().trim().isNotEmpty == true
            ? transaction['kasir'].toString()
            : cashierFallback,
        'jumlah': transaction['jumlah']?.toString() ?? '0',
        'pembayaran': transaction['pembayaran']?.toString() ?? '-',
        'total': _formatAmount(amount),
        'status': _transactionStatus(transaction),
        'buktiPembayaranPath':
            transaction['buktiPembayaranPath']?.toString() ?? '',
        'buktiPembayaranBase64':
            transaction['buktiPembayaranBase64']?.toString() ?? '',
      };
    }).toList();

    return ReportSnapshot(
      openingCash: openingCash,
      currentCash: currentCash,
      transactionRows: transactionRows,
      drawerRows: drawerRows,
    );
  }

  static double _num(Object? v) => double.tryParse(v?.toString() ?? '') ?? 0;

  static String _tgl(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<ReportSnapshot> fetch({
    required DateTime dari,
    required DateTime sampai,
    required String cashierFallback,
    int? idShift,
    int? idPengguna,
  }) async {
    final queryKas = <String, String>{
      'dari_tanggal': _tgl(dari),
      'sampai_tanggal': _tgl(sampai),
      if (idShift != null) 'id_shift': '$idShift',
    };
    final queryTrx = <String, String>{
      ...queryKas,
      if (idPengguna != null) 'id_pengguna': '$idPengguna',
    };

    final hasil = await Future.wait([
      ApiService.get('laporan', query: queryTrx),
      ApiService.get('laporan/kas-laci', query: queryKas),
    ]);

    final trx = (((hasil[0]['data'] as Map)['transaksi']) as List? ?? [])
        .whereType<Map>();
    final transactionRows = trx.map((t) {
      final raw = t['tanggal']?.toString() ?? '';
      final detail = (t['detail_transaksi'] as List? ?? []).whereType<Map>();
      final jumlah = detail.fold<int>(
        0,
        (s, d) => s + (int.tryParse(d['jumlah'].toString()) ?? 0),
      );
      final kode = t['kode']?.toString();
      return <String, String>{
        'id': (kode != null && kode.isNotEmpty)
            ? kode
            : 'TRX-${t['id_transaksi']}',
        'tanggal': raw,
        'jam': _timeFromDate(raw),
        'shiftId': t['id_shift_bayar']?.toString() ?? '',
        'kasir':
            (t['pengguna'] as Map?)?['nama']?.toString() ?? cashierFallback,
        'jumlah': '$jumlah',
        'pembayaran':
            (t['metode_pembayaran'] as Map?)?['nama_metode']?.toString() ?? '-',
        'total': _formatAmount(_num(t['total'])),
        'status': 'Lunas',
        'buktiPembayaranPath': '',
        'buktiPembayaranBase64': '',
      };
    }).toList();

    final kas = hasil[1]['data'] as Map;
    final ringkasan = kas['ringkasan'] as Map;
    final drawerRows = (kas['baris'] as List? ?? []).whereType<Map>().map((b) {
      final raw = b['waktu']?.toString() ?? '';
      final jenis = b['jenis']?.toString() ?? 'masuk';
      return <String, String>{
        'kasir': b['kasir']?.toString() ?? cashierFallback,
        'tanggal': raw,
        'jam': _timeFromDate(raw),
        'nominal':
            '${jenis == 'keluar' ? '-' : '+'}${_formatAmount(_num(b['jumlah']))}',
        'keterangan': b['keterangan']?.toString() ?? '',
        'jenis': jenis,
        'shiftId': b['id_shift']?.toString() ?? '',
      };
    }).toList();

    return ReportSnapshot(
      openingCash: _num(ringkasan['kas_awal']),
      currentCash: _num(ringkasan['kas_saat_ini']),
      transactionRows: transactionRows,
      drawerRows: drawerRows,
    );
  }

  static bool _isPaid(Map<String, dynamic> transaction) {
    final status = transaction['bayar']?.toString().toLowerCase();
    if (status == 'pending' || status == 'belum bayar') return false;
    if (status == 'lunas') return true;
    final payment = transaction['pembayaran']?.toString().toLowerCase();
    return payment == 'cash' || payment == 'tunai' || payment == 'qris';
  }

  static String _transactionStatus(Map<String, dynamic> transaction) {
    if (_isPaid(transaction)) return 'Lunas';
    final value = transaction['bayar']?.toString().trim();
    return value == null || value.isEmpty ? 'Belum Bayar' : value;
  }

  static String _timeFromDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '--:--';
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatAmount(double value) =>
      value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
}

class ReportSnapshot {
  const ReportSnapshot({
    required this.openingCash,
    required this.currentCash,
    required this.transactionRows,
    required this.drawerRows,
  });

  final double openingCash;
  final double currentCash;
  final List<Map<String, String>> transactionRows;
  final List<Map<String, String>> drawerRows;
}
