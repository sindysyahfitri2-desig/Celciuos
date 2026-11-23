import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/owner_profile_store.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class LaporanStokExport {
  LaporanStokExport._();

  static const _bulan = [
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

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _angka(num value) {
    final neg = value < 0;
    final abs = value.abs();
    if (abs % 1 == 0) {
      final str = abs.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
      return '${neg ? '-' : ''}$str';
    }
    return '${neg ? '-' : ''}${abs.toStringAsFixed(1)}';
  }

  static String _rupiah(num value) {
    final neg = value < 0;
    final str = value.abs().round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '${neg ? '-' : ''}Rp $str';
  }

  static Future<void> _saveBytes({
    required String name,
    required Uint8List bytes,
    required String ext,
    required MimeType mime,
  }) async {
    if (kIsWeb) {
      await FileSaver.instance.saveFile(
        name: name,
        bytes: bytes,
        fileExtension: ext,
        mimeType: mime,
      );
      return;
    }
    try {
      await FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        fileExtension: ext,
        mimeType: mime,
      );
    } on UnimplementedError {
      await FileSaver.instance.saveFile(
        name: name,
        bytes: bytes,
        fileExtension: ext,
        mimeType: mime,
      );
    }
  }

  static Future<void> _catatAudit(String jenis, String periode) async {
    try {
      await ApiService.post('laporan', {
        'jenis_laporan': jenis,
        'periode': periode,
      });
    } catch (_) {}
  }

  // ============================================================
  // EKSPOR PDF LAPORAN MANAJEMEN STOK RESMI
  // ============================================================

  static Future<void> exportPdf({
    required Map<String, dynamic> laporan,
    required String labelPeriode,
  }) async {
    final now = DateTime.now();
    final d2 = now.day.toString().padLeft(2, '0');
    final m2 = now.month.toString().padLeft(2, '0');
    final y4 = now.year.toString();
    final longDate = '${now.day} ${_bulan[now.month - 1]} $y4';
    final docNo = 'LS-CC/$y4/$m2/$d2';

    final toko = (laporan['toko'] as Map?) ?? {};
    final storeName = (toko['nama_toko']?.toString().trim().isNotEmpty == true)
        ? toko['nama_toko'].toString().toUpperCase()
        : 'CELCIOUS COFFEE INDONESIA';
    final address = (toko['alamat']?.toString().trim().isNotEmpty == true)
        ? toko['alamat'].toString()
        : 'Jl. Arah Kampung Satu, Mekar Sawit, Kec. Sawit Seberang, Kab. Langkat, Sumatera Utara';

    final ringkasan = (laporan['ringkasan'] as Map?) ?? {};
    final terlaris = (laporan['produk_terlaris'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final kurangLaku = (laporan['produk_kurang_laku'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final cepatHabis = (laporan['bahan_cepat_habis'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final terbuang = (laporan['bahan_terbuang'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final rekap = (laporan['rekap_bahan'] as List? ?? const [])
        .whereType<Map>()
        .toList();

    final ownerName = OwnerProfileStore.ownerName.value.trim().isNotEmpty
        ? OwnerProfileStore.ownerName.value.trim()
        : 'Owner Celcious';

    final navyPdf = PdfColor.fromInt(0xFF0B2540);
    final mutedPdf = PdfColor.fromInt(0xFF64788B);
    final borderPdf = PdfColor.fromInt(0xFF9FB0C2);
    final headerBg = PdfColor.fromInt(0xFFEAF3FB);
    final zebraBg = PdfColor.fromInt(0xFFF7FAFD);

    pw.Widget sectionTitle(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: navyPdf,
        ),
      ),
    );

    pw.Widget buildTable(
      List<String> headers,
      List<List<String>> rows, {
      Map<int, pw.Alignment>? alignments,
    }) {
      return pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        border: pw.TableBorder.all(color: borderPdf, width: 0.5),
        headerStyle: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: navyPdf,
        ),
        headerDecoration: pw.BoxDecoration(color: headerBg),
        cellStyle: const pw.TextStyle(fontSize: 7.8),
        oddRowDecoration: pw.BoxDecoration(color: zebraBg),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        cellAlignments: alignments ?? {},
      );
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: borderPdf, width: 0.6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Dokumen Sah Internal Celcious Coffee • $docNo',
                style: pw.TextStyle(fontSize: 7.5, color: mutedPdf),
              ),
              pw.Text(
                'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 7.5, color: mutedPdf),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          // KOP DOKUMEN
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                storeName,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: navyPdf,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                address,
                style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'No. Dokumen: $docNo',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: navyPdf,
                    ),
                  ),
                  pw.Text(
                    'Periode: $labelPeriode',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: navyPdf,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: navyPdf, thickness: 1.3),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'LAPORAN MANAJEMEN STOK, ANALISIS PENJUALAN & WASTE',
                  style: pw.TextStyle(
                    fontSize: 11.5,
                    fontWeight: pw.FontWeight.bold,
                    color: navyPdf,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'Periode: $labelPeriode',
                  style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(color: navyPdf, thickness: 1.0),
            ],
          ),

          // RINGKASAN KPI
          sectionTitle('1. RINGKASAN PERSEDIAAN & KINERJA STOK'),
          buildTable(
            ['Indikator', 'Nilai'],
            [
              [
                'Total Nilai Persediaan Bahan Baku',
                _rupiah(_num(ringkasan['total_nilai_persediaan'])),
              ],
              [
                'Total Biaya Pembelian (Restock)',
                _rupiah(_num(ringkasan['total_biaya_pembelian'])),
              ],
              [
                'Total Porsi Produk Terjual (Lunas)',
                '${_angka(_num(ringkasan['total_item_terjual']))} porsi',
              ],
              [
                'Estimasi Total HPP Pemakaian Resep',
                _rupiah(_num(ringkasan['total_estimasi_hpp'])),
              ],
              [
                'Total Kerugian Bahan Terbuang / Rusak (Waste)',
                _rupiah(_num(ringkasan['total_kerugian_waste'])),
              ],
              [
                'Status Bahan Baku (Aktif / Menipis / Habis)',
                '${ringkasan['total_bahan_baku'] ?? 0} aktif  •  ${ringkasan['total_bahan_menipis'] ?? 0} menipis  •  ${ringkasan['total_bahan_habis'] ?? 0} habis',
              ],
            ],
            alignments: {1: pw.Alignment.centerRight},
          ),

          // 2. PRODUK TERLARIS
          sectionTitle('2. PRODUK PALING BANYAK TERJUAL (BEST SELLER)'),
          if (terlaris.isEmpty)
            pw.Text(
              'Belum ada penjualan produk lunas pada periode ini.',
              style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
            )
          else
            buildTable(
              ['No', 'Nama Produk', 'Kategori', 'Terjual', 'Omzet', 'Est. HPP', 'Est. Laba'],
              List.generate(terlaris.length, (i) {
                final p = terlaris[i];
                return [
                  '${i + 1}',
                  '${p['nama_produk'] ?? '-'}',
                  '${p['kategori'] ?? '-'}',
                  '${_angka(_num(p['total_terjual']))}x',
                  _rupiah(_num(p['total_omzet'])),
                  _rupiah(_num(p['estimasi_hpp'])),
                  _rupiah(_num(p['estimasi_laba'])),
                ];
              }),
              alignments: {
                0: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerRight,
              },
            ),

          // 3. PRODUK KURANG LAKU
          sectionTitle('3. PRODUK KURANG LAKU / PERLU EVALUASI (SLOW MOVING)'),
          if (kurangLaku.isEmpty)
            pw.Text(
              'Semua produk aktif terjual dengan baik.',
              style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
            )
          else
            buildTable(
              ['No', 'Nama Produk', 'Kategori', 'Terjual', 'Omzet'],
              List.generate(kurangLaku.length, (i) {
                final p = kurangLaku[i];
                return [
                  '${i + 1}',
                  '${p['nama_produk'] ?? '-'}',
                  '${p['kategori'] ?? '-'}',
                  '${_angka(_num(p['total_terjual']))}x',
                  _rupiah(_num(p['total_omzet'])),
                ];
              }),
              alignments: {
                0: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
            ),

          // 4. BAHAN PALING CEPAT HABIS
          sectionTitle('4. BAHAN BAKU PALING CEPAT HABIS (PEMAKAIAN TERTINGGI)'),
          if (cepatHabis.isEmpty)
            pw.Text(
              'Belum ada pemakaian bahan baku dari transaksi pada periode ini.',
              style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
            )
          else
            buildTable(
              ['Nama Bahan', 'Pemakaian', 'Sisa Stok', 'Rata/Hari', 'Est. Habis', 'Status'],
              cepatHabis.map((b) {
                final sat = b['satuan'] ?? '';
                final est = b['estimasi_habis_hari'];
                return [
                  '${b['nama_bahan_baku'] ?? '-'}',
                  '${_angka(_num(b['total_pemakaian']))} $sat',
                  '${_angka(_num(b['stok_tersedia']))} $sat',
                  '${_angka(_num(b['rata_pemakaian_harian']))} $sat',
                  est == null ? '-' : '$est hari',
                  '${b['status_stok'] ?? 'aman'}'.toUpperCase(),
                ];
              }).toList(),
              alignments: {
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.center,
              },
            ),

          // 5. BAHAN TERBUANG / WASTE
          sectionTitle('5. BAHAN TERBUANG / RUSAK / KEDALUWARSA (WASTE)'),
          if (terbuang.isEmpty)
            pw.Text(
              'Tidak ada bahan baku terbuang / rusak pada periode ini (0% waste).',
              style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
            )
          else
            buildTable(
              ['Nama Bahan', 'Alasan', 'Jumlah', 'Estimasi Kerugian', 'Catatan'],
              terbuang.map((w) {
                return [
                  '${w['nama_bahan_baku'] ?? '-'}',
                  '${w['alasan'] ?? '-'}'.toUpperCase(),
                  '${_angka(_num(w['total_jumlah']))} ${w['satuan'] ?? ''}',
                  _rupiah(_num(w['estimasi_kerugian'])),
                  '${w['catatan'] ?? '-'}',
                ];
              }).toList(),
              alignments: {
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),

          // 6. REKAP PERSEDIAAN LENGKAP
          sectionTitle('6. REKAP PERSEDIAAN & MUTASI BAHAN BAKU'),
          buildTable(
            ['Nama Bahan', 'Kategori', 'Stok', 'Min', 'Status', 'Nilai Aset', 'Pemakaian'],
            rekap.map((b) {
              final sat = b['satuan'] ?? '';
              return [
                '${b['nama_bahan_baku'] ?? '-'}',
                '${b['kategori'] ?? '-'}',
                '${_angka(_num(b['stok_tersedia']))} $sat',
                '${_angka(_num(b['stok_minimum']))} $sat',
                '${b['status_stok'] ?? 'aman'}'.toUpperCase(),
                _rupiah(_num(b['nilai_persediaan'])),
                '${_angka(_num(b['total_pemakaian']))} $sat',
              ];
            }).toList(),
            alignments: {
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.center,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
            },
          ),

          // TANDA TANGAN
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('Langkat, $longDate', style: pw.TextStyle(fontSize: 8.5, color: navyPdf)),
                pw.SizedBox(height: 4),
                pw.Text(
                  'DISETUJUI & DISAHKAN,',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: mutedPdf,
                  ),
                ),
                pw.SizedBox(height: 36),
                pw.Text(
                  ownerName,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: navyPdf,
                  ),
                ),
                pw.Text(
                  'Owner / Pemilik Celcious Coffee',
                  style: pw.TextStyle(fontSize: 8, color: mutedPdf),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await _saveBytes(
      name: 'Laporan_Manajemen_Stok_${y4}_${m2}_$d2',
      bytes: bytes,
      ext: 'pdf',
      mime: MimeType.pdf,
    );
    await _catatAudit('Laporan Manajemen Stok (PDF)', labelPeriode);
  }

  // ============================================================
  // EKSPOR EXCEL 4-SHEET LAPORAN MANAJEMEN STOK
  // ============================================================

  static Future<void> exportExcel({
    required Map<String, dynamic> laporan,
    required String labelPeriode,
  }) async {
    final now = DateTime.now();
    final d2 = now.day.toString().padLeft(2, '0');
    final m2 = now.month.toString().padLeft(2, '0');
    final y4 = now.year.toString();

    final excel = xl.Excel.createExcel();
    excel.rename('Sheet1', 'Persediaan Bahan');

    final rekap = (laporan['rekap_bahan'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final terlaris = (laporan['produk_terlaris'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final kurangLaku = (laporan['produk_kurang_laku'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final cepatHabis = (laporan['bahan_cepat_habis'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final terbuang = (laporan['bahan_terbuang'] as List? ?? const [])
        .whereType<Map>()
        .toList();

    // Sheet 1: Persediaan Bahan
    final s1 = excel['Persediaan Bahan'];
    s1.appendRow([
      xl.TextCellValue('Nama Bahan'),
      xl.TextCellValue('Kategori'),
      xl.TextCellValue('Stok Tersedia'),
      xl.TextCellValue('Stok Minimum'),
      xl.TextCellValue('Satuan'),
      xl.TextCellValue('Status'),
      xl.TextCellValue('Harga Beli (Rp)'),
      xl.TextCellValue('Nilai Aset (Rp)'),
      xl.TextCellValue('Masuk'),
      xl.TextCellValue('Keluar / Waste'),
      xl.TextCellValue('Pemakaian Kasir'),
    ]);
    for (final b in rekap) {
      s1.appendRow([
        xl.TextCellValue('${b['nama_bahan_baku'] ?? '-'}'),
        xl.TextCellValue('${b['kategori'] ?? '-'}'),
        xl.DoubleCellValue(_num(b['stok_tersedia'])),
        xl.DoubleCellValue(_num(b['stok_minimum'])),
        xl.TextCellValue('${b['satuan'] ?? ''}'),
        xl.TextCellValue('${b['status_stok'] ?? 'aman'}'),
        xl.DoubleCellValue(_num(b['harga_beli'])),
        xl.DoubleCellValue(_num(b['nilai_persediaan'])),
        xl.DoubleCellValue(_num(b['total_masuk'])),
        xl.DoubleCellValue(_num(b['total_keluar'])),
        xl.DoubleCellValue(_num(b['total_pemakaian'])),
      ]);
    }

    // Sheet 2: Produk Terlaris & Kurang Laku
    final s2 = excel['Analisis Produk'];
    s2.appendRow([
      xl.TextCellValue('Kelompok'),
      xl.TextCellValue('Nama Produk'),
      xl.TextCellValue('Kategori'),
      xl.TextCellValue('Terjual (Porsi)'),
      xl.TextCellValue('Total Omzet (Rp)'),
      xl.TextCellValue('Estimasi HPP (Rp)'),
      xl.TextCellValue('Estimasi Laba (Rp)'),
    ]);
    for (final p in terlaris) {
      s2.appendRow([
        xl.TextCellValue('Terlaris'),
        xl.TextCellValue('${p['nama_produk'] ?? '-'}'),
        xl.TextCellValue('${p['kategori'] ?? '-'}'),
        xl.IntCellValue(_num(p['total_terjual']).toInt()),
        xl.DoubleCellValue(_num(p['total_omzet'])),
        xl.DoubleCellValue(_num(p['estimasi_hpp'])),
        xl.DoubleCellValue(_num(p['estimasi_laba'])),
      ]);
    }
    for (final p in kurangLaku) {
      s2.appendRow([
        xl.TextCellValue('Kurang Laku'),
        xl.TextCellValue('${p['nama_produk'] ?? '-'}'),
        xl.TextCellValue('${p['kategori'] ?? '-'}'),
        xl.IntCellValue(_num(p['total_terjual']).toInt()),
        xl.DoubleCellValue(_num(p['total_omzet'])),
        xl.DoubleCellValue(_num(p['estimasi_hpp'])),
        xl.DoubleCellValue(_num(p['estimasi_laba'])),
      ]);
    }

    // Sheet 3: Bahan Cepat Habis
    final s3 = excel['Bahan Cepat Habis'];
    s3.appendRow([
      xl.TextCellValue('Nama Bahan'),
      xl.TextCellValue('Satuan'),
      xl.TextCellValue('Pemakaian Penjualan'),
      xl.TextCellValue('Sisa Stok'),
      xl.TextCellValue('Rata-rata/Hari'),
      xl.TextCellValue('Estimasi Habis (Hari)'),
      xl.TextCellValue('Status'),
    ]);
    for (final b in cepatHabis) {
      s3.appendRow([
        xl.TextCellValue('${b['nama_bahan_baku'] ?? '-'}'),
        xl.TextCellValue('${b['satuan'] ?? ''}'),
        xl.DoubleCellValue(_num(b['total_pemakaian'])),
        xl.DoubleCellValue(_num(b['stok_tersedia'])),
        xl.DoubleCellValue(_num(b['rata_pemakaian_harian'])),
        xl.TextCellValue(
          b['estimasi_habis_hari'] == null ? '-' : '${b['estimasi_habis_hari']}',
        ),
        xl.TextCellValue('${b['status_stok'] ?? 'aman'}'),
      ]);
    }

    // Sheet 4: Bahan Terbuang (Waste)
    final s4 = excel['Bahan Terbuang (Waste)'];
    s4.appendRow([
      xl.TextCellValue('Nama Bahan'),
      xl.TextCellValue('Alasan'),
      xl.TextCellValue('Jumlah Terbuang'),
      xl.TextCellValue('Satuan'),
      xl.TextCellValue('Estimasi Kerugian (Rp)'),
      xl.TextCellValue('Catatan'),
    ]);
    for (final w in terbuang) {
      s4.appendRow([
        xl.TextCellValue('${w['nama_bahan_baku'] ?? '-'}'),
        xl.TextCellValue('${w['alasan'] ?? '-'}'),
        xl.DoubleCellValue(_num(w['total_jumlah'])),
        xl.TextCellValue('${w['satuan'] ?? ''}'),
        xl.DoubleCellValue(_num(w['estimasi_kerugian'])),
        xl.TextCellValue('${w['catatan'] ?? '-'}'),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('File Excel gagal dibuat.');
    await _saveBytes(
      name: 'Laporan_Manajemen_Stok_${y4}_${m2}_$d2',
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mime: MimeType.microsoftExcel,
    );
    await _catatAudit('Laporan Manajemen Stok (Excel)', labelPeriode);
  }
}
