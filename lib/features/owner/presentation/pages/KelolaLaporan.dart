import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

// ============================================================
// KONSTANTA DESAIN
// ============================================================\


import 'package:flutter/material.dart' hide Border;
import 'package:flutter/material.dart' as m;
import 'package:excel/excel.dart';

import 'excel_saver.dart';


const Color _navy = Color(0xFF082640);
const Color _pageBg = Color(0xFFDCE9F4);
const Color _muted = Color(0xFF71869A);
const Color _xlGreen = Color(0xFF217346);
const Color _xlGreenDark = Color(0xFF185C37);
const Color _gridLine = Color(0xFFD4D4D4);
const Color _tableLine = Color(0xFF8E9AA6);

const List<BoxShadow> _kShadow = [
  BoxShadow(color: Color(0x40000000), blurRadius: 5, offset: Offset(2, 3)),
];

// ============================================================
// MODEL DATA (tetap kompatibel dengan pemanggilan lama)
// ============================================================

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

class LaporanPreviewData {
  const LaporanPreviewData({
    this.totalOmzet,
    this.totalTunai,
    this.totalNonTunai,
    this.totalTransaksi,
    this.rows = const [],
    this.namaKasir = 'Kasir',
  });

  // Dipertahankan agar pemanggilan lama tidak error.
  final num? totalOmzet;
  final num? totalTunai;
  final num? totalNonTunai;
  final int? totalTransaksi;

  final List<LaporanPreviewRow> rows;
  final String namaKasir;
}

// ============================================================
// MODEL LEMBAR KERJA
// Satu sumber data untuk PRATINJAU dan FILE .xlsx,
// sehingga isi keduanya selalu sama.
// ============================================================

class _SCell {
  const _SCell(
    this.text, {
    this.number,
    this.span = 1,
    this.bold = false,
    this.italic = false,
    this.align = TextAlign.left,
    this.fontSize = 11,
    this.color = const Color(0xFF000000),
    this.bg,
    this.border = false,
    this.wrap = false,
  });

  final String text;
  final num? number;
  final int span;
  final bool bold;
  final bool italic;
  final TextAlign align;
  final double fontSize;
  final Color color;
  final Color? bg;
  final bool border;
  final bool wrap;

  /// Isi yang tampil di formula bar.
  String get raw {
    if (number != null) {
      return number is int || number == number!.roundToDouble()
          ? number!.round().toString()
          : number.toString();
    }
    return text;
  }
}

class _SRow {
  const _SRow(this.cells, {this.height = 22});
  final List<_SCell> cells;
  final double height;
}

const int _dataCols = 5;
const List<double> _colWidths = [60, 110, 230, 160, 130];
const List<double> _extraColWidths = [90, 90, 90, 90, 90];
const List<double> _excelColChars = [8, 18, 32, 24, 20];

String _rupiah(num v) {
  final neg = v < 0;
  final s = v.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${neg ? '-' : ''}Rp $buf';
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

String _colLetter(int i) => String.fromCharCode(65 + i);

_SRow _blankRow() => const _SRow([_SCell('', span: _dataCols)]);

List<_SRow> _buildSheet({
  required LaporanPreviewData? data,
  required String judul,
  required String periode,
}) {
  final tx = data?.rows ?? const <LaporanPreviewRow>[];
  final rows = <_SRow>[];

  // --- Header laporan (rata tengah) ---
  rows.add(
    const _SRow([
      _SCell(
        'CELCIOUS COFFE',
        span: _dataCols,
        bold: true,
        fontSize: 18,
        color: _navy,
        align: TextAlign.center,
      ),
    ], height: 32),
  );
  rows.add(
    const _SRow([
      _SCell(
        'Dusun vak111 kampun, Mekar Sawit, Kec. Sawit Seberang, '
        'Kabupaten Langkat, Sumatera Utara 20852',
        span: _dataCols,
        fontSize: 10,
        align: TextAlign.center,
        wrap: true,
      ),
    ], height: 36),
  );
  rows.add(
    _SRow([
      _SCell(
        judul.toUpperCase(),
        span: _dataCols,
        bold: true,
        fontSize: 14,
        color: _navy,
        align: TextAlign.center,
      ),
    ], height: 26),
  );
  rows.add(
    _SRow([
      _SCell(
        'Periode: $periode',
        span: _dataCols,
        italic: true,
        fontSize: 10,
        align: TextAlign.center,
      ),
    ]),
  );

  // --- Header tabel ---
  const headers = [
    'No.',
    'Tanggal',
    'Keterangan',
    'Metode Pembayaran',
    'Nominal',
  ];
  rows.add(
    _SRow([
      for (final h in headers)
        _SCell(
          h,
          bold: true,
          color: Colors.white,
          bg: _navy,
          align: TextAlign.center,
          border: true,
        ),
    ], height: 25),
  );

  // --- Data transaksi ---
  if (tx.isEmpty) {
    rows.add(
      const _SRow([
        _SCell('1', number: 1, align: TextAlign.center, border: true),
        _SCell('Belum ada transaksi', span: 3, border: true),
        _SCell('-', align: TextAlign.right, border: true),
      ]),
    );
  } else {
    for (var i = 0; i < tx.length; i++) {
      final r = tx[i];
      rows.add(
        _SRow([
          _SCell(
            '${i + 1}',
            number: i + 1,
            align: TextAlign.center,
            border: true,
          ),
          _SCell(r.tanggal, border: true),
          _SCell(r.keterangan, border: true),
          _SCell(r.metode, border: true),
          _SCell(
            _rupiah(r.nominal),
            number: r.nominal,
            align: TextAlign.right,
            border: true,
          ),
        ]),
      );
    }
  }

  // --- Tanda tangan kasir ---
  rows
    ..add(_blankRow())
    ..add(_blankRow())
    ..add(_blankRow());

  final now = DateTime.now();
  final tgl =
      '${now.day.toString().padLeft(2, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-${now.year}';

  _SRow sig(_SCell c) => _SRow([
    const _SCell(''),
    const _SCell(''),
    const _SCell(''),
    c,
  ]);

  rows
    ..add(sig(_SCell('Langkat, $tgl', span: 2, align: TextAlign.center)))
    ..add(sig(const _SCell('Kasir,', span: 2, align: TextAlign.center)))
    ..add(sig(const _SCell('', span: 2)))
    ..add(
      sig(
        const _SCell(
          'Tanda tangan digital',
          span: 2,
          italic: true,
          color: Color(0xFF239653),
          align: TextAlign.center,
        ),
      ),
    )
    ..add(sig(const _SCell('', span: 2)))
    ..add(
      sig(
        _SCell(
          '/${data?.namaKasir ?? 'Kasir'}/',
          span: 2,
          bold: true,
          align: TextAlign.center,
        ),
      ),
    );

  return rows;
}

// ============================================================
// EXPORT .XLSX ASLI
// ============================================================

Uint8List _encodeExcel(List<_SRow> rows) {
  final excel = xl.Excel.createExcel();
  excel.rename('Sheet1', 'Laporan');
  final sheet = excel['Laporan'];

  xl.Border thin() => xl.Border(
    borderStyle: xl.BorderStyle.Thin,
    borderColorHex: xl.ExcelColor.fromHexString(_hex(_tableLine)),
  );

  xl.HorizontalAlign hAlign(TextAlign a) => switch (a) {
    TextAlign.center => xl.HorizontalAlign.Center,
    TextAlign.right => xl.HorizontalAlign.Right,
    _ => xl.HorizontalAlign.Left,
  };

  for (var r = 0; r < rows.length; r++) {
    final row = rows[r];
    var col = 0;

    for (final c in row.cells) {
      final start = xl.CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: r,
      );

      if (c.span > 1) {
        sheet.merge(
          start,
          xl.CellIndex.indexByColumnRow(
            columnIndex: col + c.span - 1,
            rowIndex: r,
          ),
        );
      }

      final cell = sheet.cell(start);

      if (c.number != null) {
        cell.value = c.number is int
            ? xl.IntCellValue(c.number! as int)
            : xl.DoubleCellValue(c.number!.toDouble());
      } else if (c.text.isNotEmpty) {
        cell.value = xl.TextCellValue(c.text);
      }

      cell.cellStyle = xl.CellStyle(
        bold: c.bold,
        italic: c.italic,
        fontSize: c.fontSize.round(),
        fontColorHex: xl.ExcelColor.fromHexString(_hex(c.color)),
        backgroundColorHex: c.bg != null
            ? xl.ExcelColor.fromHexString(_hex(c.bg!))
            : xl.ExcelColor.none,
        horizontalAlign: hAlign(c.align),
        verticalAlign: xl.VerticalAlign.Center,
        textWrapping: c.wrap ? xl.TextWrapping.WrapText : null,
        leftBorder: c.border ? thin() : null,
        rightBorder: c.border ? thin() : null,
        topBorder: c.border ? thin() : null,
        bottomBorder: c.border ? thin() : null,
      );

      col += c.span;
    }

    if (row.height != 22) sheet.setRowHeight(r, row.height * 0.75);
  }

  for (var i = 0; i < _excelColChars.length; i++) {
    sheet.setColumnWidth(i, _excelColChars[i]);
  }

  final bytes = excel.encode();
  if (bytes == null) throw Exception('File Excel gagal dibuat.');
  return Uint8List.fromList(bytes);
}

String _safeFileName(String judul) {
  final s = judul
      .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return s.isEmpty ? 'Laporan_Transaksi' : s;
}

// ============================================================
// HALAMAN KELOLA LAPORAN
// ============================================================

class KelolaLaporanContent extends StatefulWidget {
  const KelolaLaporanContent({
    super.key,
    this.onDownload,
    this.previewData,
    this.judulLaporan = 'Laporan Keuangan',
    this.tanggalLaporan = '30 Oktober 2026',
  });

  /// Dipanggil setelah file Excel berhasil diekspor (opsional).
  final VoidCallback? onDownload;

  /// Data transaksi asli dari sistem.
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
        widget.tanggalLaporan.toLowerCase().contains(keyword);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPreview() {
    final rows = _buildSheet(
      data: widget.previewData,
      judul: widget.judulLaporan,
      periode: widget.tanggalLaporan,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LaporanExcelPreviewPage(
          rows: rows,
          judul: widget.judulLaporan,
          onExported: widget.onDownload,
        ),
  Uint8List _createExcelBytes() {
    final reportData = widget.previewData;
    final rows = reportData?.rows ?? const <LaporanPreviewRow>[];

    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Laporan') {
      excel.rename(defaultSheet, 'Laporan');
    }
    final sheet = excel['Laporan'];

    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 36);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 18);

    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));
    final brandCell = sheet.cell(CellIndex.indexByString('A1'));
    brandCell.value = TextCellValue('CELCIOUS COFFE');
    brandCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 18,
      fontColorHex: ExcelColor.fromHexString('#082640'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('D2'));
    final addressCell = sheet.cell(CellIndex.indexByString('A2'));
    addressCell.value = TextCellValue(
      'Dusun vak111 kampun, Mekar Sawit, Kec. Sawit Seberang, Kabupaten Langkat, Sumatera Utara 20852',
    );
    addressCell.cellStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    sheet.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('D3'));
    final titleCell = sheet.cell(CellIndex.indexByString('A3'));
    titleCell.value = TextCellValue(widget.judulLaporan);
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#082640'),
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.merge(CellIndex.indexByString('A4'), CellIndex.indexByString('D4'));
    final dateCell = sheet.cell(CellIndex.indexByString('A4'));
    dateCell.value = TextCellValue(widget.tanggalLaporan);
    dateCell.cellStyle = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#6B7785'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final headers = ['Tanggal', 'Keterangan', 'Metode', 'Nominal'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#082640'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }

    var rowIndex = 6;
    for (final row in rows) {
      final values = [
        row.tanggal,
        row.keterangan,
        row.metode,
        row.nominal.toString(),
      ];
      for (var i = 0; i < values.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
        );
        cell.value = TextCellValue(values[i]);
        cell.cellStyle = CellStyle(
          fontSize: 10,
          fontColorHex: ExcelColor.fromHexString('#082640'),
          horizontalAlign:
              i == 3 ? HorizontalAlign.Right : HorizontalAlign.Left,
          verticalAlign: VerticalAlign.Center,
        );
      }
      rowIndex++;
    }

    return Uint8List.fromList(excel.encode()!);
  }

  String get _safeFileName {
    final safe = widget.judulLaporan
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return safe.isEmpty ? 'laporan_transaksi' : safe;
  }

  void _snack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _downloadExcel() async {
    try {
      final saver = ExcelSaver();
      await saver.saveExcel(_safeFileName, _createExcelBytes());
      _snack('Laporan Excel berhasil disiapkan.');
    } catch (e) {
      _snack('Gagal mengunduh laporan Excel: $e');
    }
  }

  Future<void> _openExcelPreview() async {
    try {
      final saver = ExcelSaver();
      await saver.saveExcel(_safeFileName, _createExcelBytes());
      _snack('File Excel berhasil dibuka / diunduh.');
    } catch (e) {
      _snack('Gagal membuka pratinjau Excel: $e');
    }
  }

  void _openPreview() {
    final data = widget.previewData;
    if (data == null || data.rows.isEmpty) {
      _snack('Belum ada data laporan untuk ditampilkan.');
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => _ReportPreviewDialog(
        title: widget.judulLaporan,
        tanggal: widget.tanggalLaporan,
        data: data,
        onDownload: () {
          Navigator.of(dialogContext).pop();
          _downloadExcel();
        },
        onOpenFile: () {
          Navigator.of(dialogContext).pop();
          _openExcelPreview();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _pageBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 760;

          final content = Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 28,
              isMobile ? 22 : 30,
              isMobile ? 16 : 28,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title(),
                      const SizedBox(height: 16),
                      _searchField(),
                    ],
                  )
                else
                  Row(
                    children: [
                      _title(),
                      const Spacer(),
                      SizedBox(width: 250, child: _searchField()),
                    ],
                  ),
                SizedBox(height: isMobile ? 30 : 54),
                if (_isMatch)
                  Align(
                    alignment: Alignment.topLeft,
                    child: _ReportCard(
                      title: widget.judulLaporan,
                      date: widget.tanggalLaporan,
                      onTap: _openPreview,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _kShadow,
                    ),
                    child: const Text(
                      'Laporan tidak ditemukan.',
                      style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );

          // Kalau tinggi dibatasi induk: bisa di-scroll sendiri.
          // Kalau induk sudah scroll (tinggi tak terbatas): tampil biasa.
          if (constraints.hasBoundedHeight) {
            return SingleChildScrollView(child: content);
          }
          return content;
        },
      ),
    );
  }

  Widget _title() {
    return const Text(
      'Kelola Laporan',
      style: TextStyle(
        color: _navy,
        fontSize: 27,
        fontWeight: FontWeight.w900,
        letterSpacing: .1,
        shadows: [
          Shadow(color: Color(0x66000000), offset: Offset(2, 3), blurRadius: 4),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _kShadow,
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 12, color: _navy),
        decoration: InputDecoration(
          hintText: 'Cari',
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFA9BBD1)),
          prefixIcon: const Icon(Icons.search_rounded, size: 15, color: _muted),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// ============================================================
// LOGO EXCEL
// ============================================================
class _ExcelLogo extends StatelessWidget {
  const _ExcelLogo({this.size = 34});

class _ExcelLogo extends StatelessWidget {
  const _ExcelLogo({this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _xlGreen,
        borderRadius: BorderRadius.circular(size * .16),
      ),
      child: Text(
        'X',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .66,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

// ============================================================
// KARTU LAPORAN (sesuai desain)
// ============================================================

class _ReportCard extends StatefulWidget {
  const _ReportCard({
    required this.title,
    required this.date,
    required this.onTap,
  });

  final String title;
  final String date;
  final VoidCallback onTap;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        width: isMobile ? double.infinity : 270,
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? .38 : .28),
              blurRadius: _hovered ? 9 : 5,
              offset: Offset(2, _hovered ? 5 : 3),
              color: _navy.withOpacity(_hovered ? .28 : .18),
              blurRadius: _hovered ? 20 : 13,
              offset: Offset(0, _hovered ? 9 : 5),
            ),
            const BoxShadow(
              color: Color(0x1AFFFFFF),
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Row(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const _ExcelLogo(size: 42),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x59000000),
                                blurRadius: 3,
                                offset: Offset(1, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 13,
                                color: _navy,
                              ),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Lihat Laporan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _navy,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HALAMAN PRATINJAU EXCEL (di dalam aplikasi)
// ============================================================

class LaporanExcelPreviewPage extends StatefulWidget {
  const LaporanExcelPreviewPage({
    super.key,
    required this.rows,
    required this.judul,
    this.onExported,
  });

  final List<_SRow> rows;
  final String judul;
  final VoidCallback? onExported;

  @override
  State<LaporanExcelPreviewPage> createState() =>
      _LaporanExcelPreviewPageState();
}

class _LaporanExcelPreviewPageState extends State<LaporanExcelPreviewPage> {
  static const double _rowHeaderW = 44;
  static const double _colHeaderH = 24;
  static const double _defaultRowH = 22;
  static const int _minRows = 45;

  final ScrollController _hCtrl = ScrollController();
  final ScrollController _vCtrl = ScrollController();

  int _selRow = 0;
  int _selCol = 0;
  bool _exporting = false;

  List<double> get _allWidths => [..._colWidths, ..._extraColWidths];

  String get _fileName => '${_safeFileName(widget.judul)}.xlsx';

  @override
  void dispose() {
    _hCtrl.dispose();
    _vCtrl.dispose();
    super.dispose();
  }

  _SCell? _cellAt(int r, int c) {
    if (r >= widget.rows.length) return null;
    var col = 0;
    for (final cell in widget.rows[r].cells) {
      if (c >= col && c < col + cell.span) return cell;
      col += cell.span;
    }
    return null;
  }

  // ----------------------------------------------------------
  // EXPORT
  // ----------------------------------------------------------

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      await FileSaver.instance.saveAs(
        name: _safeFileName(widget.judul),
        bytes: _encodeExcel(widget.rows),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      widget.onExported?.call();
      _snack('Laporan berhasil diekspor ke Excel.');
    } catch (e) {
      _snack('Gagal mengekspor laporan: $e', error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : _xlGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _titleBar(),
            _ribbonTabs(),
            _toolbar(),
            _formulaBar(),
            Expanded(child: _grid()),
            _sheetTabs(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HEADER APLIKASI (hijau Excel)
  // ----------------------------------------------------------

  Widget _titleBar() {
    final compact = MediaQuery.sizeOf(context).width < 560;

    return Container(
      height: 48,
      color: _xlGreen,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const _ExcelLogo(size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$_fileName  -  Pratinjau',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (compact)
            IconButton.filled(
              tooltip: 'Export ke Excel',
              onPressed: _exporting ? null : _export,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _xlGreenDark,
              ),
              icon: _exporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined, size: 20),
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x59000000),
                    blurRadius: 3,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: _exporting ? null : _export,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _xlGreenDark,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: _exporting
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined, size: 18),
                label: const Text(
                  'Export ke Excel',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // TAB RIBBON
  // ----------------------------------------------------------

  Widget _ribbonTabs() {
    const tabs = [
      'File',
      'Beranda',
      'Sisipkan',
      'Tata Letak',
      'Rumus',
      'Data',
      'Tinjau',
      'Lihat',
    ];

    return Container(
      height: 32,
      color: const Color(0xFFF3F3F3),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final t in tabs)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: t == 'Beranda'
                  ? const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: _xlGreen, width: 2),
                      ),
                    )
                  : null,
              child: Text(
                t,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: t == 'Beranda' ? FontWeight.w700 : FontWeight.w500,
                  color: t == 'Beranda' ? _xlGreenDark : Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // TOOLBAR GAYA EXCEL (tampilan saja)
  // ----------------------------------------------------------

  Widget _toolbar() {
    Widget ic(IconData i, {bool active = false}) => Container(
      width: 30,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFD3F0E0) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(i, size: 17, color: Colors.black87),
    );

    Widget sep() => Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFD0D0D0),
    );

    Widget box(String t, double w) => Container(
      width: w,
      height: 24,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC8C8C8)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(t, style: const TextStyle(fontSize: 11)),
          ),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
    );

    return Container(
      height: 42,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          Center(child: ic(Icons.content_paste_rounded)),
          Center(child: ic(Icons.content_copy_rounded)),
          Center(child: sep()),
          Center(child: box('Calibri', 100)),
          const SizedBox(width: 4),
          Center(child: box('11', 52)),
          Center(child: sep()),
          Center(child: ic(Icons.format_bold_rounded)),
          Center(child: ic(Icons.format_italic_rounded)),
          Center(child: ic(Icons.format_underlined_rounded)),
          Center(child: ic(Icons.format_color_fill_rounded)),
          Center(child: ic(Icons.format_color_text_rounded)),
          Center(child: sep()),
          Center(child: ic(Icons.format_align_left_rounded)),
          Center(child: ic(Icons.format_align_center_rounded, active: true)),
          Center(child: ic(Icons.format_align_right_rounded)),
          Center(child: ic(Icons.merge_type_rounded)),
          Center(child: sep()),
          Center(child: ic(Icons.attach_money_rounded)),
          Center(child: ic(Icons.percent_rounded)),
          Center(child: ic(Icons.border_all_rounded)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // FORMULA BAR
  // ----------------------------------------------------------

  Widget _formulaBar() {
    final cell = _cellAt(_selRow, _selCol);

    return Container(
      height: 30,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFD0D0D0))),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFFD0D0D0))),
            ),
            child: Text(
              '${_colLetter(_selCol)}${_selRow + 1}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'fx',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Container(width: 1, height: 18, color: const Color(0xFFD0D0D0)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cell?.raw ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontFamily: 'Calibri'),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // GRID (scroll horizontal + vertikal)
  // ----------------------------------------------------------

  Widget _grid() {
    final widths = _allWidths;
    final totalW = _rowHeaderW + widths.fold<double>(0, (a, b) => a + b);
    final rowCount = widget.rows.length < _minRows
        ? _minRows
        : widget.rows.length + 10;

    return LayoutBuilder(
      builder: (context, box) {
        final w = totalW > box.maxWidth ? totalW : box.maxWidth;

        return Container(
          color: Colors.white,
          child: Scrollbar(
            controller: _hCtrl,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _hCtrl,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: w,
                height: box.maxHeight,
                child: Column(
                  children: [
                    _columnHeaders(widths),
                    Expanded(
                      child: Scrollbar(
                        controller: _vCtrl,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _vCtrl,
                          itemCount: rowCount,
                          itemBuilder: (_, r) => _gridRow(r, widths),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _columnHeaders(List<double> widths) {
    return SizedBox(
      height: _colHeaderH,
      child: Row(
        children: [
          Container(
            width: _rowHeaderW,
            height: _colHeaderH,
            decoration: const BoxDecoration(
              color: Color(0xFFE6E6E6),
              border: Border(
                right: BorderSide(color: Color(0xFFBDBDBD)),
                bottom: BorderSide(color: Color(0xFFBDBDBD)),
              ),
            ),
          ),
          for (var c = 0; c < widths.length; c++)
            Container(
              width: widths[c],
              height: _colHeaderH,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c == _selCol
                    ? const Color(0xFFD3F0E0)
                    : const Color(0xFFE6E6E6),
                border: Border(
                  right: const BorderSide(color: Color(0xFFBDBDBD)),
                  bottom: BorderSide(
                    color: c == _selCol ? _xlGreen : const Color(0xFFBDBDBD),
                    width: c == _selCol ? 2 : 1,
                  ),
                ),
              ),
              child: Text(
                _colLetter(c),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: c == _selCol ? FontWeight.w700 : FontWeight.w500,
                  color: c == _selCol ? _xlGreenDark : Colors.black87,
                ),
              ),
            ),
        ],
/// Dialog pratinjau laporan sebelum unduhan / pembuka file.
class _ReportPreviewDialog extends StatelessWidget {
  const _ReportPreviewDialog({
    required this.title,
    required this.tanggal,
    required this.data,
    required this.onDownload,
    required this.onOpenFile,
  });

  final String title;
  final String tanggal;
  final LaporanPreviewData data;
  final VoidCallback onDownload;
  final VoidCallback onOpenFile;

  @override
  Widget build(BuildContext context) {
    final rows = data.rows;
    final compact = MediaQuery.of(context).size.width < 520;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment_outlined, color: _navy, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tanggal,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: _muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ringkasanBox(
                      'Total Transaksi',
                      '${data.totalTransaksi ?? rows.length}',
                      Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ringkasanBox(
                      'Total Omzet',
                      formatRupiah(data.totalOmzet?.toDouble() ?? 0),
                      Icons.attach_money,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Detail Transaksi',
                style: TextStyle(
                  color: _navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 260,
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: m.Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: compact
                            ? _barisKompak(row)
                            : _barisLebar(row),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.file_download, size: 18),
                      label: const Text('Unduh Excel'),
                      onPressed: onDownload,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navy,
                        side: const BorderSide(color: _navy),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Buka File'),
                      onPressed: onOpenFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridRow(int r, List<double> widths) {
    final row = r < widget.rows.length ? widget.rows[r] : null;
    final h = row?.height ?? _defaultRowH;
    final selectedRow = r == _selRow;

    final cells = <Widget>[];
    var col = 0;

    if (row != null) {
      for (final cell in row.cells) {
        var w = 0.0;
        for (var i = col; i < col + cell.span; i++) {
          w += widths[i];
        }
        cells.add(_cellBox(r, col, w, h, cell));
        col += cell.span;
      }
    }

    for (; col < widths.length; col++) {
      cells.add(_cellBox(r, col, widths[col], h, null));
    }

    return Row(
      children: [
        Container(
          width: _rowHeaderW,
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selectedRow
                ? const Color(0xFFD3F0E0)
                : const Color(0xFFE6E6E6),
            border: Border(
              right: BorderSide(
                color: selectedRow ? _xlGreen : const Color(0xFFBDBDBD),
                width: selectedRow ? 2 : 1,
              ),
              bottom: const BorderSide(color: Color(0xFFBDBDBD)),
            ),
          ),
          child: Text(
            '${r + 1}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: selectedRow ? FontWeight.w700 : FontWeight.w500,
              color: selectedRow ? _xlGreenDark : Colors.black87,
            ),
          ),
        ),
        ...cells,
  Widget _barisLebar(LaporanPreviewRow row) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            row.tanggal,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            row.keterangan,
            style: const TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 90,
          child: Text(
            row.metode,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ),
        SizedBox(
          width: 100,
          child: Text(
            formatRupiah(row.nominal.toDouble()),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cellBox(int r, int c, double w, double h, _SCell? cell) {
    final selected = r == _selRow && c == _selCol;

    final BoxBorder border = selected
        ? Border.all(color: _xlGreen, width: 2)
        : (cell?.border ?? false)
        ? Border.all(color: _tableLine, width: .8)
        : const Border(
            right: BorderSide(color: _gridLine, width: .6),
            bottom: BorderSide(color: _gridLine, width: .6),
          );

    final alignment = switch (cell?.align) {
      TextAlign.center => Alignment.center,
      TextAlign.right => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _selRow = r;
        _selCol = c;
      }),
      child: Container(
        width: w,
        height: h,
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(color: cell?.bg ?? Colors.white, border: border),
        child: cell == null || cell.text.isEmpty
            ? null
            : Text(
                cell.text,
                maxLines: cell.wrap ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                textAlign: cell.align,
                style: TextStyle(
                  fontFamily: 'Calibri',
                  fontSize: cell.fontSize,
                  fontWeight: cell.bold ? FontWeight.w700 : FontWeight.w400,
                  fontStyle: cell.italic ? FontStyle.italic : FontStyle.normal,
                  color: cell.color,
                  height: 1.15,
                ),
              ),
      ),
    );
  }

  // ----------------------------------------------------------
  // TAB SHEET + STATUS BAR
  // ----------------------------------------------------------

  Widget _sheetTabs() {
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F3F3),
        border: Border(top: BorderSide(color: Color(0xFFD0D0D0))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(Icons.chevron_left_rounded, size: 18, color: Colors.grey),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
          const SizedBox(width: 6),
          Container(
            height: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: _xlGreen, width: 3),
                left: BorderSide(color: Color(0xFFD0D0D0)),
                right: BorderSide(color: Color(0xFFD0D0D0)),
              ),
            ),
            child: const Text(
              'Laporan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _xlGreenDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.add_circle_outline, size: 18, color: Colors.grey),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text(
              'Siap',
              style: TextStyle(fontSize: 11, color: Colors.black54),
  Widget _barisKompak(LaporanPreviewRow row) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.keterangan,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${row.tanggal} • ${row.metode}',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatRupiah(row.nominal.toDouble()),
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: _navy,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _ringkasanBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: m.Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: _navy,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Format rupiah sederhana untuk dialog pratinjau.
String formatRupiah(double value) {
  final angka = value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (mt) => '${mt[1]}.',
      );
  return 'Rp. $angka';
}