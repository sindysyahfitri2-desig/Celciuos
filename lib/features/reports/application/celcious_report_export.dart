import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:kasir_celcious_coffe/data/app_branding_store.dart';

// ============================================================
// KONSTANTA BRANDING CELCIOUS COFFEE
// ============================================================

const String kCelciousStoreName = 'CELCIOUS COFFEE';
const String kCelciousAddress =
    'Jl. Arah Kampung Satu, Mekar Sawit, Kec. Sawit Seberang, Kab. Langkat';
const String kCelciousContact =
    'Instagram : celcious.cs, Telepon : 082369273120';
const String kCelciousDefaultOwner = 'Agung Satrio';
const String kCelciousDefaultKasirSiang = 'Natasya';
const String kCelciousDefaultKasirMalam = 'Reyhan';

const List<String> kBulanIndonesia = [
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

// ============================================================
// MODEL DATA TERSTRUKTUR
// ============================================================

class CelciousShiftTransactionRow {
  const CelciousShiftTransactionRow({
    required this.no,
    required this.idPemesanan,
    required this.jam,
    required this.namaKasir,
    required this.jumlahPemesanan,
    required this.totalHarga,
    this.pesanan = '-',
    this.metodePembayaran = 'Cash',
  });

  final int no;
  final String idPemesanan;
  final String jam;
  final String namaKasir;
  final int jumlahPemesanan;
  final num totalHarga;
  final String pesanan;
  final String metodePembayaran;
}

class CelciousTransactionReportData {
  const CelciousTransactionReportData({
    this.storeName = kCelciousStoreName,
    this.address = kCelciousAddress,
    this.contactLine = kCelciousContact,
    this.reportTitle = 'LAPORAN TRANSAKSI CELCIOUS COFFEE',
    required this.periodDateText,
    required this.siangRows,
    required this.malamRows,
    required this.totalSiang,
    required this.totalMalam,
    required this.kasirSiang,
    required this.kasirMalam,
    required this.ownerName,
    required this.locationDate,
  });

  final String storeName;
  final String address;
  final String contactLine;
  final String reportTitle;
  final String periodDateText;
  final List<CelciousShiftTransactionRow> siangRows;
  final List<CelciousShiftTransactionRow> malamRows;
  final num totalSiang;
  final num totalMalam;
  final String kasirSiang;
  final String kasirMalam;
  final String ownerName;
  final String locationDate;

  num get grandTotal => totalSiang + totalMalam;
  int get totalTransaksi => siangRows.length + malamRows.length;
}

class CelciousCashDrawerShiftRow {
  const CelciousCashDrawerShiftRow({
    required this.no,
    required this.tanggal,
    required this.jam,
    required this.namaKasir,
    required this.keterangan,
    required this.jenis,
    required this.nominalSigned,
    required this.nominalText,
    this.pemasukan,
    this.pengeluaran,
    this.saldo = 0,
  });

  final int no;
  final String tanggal;
  final String jam;
  final String namaKasir;
  final String keterangan;
  final String jenis;
  final num nominalSigned;
  final String nominalText;
  final num? pemasukan;
  final num? pengeluaran;
  final num saldo;
}

class CelciousCashDrawerReportData {
  const CelciousCashDrawerReportData({
    this.storeName = kCelciousStoreName,
    this.address = kCelciousAddress,
    this.contactLine = kCelciousContact,
    this.reportTitle = 'LAPORAN KAS LACI CELCIOUS COFFEE',
    required this.periodDateText,
    required this.openingCash,
    required this.currentCash,
    required this.siangRows,
    required this.malamRows,
    required this.totalSiang,
    required this.totalMalam,
    required this.kasirSiang,
    required this.kasirMalam,
    required this.ownerName,
    required this.locationDate,
    this.allRows = const [],
    this.totalPemasukan = 0,
    this.totalPengeluaran = 0,
    this.saldoAkhir = 0,
  });

  final String storeName;
  final String address;
  final String contactLine;
  final String reportTitle;
  final String periodDateText;
  final num openingCash;
  final num currentCash;
  final List<CelciousCashDrawerShiftRow> siangRows;
  final List<CelciousCashDrawerShiftRow> malamRows;
  final num totalSiang;
  final num totalMalam;
  final String kasirSiang;
  final String kasirMalam;
  final String ownerName;
  final String locationDate;
  final List<CelciousCashDrawerShiftRow> allRows;
  final num totalPemasukan;
  final num totalPengeluaran;
  final num saldoAkhir;

  num get selisihKas => currentCash - saldoAkhir;
}

// ============================================================
// HELPER FORMAT & PEMBAGIAN SHIFT
// ============================================================

class CelciousReportExport {
  CelciousReportExport._();

  static String formatTanggalIndonesia(DateTime dt) =>
      '${dt.day} ${kBulanIndonesia[dt.month - 1]} ${dt.year}';

  static String formatAngka(num v) {
    final neg = v < 0;
    final s = v.abs().round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${neg ? '-' : ''}$buf';
  }

  static String formatRupiah(num v) {
    if (v < 0) return '-Rp. ${formatAngka(v.abs())}';
    return 'Rp. ${formatAngka(v)}';
  }

  static num parseNominal(String? raw) {
    final clean = (raw ?? '0').trim();
    if (clean.isEmpty) return 0;
    final isNeg = clean.startsWith('-');
    final digits = clean.replaceAll(RegExp(r'[^0-9]'), '');
    final value = num.tryParse(digits) ?? 0;
    return isNeg ? -value : value;
  }

  static int? extractHour(String? jam, String? tanggal) {
    final j = (jam ?? '').trim();
    final jamMatch = RegExp(r'^(\d{1,2})[:.](\d{2})').firstMatch(j);
    if (jamMatch != null) return int.tryParse(jamMatch.group(1)!);

    final t = (tanggal ?? '').trim();
    final parsed = DateTime.tryParse(t)?.toLocal();
    if (parsed != null) return parsed.hour;

    final tailMatch = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(t);
    if (tailMatch != null) return int.tryParse(tailMatch.group(1)!);
    return null;
  }

  static bool isShiftMalam({String? jam, String? tanggal}) {
    final hour = extractHour(jam, tanggal);
    if (hour == null) return false;
    // Sift Pagi (Shift 1): 11:00 - 17:00 (< 18:00 masuk shift 1 agar tidak hilang)
    // Sift Malam (Shift 2): 18:00 - 00:00 (dan dini hari < 06:00 masuk malam)
    return hour >= 18 || hour < 6;
  }

  static String resolveOwnerName(String? raw) {
    final clean = (raw ?? '').trim();
    if (clean.isEmpty || clean.toLowerCase() == 'owner') {
      return kCelciousDefaultOwner;
    }
    return clean;
  }

  static String resolveCashierName(
    Iterable<String> names, {
    String? explicit,
    required String fallback,
  }) {
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit.trim();
    }
    final unique = <String>{};
    for (final raw in names) {
      final n = raw.trim();
      if (n.isNotEmpty && n.toLowerCase() != 'kasir' && n != '-') {
        unique.add(n);
      }
    }
    if (unique.isNotEmpty) return unique.join(', ');
    for (final raw in names) {
      final n = raw.trim();
      if (n.isNotEmpty && n != '-') return n;
    }
    return fallback;
  }

  /// Memuat bytes logo toko (prioritas: logo pengaturan -> file lokal -> asset default).
  static Future<Uint8List?> loadBrandLogoBytes() async {
    final mem = AppBrandingStore.logoBytes.value;
    if (mem != null && mem.isNotEmpty) return mem;

    if (!kIsWeb) {
      final path = AppBrandingStore.logoPath.value;
      if (path != null && path.trim().isNotEmpty) {
        try {
          final file = File(path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            if (bytes.isNotEmpty) return bytes;
          }
        } catch (_) {}
      }
    }

    try {
      final data = await rootBundle.load('assets/images/Logo.jpeg');
      final bytes = data.buffer.asUint8List();
      if (bytes.isNotEmpty) return bytes;
    } catch (_) {}

    return null;
  }

  /// Membangun data laporan transaksi per shift dari list baris `ReportService` / `LaporanPage`.
  static CelciousTransactionReportData buildTransactionDataFromMaps({
    required List<Map<String, String>> rows,
    required String periodDateText,
    String? ownerName,
    String? kasirSiangOverride,
    String? kasirMalamOverride,
    String reportTitle = 'LAPORAN TRANSAKSI CELCIOUS COFFEE',
  }) {
    final siang = <CelciousShiftTransactionRow>[];
    final malam = <CelciousShiftTransactionRow>[];

    for (final r in rows) {
      final id = (r['id'] ?? '-').trim();
      final rawJam = (r['jam'] ?? '').trim();
      final rawTanggal = (r['tanggal'] ?? '').trim();
      final jam = (rawJam.isNotEmpty && rawJam != '--:--') ? rawJam : '-';
      final kasir = (r['kasir'] ?? 'Kasir').trim();
      final qty = int.tryParse((r['jumlah'] ?? '1').trim()) ?? 1;
      final total = parseNominal(r['total']);
      final pesananRaw = (r['pesanan'] ?? '').trim();
      final pesanan = pesananRaw.isEmpty ? '-' : pesananRaw;
      final metodeRaw = (r['pembayaran'] ?? '').trim();
      final metode =
          (metodeRaw.isEmpty || metodeRaw == '-') ? 'Cash' : metodeRaw;

      if (isShiftMalam(jam: jam, tanggal: rawTanggal)) {
        malam.add(
          CelciousShiftTransactionRow(
            no: malam.length + 1,
            idPemesanan: id.isEmpty ? '-' : id,
            jam: jam,
            namaKasir: kasir.isEmpty ? 'Kasir' : kasir,
            jumlahPemesanan: qty <= 0 ? 1 : qty,
            totalHarga: total,
            pesanan: pesanan,
            metodePembayaran: metode,
          ),
        );
      } else {
        siang.add(
          CelciousShiftTransactionRow(
            no: siang.length + 1,
            idPemesanan: id.isEmpty ? '-' : id,
            jam: jam,
            namaKasir: kasir.isEmpty ? 'Kasir' : kasir,
            jumlahPemesanan: qty <= 0 ? 1 : qty,
            totalHarga: total,
            pesanan: pesanan,
            metodePembayaran: metode,
          ),
        );
      }
    }

    final totalSiang = siang.fold<num>(0, (s, e) => s + e.totalHarga);
    final totalMalam = malam.fold<num>(0, (s, e) => s + e.totalHarga);

    return CelciousTransactionReportData(
      reportTitle: reportTitle,
      periodDateText: periodDateText,
      siangRows: siang,
      malamRows: malam,
      totalSiang: totalSiang,
      totalMalam: totalMalam,
      kasirSiang: resolveCashierName(
        siang.map((e) => e.namaKasir),
        explicit: kasirSiangOverride,
        fallback: kCelciousDefaultKasirSiang,
      ),
      kasirMalam: resolveCashierName(
        malam.map((e) => e.namaKasir),
        explicit: kasirMalamOverride,
        fallback: kCelciousDefaultKasirMalam,
      ),
      ownerName: resolveOwnerName(ownerName),
      locationDate: 'Langkat, $periodDateText',
    );
  }

  /// Membangun data laporan kas laci per shift dari list baris `LaporanPage`.
  static CelciousCashDrawerReportData buildCashDrawerDataFromMaps({
    required List<Map<String, String>> rows,
    required String periodDateText,
    required num openingCash,
    required num currentCash,
    String? ownerName,
  }) {
    final siang = <CelciousCashDrawerShiftRow>[];
    final malam = <CelciousCashDrawerShiftRow>[];
    final allRows = <CelciousCashDrawerShiftRow>[];

    String formatDateShort(String? raw) {
      if (raw == null || raw.trim().isEmpty) return '-';
      final dt = DateTime.tryParse(raw)?.toLocal();
      if (dt == null) return raw.trim();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    num runningSaldo = openingCash;
    num totalPemasukan = 0;
    num totalPengeluaran = 0;
    bool skippedInitialOpening = false;

    for (final r in rows) {
      final rawTanggal = r['tanggal'] ?? '';
      final rawJam = (r['jam'] ?? '').trim();
      final jam = (rawJam.isNotEmpty && rawJam != '--:--') ? rawJam : '-';
      final kasir = (r['kasir'] ?? 'Kasir').trim();
      final ket = (r['keterangan'] ?? '-').trim();
      final jenis = (r['jenis'] ?? 'masuk').trim().toLowerCase();
      final rawNom = (r['nominal'] ?? '0').trim();
      final absNom = parseNominal(rawNom).abs();

      // Modal awal sudah tampil di header "Modal Awal : Rp. ...", jadi lewati 1 baris
      // "Kas awal shift" pertama yang nilainya sama agar saldo berjalan akurat 100%.
      if (!skippedInitialOpening &&
          openingCash > 0 &&
          ket.toLowerCase() == 'kas awal shift' &&
          (absNom - openingCash).abs() < 0.01) {
        skippedInitialOpening = true;
        continue;
      }

      final signed = jenis == 'keluar' ? -absNom : absNom;
      final prefix = jenis == 'keluar' ? '-Rp. ' : '+Rp. ';
      final nominalText = '$prefix${formatAngka(absNom)}';
      final num? masukVal = jenis == 'keluar' ? null : absNom;
      final num? keluarVal = jenis == 'keluar' ? absNom : null;

      if (masukVal != null) totalPemasukan += masukVal;
      if (keluarVal != null) totalPengeluaran += keluarVal;
      runningSaldo = runningSaldo + (masukVal ?? 0) - (keluarVal ?? 0);

      final itemAll = CelciousCashDrawerShiftRow(
        no: allRows.length + 1,
        tanggal: formatDateShort(rawTanggal),
        jam: jam,
        namaKasir: kasir.isEmpty ? 'Kasir' : kasir,
        keterangan: ket.isEmpty ? '-' : ket,
        jenis: jenis,
        nominalSigned: signed,
        nominalText: nominalText,
        pemasukan: masukVal,
        pengeluaran: keluarVal,
        saldo: runningSaldo,
      );
      allRows.add(itemAll);

      if (isShiftMalam(jam: jam, tanggal: rawTanggal)) {
        malam.add(
          CelciousCashDrawerShiftRow(
            no: malam.length + 1,
            tanggal: itemAll.tanggal,
            jam: jam,
            namaKasir: itemAll.namaKasir,
            keterangan: itemAll.keterangan,
            jenis: jenis,
            nominalSigned: signed,
            nominalText: nominalText,
            pemasukan: masukVal,
            pengeluaran: keluarVal,
            saldo: runningSaldo,
          ),
        );
      } else {
        siang.add(
          CelciousCashDrawerShiftRow(
            no: siang.length + 1,
            tanggal: itemAll.tanggal,
            jam: jam,
            namaKasir: itemAll.namaKasir,
            keterangan: itemAll.keterangan,
            jenis: jenis,
            nominalSigned: signed,
            nominalText: nominalText,
            pemasukan: masukVal,
            pengeluaran: keluarVal,
            saldo: runningSaldo,
          ),
        );
      }
    }

    final totalSiang = siang.fold<num>(0, (s, e) => s + e.nominalSigned);
    final totalMalam = malam.fold<num>(0, (s, e) => s + e.nominalSigned);

    return CelciousCashDrawerReportData(
      periodDateText: periodDateText,
      openingCash: openingCash,
      currentCash: currentCash,
      siangRows: siang,
      malamRows: malam,
      totalSiang: totalSiang,
      totalMalam: totalMalam,
      kasirSiang: resolveCashierName(
        siang.map((e) => e.namaKasir),
        fallback: kCelciousDefaultKasirSiang,
      ),
      kasirMalam: resolveCashierName(
        malam.map((e) => e.namaKasir),
        fallback: kCelciousDefaultKasirMalam,
      ),
      ownerName: resolveOwnerName(ownerName),
      locationDate: 'Langkat, $periodDateText',
      allRows: allRows,
      totalPemasukan: totalPemasukan,
      totalPengeluaran: totalPengeluaran,
      saldoAkhir: runningSaldo,
    );
  }

  // ============================================================
  // EXPORT EXCEL: LAPORAN TRANSAKSI / KEUANGAN
  // ============================================================

  static Uint8List buildTransactionReportExcel(
    CelciousTransactionReportData r, {
    Uint8List? logoBytes,
  }) {
    final excel = xl.Excel.createExcel();
    excel.rename('Sheet1', 'Laporan Transaksi');
    final sheet = excel['Laporan Transaksi'];

    final thinBorder = xl.Border(
      borderStyle: xl.BorderStyle.Thin,
      borderColorHex: xl.ExcelColor.fromHexString('FF4A5D70'),
    );
    final headerDivider = xl.Border(
      borderStyle: xl.BorderStyle.Medium,
      borderColorHex: xl.ExcelColor.fromHexString('FF0B2540'),
    );
    final navyHex = xl.ExcelColor.fromHexString('FF0B2540');
    final subBgHex = xl.ExcelColor.fromHexString('FFEDF4FA');

    xl.CellIndex idx(int col, int row) =>
        xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);

    void writeMerged(
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

    int writeShiftTable(
      int startRow, {
      required String shiftTitle,
      required List<CelciousShiftTransactionRow> rows,
      required num totalAmount,
    }) {
      var row = startRow;
      writeMerged(
        row++,
        0,
        6,
        shiftTitle,
        bold: true,
        size: 11,
        align: xl.HorizontalAlign.Left,
      );

      const headers = [
        'No',
        'Jam',
        'No. Struk',
        'Pesanan',
        'Jumlah Pesanan',
        'Metode Pembayaran',
        'Total Harga',
      ];
      final headerStyle = xl.CellStyle(
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
      for (var c = 0; c < headers.length; c++) {
        final cell = sheet.cell(idx(c, row));
        cell.value = xl.TextCellValue(headers[c]);
        cell.cellStyle = headerStyle;
      }
      row++;

      xl.CellStyle dataStyle(xl.HorizontalAlign align) => xl.CellStyle(
        fontSize: 10,
        horizontalAlign: align,
        verticalAlign: xl.VerticalAlign.Center,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      if (rows.isEmpty) {
        for (var i = 0; i < 6; i++) {
          for (var c = 0; c < 7; c++) {
            final cell = sheet.cell(idx(c, row));
            if (c == 6) {
              cell.value = xl.TextCellValue('Rp.');
              cell.cellStyle = dataStyle(xl.HorizontalAlign.Left);
            } else {
              cell.value = xl.TextCellValue('');
              cell.cellStyle = dataStyle(xl.HorizontalAlign.Center);
            }
          }
          row++;
        }
      } else {
        for (final item in rows) {
          sheet.cell(idx(0, row))
            ..value = xl.IntCellValue(item.no)
            ..cellStyle = dataStyle(xl.HorizontalAlign.Center);
          sheet.cell(idx(1, row))
            ..value = xl.TextCellValue(item.jam)
            ..cellStyle = dataStyle(xl.HorizontalAlign.Center);
          sheet.cell(idx(2, row))
            ..value = xl.TextCellValue(item.idPemesanan)
            ..cellStyle = dataStyle(xl.HorizontalAlign.Center);
          sheet.cell(idx(3, row))
            ..value = xl.TextCellValue(item.pesanan)
            ..cellStyle = dataStyle(xl.HorizontalAlign.Left);
          sheet.cell(idx(4, row))
            ..value = xl.IntCellValue(item.jumlahPemesanan)
            ..cellStyle = dataStyle(xl.HorizontalAlign.Center);
          sheet.cell(idx(5, row))
            ..value = xl.TextCellValue(item.metodePembayaran)
            ..cellStyle = dataStyle(xl.HorizontalAlign.Center);
          sheet.cell(idx(6, row))
            ..value = xl.TextCellValue(formatRupiah(item.totalHarga))
            ..cellStyle = dataStyle(xl.HorizontalAlign.Right);
          row++;
        }
      }

      // Baris Total
      writeMerged(
        row,
        0,
        5,
        'Total',
        bold: true,
        size: 10,
        align: xl.HorizontalAlign.Center,
        bg: subBgHex,
        bordered: true,
      );
      final totalCell = sheet.cell(idx(6, row));
      final emptyZero = rows.isEmpty && totalAmount == 0;
      totalCell.value = xl.TextCellValue(
        emptyZero ? 'Rp.' : formatRupiah(totalAmount),
      );
      totalCell.cellStyle = xl.CellStyle(
        bold: true,
        fontSize: 10,
        horizontalAlign:
            emptyZero ? xl.HorizontalAlign.Left : xl.HorizontalAlign.Right,
        verticalAlign: xl.VerticalAlign.Center,
        backgroundColorHex: subBgHex,
        fontColorHex: navyHex,
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );
      row++;
      return row;
    }

    var row = 0;
    // Kop Surat (logo akan ditanam di kiri atas kolom A baris 1-3)
    writeMerged(row++, 0, 6, r.storeName, bold: true, size: 15);
    writeMerged(row++, 0, 6, r.address, size: 10);
    writeMerged(
      row++,
      0,
      6,
      r.contactLine,
      size: 10,
      bottomBorder: headerDivider,
    );
    row++;

    // Judul & Periode
    writeMerged(row++, 0, 6, r.reportTitle, bold: true, size: 13);
    writeMerged(row++, 0, 6, 'Periode ${r.periodDateText}', bold: true, size: 11);
    row++;

    // 1. Sift Pagi
    row = writeShiftTable(
      row,
      shiftTitle: '1. Sift Pagi ( Pukul 11:00 - 17:00 ) : ${r.kasirSiang}',
      rows: r.siangRows,
      totalAmount: r.totalSiang,
    );
    row++;

    // 2. Sift Malam
    row = writeShiftTable(
      row,
      shiftTitle: '2. Sift Malam ( Pukul 18:00 - 00:00 ) : ${r.kasirMalam}',
      rows: r.malamRows,
      totalAmount: r.totalMalam,
    );
    row += 2;

    // Tanda Tangan
    writeMerged(
      row,
      0,
      2,
      'Mengetahui :',
      size: 10,
      align: xl.HorizontalAlign.Left,
    );
    writeMerged(
      row,
      4,
      6,
      r.locationDate,
      size: 10,
      align: xl.HorizontalAlign.Center,
    );
    row += 4;

    writeMerged(row, 0, 2, '(${r.ownerName})', bold: true, size: 10);
    writeMerged(row, 3, 4, '(${r.kasirSiang})', bold: true, size: 10);
    writeMerged(row, 5, 6, '(${r.kasirMalam})', bold: true, size: 10);
    row++;

    writeMerged(row, 0, 2, 'Owner', size: 10);
    writeMerged(row, 3, 4, 'Kasir Pagi', size: 10);
    writeMerged(row, 5, 6, 'Kasir Malam', size: 10);

    sheet.setRowHeight(0, 24);
    sheet.setRowHeight(1, 18);
    sheet.setRowHeight(2, 18);
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 10);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 30);
    sheet.setColumnWidth(4, 16);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 20);

    final rawBytes = excel.encode();
    if (rawBytes == null) throw Exception('File Excel gagal dibuat.');
    final baseBytes = Uint8List.fromList(rawBytes);

    if (logoBytes != null && logoBytes.isNotEmpty) {
      return _embedLogoIntoXlsx(baseBytes, logoBytes);
    }
    return baseBytes;
  }

  // ============================================================
  // EXPORT EXCEL: LAPORAN KAS LACI
  // ============================================================

  static Uint8List buildCashDrawerReportExcel(
    CelciousCashDrawerReportData r, {
    Uint8List? logoBytes,
  }) {
    final excel = xl.Excel.createExcel();
    excel.rename('Sheet1', 'Laporan Kas Laci');
    final sheet = excel['Laporan Kas Laci'];

    final thinBorder = xl.Border(
      borderStyle: xl.BorderStyle.Thin,
      borderColorHex: xl.ExcelColor.fromHexString('FF4A5D70'),
    );
    final headerDivider = xl.Border(
      borderStyle: xl.BorderStyle.Medium,
      borderColorHex: xl.ExcelColor.fromHexString('FF0B2540'),
    );
    final navyHex = xl.ExcelColor.fromHexString('FF0B2540');
    final subBgHex = xl.ExcelColor.fromHexString('FFEDF4FA');

    xl.CellIndex idx(int col, int row) =>
        xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);

    void writeMerged(
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

    var row = 0;
    // Kop Surat (7 kolom: 0..6)
    writeMerged(row++, 0, 6, r.storeName, bold: true, size: 15);
    writeMerged(row++, 0, 6, r.address, size: 10);
    writeMerged(
      row++,
      0,
      6,
      r.contactLine,
      size: 10,
      bottomBorder: headerDivider,
    );
    row++;

    // Judul & Periode
    writeMerged(row++, 0, 6, r.reportTitle, bold: true, size: 13);
    writeMerged(row++, 0, 6, 'Periode ${r.periodDateText}', bold: true, size: 11);
    row++;

    // Modal Awal
    writeMerged(
      row++,
      0,
      6,
      'Modal Awal : ${formatRupiah(r.openingCash)}',
      bold: true,
      size: 11,
      align: xl.HorizontalAlign.Left,
    );

    const headers = [
      'No',
      'Waktu',
      'Nama Kasir',
      'Keterangan',
      'Pemasukan',
      'Pengeluaran',
      'Saldo',
    ];
    final headerStyle = xl.CellStyle(
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
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(idx(c, row));
      cell.value = xl.TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }
    row++;

    xl.CellStyle dataStyle(xl.HorizontalAlign align, {bool bold = false, xl.ExcelColor? bg}) =>
        xl.CellStyle(
          bold: bold,
          fontSize: 10,
          horizontalAlign: align,
          verticalAlign: xl.VerticalAlign.Center,
          backgroundColorHex: bg ?? xl.ExcelColor.none,
          fontColorHex: navyHex,
          leftBorder: thinBorder,
          rightBorder: thinBorder,
          topBorder: thinBorder,
          bottomBorder: thinBorder,
        );

    final kasRows = r.allRows;
    if (kasRows.isEmpty) {
      for (var i = 0; i < 4; i++) {
        for (var c = 0; c < 7; c++) {
          final cell = sheet.cell(idx(c, row));
          if (c >= 4) {
            cell.value = xl.TextCellValue('Rp.');
            cell.cellStyle = dataStyle(xl.HorizontalAlign.Left);
          } else {
            cell.value = xl.TextCellValue('');
            cell.cellStyle = dataStyle(xl.HorizontalAlign.Center);
          }
        }
        row++;
      }
    } else {
      for (final item in kasRows) {
        sheet.cell(idx(0, row))
          ..value = xl.IntCellValue(item.no)
          ..cellStyle = dataStyle(xl.HorizontalAlign.Center);
        sheet.cell(idx(1, row))
          ..value = xl.TextCellValue('${item.tanggal} ${item.jam}'.trim())
          ..cellStyle = dataStyle(xl.HorizontalAlign.Center);
        sheet.cell(idx(2, row))
          ..value = xl.TextCellValue(item.namaKasir)
          ..cellStyle = dataStyle(xl.HorizontalAlign.Left);
        sheet.cell(idx(3, row))
          ..value = xl.TextCellValue(item.keterangan)
          ..cellStyle = dataStyle(xl.HorizontalAlign.Left);
        sheet.cell(idx(4, row))
          ..value = xl.TextCellValue(
            item.pemasukan != null ? formatRupiah(item.pemasukan!) : '-',
          )
          ..cellStyle = dataStyle(xl.HorizontalAlign.Right);
        sheet.cell(idx(5, row))
          ..value = xl.TextCellValue(
            item.pengeluaran != null ? formatRupiah(item.pengeluaran!) : '-',
          )
          ..cellStyle = dataStyle(xl.HorizontalAlign.Right);
        sheet.cell(idx(6, row))
          ..value = xl.TextCellValue(formatRupiah(item.saldo))
          ..cellStyle = dataStyle(xl.HorizontalAlign.Right, bold: true);
        row++;
      }
    }

    // Baris Total
    writeMerged(
      row,
      0,
      3,
      'Total',
      bold: true,
      size: 10,
      align: xl.HorizontalAlign.Center,
      bg: subBgHex,
      bordered: true,
    );
    sheet.cell(idx(4, row))
      ..value = xl.TextCellValue(formatRupiah(r.totalPemasukan))
      ..cellStyle = dataStyle(xl.HorizontalAlign.Right, bold: true, bg: subBgHex);
    sheet.cell(idx(5, row))
      ..value = xl.TextCellValue(formatRupiah(r.totalPengeluaran))
      ..cellStyle = dataStyle(xl.HorizontalAlign.Right, bold: true, bg: subBgHex);
    sheet.cell(idx(6, row))
      ..value = xl.TextCellValue(formatRupiah(r.saldoAkhir))
      ..cellStyle = dataStyle(xl.HorizontalAlign.Right, bold: true, bg: subBgHex);
    row += 2;

    // Uang Kas Di Laci & Selisih Kas
    writeMerged(
      row++,
      0,
      6,
      'Uang Kas Di Laci : ${formatRupiah(r.currentCash)}',
      bold: true,
      size: 10,
      align: xl.HorizontalAlign.Left,
    );
    final selisih = r.selisihKas;
    final selisihText = selisih == 0
        ? 'Rp. 0 (Balance / Tepat)'
        : '${selisih > 0 ? '+ ' : ''}${formatRupiah(selisih)}';
    writeMerged(
      row++,
      0,
      6,
      'Selisih Kas : $selisihText',
      bold: true,
      size: 10,
      align: xl.HorizontalAlign.Left,
    );
    row += 2;

    // Tanda Tangan
    writeMerged(
      row,
      0,
      2,
      'Mengetahui :',
      size: 10,
      align: xl.HorizontalAlign.Left,
    );
    writeMerged(
      row,
      4,
      6,
      r.locationDate,
      size: 10,
      align: xl.HorizontalAlign.Center,
    );
    row += 4;

    writeMerged(row, 0, 2, '(${r.ownerName})', bold: true, size: 10);
    writeMerged(row, 3, 4, '(${r.kasirSiang})', bold: true, size: 10);
    writeMerged(row, 5, 6, '(${r.kasirMalam})', bold: true, size: 10);
    row++;

    writeMerged(row, 0, 2, 'Owner', size: 10);
    writeMerged(row, 3, 4, 'Kasir Pagi', size: 10);
    writeMerged(row, 5, 6, 'Kasir Malam', size: 10);

    sheet.setRowHeight(0, 24);
    sheet.setRowHeight(1, 18);
    sheet.setRowHeight(2, 18);
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 28);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 20);

    final rawBytes = excel.encode();
    if (rawBytes == null) throw Exception('File Excel gagal dibuat.');
    final baseBytes = Uint8List.fromList(rawBytes);

    if (logoBytes != null && logoBytes.isNotEmpty) {
      return _embedLogoIntoXlsx(baseBytes, logoBytes);
    }
    return baseBytes;
  }

  // ============================================================
  // EXPORT PDF: LAPORAN TRANSAKSI / KEUANGAN (DENGAN LOGO ASLI)
  // ============================================================

  static Future<Uint8List> buildTransactionReportPdf(
    CelciousTransactionReportData r, {
    Uint8List? logoBytes,
  }) async {
    final doc = pw.Document();
    final navyPdf = PdfColor.fromInt(0xFF0B2540);
    final mutedPdf = PdfColor.fromInt(0xFF64788B);
    final borderPdf = PdfColor.fromInt(0xFF8EA4B8);
    final subBgPdf = PdfColor.fromInt(0xFFEDF4FA);

    pw.Widget buildShiftPdfTable({
      required String title,
      required List<CelciousShiftTransactionRow> rows,
      required num total,
    }) {
      final tableRows = <pw.TableRow>[
        pw.TableRow(
          decoration: pw.BoxDecoration(color: navyPdf),
          children: [
            for (final h in const [
              'No',
              'Jam',
              'No. Struk',
              'Pesanan',
              'Jml',
              'Metode',
              'Total Harga',
            ])
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 6,
                ),
                child: pw.Text(
                  h,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8.2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ];

      if (rows.isEmpty) {
        for (var i = 0; i < 6; i++) {
          tableRows.add(
            pw.TableRow(
              children: [
                for (var c = 0; c < 7; c++)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 6,
                    ),
                    child: pw.Text(
                      c == 6 ? 'Rp.' : '',
                      style: pw.TextStyle(fontSize: 8.2, color: mutedPdf),
                    ),
                  ),
              ],
            ),
          );
        }
      } else {
        for (final item in rows) {
          tableRows.add(
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    '${item.no}',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8.2),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    item.jam,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8.2),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    item.idPemesanan,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8.2),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    item.pesanan,
                    style: const pw.TextStyle(fontSize: 8.2),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    '${item.jumlahPemesanan}',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8.2),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    item.metodePembayaran,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8.2),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: pw.Text(
                    formatRupiah(item.totalHarga),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 8.2),
                  ),
                ),
              ],
            ),
          );
        }
      }

      final emptyZero = rows.isEmpty && total == 0;
      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: subBgPdf),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: pw.Text(
                'Total',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8.4,
                  fontWeight: pw.FontWeight.bold,
                  color: navyPdf,
                ),
              ),
            ),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: pw.Text(
                emptyZero ? 'Rp.' : formatRupiah(total),
                textAlign:
                    emptyZero ? pw.TextAlign.left : pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 8.4,
                  fontWeight: pw.FontWeight.bold,
                  color: navyPdf,
                ),
              ),
            ),
          ],
        ),
      );

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9.8,
              fontWeight: pw.FontWeight.bold,
              color: navyPdf,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: borderPdf, width: 0.7),
            columnWidths: const {
              0: pw.FixedColumnWidth(32),
              1: pw.FixedColumnWidth(40),
              2: pw.FixedColumnWidth(68),
              3: pw.FlexColumnWidth(2.6),
              4: pw.FixedColumnWidth(34),
              5: pw.FixedColumnWidth(50),
              6: pw.FlexColumnWidth(1.5),
            },
            children: tableRows,
          ),
        ],
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          _pdfKopSurat(
            storeName: r.storeName,
            address: r.address,
            contactLine: r.contactLine,
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
                  r.reportTitle,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: navyPdf,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Periode ${r.periodDateText}',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: mutedPdf,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          buildShiftPdfTable(
            title: '1. Sift Pagi ( Pukul 11:00 - 17:00 ) : ${r.kasirSiang}',
            rows: r.siangRows,
            total: r.totalSiang,
          ),
          pw.SizedBox(height: 16),
          buildShiftPdfTable(
            title: '2. Sift Malam ( Pukul 18:00 - 00:00 ) : ${r.kasirMalam}',
            rows: r.malamRows,
            total: r.totalMalam,
          ),
          pw.SizedBox(height: 28),
          _pdfSignatureBlock(
            locationDate: r.locationDate,
            ownerName: r.ownerName,
            kasirSiang: r.kasirSiang,
            kasirMalam: r.kasirMalam,
            navyPdf: navyPdf,
            mutedPdf: mutedPdf,
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ============================================================
  // EXPORT PDF: LAPORAN KAS LACI (DENGAN LOGO ASLI)
  // ============================================================

  static Future<Uint8List> buildCashDrawerReportPdf(
    CelciousCashDrawerReportData r, {
    Uint8List? logoBytes,
  }) async {
    final doc = pw.Document();
    final navyPdf = PdfColor.fromInt(0xFF0B2540);
    final mutedPdf = PdfColor.fromInt(0xFF64788B);
    final borderPdf = PdfColor.fromInt(0xFF8EA4B8);
    final subBgPdf = PdfColor.fromInt(0xFFEDF4FA);

    final kasRows = r.allRows;
    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: navyPdf),
        children: [
          for (final h in const [
            'No',
            'Waktu',
            'Nama Kasir',
            'Keterangan',
            'Pemasukan',
            'Pengeluaran',
            'Saldo',
          ])
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: pw.Text(
                h,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 8.2,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    ];

    if (kasRows.isEmpty) {
      for (var i = 0; i < 4; i++) {
        tableRows.add(
          pw.TableRow(
            children: [
              for (var c = 0; c < 7; c++)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                  child: pw.Text(
                    c >= 4 ? 'Rp.' : '',
                    style: pw.TextStyle(fontSize: 8.2, color: mutedPdf),
                  ),
                ),
            ],
          ),
        );
      }
    } else {
      for (final item in kasRows) {
        tableRows.add(
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: pw.Text(
                  '${item.no}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8.2),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: pw.Text(
                  '${item.tanggal} ${item.jam}'.trim(),
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8.0),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: pw.Text(
                  item.namaKasir,
                  style: const pw.TextStyle(fontSize: 8.2),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: pw.Text(
                  item.keterangan,
                  style: const pw.TextStyle(fontSize: 8.2),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: pw.Text(
                  item.pemasukan != null ? formatRupiah(item.pemasukan!) : '-',
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 8.2),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: pw.Text(
                  item.pengeluaran != null ? formatRupiah(item.pengeluaran!) : '-',
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 8.2),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: pw.Text(
                  formatRupiah(item.saldo),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 8.2,
                    fontWeight: pw.FontWeight.bold,
                    color: navyPdf,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: subBgPdf),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            child: pw.Text(
              'Total',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 8.4,
                fontWeight: pw.FontWeight.bold,
                color: navyPdf,
              ),
            ),
          ),
          pw.SizedBox(),
          pw.SizedBox(),
          pw.SizedBox(),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            child: pw.Text(
              formatRupiah(r.totalPemasukan),
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 8.4,
                fontWeight: pw.FontWeight.bold,
                color: navyPdf,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            child: pw.Text(
              formatRupiah(r.totalPengeluaran),
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 8.4,
                fontWeight: pw.FontWeight.bold,
                color: navyPdf,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            child: pw.Text(
              formatRupiah(r.saldoAkhir),
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 8.4,
                fontWeight: pw.FontWeight.bold,
                color: navyPdf,
              ),
            ),
          ),
        ],
      ),
    );

    final selisih = r.selisihKas;
    final selisihText = selisih == 0
        ? 'Rp. 0 (Balance / Tepat)'
        : '${selisih > 0 ? '+ ' : ''}${formatRupiah(selisih)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          _pdfKopSurat(
            storeName: r.storeName,
            address: r.address,
            contactLine: r.contactLine,
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
                  r.reportTitle,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: navyPdf,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Periode ${r.periodDateText}',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: mutedPdf,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Modal Awal : ${formatRupiah(r.openingCash)}',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: navyPdf,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: borderPdf, width: 0.7),
            columnWidths: const {
              0: pw.FixedColumnWidth(28),
              1: pw.FixedColumnWidth(72),
              2: pw.FlexColumnWidth(1.3),
              3: pw.FlexColumnWidth(2.1),
              4: pw.FlexColumnWidth(1.4),
              5: pw.FlexColumnWidth(1.4),
              6: pw.FlexColumnWidth(1.5),
            },
            children: tableRows,
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.SizedBox(
                width: 125,
                child: pw.Text(
                  'Uang Kas Di Laci',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: navyPdf,
                  ),
                ),
              ),
              pw.Text(
                ':  ${formatRupiah(r.currentCash)}',
                style: pw.TextStyle(fontSize: 9.5, color: navyPdf),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.SizedBox(
                width: 125,
                child: pw.Text(
                  'Selisih Kas',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: navyPdf,
                  ),
                ),
              ),
              pw.Text(
                ':  $selisihText',
                style: pw.TextStyle(fontSize: 9.5, color: navyPdf),
              ),
            ],
          ),
          pw.SizedBox(height: 26),
          _pdfSignatureBlock(
            locationDate: r.locationDate,
            ownerName: r.ownerName,
            kasirSiang: r.kasirSiang,
            kasirMalam: r.kasirMalam,
            navyPdf: navyPdf,
            mutedPdf: mutedPdf,
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ============================================================
  // KOMPONEN PDF INTERNAL (KOP SURAT BERLOGO + TANDA TANGAN)
  // ============================================================

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

  static pw.Widget _pdfSignatureBlock({
    required String locationDate,
    required String ownerName,
    required String kasirSiang,
    required String kasirMalam,
    required PdfColor navyPdf,
    required PdfColor mutedPdf,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Mengetahui :',
              style: pw.TextStyle(fontSize: 9.2, color: navyPdf),
            ),
            pw.Text(
              locationDate,
              style: pw.TextStyle(fontSize: 9.2, color: navyPdf),
            ),
          ],
        ),
        pw.SizedBox(height: 44),
        pw.Row(
          children: [
            for (final sig in [
              ('($ownerName)', 'Owner'),
              ('($kasirSiang)', 'Kasir Pagi'),
              ('($kasirMalam)', 'Kasir Malam'),
            ])
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      sig.$1,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 9.2,
                        fontWeight: pw.FontWeight.bold,
                        color: navyPdf,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      sig.$2,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(fontSize: 8.5, color: mutedPdf),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // TANAM LOGO ASLI KE FILE .XLSX (OOXML DRAWING)
  // ============================================================

  static Uint8List _embedLogoIntoXlsx(
    Uint8List xlsxBytes,
    Uint8List logoBytes,
  ) {
    try {
      final isPng = logoBytes.length >= 4 &&
          logoBytes[0] == 0x89 &&
          logoBytes[1] == 0x50 &&
          logoBytes[2] == 0x4E &&
          logoBytes[3] == 0x47;
      final ext = isPng ? 'png' : 'jpeg';
      final mime = isPng ? 'image/png' : 'image/jpeg';

      final archive = ZipDecoder().decodeBytes(xlsxBytes);
      final updated = Archive();

      bool hasDrawingRels = false;

      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name;

        if (name == 'xl/drawings/drawing1.xml') {
          final drawingXml = utf8.encode(
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<xdr:wsDr '
            'xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" '
            'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            '<xdr:oneCellAnchor>'
            '<xdr:from>'
            '<xdr:col>0</xdr:col><xdr:colOff>50000</xdr:colOff>'
            '<xdr:row>0</xdr:row><xdr:rowOff>30000</xdr:rowOff>'
            '</xdr:from>'
            '<xdr:ext cx="610000" cy="610000"/>'
            '<xdr:pic>'
            '<xdr:nvPicPr>'
            '<xdr:cNvPr id="2" name="Logo Celcious Coffee"/>'
            '<xdr:cNvPicPr><a:picLocks noChangeAspect="1"/></xdr:cNvPicPr>'
            '</xdr:nvPicPr>'
            '<xdr:blipFill>'
            '<a:blip r:embed="rId1"/>'
            '<a:stretch><a:fillRect/></a:stretch>'
            '</xdr:blipFill>'
            '<xdr:spPr>'
            '<a:xfrm><a:off x="0" y="0"/><a:ext cx="610000" cy="610000"/></a:xfrm>'
            '<a:prstGeom prst="ellipse"><a:avLst/></a:prstGeom>'
            '</xdr:spPr>'
            '</xdr:pic>'
            '<xdr:clientData/>'
            '</xdr:oneCellAnchor>'
            '</xdr:wsDr>',
          );
          updated.addFile(ArchiveFile(name, drawingXml.length, drawingXml));
        } else if (name == '[Content_Types].xml') {
          var content = utf8.decode(file.content as List<int>);
          if (!content.contains('Extension="$ext"')) {
            content = content.replaceFirst(
              '</Types>',
              '<Default Extension="$ext" ContentType="$mime"/></Types>',
            );
          }
          if (!content.contains('/xl/drawings/drawing1.xml')) {
            content = content.replaceFirst(
              '</Types>',
              '<Override PartName="/xl/drawings/drawing1.xml" '
                  'ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/>'
                  '</Types>',
            );
          }
          final encoded = utf8.encode(content);
          updated.addFile(ArchiveFile(name, encoded.length, encoded));
        } else if (name == 'xl/drawings/_rels/drawing1.xml.rels') {
          hasDrawingRels = true;
          final relsXml = utf8.encode(
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" '
            'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
            'Target="../media/logo.$ext"/>'
            '</Relationships>',
          );
          updated.addFile(ArchiveFile(name, relsXml.length, relsXml));
        } else {
          final bytes = file.content as List<int>;
          updated.addFile(ArchiveFile(name, bytes.length, bytes));
        }
      }

      // Tambahkan gambar logo ke xl/media/
      updated.addFile(
        ArchiveFile('xl/media/logo.$ext', logoBytes.length, logoBytes),
      );

      // Tambahkan relasi drawing -> gambar bila belum ada
      if (!hasDrawingRels) {
        final relsXml = utf8.encode(
          '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
          'Target="../media/logo.$ext"/>'
          '</Relationships>',
        );
        updated.addFile(
          ArchiveFile(
            'xl/drawings/_rels/drawing1.xml.rels',
            relsXml.length,
            relsXml,
          ),
        );
      }

      final encodedZip = ZipEncoder().encode(updated);
      if (encodedZip == null || encodedZip.isEmpty) return xlsxBytes;
      return Uint8List.fromList(encodedZip);
    } catch (_) {
      return xlsxBytes;
    }
  }
}
