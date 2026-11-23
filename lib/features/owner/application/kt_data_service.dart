
import 'package:flutter/foundation.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/owner/application/kt_model.dart';

class KtDataService {
  KtDataService._();

  static List<Listenable> get sumberData => [
        TransactionStore.transactions,
        TransactionStore.activeShift,
        TransactionStore.shiftOpeningCash,
      ];

  // ==========================================================
  // DATA CONTOH UNTUK PREVIEW DESAIN
  // ==========================================================

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

      // Contoh penjualan berdasarkan jam.
      penjualanPerJam: {
        16: 250000,
        17: 420000,
        18: 520000,
        19: 680000,
        20: 490000,
        21: 1500000,
        22: 600000,
        23: 350000,
        0: 200000,
      },

      // Contoh HPP untuk preview saja.
      totalHpp: 3000000,

      transaksi: List.generate(
        3,
        (i) => TransaksiKasir(
          id: 'TRX-00${i + 1}',
          kasir: kasir,
          ringkasanItem: '1 Item (Americano)',
          totalHarga: 16000,
          lunas: true,
          metodeBayar: 'cash',
          fotoAsset: 'assets/images/kopi.png',
        ),
      ),
    );
  }

  // ==========================================================
  // DATA ASLI DARI BACKEND API (REAL-TIME OWNER)
  // ==========================================================

  static Future<RekapShift?> fetchDariBackend(String namaKasirDefault) async {
    try {
      final results = await Future.wait([
        ApiService.get('shift/aktif').catchError((_) => <String, dynamic>{}),
        ApiService.get('transaksi').catchError((_) => <String, dynamic>{}),
      ]);

      final shiftWrap = results[0]['data'];
      final shiftMap = (shiftWrap is Map && shiftWrap['shift'] is Map)
          ? Map<String, dynamic>.from(shiftWrap['shift'] as Map)
          : null;

      final trxListRaw = results[1]['data'];
      final trxList = trxListRaw is List
          ? trxListRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      if (shiftMap == null && trxList.isEmpty) return null;

      final kasir2 = shiftMap?['kasir2'];
      final kasir1 = shiftMap?['kasir1'];
      final activeKasir = (kasir2 is Map && (kasir2['nama']?.toString().trim().isNotEmpty ?? false))
          ? kasir2
          : (kasir1 is Map ? kasir1 : null);
      final kasir = (activeKasir != null && (activeKasir['nama']?.toString().trim().isNotEmpty ?? false))
          ? activeKasir['nama'].toString()
          : namaKasirDefault;

      String? fotoKasir;
      final rawFotoUrl = activeKasir?['foto_url']?.toString().trim();
      final rawFoto = activeKasir?['foto']?.toString().trim();
      if (rawFoto != null && rawFoto.isNotEmpty) {
        final fileName = rawFoto.split('/').last.split('\\').last;
        fotoKasir = '${ApiService.baseUrl}/foto-staf/$fileName';
      } else if (rawFotoUrl != null && rawFotoUrl.isNotEmpty) {
        fotoKasir = rawFotoUrl;
      }

      final dibuka = DateTime.tryParse(shiftMap?['dibuka_pada']?.toString() ?? '')?.toLocal();
      final modalAwal = double.tryParse(shiftMap?['kas_awal']?.toString() ?? '') ?? 0.0;

      // Filter transaksi hari ini (atau shift aktif jika tersedia)
      final idShiftAktif = shiftMap?['id_shift'];
      final today = DateTime.now();
      final transaksiRelevan = trxList.where((t) {
        if (idShiftAktif != null) {
          final idS = t['id_shift'];
          final idSBayar = t['id_shift_bayar'];
          if (idS == idShiftAktif || idSBayar == idShiftAktif) return true;
        }
        final tgl = DateTime.tryParse(t['tanggal']?.toString() ?? '')?.toLocal();
        return tgl != null &&
            tgl.year == today.year &&
            tgl.month == today.month &&
            tgl.day == today.day;
      }).toList();

      double tunai = 0;
      double qr = 0;
      int nTunai = 0;
      int nQr = 0;
      final daftar = <TransaksiKasir>[];
      final penjualanPerJam = <int, double>{};

      for (final t in transaksiRelevan) {
        final statusBayar = t['status_bayar']?.toString().toLowerCase() ?? '';
        if (statusBayar == 'dibatalkan') continue;

        final lunas = statusBayar == 'lunas';
        final total = double.tryParse(t['total']?.toString() ?? '') ?? 0.0;
        final metode = (t['metode_pembayaran'] is Map
                ? t['metode_pembayaran']['nama_metode']?.toString()
                : null) ??
            (t['midtrans_order_id'] != null ? 'QRIS' : 'Cash');
        final mLower = metode.toLowerCase();
        final isQris = mLower.contains('qris');

        if (lunas) {
          if (isQris) {
            qr += total;
            nQr++;
          } else {
            tunai += total;
            nTunai++;
          }

          final waktu = DateTime.tryParse(
                (t['dibayar_pada'] ?? t['tanggal'] ?? '').toString(),
              )?.toLocal();
          if (waktu != null) {
            penjualanPerJam[waktu.hour] = (penjualanPerJam[waktu.hour] ?? 0) + total;
          }
        }

        final details = (t['detail_transaksi'] as List? ?? []).whereType<Map>().toList();
        var totalQty = 0;
        String? firstMenu;
        for (final d in details) {
          final q = int.tryParse('${d['jumlah'] ?? 1}') ?? 1;
          totalQty += q;
          if (firstMenu == null && d['produk'] is Map) {
            firstMenu = d['produk']['nama_produk']?.toString();
          }
        }
        final pelanggan = t['nama_pelanggan']?.toString() ?? '';
        final ringkasan = firstMenu != null
            ? '$totalQty Item ($firstMenu${details.length > 1 ? ', +${details.length - 1}' : ''})'
            : (pelanggan.isNotEmpty ? '$totalQty Item ($pelanggan)' : '$totalQty Item');

        final namaKasirTrx = (t['pengguna'] is Map && t['pengguna']['nama'] != null)
            ? t['pengguna']['nama'].toString()
            : kasir;

        daftar.add(
          TransaksiKasir(
            id: t['kode']?.toString() ?? '#${t['id_transaksi']}',
            kasir: namaKasirTrx,
            ringkasanItem: ringkasan,
            totalHarga: total,
            lunas: lunas,
            metodeBayar: isQris ? 'QRIS' : 'Cash',
            fotoAsset: 'assets/images/kopi.png',
          ),
        );
      }

      final sore = (dibuka?.hour ?? today.hour) >= 15;
      return RekapShift(
        tanggal: dibuka ?? today,
        namaShift: sore ? 'Sift Sore' : 'Sift Pagi',
        rentangJam: sore ? '15.00-20.00' : '05.00-15.00',
        namaKasir: kasir,
        statusShift: shiftMap == null ? 'Tidak Aktif' : 'Berjalan',
        fotoKasirAsset: fotoKasir,
        modalAwal: modalAwal,
        serahTerima: dibuka == null ? '-' : '${formatJam(dibuka)} wib',
        penjualanTunai: tunai,
        jumlahTransaksiTunai: nTunai,
        penjualanQr: qr,
        jumlahTransaksiQr: nQr,
        transaksi: daftar,
        penjualanPerJam: penjualanPerJam,
        totalHpp: null,
      );
    } catch (e) {
      debugPrint('Gagal memuat rekap transaksi dari backend: $e');
      return null;
    }
  }

  // ==========================================================
  // DATA ASLI DARI TRANSACTION STORE
  // ==========================================================

  static RekapShift dariStore(String namaKasirDefault) {
    final shift = TransactionStore.activeShift.value;
    final shiftId = shift?['id']?.toString();

    final kasir = shift?['cashier']?.toString().trim().isNotEmpty == true
        ? shift!['cashier'].toString()
        : namaKasirDefault;

    final dibuka = DateTime.tryParse(
      shift?['openedAt']?.toString() ?? '',
    );

    final modalAwal =
        (shift?['openingCash'] as num?)?.toDouble() ??
            TransactionStore.shiftOpeningCash.value;

    final transaksiShift = shiftId == null
        ? <Map<String, dynamic>>[]
        : TransactionStore.transactions.value
            .where((t) => t['shiftId']?.toString() == shiftId)
            .toList();

    double tunai = 0;
    double qr = 0;

    int nTunai = 0;
    int nQr = 0;

    final daftar = <TransaksiKasir>[];
    final penjualanPerJam = <int, double>{};

    double totalHpp = 0;
    bool semuaHppTersedia = true;
    bool adaTransaksiLunas = false;

    for (final t in transaksiShift) {
      final total = (t['total'] as num?)?.toDouble() ?? 0;

      final metode = t['pembayaran']?.toString().toLowerCase() ?? '';

      final lunas = _sudahLunas(t);
      final qris = metode == 'qris';

      if (lunas) {
        adaTransaksiLunas = true;

        if (metode == 'cash' || metode == 'tunai') {
          tunai += total;
          nTunai++;
        } else if (qris) {
          qr += total;
          nQr++;
        }

        // Ambil waktu transaksi.
        final waktu = _parseWaktu(t);

        if (waktu != null) {
          final jam = waktu.hour;

          penjualanPerJam[jam] =
              (penjualanPerJam[jam] ?? 0) + total;
        }

        // Ambil HPP total transaksi jika tersedia.
        // Field ini harus berupa total HPP, bukan HPP satuan.
        final hpp = _ambilHpp(t);

        if (hpp == null) {
          semuaHppTersedia = false;
        } else {
          totalHpp += hpp;
        }
      }

      final namaMenu =
          (t['menu'] ?? t['namaMenu'] ?? t['nama'] ?? '').toString();

      final jumlah = t['jumlah']?.toString() ?? '1';

      daftar.add(
        TransaksiKasir(
          id: t['id']?.toString() ?? '-',
          kasir: t['kasir']?.toString().trim().isNotEmpty == true
              ? t['kasir'].toString()
              : kasir,
          ringkasanItem: namaMenu.isEmpty
              ? '$jumlah Item'
              : '$jumlah Item ($namaMenu)',
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

      penjualanPerJam: penjualanPerJam,

      // Laba tidak dihitung jika ada transaksi lunas
      // yang belum memiliki data HPP.
      totalHpp: adaTransaksiLunas && semuaHppTersedia
          ? totalHpp
          : null,
    );
  }

  // ==========================================================
  // MEMBACA WAKTU TRANSAKSI
  // ==========================================================

  static DateTime? _parseWaktu(Map<String, dynamic> t) {
    final raw = t['createdAt'] ??
        t['created_at'] ??
        t['tanggal'] ??
        t['waktu'] ??
        t['timestamp'];

    if (raw == null) return null;

    if (raw is DateTime) {
      return raw;
    }

    if (raw is int) {
      // Mendukung timestamp detik maupun milidetik.
      final milliseconds =
          raw < 1000000000000 ? raw * 1000 : raw;

      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }

    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;

      final angka = int.tryParse(raw);

      if (angka != null) {
        final milliseconds =
            angka < 1000000000000 ? angka * 1000 : angka;

        return DateTime.fromMillisecondsSinceEpoch(milliseconds);
      }
    }

    return null;
  }

  // ==========================================================
  // MEMBACA HPP TRANSAKSI
  // ==========================================================

  static double? _ambilHpp(Map<String, dynamic> t) {
    final raw = t['totalHpp'] ??
        t['hppTotal'] ??
        t['total_hpp'] ??
        t['totalModal'] ??
        t['total_modal'] ??
        t['costTotal'];

    if (raw is num) return raw.toDouble();

    if (raw is String) {
      return double.tryParse(raw);
    }

    return null;
  }

  // ==========================================================
  // STATUS PEMBAYARAN
  // ==========================================================

  static bool _sudahLunas(Map<String, dynamic> item) {
    final status = item['bayar']?.toString().toLowerCase();

    if (status == 'pending' || status == 'belum bayar') {
      return false;
    }

    if (status == 'lunas') {
      return true;
    }

    final metode = item['pembayaran']?.toString().toLowerCase();

    return metode == 'cash' ||
        metode == 'tunai' ||
        metode == 'qris';
  }
}
