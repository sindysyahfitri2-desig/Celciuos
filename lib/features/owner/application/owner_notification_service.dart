import 'package:flutter/foundation.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';

enum OwnerNotifType { stok, shift, order }

class OwnerNotificationItem {
  const OwnerNotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.type,
    required this.targetMenuIndex,
    this.isUrgent = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String timeLabel;
  final OwnerNotifType type;
  final int targetMenuIndex; // 3 = Manajemen Stok, 4 = Transaksi
  final bool isUrgent;
}

class OwnerNotificationService {
  OwnerNotificationService._();

  static String _rp(num v) {
    final digits = v.round().toString();
    return 'Rp ${digits.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  static String _formatJam(String? iso) {
    if (iso == null || iso.isEmpty) return 'Baru saja';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return 'Baru saja';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24 && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  /// Ambil notifikasi real-time Owner (Stok menipis/habis, Shift & Kas Laci, Pesanan Meja/Transaksi).
  static Future<List<OwnerNotificationItem>> fetchAll() async {
    try {
      final results = await Future.wait([
        ApiService.get('bahan-baku', query: {'status': 'aktif'})
            .catchError((_) => <String, dynamic>{}),
        ApiService.get('shift/aktif').catchError((_) => <String, dynamic>{}),
        ApiService.get('laporan/kas-laci')
            .catchError((_) => <String, dynamic>{}),
        ApiService.get('transaksi', query: {'limit': '10'})
            .catchError((_) => <String, dynamic>{}),
      ]);

      final items = <OwnerNotificationItem>[];

      // 1. STOK BAHAN BAKU MENIPIS / HABIS
      final bahanRaw = results[0]['data'];
      if (bahanRaw is List) {
        for (final row in bahanRaw.whereType<Map>()) {
          final nama = row['nama_bahan_baku']?.toString() ?? 'Bahan Baku';
          final satuan = row['satuan']?.toString() ?? '';
          final stok = _num(row['stok']);
          final minStok = _num(row['stok_minimum']);

          if (stok <= 0) {
            items.add(
              OwnerNotificationItem(
                id: 'stok-habis-${row['id_bahan_baku']}',
                title: 'Stok Habis: $nama',
                subtitle: 'Tersisa 0 $satuan — segera lakukan restock bahan baku.',
                timeLabel: 'Prioritas',
                type: OwnerNotifType.stok,
                targetMenuIndex: 3,
                isUrgent: true,
              ),
            );
          } else if (minStok > 0 && stok <= minStok) {
            final stokTxt = stok == stok.roundToDouble()
                ? stok.toInt().toString()
                : stok.toStringAsFixed(1);
            final minTxt = minStok == minStok.roundToDouble()
                ? minStok.toInt().toString()
                : minStok.toStringAsFixed(1);
            items.add(
              OwnerNotificationItem(
                id: 'stok-tipis-${row['id_bahan_baku']}',
                title: 'Stok Menipis: $nama',
                subtitle: 'Tersisa $stokTxt $satuan (batas minimum $minTxt $satuan).',
                timeLabel: 'Perlu Restock',
                type: OwnerNotifType.stok,
                targetMenuIndex: 3,
                isUrgent: true,
              ),
            );
          }
        }
      }

      // 2. SHIFT AKTIF & PENGAWASAN KAS LACI
      final shiftWrap = results[1]['data'];
      if (shiftWrap is Map && shiftWrap['shift'] is Map) {
        final shift = Map<String, dynamic>.from(shiftWrap['shift'] as Map);
        final kasir1 = shift['kasir1'];
        final namaKasir =
            (kasir1 is Map ? kasir1['nama']?.toString() : null) ?? 'Kasir';
        final kasAwal = _num(shift['kas_awal']);
        items.add(
          OwnerNotificationItem(
            id: 'shift-aktif-${shift['id_shift']}',
            title: 'Shift Aktif — $namaKasir',
            subtitle: 'Modal awal laci ${_rp(kasAwal)} sedang berjalan.',
            timeLabel: _formatJam(shift['dibuka_pada']?.toString()),
            type: OwnerNotifType.shift,
            targetMenuIndex: 4,
          ),
        );
      }

      final kasRaw = results[2]['data'];
      final kasListRaw = kasRaw is List
          ? kasRaw
          : (kasRaw is Map && kasRaw['baris'] is List
                ? kasRaw['baris'] as List
                : (kasRaw is Map && kasRaw['data'] is List
                      ? kasRaw['data'] as List
                      : const []));
      final kasMutasiManual = kasListRaw.whereType<Map>().where((row) {
        final ket = (row['keterangan']?.toString() ?? '').trim().toLowerCase();
        return ket != 'kas awal shift' && ket != 'penjualan cash';
      }).toList().reversed;
      for (final row in kasMutasiManual.take(5)) {
        final jenis = row['jenis']?.toString().toLowerCase() ?? '';
        final jumlah = _num(row['jumlah'] ?? row['nominal']);
        final ket = row['keterangan']?.toString().trim() ?? '-';
        final kasir = row['kasir']?.toString().trim() ?? '';
        final isKeluar = jenis == 'keluar';
        items.add(
          OwnerNotificationItem(
            id: 'kas-${row['id_kas'] ?? row['waktu'] ?? ket}',
            title: isKeluar
                ? 'Kas Laci Keluar: ${_rp(jumlah)}'
                : 'Kas Laci Masuk: ${_rp(jumlah)}',
            subtitle: kasir.isNotEmpty
                ? '$kasir • Keterangan: $ket'
                : 'Keterangan: $ket',
            timeLabel: _formatJam(
              (row['waktu'] ?? row['created_at'] ?? row['tanggal'])?.toString(),
            ),
            type: OwnerNotifType.shift,
            targetMenuIndex: 4,
            isUrgent: isKeluar,
          ),
        );
      }

      // 3. PESANAN MASUK / ORDER MEJA TERBARU
      final trxRaw = results[3]['data'];
      if (trxRaw is List) {
        for (final row in trxRaw.whereType<Map>().take(6)) {
          final kode = row['kode']?.toString() ?? '#${row['id_transaksi']}';
          final pelanggan = row['nama_pelanggan']?.toString() ?? 'Pelanggan';
          final total = _num(row['total']);
          final statusBayar = row['status_bayar']?.toString().toLowerCase() ?? '';
          if (statusBayar == 'dibatalkan') continue;

          final metode = (row['metode_pembayaran'] is Map
                  ? row['metode_pembayaran']['nama_metode']?.toString()
                  : null) ??
              (row['midtrans_order_id'] != null ? 'QRIS' : 'Cash');
          final isMeja = pelanggan.toLowerCase().startsWith('meja ');
          final lunas = statusBayar == 'lunas';

          items.add(
            OwnerNotificationItem(
              id: 'trx-${row['id_transaksi']}-$statusBayar',
              title: isMeja
                  ? 'Order Meja $kode'
                  : 'Transaksi $kode',
              subtitle: lunas
                  ? '$pelanggan • ${_rp(total)} ($metode Lunas)'
                  : '$pelanggan • ${_rp(total)} (Menunggu bayar $metode)',
              timeLabel: _formatJam(
                (row['dibayar_pada'] ?? row['tanggal'])?.toString(),
              ),
              type: OwnerNotifType.order,
              targetMenuIndex: 4,
              isUrgent: !lunas && isMeja,
            ),
          );
        }
      }

      return items;
    } catch (e) {
      debugPrint('Gagal memuat notifikasi owner: $e');
      return const [];
    }
  }
}
