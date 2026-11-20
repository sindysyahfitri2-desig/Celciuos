import 'package:kasir_celcious_coffe/data/api_service.dart';

class DashboardService {
  Future<Map<String, dynamic>> ambilDashboard() async {
    final response = await ApiService.get(
      'transaksi',
    ).timeout(const Duration(seconds: 15));
    final rawTransactions = response['data'];
    if (rawTransactions is! List) {
      throw const FormatException(
        'Format data transaksi untuk dashboard tidak valid.',
      );
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    var omzetHariIni = 0.0;
    var totalTunai = 0.0;
    var totalTransaksi = 0;
    final omzetPerJam = List<double>.filled(24, 0);
    final omzetPerMetode = <String, double>{};

    for (final rawTransaction in rawTransactions) {
      if (rawTransaction is! Map) continue;
      final transaction = Map<String, dynamic>.from(rawTransaction);
      final status = transaction['status_bayar']?.toString().toLowerCase();
      if (status == 'dibatalkan') continue;

      final tanggal = DateTime.tryParse(
        transaction['tanggal']?.toString() ?? '',
      )?.toLocal();
      if (tanggal == null ||
          tanggal.isBefore(startOfToday) ||
          !tanggal.isBefore(endOfToday)) {
        continue;
      }

      final total = _number(transaction['total']);
      omzetHariIni += total;
      omzetPerJam[tanggal.hour] += total;
      totalTransaksi++;
      if (status != 'lunas') continue;

      final rawMetode = transaction['metode_pembayaran'];
      final metodeData = rawMetode is Map
          ? Map<String, dynamic>.from(rawMetode)
          : const <String, dynamic>{};
      final metode = (metodeData['nama_metode'] ?? 'Tunai').toString().trim();
      final namaMetode = metode.isEmpty ? 'Tunai' : metode;

      if (_isTunai(namaMetode)) {
        totalTunai += total;
      } else {
        omzetPerMetode.update(
          namaMetode,
          (subtotal) => subtotal + total,
          ifAbsent: () => total,
        );
      }
    }

    return {
      'ringkasan': {
        'omzet_hari_ini': omzetHariIni,
        'total_transaksi': totalTransaksi,
        'kas_laci': totalTunai,
        'total_tunai': totalTunai,
      },
      'distribusi_metode': [
        for (final entry in omzetPerMetode.entries)
          {'metode': entry.key, 'total_nominal': entry.value},
      ],
      'grafik_per_jam': [
        for (var jam = 0; jam < omzetPerJam.length; jam++)
          {'jam': jam.toString().padLeft(2, '0'), 'total': omzetPerJam[jam]},
      ],
    };
  }

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static bool _isTunai(String metode) {
    final normalized = metode.toLowerCase();
    return normalized == 'tunai' || normalized == 'cash';
  }
}
