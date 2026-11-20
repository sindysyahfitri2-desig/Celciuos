import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart' hide Border;
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart' show OpenFilex;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart' as m;

const Color _navy = Color(0xFF082640);
const Color _navy2 = Color(0xFF103657);
const Color _pageBg = Color(0xFFDCE9F4);
const Color _muted = Color(0xFF71869A);
const Color _green = Color(0xFF239653);

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

/// Data transaksi yang ditampilkan pada pratinjau.
class LaporanPreviewData {
  const LaporanPreviewData({
    this.totalOmzet,
    this.totalTunai,
    this.totalNonTunai,
    this.totalTransaksi,
    this.rows = const [],
    this.namaKasir = 'Kasir',
  });

  // Dipertahankan agar pemanggilan lama tidak menyebabkan error.
  // Ringkasan ini tidak ditampilkan lagi.
  final num? totalOmzet;
  final num? totalTunai;
  final num? totalNonTunai;
  final int? totalTransaksi;

  final List<LaporanPreviewRow> rows;
  final String namaKasir;
}

class KelolaLaporanContent extends StatefulWidget {
  const KelolaLaporanContent({
    super.key,
    this.onDownload,
    this.previewData,
    this.judulLaporan = 'Laporan Transaksi',
    this.tanggalLaporan = '1–31 Oktober 2026',
  });

  /// Fungsi untuk mengunduh file Excel.
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

  Uint8List _createExcelBytes() {
    final reportData = widget.previewData;
    final rows = reportData?.rows ?? const <LaporanPreviewRow>[];

    final excel = Excel.createExcel();
    final sheet = excel['Laporan'];

    // Identitas usaha dan informasi laporan.
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'));
    final brandCell = sheet.cell(CellIndex.indexByString('A1'));
    brandCell.value = TextCellValue('CELCIOUS COFFE');
    brandCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 18,
      fontColorHex: ExcelColor.fromHexString('#082640'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('E2'));
    final addressCell = sheet.cell(CellIndex.indexByString('A2'));
    addressCell.value = TextCellValue(
      'Dusun vak111 kampun, Mekar Sawit, Kec. Sawit Seberang, '
      'Kabupaten Langkat, Sumatera Utara 20852',
    );
    addressCell.cellStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    sheet.merge(CellIndex.indexByString('A3'), CellIndex.indexByString('E3'));
    final titleCell = sheet.cell(CellIndex.indexByString('A3'));
    titleCell.value = TextCellValue(widget.judulLaporan.toUpperCase());
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#082640'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    sheet.merge(CellIndex.indexByString('A4'), CellIndex.indexByString('E4'));
    final periodCell = sheet.cell(CellIndex.indexByString('A4'));
    periodCell.value = TextCellValue('Periode: ${widget.tanggalLaporan}');
    periodCell.cellStyle = CellStyle(
      italic: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Kolom laporan dimulai pada baris kelima lembar kerja Excel.
    final headers = <String>[
      'No.',
      'Tanggal',
      'Keterangan',
      'Metode Pembayaran',
      'Nominal',
    ];

    for (var column = 0; column < headers.length; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 4),
      );
      cell.value = TextCellValue(headers[column]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#082640'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }

    if (rows.isEmpty) {
      sheet.merge(CellIndex.indexByString('B6'), CellIndex.indexByString('D6'));
      sheet.cell(CellIndex.indexByString('A6')).value = IntCellValue(1);
      sheet.cell(CellIndex.indexByString('B6')).value = TextCellValue(
        'Belum ada transaksi',
      );
      sheet.cell(CellIndex.indexByString('E6')).value = TextCellValue('-');
    } else {
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        final excelRow = index + 5;

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: excelRow),
            )
            .value = IntCellValue(
          index + 1,
        );

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: excelRow),
            )
            .value = TextCellValue(
          row.tanggal,
        );

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: excelRow),
            )
            .value = TextCellValue(
          row.keterangan,
        );

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: excelRow),
            )
            .value = TextCellValue(
          row.metode,
        );

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: excelRow),
            )
            .value = DoubleCellValue(
          row.nominal.toDouble(),
        );
      }
    }

    // Area tanda tangan kasir pada bagian bawah laporan.
    final signatureRow = rows.length + 8;
    final now = DateTime.now();
    final tanggalCetak =
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-${now.year}';

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: signatureRow),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: signatureRow),
    );
    final dateSignature = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: signatureRow),
    );
    dateSignature.value = TextCellValue('Langkat, $tanggalCetak');
    dateSignature.cellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
    );

    final kasirRow = signatureRow + 1;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: kasirRow),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: kasirRow),
    );
    final kasirCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: kasirRow),
    );
    kasirCell.value = TextCellValue('Kasir,');
    kasirCell.cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);

    final digitalRow = signatureRow + 3;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: digitalRow),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: digitalRow),
    );
    final digitalCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: digitalRow),
    );
    digitalCell.value = TextCellValue('Tanda tangan digital');
    digitalCell.cellStyle = CellStyle(
      italic: true,
      fontColorHex: ExcelColor.fromHexString('#239653'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final namaRow = signatureRow + 5;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: namaRow),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: namaRow),
    );
    final namaCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: namaRow),
    );
    namaCell.value = TextCellValue('/${reportData?.namaKasir ?? 'Kasir'}/');
    namaCell.cellStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 32);
    sheet.setColumnWidth(3, 24);
    sheet.setColumnWidth(4, 20);
    sheet.setRowHeight(0, 30);
    sheet.setRowHeight(1, 30);
    sheet.setRowHeight(2, 25);
    sheet.setRowHeight(4, 25);

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('File Excel gagal dibuat.');
    }
    return Uint8List.fromList(bytes);
  }

  String get _safeFileName {
    final safeName = widget.judulLaporan
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return safeName.isEmpty ? 'Laporan_Transaksi' : safeName;
  }

  Future<void> _downloadExcel() async {
    try {
      await FileSaver.instance.saveAs(
        name: _safeFileName,
        bytes: _createExcelBytes(),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan Excel berhasil disiapkan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh laporan Excel: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openExcelPreview() async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$_safeFileName.xlsx');
      await file.writeAsBytes(_createExcelBytes(), flush: true);

      // Membuka file melalui aplikasi spreadsheet default pada perangkat.
      await OpenFilex.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka pratinjau Excel: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openPreview() {
    _openExcelPreview();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _pageBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 760;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 28,
              isMobile ? 22 : 30,
              isMobile ? 16 : 28,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 16),
                      _buildSearchField(),
                    ],
                  )
                else
                  Row(
                    children: [
                      _buildTitle(),
                      const Spacer(),
                      SizedBox(width: 250, child: _buildSearchField()),
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
                      color: Colors.white.withValues(alpha: .75),
                      borderRadius: BorderRadius.circular(14),
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
        },
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Kelola Laporan',
      style: TextStyle(
        color: _navy,
        fontSize: 27,
        fontWeight: FontWeight.w900,
        letterSpacing: .1,
        shadows: [
          Shadow(color: Color(0x5589A7B8), offset: Offset(2, 3), blurRadius: 4),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: .10),
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
          hintText: 'Cari laporan',
          hintStyle: const TextStyle(fontSize: 12, color: _muted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _muted),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _ExcelLogo extends StatelessWidget {
  const _ExcelLogo({this.size = 34, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 10,
      height: size + 10,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF168447),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'X',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .72,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

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
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        width: isMobile ? double.infinity : 330,
        constraints: const BoxConstraints(minHeight: 112),
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(11),
          border: m.Border.all(color: Colors.white.withOpacity(0.75)),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: _hovered ? .28 : .18),
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
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const _ExcelLogo(size: 43),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(height: 3),
                        Text(
                          widget.date,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Container(
                          height: 27,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility_rounded,
                                size: 14,
                                color: _navy,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Lihat Laporan',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                    size: 20,
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

