import 'package:excel/excel.dart' as xl;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';

// ============================================================
// KONSTANTA DESAIN
// ============================================================

const Color _navy = Color(0xFF0B2540);
const Color _navyBar = Color(0xFF102A45);
const Color _logoBlue = Color(0xFF39648B);
const Color _pageBg = Color(0xFFDCE9F4);
const Color _muted = Color(0xFF64788B);
const Color _tableBorder = Color(0xFF9FB0C2);
const Color _rowDivider = Color(0xFFDDE5EE);
const Color _subtotalBg = Color(0xFFF3F7FB);
const Color _netIncomeBg = Color(0xFFE9F1F9);
const Color _lightBlueBtn = Color(0xFFA8CBE9);

Future<void> _saveExportFile({
  required String name,
  required Uint8List bytes,
  required String fileExtension,
  required MimeType mimeType,
}) async {
  if (kIsWeb) {
    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: fileExtension,
      mimeType: mimeType,
    );
    return;
  }

  try {
    await FileSaver.instance.saveAs(
      name: name,
      bytes: bytes,
      fileExtension: fileExtension,
      mimeType: mimeType,
    );
  } on UnimplementedError {
    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: fileExtension,
      mimeType: mimeType,
    );
  }
}

const List<BoxShadow> _kCardShadow = [
  BoxShadow(
    color: Color(0x26082640),
    blurRadius: 14,
    offset: Offset(0, 6),
  ),
];

const List<BoxShadow> _kSoftShadow = [
  BoxShadow(
    color: Color(0x1F082640),
    blurRadius: 8,
    offset: Offset(0, 3),
  ),
];

// ============================================================
// MODEL DATA (tetap kompatibel dengan pemanggilan lama)
// ============================================================

/// Satu baris transaksi untuk laporan.
class LaporanPreviewRow {
  const LaporanPreviewRow({
    required this.tanggal,
    required this.keterangan,
    required this.metode,
    required this.nominal,
  });

  final String tanggal;
  final String keterangan;
  final String metode;
  final num nominal;
}

/// Item baris rincian pendapatan atau beban pada laporan laba rugi.
class LaporanNominalItem {
  const LaporanNominalItem({
    required this.label,
    required this.nominal,
  });

  final String label;
  final num nominal;
}

/// Data transaksi & keuangan yang ditampilkan pada pratinjau dan dokumen.
class LaporanPreviewData {
  const LaporanPreviewData({
    this.totalOmzet,
    this.totalTunai,
    this.totalNonTunai,
    this.totalTransaksi,
    this.rows = const [],
    this.pendapatanItems = const [],
    this.bebanItems = const [],
    this.pajakPersen = 0,
    this.pajakNominal,
    this.namaKasir = 'Kasir',
    this.namaOwner = 'Owner',
    this.alamatToko =
        'Jl. Arah Kampung Satu, Mekar Sawit, Kec. Sawit Seberang, '
        'Kab. Langkat, Sumatera Utara',
    this.noDokumen,
    this.sysId,
  });

  final num? totalOmzet;
  final num? totalTunai;
  final num? totalNonTunai;
  final int? totalTransaksi;

  final List<LaporanPreviewRow> rows;
  final List<LaporanNominalItem> pendapatanItems;
  final List<LaporanNominalItem> bebanItems;
  final double pajakPersen;
  final num? pajakNominal;
  final String namaKasir;
  final String namaOwner;
  final String alamatToko;
  final String? noDokumen;
  final String? sysId;
}

/// Ringkasan terhitung yang dipakai bersama untuk thumbnail, pratinjau, PDF & Excel.
class ComputedFinancialReport {
  const ComputedFinancialReport({
    required this.storeName,
    required this.address,
    required this.docNo,
    required this.shortPeriod,
    required this.fullPeriod,
    required this.reportTitle,
    required this.revenueItems,
    required this.totalRevenue,
    required this.expenseItems,
    required this.totalExpense,
    required this.profitBeforeTax,
    required this.taxPercent,
    required this.taxAmount,
    required this.netIncome,
    required this.locationDate,
    required this.cashierName,
    required this.ownerName,
    required this.sysId,
    required this.rows,
  });

  final String storeName;
  final String address;
  final String docNo;
  final String shortPeriod;
  final String fullPeriod;
  final String reportTitle;
  final List<LaporanNominalItem> revenueItems;
  final num totalRevenue;
  final List<LaporanNominalItem> expenseItems;
  final num totalExpense;
  final num profitBeforeTax;
  final double taxPercent;
  final num taxAmount;
  final num netIncome;
  final String locationDate;
  final String cashierName;
  final String ownerName;
  final String sysId;
  final List<LaporanPreviewRow> rows;
}

const List<String> _bulanPendek = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

const List<String> _bulanPanjang = [
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

String _formatAngka(num v) {
  final neg = v < 0;
  final s = v.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${neg ? '-' : ''}$buf';
}

String _rupiah(num v) => 'Rp ${_formatAngka(v)}';

String _safeFileName(String judul) {
  final s = judul
      .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return s.isEmpty ? 'Laporan_Laba_Rugi' : s;
}

ComputedFinancialReport _computeReport({
  required LaporanPreviewData? data,
  required String judul,
  required String tanggalLaporan,
}) {
  final now = DateTime.now();
  final d2 = now.day.toString().padLeft(2, '0');
  final m2 = now.month.toString().padLeft(2, '0');
  final y4 = now.year.toString();

  final rows = data?.rows ?? const <LaporanPreviewRow>[];
  final sumRows = rows.fold<num>(0, (s, r) => s + r.nominal);

  // Bangun rincian pendapatan
  final revenueItems = <LaporanNominalItem>[];
  if (data != null && data.pendapatanItems.isNotEmpty) {
    revenueItems.addAll(data.pendapatanItems);
  } else {
    final tunai = data?.totalTunai ??
        rows
            .where((r) =>
                r.metode.toLowerCase().contains('cash') ||
                r.metode.toLowerCase().contains('tunai'))
            .fold<num>(0, (s, r) => s + r.nominal);
    final nonTunai = data?.totalNonTunai ??
        rows
            .where((r) =>
                !r.metode.toLowerCase().contains('cash') &&
                !r.metode.toLowerCase().contains('tunai'))
            .fold<num>(0, (s, r) => s + r.nominal);

    if (tunai > 0 || nonTunai > 0) {
      if (tunai > 0) {
        revenueItems.add(
          LaporanNominalItem(
            label: 'Penjualan Kopi & Minuman (Tunai)',
            nominal: tunai,
          ),
        );
      }
      if (nonTunai > 0) {
        revenueItems.add(
          LaporanNominalItem(
            label: 'Penjualan Non-Tunai / QRIS',
            nominal: nonTunai,
          ),
        );
      }
    } else {
      final omzet = data?.totalOmzet ?? sumRows;
      revenueItems.addAll([
        LaporanNominalItem(
          label: 'Penjualan Kopi & Minuman',
          nominal: omzet,
        ),
        const LaporanNominalItem(
          label: 'Penjualan Makanan / Snack',
          nominal: 0,
        ),
      ]);
    }
  }

  final totalRevenue = revenueItems.fold<num>(0, (s, e) => s + e.nominal);

  // Bangun rincian beban
  final expenseItems = <LaporanNominalItem>[];
  if (data != null && data.bebanItems.isNotEmpty) {
    expenseItems.addAll(data.bebanItems);
  } else {
    expenseItems.add(
      const LaporanNominalItem(
        label: 'Beban Operasional / Perlengkapan Bar',
        nominal: 0,
      ),
    );
  }

  final totalExpense = expenseItems.fold<num>(0, (s, e) => s + e.nominal);
  final profitBeforeTax = totalRevenue - totalExpense;
  final taxPercent = data?.pajakPersen ?? 0;
  final taxAmount = data?.pajakNominal != null
      ? data!.pajakNominal!.round()
      : (profitBeforeTax > 0
            ? (profitBeforeTax * (taxPercent / 100)).round()
            : 0);
  final netIncome = profitBeforeTax - taxAmount;

  final shortPeriod =
      tanggalLaporan.trim().isEmpty
          ? '$d2 ${_bulanPendek[now.month - 1]} $y4'
          : tanggalLaporan.trim();
  final longDate = '${now.day} ${_bulanPanjang[now.month - 1]} $y4';
  final fullPeriod = tanggalLaporan.trim().isEmpty
      ? '$longDate / Tahun $y4'
      : '${tanggalLaporan.trim()} / Tahun $y4';

  final docNo = (data?.noDokumen?.trim().isNotEmpty == true)
      ? data!.noDokumen!.trim()
      : 'LK-CC/$y4/$m2/$d2';
  final sysId = (data?.sysId?.trim().isNotEmpty == true)
      ? data!.sysId!.trim()
      : 'CC-$y4$m2$d2';

  final cashierName = (data?.namaKasir.trim().isNotEmpty == true)
      ? data!.namaKasir.trim()
      : 'Kasir';
  final ownerName = (data?.namaOwner.trim().isNotEmpty == true)
      ? data!.namaOwner.trim()
      : 'Owner';

  final reportTitle = judul.trim().isEmpty ||
          judul.trim().toLowerCase() == 'laporan transaksi' ||
          judul.trim().toLowerCase() == 'laporan keuangan'
      ? 'LAPORAN LABA RUGI & KEUANGAN HARIAN'
      : judul.trim().toUpperCase();

  return ComputedFinancialReport(
    storeName: 'CELCIOUS COFFEE INDONESIA',
    address: data?.alamatToko ??
        'Jl. Arah Kampung Satu, Mekar Sawit, Kec. Sawit Seberang, '
            'Kab. Langkat, Sumatera Utara',
    docNo: docNo,
    shortPeriod: shortPeriod,
    fullPeriod: fullPeriod,
    reportTitle: reportTitle,
    revenueItems: revenueItems,
    totalRevenue: totalRevenue,
    expenseItems: expenseItems,
    totalExpense: totalExpense,
    profitBeforeTax: profitBeforeTax,
    taxPercent: taxPercent,
    taxAmount: taxAmount,
    netIncome: netIncome,
    locationDate: 'Langkat, $longDate',
    cashierName: cashierName,
    ownerName: ownerName,
    sysId: sysId,
    rows: rows,
  );
}

// ============================================================
// EXPORT PDF & EXCEL
// ============================================================

Future<Uint8List> _buildPdfBytes(ComputedFinancialReport r) async {
  final doc = pw.Document();
  final navyPdf = PdfColor.fromInt(0xFF0B2540);
  final navyBarPdf = PdfColor.fromInt(0xFF102A45);
  final mutedPdf = PdfColor.fromInt(0xFF64788B);
  final borderPdf = PdfColor.fromInt(0xFF9FB0C2);
  final rowDivPdf = PdfColor.fromInt(0xFFDDE5EE);
  final subBgPdf = PdfColor.fromInt(0xFFF3F7FB);
  final netBgPdf = PdfColor.fromInt(0xFFE9F1F9);

  pw.Widget amountRow(
    String label,
    num amount, {
    bool indent = false,
    bool bold = false,
    bool italic = false,
    bool centerLabel = false,
    bool dashZero = false,
    PdfColor? bg,
    bool strongBottom = false,
  }) {
    final amountText =
        dashZero && amount == 0 ? '-' : _formatAngka(amount);
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: bg,
        border: pw.Border(
          bottom: pw.BorderSide(
            color: strongBottom ? navyPdf : rowDivPdf,
            width: strongBottom ? 1.2 : 0.6,
          ),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Padding(
              padding: pw.EdgeInsets.fromLTRB(
                indent ? 24 : 10,
                7,
                10,
                7,
              ),
              child: pw.Text(
                label,
                textAlign:
                    centerLabel ? pw.TextAlign.center : pw.TextAlign.left,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  fontStyle:
                      italic ? pw.FontStyle.italic : pw.FontStyle.normal,
                  color: bold ? navyPdf : PdfColors.black,
                ),
              ),
            ),
          ),
          pw.Container(
            width: 130,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: rowDivPdf, width: 0.6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Rp',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: bold ? navyPdf : mutedPdf,
                  ),
                ),
                pw.Text(
                  amountText,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: bold ? navyPdf : PdfColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget sectionBar(String title) {
    return pw.Container(
      width: double.infinity,
      color: navyBarPdf,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      alignment: pw.Alignment.center,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  pw.Widget sigBox(String roleHeader, String roleSub, String name, String desc) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: rowDivPdf, width: 0.9),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              roleHeader,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: navyPdf,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              roleSub,
              style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
            ),
            pw.SizedBox(height: 36),
            pw.Container(width: 110, height: 1, color: navyPdf),
            pw.SizedBox(height: 6),
            pw.Text(
              name.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: navyPdf,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              desc,
              style: pw.TextStyle(fontSize: 8, color: mutedPdf),
            ),
          ],
        ),
      ),
    );
  }

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 48,
                height: 48,
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
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      r.storeName,
                      style: pw.TextStyle(
                        fontSize: 13.5,
                        fontWeight: pw.FontWeight.bold,
                        color: navyPdf,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      r.address,
                      style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'No. Dokumen: ${r.docNo}',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: navyPdf,
                          ),
                        ),
                        pw.Text(
                          'Periode: ${r.shortPeriod}',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: navyPdf,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: navyPdf, thickness: 1.2),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              r.reportTitle,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 12.5,
                fontWeight: pw.FontWeight.bold,
                color: navyPdf,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Periode: ${r.fullPeriod}',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: mutedPdf,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: navyPdf, thickness: 1.2),
          pw.SizedBox(height: 14),
          pw.Text(
            '1. RINCIAN LABA RUGI OPERASIONAL',
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: navyPdf,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderPdf, width: 0.9),
            ),
            child: pw.Column(
              children: [
                sectionBar('PENDAPATAN'),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: rowDivPdf, width: 0.6),
                    ),
                  ),
                  child: pw.Text(
                    'Penjualan Makanan dan Minuman',
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: navyPdf,
                    ),
                  ),
                ),
                for (final item in r.revenueItems)
                  amountRow(item.label, item.nominal, indent: true),
                amountRow(
                  'JUMLAH PENDAPATAN',
                  r.totalRevenue,
                  bold: true,
                  centerLabel: true,
                  bg: subBgPdf,
                ),
                sectionBar('BEBAN / PENGELUARAN'),
                for (final item in r.expenseItems)
                  amountRow(item.label, item.nominal, indent: true),
                amountRow(
                  'JUMLAH BEBAN',
                  r.totalExpense,
                  bold: true,
                  centerLabel: true,
                  bg: subBgPdf,
                ),
                amountRow(
                  'Laba (Rugi) Sebelum Pajak',
                  r.profitBeforeTax,
                  bold: true,
                ),
                amountRow(
                  'Pajak / PPN (${r.taxPercent.toStringAsFixed(0)}%)',
                  r.taxAmount,
                  italic: true,
                  dashZero: true,
                ),
                amountRow(
                  'LABA BERSIH SETELAH PAJAK (NET INCOME)',
                  r.netIncome,
                  bold: true,
                  bg: netBgPdf,
                  strongBottom: true,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            '* Catatan: Data keuangan di atas disusun berdasarkan pencatatan '
            'kas harian Celcious Coffee Langkat yang sah.',
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
              color: mutedPdf,
            ),
          ),
          pw.Spacer(),
          pw.Text(
            r.locationDate,
            style: pw.TextStyle(fontSize: 9, color: navyPdf),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              sigBox(
                'DIBUAT OLEH,',
                'Kasir / Staf Operasional',
                r.cashierName,
                'Staf Kasir Celcious',
              ),
              pw.SizedBox(width: 16),
              sigBox(
                'DISETUJUI & DISAHKAN,',
                'Manager / Owner',
                r.ownerName,
                'Owner / Pemilik Celcious Coffee',
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: rowDivPdf, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Dokumen Sah Internal Celcious Coffee',
                  style: pw.TextStyle(fontSize: 8, color: mutedPdf),
                ),
                pw.Text(
                  'Halaman 1 dari 1',
                  style: pw.TextStyle(fontSize: 8, color: mutedPdf),
                ),
                pw.Text(
                  'SYS-ID: ${r.sysId}',
                  style: pw.TextStyle(fontSize: 8, color: mutedPdf),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

Uint8List _encodeExcel(ComputedFinancialReport r) {
  final excel = xl.Excel.createExcel();
  excel.rename('Sheet1', 'Laporan');
  final sheet = excel['Laporan'];

  void writeMerged(int row, String text, {bool bold = false, int size = 11}) {
    final start = xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row);
    final end = xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row);
    sheet.merge(start, end);
    final cell = sheet.cell(start);
    cell.value = xl.TextCellValue(text);
    cell.cellStyle = xl.CellStyle(
      bold: bold,
      fontSize: size,
      horizontalAlign: xl.HorizontalAlign.Center,
    );
  }

  void writeLine(int row, String label, num? amount, {bool bold = false}) {
    final c0 = sheet.cell(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
    );
    final c1 = sheet.cell(
      xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
    );
    sheet.merge(
      xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
    );
    c0.value = xl.TextCellValue(label);
    c0.cellStyle = xl.CellStyle(bold: bold);
    c1.cellStyle = xl.CellStyle(bold: bold);

    final c2 = sheet.cell(
      xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
    );
    if (amount != null) {
      c2.value = xl.TextCellValue(_rupiah(amount));
      c2.cellStyle = xl.CellStyle(
        bold: bold,
        horizontalAlign: xl.HorizontalAlign.Right,
      );
    }
  }

  var row = 0;
  writeMerged(row++, r.storeName, bold: true, size: 14);
  writeMerged(row++, r.address, size: 10);
  writeMerged(row++, r.reportTitle, bold: true, size: 12);
  writeMerged(row++, 'Periode: ${r.fullPeriod}', size: 10);
  row++;

  writeLine(row++, 'PENDAPATAN', null, bold: true);
  for (final item in r.revenueItems) {
    writeLine(row++, '  ${item.label}', item.nominal);
  }
  writeLine(row++, 'JUMLAH PENDAPATAN', r.totalRevenue, bold: true);
  row++;

  writeLine(row++, 'BEBAN / PENGELUARAN', null, bold: true);
  for (final item in r.expenseItems) {
    writeLine(row++, '  ${item.label}', item.nominal);
  }
  writeLine(row++, 'JUMLAH BEBAN', r.totalExpense, bold: true);
  row++;

  writeLine(row++, 'Laba (Rugi) Sebelum Pajak', r.profitBeforeTax, bold: true);
  writeLine(
    row++,
    'Pajak / PPN (${r.taxPercent.toStringAsFixed(0)}%)',
    r.taxAmount,
  );
  writeLine(
    row++,
    'LABA BERSIH SETELAH PAJAK (NET INCOME)',
    r.netIncome,
    bold: true,
  );

  sheet.setColumnWidth(0, 32);
  sheet.setColumnWidth(1, 20);
  sheet.setColumnWidth(2, 22);

  // Sheet 2: Rincian seluruh transaksi lunas pada periode laporan
  if (r.rows.isNotEmpty) {
    final trxSheet = excel['Rincian Transaksi'];
    final headers = ['Tanggal', 'Keterangan / Order', 'Metode', 'Nominal'];
    for (var col = 0; col < headers.length; col++) {
      final cell = trxSheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = xl.TextCellValue(headers[col]);
      cell.cellStyle = xl.CellStyle(bold: true);
    }

    for (var i = 0; i < r.rows.length; i++) {
      final item = r.rows[i];
      final rowIdx = i + 1;
      trxSheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
          .value = xl.TextCellValue(item.tanggal);
      trxSheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx))
          .value = xl.TextCellValue(item.keterangan);
      trxSheet
          .cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx))
          .value = xl.TextCellValue(item.metode);
      final nomCell = trxSheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx),
      );
      nomCell.value = xl.TextCellValue(_rupiah(item.nominal));
      nomCell.cellStyle = xl.CellStyle(
        horizontalAlign: xl.HorizontalAlign.Right,
      );
    }

    trxSheet.setColumnWidth(0, 20);
    trxSheet.setColumnWidth(1, 34);
    trxSheet.setColumnWidth(2, 14);
    trxSheet.setColumnWidth(3, 18);
  }

  final bytes = excel.encode();
  if (bytes == null) throw Exception('File Excel gagal dibuat.');
  return Uint8List.fromList(bytes);
}

// ============================================================
// HALAMAN KELOLA LAPORAN
// ============================================================

class KelolaLaporanContent extends StatefulWidget {
  const KelolaLaporanContent({
    super.key,
    this.onDownload,
    this.previewData,
    this.judulLaporan = 'Laporan Laba Rugi & Keuangan Harian',
    this.tanggalLaporan = '11 November 2026',
  });

  final VoidCallback? onDownload;
  final LaporanPreviewData? previewData;
  final String judulLaporan;
  final String tanggalLaporan;

  @override
  State<KelolaLaporanContent> createState() => _KelolaLaporanContentState();
}

class _KelolaLaporanContentState extends State<KelolaLaporanContent> {
  final TextEditingController _searchController = TextEditingController();

  bool get _isMatch {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return true;
    return widget.judulLaporan.toLowerCase().contains(keyword) ||
        widget.tanggalLaporan.toLowerCase().contains(keyword) ||
        'laba rugi'.contains(keyword) ||
        'celcious'.contains(keyword);
  }

  ComputedFinancialReport get _report => _computeReport(
    data: widget.previewData,
    judul: widget.judulLaporan,
    tanggalLaporan: widget.tanggalLaporan,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LaporanDocumentPreviewPage(
          report: _report,
          judul: widget.judulLaporan,
          onExported: widget.onDownload,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return SizedBox.expand(
      child: ColoredBox(
        color: _pageBg,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isPhone = width < 600;
            final isTablet = width >= 600 && width < 1024;
            final pad = isPhone ? 16.0 : (isTablet ? 24.0 : 30.0);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                pad,
                isPhone ? 18 : 26,
                pad,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPhone)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _title(isPhone),
                        const SizedBox(height: 14),
                        _searchField(),
                      ],
                    )
                  else
                    Row(
                      children: [
                        _title(isPhone),
                        const Spacer(),
                        SizedBox(
                          width: isTablet ? 230 : 270,
                          child: _searchField(),
                        ),
                      ],
                    ),
                  SizedBox(height: isPhone ? 18 : 24),
                  if (_isMatch)
                    Align(
                      alignment: Alignment.topLeft,
                      child: _ReportDocumentCard(
                        report: report,
                        cardWidth: isPhone
                            ? 162.0
                            : isTablet
                                ? 174.0
                                : 186.0,
                        onTap: _openPreview,
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _kSoftShadow,
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            color: _muted,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Laporan tidak ditemukan.',
                            style: TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _title(bool isPhone) {
    return Text(
      'Kelola Laporan',
      style: TextStyle(
        color: _navy,
        fontSize: isPhone ? 24 : 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
        shadows: const [
          Shadow(
            color: Color(0x33082640),
            offset: Offset(1, 2),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _kSoftShadow,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 13, color: _navy),
        decoration: InputDecoration(
          hintText: 'Cari laporan...',
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9EB0C4)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _muted),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// ============================================================
// KARTU PRATINJAU DOKUMEN (sebelum diklik: desain sama dengan isi)
// ============================================================

class _ReportDocumentCard extends StatefulWidget {
  const _ReportDocumentCard({
    required this.report,
    required this.cardWidth,
    required this.onTap,
  });

  final ComputedFinancialReport report;
  final double cardWidth;
  final VoidCallback onTap;

  @override
  State<_ReportDocumentCard> createState() => _ReportDocumentCardState();
}

class _ReportDocumentCardState extends State<_ReportDocumentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        width: widget.cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? _navy.withValues(alpha: 0.35)
                : const Color(0xFFD1DEE9),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: _hovered ? 0.22 : 0.12),
              blurRadius: _hovered ? 18 : 10,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thumbnail dokumen formal (kompak, identik dengan tampilan saat diklik)
                Padding(
                  padding: const EdgeInsets.fromLTRB(7, 7, 7, 6),
                  child: AspectRatio(
                    aspectRatio: 0.72,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD9E2EC)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: IgnorePointer(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: 620,
                            child: _FinancialReportDocument(
                              report: widget.report,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Informasi singkat di bawah thumbnail
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF3FB),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(15),
                    ),
                    border: Border(
                      top: BorderSide(color: Color(0xFFCDE0F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _navy,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.report.reportTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 9.8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.report.shortPeriod,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 8.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.open_in_new_rounded,
                        color: _navy,
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// KOMPONEN DOKUMEN LAPORAN LABA RUGI (dipakai sebelum & sesudah klik)
// ============================================================

class _FinancialReportDocument extends StatelessWidget {
  const _FinancialReportDocument({required this.report});

  final ComputedFinancialReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(30, 26, 30, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --------------------------------------------------
          // KOP SURAT / HEADER PERUSAHAAN
          // --------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: _logoBlue,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: const AppBrandingLogo(
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.local_cafe_rounded,
                  fallbackIconSize: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.storeName,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      report.address,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: _muted,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'No. Dokumen: ',
                                  style: TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(text: report.docNo),
                              ],
                            ),
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: _muted,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Periode: ',
                                style: TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(text: report.shortPeriod),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Container(height: 1.6, color: _navy),
          const SizedBox(height: 14),

          // --------------------------------------------------
          // JUDUL LAPORAN
          // --------------------------------------------------
          Center(
            child: Column(
              children: [
                Text(
                  report.reportTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Periode: ${report.fullPeriod}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF334B61),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Container(height: 1.6, color: _navy),
          const SizedBox(height: 20),

          // --------------------------------------------------
          // 1. RINCIAN LABA RUGI OPERASIONAL
          // --------------------------------------------------
          const Text(
            '1. RINCIAN LABA RUGI OPERASIONAL',
            style: TextStyle(
              color: _navy,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: _tableBorder, width: 1),
            ),
            child: Column(
              children: [
                _sectionBar('PENDAPATAN'),
                _groupHeaderRow('Penjualan Makanan dan Minuman'),
                for (final item in report.revenueItems)
                  _dataRow(
                    label: item.label,
                    amount: item.nominal,
                    indented: true,
                  ),
                _dataRow(
                  label: 'JUMLAH PENDAPATAN',
                  amount: report.totalRevenue,
                  bold: true,
                  centerLabel: true,
                  background: _subtotalBg,
                ),
                _sectionBar('BEBAN / PENGELUARAN'),
                for (final item in report.expenseItems)
                  _dataRow(
                    label: item.label,
                    amount: item.nominal,
                    indented: true,
                  ),
                _dataRow(
                  label: 'JUMLAH BEBAN',
                  amount: report.totalExpense,
                  bold: true,
                  centerLabel: true,
                  background: _subtotalBg,
                ),
                _dataRow(
                  label: 'Laba (Rugi) Sebelum Pajak',
                  amount: report.profitBeforeTax,
                  bold: true,
                ),
                _dataRow(
                  label:
                      'Pajak / PPN (${report.taxPercent.toStringAsFixed(0)}%)',
                  amount: report.taxAmount,
                  italic: true,
                  dashZero: true,
                ),
                _dataRow(
                  label: 'LABA BERSIH SETELAH PAJAK (NET INCOME)',
                  amount: report.netIncome,
                  bold: true,
                  background: _netIncomeBg,
                  strongBottom: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Text(
            '* Catatan: Data keuangan di atas disusun berdasarkan pencatatan '
            'kas harian Celcious Coffee Langkat yang sah.',
            style: TextStyle(
              color: _muted,
              fontSize: 9.8,
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 44),

          // --------------------------------------------------
          // TANDA TANGAN
          // --------------------------------------------------
          Text(
            report.locationDate,
            style: const TextStyle(
              color: Color(0xFF2B4156),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _signatureBox(
                  title: 'DIBUAT OLEH,',
                  subtitle: 'Kasir / Staf Operasional',
                  name: report.cashierName,
                  roleCaption: 'Staf Kasir Celcious',
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _signatureBox(
                  title: 'DISETUJUI & DISAHKAN,',
                  subtitle: 'Manager / Owner',
                  name: report.ownerName,
                  roleCaption: 'Owner / Pemilik Celcious Coffee',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // --------------------------------------------------
          // FOOTER DOKUMEN
          // --------------------------------------------------
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _rowDivider, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Dokumen Sah Internal Celcious Coffee',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _muted, fontSize: 9.5),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Halaman 1 dari 1',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _muted, fontSize: 9.5),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'SYS-ID: ${report.sysId}',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 9.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionBar(String title) {
    return Container(
      width: double.infinity,
      color: _navyBar,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _groupHeaderRow(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _rowDivider, width: 0.9),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: _navy,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _dataRow({
    required String label,
    required num amount,
    bool indented = false,
    bool bold = false,
    bool italic = false,
    bool centerLabel = false,
    bool dashZero = false,
    Color? background,
    bool strongBottom = false,
  }) {
    final amountText = dashZero && amount == 0 ? '-' : _formatAngka(amount);

    return Container(
      decoration: BoxDecoration(
        color: background ?? Colors.white,
        border: Border(
          bottom: BorderSide(
            color: strongBottom ? _navy : _rowDivider,
            width: strongBottom ? 1.5 : 0.9,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  indented ? 28 : 12,
                  9,
                  12,
                  9,
                ),
                child: Align(
                  alignment:
                      centerLabel ? Alignment.center : Alignment.centerLeft,
                  child: Text(
                    label,
                    textAlign:
                        centerLabel ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      color: bold
                          ? _navy
                          : italic
                              ? _muted
                              : const Color(0xFF1D3247),
                      fontSize: 11,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 145,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: _rowDivider, width: 0.9),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rp',
                    style: TextStyle(
                      color: bold ? _navy : _muted,
                      fontSize: 11,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    amountText,
                    style: TextStyle(
                      color: bold ? _navy : const Color(0xFF1D3247),
                      fontSize: 11.5,
                      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signatureBox({
    required String title,
    required String subtitle,
    required String name,
    required String roleCaption,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _rowDivider, width: 1),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: 44),
          Container(width: 130, height: 1.2, color: _navy),
          const SizedBox(height: 8),
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            roleCaption,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 9.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HALAMAN PRATINJAU DOKUMEN (saat kartu laporan diklik)
// ============================================================

class LaporanDocumentPreviewPage extends StatefulWidget {
  const LaporanDocumentPreviewPage({
    super.key,
    required this.report,
    required this.judul,
    this.onExported,
  });

  final ComputedFinancialReport report;
  final String judul;
  final VoidCallback? onExported;

  @override
  State<LaporanDocumentPreviewPage> createState() =>
      _LaporanDocumentPreviewPageState();
}

class _LaporanDocumentPreviewPageState
    extends State<LaporanDocumentPreviewPage> {
  bool _exportingPdf = false;
  bool _exportingExcel = false;

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final bytes = await _buildPdfBytes(widget.report);
      await _saveExportFile(
        name: _safeFileName(widget.judul),
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      widget.onExported?.call();
      _snack('Laporan PDF berhasil diunduh.');
    } catch (e) {
      _snack('Gagal mengunduh PDF: $e', error: true);
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _exportExcel() async {
    if (_exportingExcel) return;
    setState(() => _exportingExcel = true);
    try {
      final bytes = _encodeExcel(widget.report);
      await _saveExportFile(
        name: _safeFileName(widget.judul),
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      widget.onExported?.call();
      _snack('Laporan Excel (.xlsx) berhasil diunduh.');
    } catch (e) {
      _snack('Gagal mengunduh Excel: $e', error: true);
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : _navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isPhone = screenW < 600;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 2,
        titleSpacing: 4,
        title: Text(
          widget.report.reportTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isPhone ? 13 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (isPhone) ...[
            IconButton(
              tooltip: 'Unduh PDF',
              onPressed: _exportingPdf ? null : _exportPdf,
              icon: _exportingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
            ),
            IconButton(
              tooltip: 'Unduh Excel',
              onPressed: _exportingExcel ? null : _exportExcel,
              icon: _exportingExcel
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.table_chart_rounded),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: FilledButton.icon(
                onPressed: _exportingPdf ? null : _exportPdf,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _navy,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _exportingPdf
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 17),
                label: const Text(
                  'Unduh PDF',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: FilledButton.icon(
                onPressed: _exportingExcel ? null : _exportExcel,
                style: FilledButton.styleFrom(
                  backgroundColor: _lightBlueBtn,
                  foregroundColor: _navy,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _exportingExcel
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _navy,
                        ),
                      )
                    : const Icon(Icons.table_chart_rounded, size: 17),
                label: const Text(
                  'Unduh Excel',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pad = isPhone ? 12.0 : 28.0;
          final availableW = (constraints.maxWidth - pad * 2).clamp(260.0, 740.0);

          return SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: Center(
              child: Container(
                width: availableW,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCCD9E6)),
                  boxShadow: _kCardShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: availableW < 580
                    ? FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 620,
                          child: _FinancialReportDocument(
                            report: widget.report,
                          ),
                        ),
                      )
                    : _FinancialReportDocument(report: widget.report),
              ),
            ),
          );
        },
      ),
    );
  }
}
