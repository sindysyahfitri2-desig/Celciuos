
import 'package:flutter/material.dart';

// ============================================================
// BAGIAN 1: WARNA & GAYA
// ============================================================

class KtWarna {
  KtWarna._();

  static const Color navy = Color(0xff082640);
  static const Color background = Color(0xffdce9f4);
  static const Color hijau = Color(0xff1f9d3a);
  static const Color hijauTua = Color(0xff0f7a2a);
  static const Color merah = Color(0xffe53935);
  static const Color merahTua = Color(0xffb71c1c);
  static const Color oranye = Color(0xffe08a00);
  static const Color tabNonaktif = Color(0xffd3dde7);
  static const Color teksNonaktif = Color(0xff8d9aa8);
  static const Color abuTeks = Color(0xff6b7785);
  static const Color putih = Colors.white;
}

class KtGaya {
  KtGaya._();

  static List<BoxShadow> get bayangan => [
        BoxShadow(
          color: KtWarna.navy.withOpacity(0.20),
          blurRadius: 5,
          spreadRadius: 0.5,
          offset: const Offset(2, 3),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.65),
          blurRadius: 2,
          offset: const Offset(-1, -1),
        ),
      ];

  static List<BoxShadow> get bayanganRingan => [
        BoxShadow(
          color: KtWarna.navy.withOpacity(0.16),
          blurRadius: 3,
          offset: const Offset(1.5, 2),
        ),
      ];

  static List<BoxShadow> get bayanganPanel => [
        BoxShadow(
          color: KtWarna.navy.withOpacity(0.24),
          blurRadius: 7,
          spreadRadius: 0.5,
          offset: const Offset(2, 4),
        ),
      ];

  static List<Shadow> get bayanganTeks => [
        Shadow(
          color: KtWarna.navy.withOpacity(0.22),
          blurRadius: 1,
          offset: const Offset(0.8, 1),
        ),
      ];

  static List<Shadow> get bayanganAngka => [
        Shadow(
          color: KtWarna.navy.withOpacity(0.28),
          blurRadius: 1.5,
          offset: const Offset(1, 2),
        ),
      ];

  static Border get borderKartu => Border.all(
        color: const Color(0xffb6c9d9),
        width: 1,
      );

  static const LinearGradient gradasiHijau = LinearGradient(
    colors: [
      Color(0xff25a844),
      KtWarna.hijauTua,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradasiMerah = LinearGradient(
    colors: [
      KtWarna.merah,
      KtWarna.merahTua,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient gradasiNavy = LinearGradient(
    colors: [
      Color(0xff123d60),
      KtWarna.navy,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ============================================================
// BAGIAN 2: FUNGSI BANTU
// ============================================================

String formatRupiah(
  double value, {
  bool spasi = true,
  bool kapital = false,
}) {
  final angka = value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );

  final prefix = kapital ? 'RP.' : 'Rp.';
  return spasi ? '$prefix $angka' : '$prefix$angka';
}

const List<String> _namaHari = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const List<String> _namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String formatTanggalLengkap(DateTime d) {
  return '${_namaHari[d.weekday - 1]}, '
      '${d.day} ${_namaBulan[d.month - 1]} ${d.year}';
}

String formatJam(DateTime d) {
  return '${d.hour.toString().padLeft(2, '0')}.'
      '${d.minute.toString().padLeft(2, '0')}';
}

// ============================================================
// BAGIAN 3: MODEL DATA TRANSAKSI
// ============================================================

class TransaksiKasir {
  final String id;
  final String kasir;
  final String ringkasanItem;
  final double totalHarga;
  final bool lunas;
  final String metodeBayar;
  final String? fotoAsset;
  final int extraItemCount;

  const TransaksiKasir({
    required this.id,
    required this.kasir,
    required this.ringkasanItem,
    required this.totalHarga,
    required this.lunas,
    required this.metodeBayar,
    this.fotoAsset,
    this.extraItemCount = 0,
  });

  String get labelStatus =>
      lunas ? 'Berhasil ($metodeBayar)' : 'Belum Bayar';
}

// ============================================================
// BAGIAN 4: MODEL DATA REKAP SHIFT
// ============================================================

class RekapShift {
  final DateTime tanggal;
  final String namaShift;
  final String rentangJam;
  final String namaKasir;
  final String statusShift;
  final String? fotoKasirAsset;

  final double modalAwal;
  final String serahTerima;
  final double penjualanTunai;
  final int jumlahTransaksiTunai;
  final double penjualanQr;
  final int jumlahTransaksiQr;

  final List<TransaksiKasir> transaksi;

  // Data tambahan untuk panel Modal & Keuntungan.
  // Key adalah jam transaksi 0 sampai 23.
  final Map<int, double> penjualanPerJam;

  // HPP hanya terisi jika data HPP transaksi tersedia.
  final double? totalHpp;

  const RekapShift({
    required this.tanggal,
    required this.namaShift,
    required this.rentangJam,
    required this.namaKasir,
    required this.statusShift,
    required this.modalAwal,
    required this.serahTerima,
    required this.penjualanTunai,
    required this.jumlahTransaksiTunai,
    required this.penjualanQr,
    required this.jumlahTransaksiQr,
    required this.transaksi,
    this.fotoKasirAsset,
    this.penjualanPerJam = const {},
    this.totalHpp,
  });

  String get labelShift => '$namaShift ($rentangJam)';

  double get totalPenjualan => penjualanTunai + penjualanQr;

  double get kasSeharusnya => modalAwal + penjualanTunai;
}
