import 'package:excel/excel.dart' as xl;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/owner_profile_store.dart';
import 'package:kasir_celcious_coffe/features/reports/application/celcious_report_export.dart';
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

  static const _defaultAddress =
      'Jl. Arah Kampung Satu, Mekar Sawit, Kec. Sawit Seberang, Kab. Langkat, Sumatera Utara';

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
    return '${neg ? '-' : ''}Rp. $str';
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

  static pw.Widget _pdfFallbackLogo() {
    return pw.Container(
      width: 54,
      height: 54,
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF39648B),
        shape: pw.BoxShape.circle,
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        'CELCIOUS\nCOFFEE',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _pdfKopSurat({
    required String storeName,
    required String address,
    required String contactLine,
    required Uint8List? logoBytes,
    required PdfColor navyPdf,
    required PdfColor mutedPdf,
  }) {
    pw.Widget logoWidget;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      try {
        final memImg = pw.MemoryImage(logoBytes);
        logoWidget = pw.ClipOval(
          child: pw.Container(
            width: 54,
            height: 54,
            child: pw.Image(memImg, fit: pw.BoxFit.cover),
          ),
        );
      } catch (_) {
        logoWidget = _pdfFallbackLogo();
      }
    } else {
      logoWidget = _pdfFallbackLogo();
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        logoWidget,
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                storeName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: navyPdf,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                address,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                contactLine,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 66),
      ],
    );
  }

  // ============================================================
  // EKSPOR PDF LAPORAN MANAJEMEN STOK RESMI (SERAGAM DENGAN LAPORAN TRANSAKSI)
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
        ? toko['nama_toko'].toString().trim().toUpperCase()
        : kCelciousStoreName;
    final address = (toko['alamat']?.toString().trim().isNotEmpty == true)
        ? toko['alamat'].toString().trim()
        : _defaultAddress;
    final logoBytes = await CelciousReportExport.loadBrandLogoBytes();

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

    final ownerName = CelciousReportExport.resolveOwnerName(
      OwnerProfileStore.ownerName.value,
    );

    final navyPdf = PdfColor.fromInt(0xFF0B2540);
    final mutedPdf = PdfColor.fromInt(0xFF64788B);
    final borderPdf = PdfColor.fromInt(0xFF8EA4B8);
    final zebraBg = PdfColor.fromInt(0xFFF7FAFD);

    pw.Widget sectionTitle(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9.8,
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
        border: pw.TableBorder.all(color: borderPdf, width: 0.7),
        headerStyle: pw.TextStyle(
          fontSize: 8.3,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: pw.BoxDecoration(color: navyPdf),
        cellStyle: const pw.TextStyle(fontSize: 8),
        oddRowDecoration: pw.BoxDecoration(color: zebraBg),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        cellAlignments: alignments ?? {},
      );
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
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
          // KOP SURAT SERAGAM DENGAN LAPORAN TRANSAKSI
          _pdfKopSurat(
            storeName: storeName,
            address: address,
            contactLine: kCelciousContact,
            logoBytes: logoBytes,
            navyPdf: navyPdf,
            mutedPdf: mutedPdf,
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: navyPdf, thickness: 1.5),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'LAPORAN MANAJEMEN STOK CELCIOUS COFFEE',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: navyPdf,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Periode $labelPeriode',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: mutedPdf,
                  ),
                ),
              ],
            ),
          ),

          // 1. RINGKASAN KPI
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

          // FOOTER TANDA TANGAN OWNER (SERAGAM DENGAN LAPORAN TRANSAKSI)
          pw.SizedBox(height: 28),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Mengetahui :',
                style: pw.TextStyle(fontSize: 9.2, color: navyPdf),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Langkat, $longDate',
                    style: pw.TextStyle(fontSize: 9.2, color: navyPdf),
                  ),
                  pw.SizedBox(height: 44),
                  pw.Text(
                    '($ownerName)',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 9.2,
                      fontWeight: pw.FontWeight.bold,
                      color: navyPdf,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Owner',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
                  ),
                ],
              ),
            ],
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
  // (KOP SURAT SERAGAM LAPORAN TRANSAKSI + FOOTER TANDA TANGAN OWNER)
  // ============================================================

  static Future<void> exportExcel({
    required Map<String, dynamic> laporan,
    required String labelPeriode,
  }) async {
    final now = DateTime.now();
    final d2 = now.day.toString().padLeft(2, '0');
    final m2 = now.month.toString().padLeft(2, '0');
    final y4 = now.year.toString();
    final longDate = '${now.day} ${_bulan[now.month - 1]} $y4';

    final toko = (laporan['toko'] as Map?) ?? {};
    final storeName = (toko['nama_toko']?.toString().trim().isNotEmpty == true)
        ? toko['nama_toko'].toString().trim().toUpperCase()
        : kCelciousStoreName;
    final address = (toko['alamat']?.toString().trim().isNotEmpty == true)
        ? toko['alamat'].toString().trim()
        : _defaultAddress;
    final ownerName = CelciousReportExport.resolveOwnerName(
      OwnerProfileStore.ownerName.value,
    );

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

    final thinBorder = xl.Border(
      borderStyle: xl.BorderStyle.Thin,
      borderColorHex: xl.ExcelColor.fromHexString('FF4A5D70'),
    );
    final headerDivider = xl.Border(
      borderStyle: xl.BorderStyle.Medium,
      borderColorHex: xl.ExcelColor.fromHexString('FF0B2540'),
    );
    final navyHex = xl.ExcelColor.fromHexString('FF0B2540');

    xl.CellIndex idx(int col, int row) =>
        xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);

    void writeMerged(
      xl.Sheet sheet,
      int row,
      int startCol,
      int endCol,
      String text, {
      bool bold = false,
      int size = 11,
      xl.HorizontalAlign align = xl.HorizontalAlign.Center,
      xl.ExcelColor? bg,
      xl.ExcelColor? fg,
      bool bordered = false,
      xl.Border? bottomBorder,
    }) {
      if (endCol > startCol) {
        sheet.merge(idx(startCol, row), idx(endCol, row));
      }
      final style = xl.CellStyle(
        bold: bold,
        fontSize: size,
        horizontalAlign: align,
        verticalAlign: xl.VerticalAlign.Center,
        backgroundColorHex: bg ?? xl.ExcelColor.none,
        fontColorHex: fg ?? navyHex,
        leftBorder: bordered ? thinBorder : null,
        rightBorder: bordered ? thinBorder : null,
        topBorder: bordered ? thinBorder : null,
        bottomBorder: bottomBorder ?? (bordered ? thinBorder : null),
      );
      for (var c = startCol; c <= endCol; c++) {
        final cell = sheet.cell(idx(c, row));
        if (c == startCol) cell.value = xl.TextCellValue(text);
        cell.cellStyle = style;
      }
    }

    xl.CellStyle headerCellStyle() => xl.CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      backgroundColorHex: navyHex,
      fontColorHex: xl.ExcelColor.white,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    xl.CellStyle dataCellStyle(xl.HorizontalAlign align) => xl.CellStyle(
      fontSize: 10,
      horizontalAlign: align,
      verticalAlign: xl.VerticalAlign.Center,
      leftBorder: thinBorder,
      rightBorder: thinBorder,
      topBorder: thinBorder,
      bottomBorder: thinBorder,
    );

    int writeKopDanJudul(
      xl.Sheet sheet, {
      required int lastCol,
      required String reportTitle,
    }) {
      var row = 0;
      writeMerged(sheet, row++, 0, lastCol, storeName, bold: true, size: 15);
      writeMerged(sheet, row++, 0, lastCol, address, size: 10);
      writeMerged(
        sheet,
        row++,
        0,
        lastCol,
        kCelciousContact,
        size: 10,
        bottomBorder: headerDivider,
      );
      row++; // baris spasi

      writeMerged(sheet, row++, 0, lastCol, reportTitle, bold: true, size: 13);
      writeMerged(
        sheet,
        row++,
        0,
        lastCol,
        'Periode $labelPeriode',
        bold: true,
        size: 11,
      );
      row++; // baris spasi

      sheet.setRowHeight(0, 24);
      sheet.setRowHeight(1, 18);
      sheet.setRowHeight(2, 18);
      return row;
    }

    void writeOwnerSignatureFooter(
      xl.Sheet sheet, {
      required int startRow,
      required int lastCol,
    }) {
      var row = startRow + 2;
      final rightStart = lastCol >= 5 ? lastCol - 2 : (lastCol >= 3 ? lastCol - 1 : lastCol);

      writeMerged(
        sheet,
        row,
        0,
        1,
        'Mengetahui :',
        size: 10,
        align: xl.HorizontalAlign.Left,
      );
      writeMerged(
        sheet,
        row,
        rightStart,
        lastCol,
        'Langkat, $longDate',
        size: 10,
        align: xl.HorizontalAlign.Center,
      );
      row += 4;

      writeMerged(
        sheet,
        row,
        rightStart,
        lastCol,
        '($ownerName)',
        bold: true,
        size: 10,
        align: xl.HorizontalAlign.Center,
      );
      row++;

      writeMerged(
        sheet,
        row,
        rightStart,
        lastCol,
        'Owner',
        size: 10,
        align: xl.HorizontalAlign.Center,
      );
    }

    void writeStyledTable({
      required xl.Sheet sheet,
      required String reportTitle,
      required List<String> headers,
      required List<List<xl.CellValue>> rows,
      required List<xl.HorizontalAlign> aligns,
      required List<double> colWidths,
    }) {
      final lastCol = headers.length - 1;
      var row = writeKopDanJudul(
        sheet,
        lastCol: lastCol,
        reportTitle: reportTitle,
      );

      final hStyle = headerCellStyle();
      for (var c = 0; c < headers.length; c++) {
        sheet.cell(idx(c, row))
          ..value = xl.TextCellValue(headers[c])
          ..cellStyle = hStyle;
      }
      row++;

      if (rows.isEmpty) {
        writeMerged(
          sheet,
          row++,
          0,
          lastCol,
          'Belum ada data pada periode ini.',
          size: 10,
          bordered: true,
        );
      } else {
        for (final r in rows) {
          for (var c = 0; c < headers.length; c++) {
            sheet.cell(idx(c, row))
              ..value = r[c]
              ..cellStyle = dataCellStyle(aligns[c]);
          }
          row++;
        }
      }

      writeOwnerSignatureFooter(sheet, startRow: row, lastCol: lastCol);

      for (var c = 0; c < colWidths.length; c++) {
        sheet.setColumnWidth(c, colWidths[c]);
      }
    }

    // Sheet 1: Persediaan Bahan
    writeStyledTable(
      sheet: excel['Persediaan Bahan'],
      reportTitle: 'LAPORAN PERSEDIAAN BAHAN BAKU CELCIOUS COFFEE',
      headers: const [
        'No',
        'Nama Bahan',
        'Kategori',
        'Stok Tersedia',
        'Stok Minimum',
        'Satuan',
        'Status',
        'Harga Beli',
        'Nilai Aset',
        'Masuk',
        'Keluar / Waste',
        'Pemakaian Kasir',
      ],
      rows: List.generate(rekap.length, (i) {
        final b = rekap[i];
        return [
          xl.IntCellValue(i + 1),
          xl.TextCellValue('${b['nama_bahan_baku'] ?? '-'}'),
          xl.TextCellValue('${b['kategori'] ?? '-'}'),
          xl.DoubleCellValue(_num(b['stok_tersedia'])),
          xl.DoubleCellValue(_num(b['stok_minimum'])),
          xl.TextCellValue('${b['satuan'] ?? ''}'),
          xl.TextCellValue('${b['status_stok'] ?? 'aman'}'.toUpperCase()),
          xl.TextCellValue(_rupiah(_num(b['harga_beli']))),
          xl.TextCellValue(_rupiah(_num(b['nilai_persediaan']))),
          xl.DoubleCellValue(_num(b['total_masuk'])),
          xl.DoubleCellValue(_num(b['total_keluar'])),
          xl.DoubleCellValue(_num(b['total_pemakaian'])),
        ];
      }),
      aligns: const [
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Left,
        xl.HorizontalAlign.Left,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Right,
      ],
      colWidths: const [7, 24, 16, 14, 14, 10, 12, 18, 20, 11, 14, 16],
    );

    // Sheet 2: Analisis Produk
    final semuaProduk = <List<xl.CellValue>>[
      ...List.generate(terlaris.length, (i) {
        final p = terlaris[i];
        return [
          xl.IntCellValue(i + 1),
          xl.TextCellValue('Terlaris'),
          xl.TextCellValue('${p['nama_produk'] ?? '-'}'),
          xl.TextCellValue('${p['kategori'] ?? '-'}'),
          xl.IntCellValue(_num(p['total_terjual']).toInt()),
          xl.TextCellValue(_rupiah(_num(p['total_omzet']))),
          xl.TextCellValue(_rupiah(_num(p['estimasi_hpp']))),
          xl.TextCellValue(_rupiah(_num(p['estimasi_laba']))),
        ];
      }),
      ...List.generate(kurangLaku.length, (i) {
        final p = kurangLaku[i];
        return [
          xl.IntCellValue(terlaris.length + i + 1),
          xl.TextCellValue('Kurang Laku'),
          xl.TextCellValue('${p['nama_produk'] ?? '-'}'),
          xl.TextCellValue('${p['kategori'] ?? '-'}'),
          xl.IntCellValue(_num(p['total_terjual']).toInt()),
          xl.TextCellValue(_rupiah(_num(p['total_omzet']))),
          xl.TextCellValue(_rupiah(_num(p['estimasi_hpp']))),
          xl.TextCellValue(_rupiah(_num(p['estimasi_laba']))),
        ];
      }),
    ];

    writeStyledTable(
      sheet: excel['Analisis Produk'],
      reportTitle: 'LAPORAN ANALISIS PENJUALAN PRODUK CELCIOUS COFFEE',
      headers: const [
        'No',
        'Kelompok',
        'Nama Produk',
        'Kategori',
        'Terjual (Porsi)',
        'Total Omzet',
        'Estimasi HPP',
        'Estimasi Laba',
      ],
      rows: semuaProduk,
      aligns: const [
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Left,
        xl.HorizontalAlign.Left,
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Right,
      ],
      colWidths: const [7, 15, 26, 16, 15, 20, 20, 20],
    );

    // Sheet 3: Bahan Cepat Habis
    writeStyledTable(
      sheet: excel['Bahan Cepat Habis'],
      reportTitle: 'LAPORAN BAHAN BAKU CEPAT HABIS CELCIOUS COFFEE',
      headers: const [
        'No',
        'Nama Bahan',
        'Satuan',
        'Pemakaian Penjualan',
        'Sisa Stok',
        'Rata-rata/Hari',
        'Estimasi Habis (Hari)',
        'Status',
      ],
      rows: List.generate(cepatHabis.length, (i) {
        final b = cepatHabis[i];
        return [
          xl.IntCellValue(i + 1),
          xl.TextCellValue('${b['nama_bahan_baku'] ?? '-'}'),
          xl.TextCellValue('${b['satuan'] ?? ''}'),
          xl.DoubleCellValue(_num(b['total_pemakaian'])),
          xl.DoubleCellValue(_num(b['stok_tersedia'])),
          xl.DoubleCellValue(_num(b['rata_pemakaian_harian'])),
          xl.TextCellValue(
            b['estimasi_habis_hari'] == null ? '-' : '${b['estimasi_habis_hari']} hari',
          ),
          xl.TextCellValue('${b['status_stok'] ?? 'aman'}'.toUpperCase()),
        ];
      }),
      aligns: const [
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Left,
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Center,
      ],
      colWidths: const [7, 24, 12, 20, 14, 16, 20, 14],
    );

    // Sheet 4: Bahan Terbuang (Waste)
    writeStyledTable(
      sheet: excel['Bahan Terbuang (Waste)'],
      reportTitle: 'LAPORAN BAHAN TERBUANG (WASTE) CELCIOUS COFFEE',
      headers: const [
        'No',
        'Nama Bahan',
        'Alasan',
        'Jumlah Terbuang',
        'Satuan',
        'Estimasi Kerugian',
        'Catatan',
      ],
      rows: List.generate(terbuang.length, (i) {
        final w = terbuang[i];
        return [
          xl.IntCellValue(i + 1),
          xl.TextCellValue('${w['nama_bahan_baku'] ?? '-'}'),
          xl.TextCellValue('${w['alasan'] ?? '-'}'.toUpperCase()),
          xl.DoubleCellValue(_num(w['total_jumlah'])),
          xl.TextCellValue('${w['satuan'] ?? ''}'),
          xl.TextCellValue(_rupiah(_num(w['estimasi_kerugian']))),
          xl.TextCellValue('${w['catatan'] ?? '-'}'),
        ];
      }),
      aligns: const [
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Left,
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Center,
        xl.HorizontalAlign.Right,
        xl.HorizontalAlign.Left,
      ],
      colWidths: const [7, 24, 16, 16, 12, 20, 28],
    );

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
