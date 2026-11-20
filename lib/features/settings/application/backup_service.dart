import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/produk_data.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';

class BackupService {
  BackupService._();

  /// Mengambil data backup lengkap dari backend, atau fallback data lokal jika offline
  static Future<Map<String, dynamic>> fetchAllData() async {
    try {
      final res = await ApiService.get('backup/export');
      if (res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Gagal fetch backup dari API: $e. Menggunakan data lokal.');
    }

    // Fallback data lokal
    return {
      'toko': {
        'nama_toko': 'Celcious Coffee',
        'ppn_persen': (TransactionStore.ppnRate.value * 100),
      },
      'produk': ProdukData.produk.value,
      'transaksi': TransactionStore.transactions.value,
    };
  }

  /// Ekspor seluruh data ke format Excel (.xlsx)
  static Future<String> exportToExcel() async {
    final allData = await fetchAllData();
    final excel = Excel.createExcel();

    // Sheet 1: Produk
    final produkSheet = excel['Data Produk'];
    excel.setDefaultSheet('Data Produk');
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    produkSheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Nama Produk'),
      TextCellValue('Kategori'),
      TextCellValue('Harga (Rp)'),
      TextCellValue('Status'),
    ]);

    final rawProduk = allData['produk'];
    if (rawProduk is List) {
      int no = 1;
      for (final item in rawProduk) {
        if (item is Map) {
          final nama = item['nama_produk'] ?? item['name'] ?? '';
          final kategori = item['kategori'] is Map
              ? (item['kategori']['nama_kategori'] ?? '')
              : (item['category'] ?? '');
          final harga = double.tryParse(
                (item['harga'] ?? item['price'] ?? 0).toString(),
              ) ??
              0;
          final status = (item['status'] == 'aktif' || item['is_active'] == true)
              ? 'Aktif'
              : 'Nonaktif';

          produkSheet.appendRow([
            IntCellValue(no++),
            TextCellValue(nama.toString()),
            TextCellValue(kategori.toString()),
            DoubleCellValue(harga),
            TextCellValue(status),
          ]);
        }
      }
    }

    // Sheet 2: Transaksi Penjualan
    final trxSheet = excel['Riwayat Transaksi'];
    trxSheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Kode Transaksi'),
      TextCellValue('Tanggal'),
      TextCellValue('Pelanggan'),
      TextCellValue('Tipe'),
      TextCellValue('Metode'),
      TextCellValue('Total (Rp)'),
      TextCellValue('Status'),
    ]);

    final rawTrx = allData['transaksi'];
    if (rawTrx is List) {
      int no = 1;
      for (final item in rawTrx) {
        if (item is Map) {
          final kode = item['kode'] ?? item['id'] ?? '-';
          final tgl = item['tanggal'] ?? item['created_at'] ?? '-';
          final cust = item['nama_pelanggan'] ?? item['customer'] ?? 'Pelanggan';
          final tipe = item['tipe_pesanan'] ?? 'Dine In';
          final metode = item['metode_pembayaran'] is Map
              ? (item['metode_pembayaran']['nama_metode'] ?? 'Tunai')
              : (item['metode'] ?? 'Tunai');
          final total = double.tryParse((item['total'] ?? 0).toString()) ?? 0;
          final status = item['status_bayar'] ?? 'Lunas';

          trxSheet.appendRow([
            IntCellValue(no++),
            TextCellValue(kode.toString()),
            TextCellValue(tgl.toString()),
            TextCellValue(cust.toString()),
            TextCellValue(tipe.toString()),
            TextCellValue(metode.toString()),
            DoubleCellValue(total),
            TextCellValue(status.toString()),
          ]);
        }
      }
    }
        // Sheet: Detail Item (isi tiap transaksi)
    final itemSheet = excel['Detail Item'];
    itemSheet.appendRow([
      TextCellValue('Kode Transaksi'),
      TextCellValue('Produk'),
      TextCellValue('Varian/Catatan'),
      TextCellValue('Jumlah'),
      TextCellValue('Harga Satuan (Rp)'),
      TextCellValue('Subtotal (Rp)'),
    ]);

    if (rawTrx is List) {
      for (final trx in rawTrx) {
        if (trx is! Map) continue;
        final details = trx['detail_transaksi'];
        if (details is! List) continue;
        for (final d in details) {
          if (d is! Map) continue;
          itemSheet.appendRow([
            TextCellValue('${trx['kode'] ?? trx['id_transaksi'] ?? '-'}'),
            TextCellValue('${d['produk'] is Map ? d['produk']['nama_produk'] : '-'}'),
            TextCellValue('${d['varian'] ?? '-'}'),
            IntCellValue(int.tryParse('${d['jumlah']}') ?? 0),
            DoubleCellValue(double.tryParse('${d['harga_satuan']}') ?? 0),
            DoubleCellValue(double.tryParse('${d['subtotal']}') ?? 0),
          ]);
        }
      }
    }

    // Sheet 3: Pengaturan Toko
    final tokoSheet = excel['Pengaturan Toko'];
    tokoSheet.appendRow([
      TextCellValue('Parameter'),
      TextCellValue('Nilai'),
    ]);

    final rawToko = allData['toko'];
    if (rawToko is Map) {
      tokoSheet.appendRow([
        TextCellValue('Nama Toko'),
        TextCellValue(rawToko['nama_toko']?.toString() ?? 'Celcious Coffee'),
      ]);
      tokoSheet.appendRow([
        TextCellValue('Alamat'),
        TextCellValue(rawToko['alamat']?.toString() ?? '-'),
      ]);
      tokoSheet.appendRow([
        TextCellValue('PPN (%)'),
        TextCellValue('${rawToko['ppn_persen'] ?? 11}%'),
      ]);
      tokoSheet.appendRow([
        TextCellValue('Biaya Layanan (%)'),
        TextCellValue('${rawToko['biaya_layanan_persen'] ?? 2}%'),
      ]);
      tokoSheet.appendRow([
        TextCellValue('Printer Struk'),
        TextCellValue(rawToko['printer_struk']?.toString() ?? 'Aktif'),
      ]);
      tokoSheet.appendRow([
        TextCellValue('Printer Stiker'),
        TextCellValue(rawToko['printer_stiker']?.toString() ?? 'Aktif'),
      ]);
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Gagal men-generate file Excel.');
    }

    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fileName = 'Celcious_Backup_$timestamp';

    final result = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    return result;
  }

  /// Ekspor seluruh data ke file JSON (.json)
  static Future<String> exportToJson() async {
    final allData = await fetchAllData();
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert({
      'app_name': 'Celcious Coffee',
      'version': '1.0.0',
      'export_timestamp': DateTime.now().toIso8601String(),
      'backup_data': allData,
    });

    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fileName = 'Celcious_FullBackup_$timestamp';

    final result = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(utf8.encode(jsonString)),
      fileExtension: 'json',
      mimeType: MimeType.json,
    );

    return result;
  }
}
