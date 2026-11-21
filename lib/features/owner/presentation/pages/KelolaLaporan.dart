import 'dart:typed_data';

import 'package:flutter/material.dart' hide Border;
import 'package:flutter/material.dart' as m;
import 'package:excel/excel.dart';

import 'excel_saver.dart';

const Color _navy = Color(0xFF082640);
const Color _pageBg = Color(0xFFDCE9F4);
const Color _muted = Color(0xFF71869A);

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
                      color: Colors.white.withOpacity(0.75),
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
  const _ExcelLogo({this.size = 34});

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
    final isMobile = MediaQuery.of(context).size.width < 600;

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