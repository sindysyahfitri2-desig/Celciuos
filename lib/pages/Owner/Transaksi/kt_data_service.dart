import 'package:flutter/foundation.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';

// >>> IMPORT 1 dari 2 yang perlu disesuaikan dengan foldermu <<<
import '../../data/transaction_store.dart';
import 'kt_model.dart';

/// Tugas file ini: menyiapkan data untuk halaman.
/// Ada 2 sumber:
///   1. dataContoh()  -> data palsu, sama persis seperti di desain (buat preview)
///   2. dariStore()   -> data asli dari TransactionStore (sama dengan LaporanPage)
class KtDataService {
  KtDataService._();

  /// Data store yang kalau berubah, halaman perlu refresh.
  /// (Dipasang di sini supaya halaman tidak perlu import TransactionStore.)
  static List<Listenable> get sumberData => [
        TransactionStore.transactions,
        TransactionStore.activeShift,
        TransactionStore.shiftOpeningCash,
      ];

  // ----------------------------------------------------------
  // 1. DATA CONTOH (angka sama persis dengan gambar desain)
  // ----------------------------------------------------------
  static RekapShift dataContoh() {
    const kasir = 'Dessy Nurita Nathalia Manurung';
    return RekapShift(
      tanggal: DateTime(2026, 10, 26),
      namaShift: 'Sift Sore',
      rentangJam: '15.00-20.00',
      namaKasir: kasir,
      statusShift: 'Balance/Tepat',
      fotoKasirAsset: 'assets/images/kasir.png',
      modalAwal: 3500000,
      serahTerima: '20.00 wib',
      penjualanTunai: 1000000,
      jumlahTransaksiTunai: 58,
      penjualanQr: 2500000,
      jumlahTransaksiQr: 70,
      transaksi: List.generate(
        3,
        (i) => TransaksiKasir(
          id: 'TRX-00${i + 1}',
          kasir: kasir,
          ringkasanItem: '1 Item ( Americano)',
          totalHarga: 16000,
          lunas: true,
          metodeBayar: 'cash',
          fotoAsset: 'assets/images/kopi.png',
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // 2. DATA ASLI dari TransactionStore
  // ----------------------------------------------------------
  static RekapShift dariStore(String namaKasirDefault) {
    final shift = TransactionStore.activeShift.value;
    final shiftId = shift?['id']?.toString();

    final kasir = shift?['cashier']?.toString().trim().isNotEmpty == true
        ? shift!['cashier'].toString()
      
        : namaKasirDefault;

    final dibuka = DateTime.tryParse(shift?['openedAt']?.toString() ?? '');
    final modalAwal = (shift?['openingCash'] as num?)?.toDouble() ??
        TransactionStore.shiftOpeningCash.value;

    // Ambil hanya transaksi milik shift yang sedang aktif
    final transaksiShift = shiftId == null
        ? <Map<String, dynamic>>[]
        : TransactionStore.transactions.value
            .where((t) => t['shiftId']?.toString() == shiftId)
            .toList();

    double tunai = 0, qr = 0;
    int nTunai = 0, nQr = 0;

    final daftar = <TransaksiKasir>[];
    for (final t in transaksiShift) {
      final total = (t['total'] as num?)?.toDouble() ?? 0;
      final metode = t['pembayaran']?.toString().toLowerCase() ?? '';
      final lunas = _sudahLunas(t);
      final qris = metode == 'qris';

      if (lunas && (metode == 'cash' || metode == 'tunai')) {
        tunai += total;
        nTunai++;
      } else if (lunas && qris) {
        qr += total;
        nQr++;
      }

      // Nama menu: coba beberapa kemungkinan key, kalau tidak ada tampilkan jumlahnya saja
      final namaMenu = (t['menu'] ?? t['namaMenu'] ?? t['nama'] ?? '').toString();
      final jumlah = t['jumlah']?.toString() ?? '1';

      daftar.add(
        TransaksiKasir(
          id: t['id']?.toString() ?? '-',
          kasir: t['kasir']?.toString().trim().isNotEmpty == true
              ? t['kasir'].toString()
              : kasir,
          ringkasanItem:
              namaMenu.isEmpty ? '$jumlah Item' : '$jumlah Item ( $namaMenu)',
          totalHarga: total,
          lunas: lunas,
          metodeBayar: qris ? 'QRIS' : 'cash',
          fotoAsset: 'assets/images/kopi.png',
        ),
      );
    }

    final sore = (dibuka?.hour ?? 0) >= 15;

    return RekapShift(
      tanggal: dibuka ?? DateTime.now(),
      namaShift: sore ? 'Sift Sore' : 'Sift Pagi',
      rentangJam: sore ? '15.00-20.00' : '05.00-15.00',
      namaKasir: kasir,
      statusShift: shift == null ? 'Tidak Aktif' : 'Berjalan',
      fotoKasirAsset: 'assets/images/kasir.png',
      modalAwal: modalAwal,
      serahTerima: dibuka == null ? '-' : '${formatJam(dibuka)} wib',
      penjualanTunai: tunai,
      jumlahTransaksiTunai: nTunai,
      penjualanQr: qr,
      jumlahTransaksiQr: nQr,
      transaksi: daftar,
    );
  }

  /// Aturan lunas disamakan dengan _isPaid() di LaporanPage.
  static bool _sudahLunas(Map<String, dynamic> item) {
    final status = item['bayar']?.toString().toLowerCase();
    if (status == 'pending' || status == 'belum bayar') return false;
    if (status == 'lunas') return true;
    final metode = item['pembayaran']?.toString().toLowerCase();
    return metode == 'cash' || metode == 'tunai' || metode == 'qris';
  }
}