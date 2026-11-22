import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/qris_store.dart';
import 'package:kasir_celcious_coffe/data/receipt_settings_store.dart';
import 'package:kasir_celcious_coffe/data/sticker_settings_store.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Stiker {
  _Stiker(this.nomor, this.nama, this.tipe, this.menu, this.varian,
      this.waktu, this.kode, this.urutan);
  final String nomor, nama, tipe, menu, varian, waktu, kode, urutan;
}

class PrintService {
  PrintService._();

  static const kPrinterDapur = 'celcious_printer_dapur';
  static const kPrinterStruk = 'celcious_printer_struk';
  static const kDefaultAlamatToko =
      'Dusun vak111 kampun, Mekar Sawit, Kec. Sawit Seberang, '
      'Kabupaten Langkat, Sumatera Utara 20852';

  // ---------- util ----------
  static String _dua(int n) => n.toString().padLeft(2, '0');
  static int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 1;

  // Font bawaan PDF (Courier) hanya mendukung Latin-1, emoji dibuang
  static String _latin(String s) =>
      s.replaceAll(RegExp(r'[^\x00-\xFF]'), '').trim();

  static String _rp(dynamic v) {
    final n = (double.tryParse('$v') ?? 0).round();
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return 'Rp${n < 0 ? '-' : ''}$b';
  }

  static Future<Map<String, dynamic>> _toko() async {
    try {
      final res = await ApiService.get('pengaturan-toko');
      final d = res['data'];
      if (d is Map<String, dynamic>) return d;
    } catch (e) {
      debugPrint('Gagal ambil pengaturan toko: $e');
    }
    return {};
  }

  static Map<String, bool> _opsi(dynamic raw, Map<String, bool> fallback) {
    if (raw is String && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is Map) {
          return {
            for (final e in d.entries)
              if (e.value is bool) e.key.toString(): e.value as bool,
          };
        }
      } catch (_) {}
    }
    return fallback;
  }

  // ---------- pilih printer (dipanggil dari halaman pengaturan) ----------
  static Future<String?> pilihPrinter(BuildContext context, String prefKey) async {
    final p = await Printing.pickPrinter(context: context);
    if (p == null) return null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, p.url);
    return p.name;
  }

  static Future<void> _kirim(
      Uint8List bytes, String nama, String prefKey, PdfPageFormat fmt) async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(prefKey);
    if (url != null) {
      try {
        final list = await Printing.listPrinters();
        final cocok = list.where((e) => e.url == url);
        if (cocok.isNotEmpty) {
          await Printing.directPrintPdf(
            printer: cocok.first,
            onLayout: (_) async => bytes,
            name: nama,
            format: fmt,
          );
          return;
        }
      } catch (e) {
        debugPrint('Cetak langsung gagal, pakai dialog: $e');
      }
    }
    // belum pilih printer / platform tidak mendukung: tampilkan dialog cetak
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: nama, format: fmt);
  }

  // =====================================================
  // STIKER (satu stiker per porsi, mis. 1/2 dan 2/2)
  // =====================================================
  static List<_Stiker> _unitStiker(Map t) {
    final tgl = DateTime.tryParse('${t['tanggal']}')?.toLocal() ?? DateTime.now();
    const bln = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    final waktu = '${bln[tgl.month - 1]} ${tgl.day},${_dua(tgl.hour)}:${_dua(tgl.minute)}';

    final nomor = '${t['kode'] ?? '#${t['id_transaksi']}'}';
    final nama = '${t['nama_pelanggan'] ?? ''}';
    final tipe = '${t['tipe_pesanan']}' == 'Take Away' ? 'Ta' : 'Di';
    final kode = '${(t['pengguna'] is Map ? t['pengguna']['username'] : '') ?? ''}';

    final details = (t['detail_transaksi'] as List? ?? []).whereType<Map>().toList();
    final total = details.fold<int>(0, (a, d) => a + _int(d['jumlah']));

    final hasil = <_Stiker>[];
    var no = 0;
    for (final d in details) {
      final menu = '${(d['produk'] is Map ? d['produk']['nama_produk'] : '') ?? ''}';
      final varian = '${d['varian'] ?? ''}'.toUpperCase();
      for (var i = 0; i < _int(d['jumlah']); i++) {
        no++;
        hasil.add(_Stiker(nomor, nama, tipe, menu, varian, waktu, kode, '$no/$total'));
      }
    }
    return hasil;
  }

  /// Panggil setelah transaksi dibuat. [t] = res['data'] dari POST /transaksi
  static Future<void> cetakStikerTransaksi(Map t) async {
    try {
      final toko = await _toko();
      if ('${toko['printer_stiker']}' == 'nonaktif') return;

      final opsi = _opsi(toko['template_stiker'], StickerSettingsStore.options.value);
      if (opsi['enabled'] == false) return;

      final caption = _latin('${toko['caption_stiker'] ?? ''}');
      final list = _unitStiker(t);
      if (list.isEmpty) return;

      final bold = pw.Font.courierBold();
      bool on(String k) => opsi[k] ?? true;
      final fmt = PdfPageFormat(70 * PdfPageFormat.mm, 50 * PdfPageFormat.mm,
          marginAll: 3 * PdfPageFormat.mm);

      final doc = pw.Document();
      for (final s in list) {
        doc.addPage(pw.Page(
          pageFormat: fmt,
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(on('orderNumber') ? _latin(s.nomor) : '',
                      style: pw.TextStyle(font: bold, fontSize: 11)),
                  pw.Text(
                    [if (on('customerName')) _latin(s.nama), if (on('orderType')) s.tipe]
                        .join(' '),
                    style: pw.TextStyle(font: bold, fontSize: 11),
                  ),
                ],
              ),
              if (on('productName'))
                pw.Text(_latin(s.menu),
                    maxLines: 2, style: pw.TextStyle(font: bold, fontSize: 18)),
              if (on('productVariant') && s.varian.isNotEmpty)
                pw.Text(_latin(s.varian), style: pw.TextStyle(font: bold, fontSize: 9)),
              if (on('caption') && caption.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 6),
                  child: pw.Text(caption,
                      maxLines: 2,
                      style: pw.TextStyle(font: pw.Font.courierOblique(), fontSize: 8)),
                ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    [if (on('orderTime')) s.waktu, if (on('cashierCode')) _latin(s.kode)]
                        .join(' '),
                    style: pw.TextStyle(font: bold, fontSize: 8),
                  ),
                  pw.Text(on('itemProgress') ? s.urutan : '',
                      style: pw.TextStyle(font: bold, fontSize: 10)),
                ],
              ),
            ],
          ),
        ));
      }

      await _kirim(await doc.save(), 'Stiker ${list.first.nomor}', kPrinterDapur, fmt);
    } catch (e) {
      debugPrint('Gagal cetak stiker: $e');
    }
  }

  // =====================================================
  // STRUK (kertas roll 58mm; ganti ke roll80 kalau printer 80mm)
  // =====================================================
  static Future<void> cetakStruk(Map t) async {
    try {
      final toko = await _toko();
      if ('${toko['printer_struk']}' == 'nonaktif') return;

      final opsi = _opsi(toko['template_struk'], ReceiptSettingsStore.options.value);
      if (opsi['enabled'] == false) return;
      bool on(String k) => opsi[k] ?? true;

      final bold = pw.Font.courierBold();
      final reg = pw.Font.courier();
      final tgl = DateTime.tryParse('${t['tanggal']}')?.toLocal() ?? DateTime.now();
      final details = (t['detail_transaksi'] as List? ?? []).whereType<Map>().toList();

      pw.Widget baris(String a, String b, {bool tebal = false}) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                  child: pw.Text(_latin(a),
                      style: pw.TextStyle(font: tebal ? bold : reg, fontSize: 8))),
              pw.Text(b, style: pw.TextStyle(font: tebal ? bold : reg, fontSize: 8)),
            ],
          );

      pw.MemoryImage? qr;
      if (on('qrCode')) {
        final b = await QrisStore.loadImageBytes();
        if (b != null) qr = pw.MemoryImage(b);
      }

      final fmt = PdfPageFormat.roll57.copyWith(
        marginLeft: 3 * PdfPageFormat.mm,
        marginRight: 3 * PdfPageFormat.mm,
        marginTop: 3 * PdfPageFormat.mm,
        marginBottom: 6 * PdfPageFormat.mm,
      );

      final doc = pw.Document();
      doc.addPage(pw.Page(
        pageFormat: fmt,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
                child: pw.Text(_latin('${toko['nama_toko'] ?? 'Celcious Coffee'}'),
                    style: pw.TextStyle(font: bold, fontSize: 11))),
            pw.Center(
                child: pw.Text(
                    _latin(
                      '${(toko['alamat']?.toString().trim().isNotEmpty == true) ? toko['alamat'] : kDefaultAlamatToko}',
                    ),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: reg, fontSize: 7))),
            pw.Divider(thickness: 0.5),
            if (on('orderNumber'))
              pw.Text('Order #${t['kode'] ?? t['id_transaksi']}',
                  style: pw.TextStyle(font: bold, fontSize: 10)),
            if (on('cashierName') && t['pengguna'] is Map)
              pw.Text(_latin('Kasir: ${t['pengguna']['nama']}'),
                  style: pw.TextStyle(font: reg, fontSize: 8)),
            if ('${t['nama_pelanggan'] ?? ''}'.isNotEmpty)
              pw.Text(_latin('Pelanggan: ${t['nama_pelanggan']}'),
                  style: pw.TextStyle(font: reg, fontSize: 8)),
            if (on('orderTime')) ...[
              baris('Tanggal:', '${_dua(tgl.day)}/${_dua(tgl.month)}/${tgl.year}'),
              baris('Jam:', '${_dua(tgl.hour)}:${_dua(tgl.minute)}'),
            ],
            pw.Divider(thickness: 0.5),
            for (final d in details) ...[
              baris(
                '${d['produk'] is Map ? d['produk']['nama_produk'] : ''} x${_int(d['jumlah'])}',
                _rp(d['subtotal']),
              ),
              if ('${d['varian'] ?? ''}'.isNotEmpty)
                pw.Text(_latin('  ${d['varian']}'),
                    style: pw.TextStyle(font: reg, fontSize: 7)),
            ],
            pw.Divider(thickness: 0.5),
            baris('Subtotal', _rp(t['subtotal'])),
            baris('Pajak', _rp(t['ppn'])),
            if ((double.tryParse('${t['biaya_layanan']}') ?? 0) > 0)
              baris('Layanan', _rp(t['biaya_layanan'])),
            if ((double.tryParse('${t['diskon']}') ?? 0) > 0)
              baris('Diskon', '-${_rp(t['diskon'])}'),
            if (on('total')) baris('TOTAL', _rp(t['total']), tebal: true),
            if (t['metode_pembayaran'] is Map)
              baris('Bayar', '${t['metode_pembayaran']['nama_metode']}'),
            if (qr != null) ...[
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Image(qr, width: 90, height: 90)),
            ],
            pw.SizedBox(height: 6),
            pw.Center(
                child: pw.Text('Terima kasih!',
                    style: pw.TextStyle(font: reg, fontSize: 8))),
          ],
        ),
      ));

      await _kirim(await doc.save(), 'Struk ${t['kode'] ?? t['id_transaksi']}',
          kPrinterStruk, fmt);
    } catch (e) {
      debugPrint('Gagal cetak struk: $e');
    }
  }

  // =====================================================
  // STRUK DAPUR (sesuai format: Order No, Meja/Customer, Pesanan | Jlh Pesanan)
  // =====================================================
  static Future<void> cetakStrukDapur(Map<String, dynamic> receiptData) async {
    try {
      final bold = pw.Font.helveticaBold();
      final reg = pw.Font.helvetica();
      final orderId = '${receiptData['orderId'] ?? '-'}';
      final customerName = '${receiptData['customerName'] ?? ''}'.trim();
      final orderType = '${receiptData['orderType'] ?? 'Dine In'}'.trim();
      final subHeader = customerName.isNotEmpty
          ? '$orderType - $customerName'
          : orderType;

      final items = (receiptData['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final fmt = PdfPageFormat.roll57.copyWith(
        marginLeft: 4 * PdfPageFormat.mm,
        marginRight: 4 * PdfPageFormat.mm,
        marginTop: 4 * PdfPageFormat.mm,
        marginBottom: 6 * PdfPageFormat.mm,
      );

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: fmt,
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _latin('Order #$orderId'),
                style: pw.TextStyle(font: bold, fontSize: 13),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _latin(subHeader),
                style: pw.TextStyle(font: reg, fontSize: 9),
              ),
              pw.SizedBox(height: 6),
              pw.Container(height: 1.2, color: PdfColors.black),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Pesanan',
                    style: pw.TextStyle(font: bold, fontSize: 9),
                  ),
                  pw.Text(
                    'Jlh Pesanan',
                    style: pw.TextStyle(font: bold, fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              for (final item in items) ...[
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            _latin('${item['name'] ?? 'Menu'}'),
                            style: pw.TextStyle(font: bold, fontSize: 9),
                          ),
                          if ('${item['catatan'] ?? ''}'.trim().isNotEmpty)
                            pw.Text(
                              _latin('Catatan: ${item['catatan']}'),
                              style: pw.TextStyle(font: reg, fontSize: 7.5),
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      '${item['quantity'] ?? 1}',
                      style: pw.TextStyle(font: bold, fontSize: 9.5),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
              ],
            ],
          ),
        ),
      );

      await _kirim(
        await doc.save(),
        'Struk_Dapur_$orderId',
        kPrinterDapur,
        fmt,
      );
    } catch (e) {
      debugPrint('Gagal cetak struk dapur: $e');
    }
  }

  /// Cetak struk pelanggan langsung dari map `receiptData` halaman TransaksiBerhasil.
  static Future<void> cetakStrukCustomer(
    Map<String, dynamic> receiptData,
  ) async {
    final items = (receiptData['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) {
          final qty = _int(item['quantity']);
          final price = (item['price'] as num?)?.toDouble() ?? 0;
          return {
            'jumlah': qty,
            'varian': item['catatan']?.toString() ?? '',
            'harga_satuan': price,
            'subtotal': price * qty,
            'produk': {'nama_produk': item['name']?.toString() ?? 'Menu'},
          };
        })
        .toList();

    final rawDate = receiptData['orderedAt'];
    final dateIso = rawDate is DateTime
        ? rawDate.toIso8601String()
        : DateTime.now().toIso8601String();

    await cetakStruk({
      'kode': receiptData['orderId']?.toString() ?? '-',
      'nama_pelanggan': receiptData['customerName']?.toString() ?? '',
      'tipe_pesanan': receiptData['orderType']?.toString() ?? 'Dine In',
      'tanggal': dateIso,
      'subtotal': receiptData['subtotal'] ?? 0,
      'ppn': receiptData['tax'] ?? 0,
      'biaya_layanan': 0,
      'diskon': receiptData['discount'] ?? 0,
      'total': receiptData['total'] ?? 0,
      'pengguna': {'nama': receiptData['cashierName']?.toString() ?? 'Kasir'},
      'metode_pembayaran': {
        'nama_metode': receiptData['paymentMethod']?.toString() ?? '-',
      },
      'detail_transaksi': items,
    });
  }
}