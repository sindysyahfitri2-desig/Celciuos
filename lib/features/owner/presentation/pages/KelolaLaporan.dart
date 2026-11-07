import 'package:flutter/material.dart';

const Color _navy = Color(0xFF082640);
const Color _navy2 = Color(0xFF103657);
const Color _pageBg = Color(0xFFDCE9F4);
const Color _muted = Color(0xFF71869A);
const Color _green = Color(0xFF239653);

/// Satu baris transaksi untuk ditampilkan pada pratinjau laporan.
/// Isi daftar ini dengan data transaksi asli dari aplikasi/backend.
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

/// Data ringkasan untuk halaman pratinjau.
/// Jika belum diberikan, halaman pratinjau menampilkan tanda "-" dan
/// keterangan bahwa data belum dihubungkan. Tidak ada angka palsu.
class LaporanPreviewData {
  const LaporanPreviewData({
    this.totalOmzet,
    this.totalTunai,
    this.totalNonTunai,
    this.totalTransaksi,
    this.rows = const [],
  });

  final num? totalOmzet;
  final num? totalTunai;
  final num? totalNonTunai;
  final int? totalTransaksi;
  final List<LaporanPreviewRow> rows;
}

class KelolaLaporanContent extends StatefulWidget {
  const KelolaLaporanContent({
    super.key,
    this.onDownload,
    this.previewData,
    this.judulLaporan = 'Laporan Keuangan',
    this.tanggalLaporan = '30 Oktober 2026',
  });

  /// Fungsi export Excel yang sudah ada di aplikasi.
  /// Fungsi ini hanya dipanggil setelah tombol Unduh ditekan di pratinjau.
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

  String _rupiah(num? value) {
    if (value == null) return '-';
    final formatted = value.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  void _openPreview() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _LaporanPreviewDialog(
        title: widget.judulLaporan,
        date: widget.tanggalLaporan,
        data: widget.previewData,
        onDownload: widget.onDownload,
        rupiah: _rupiah,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _pageBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

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
                      color: Colors.white.withValues(alpha: 0.75),
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
          Shadow(
            color: Color(0x5589A7B8),
            offset: Offset(2, 3),
            blurRadius: 4,
          ),
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
          border: Border.all(color: Colors.white.withValues(alpha: .75)),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .15),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.grid_on_rounded,
                          size: 43,
                          color: _green,
                        ),
                        Positioned(
                          left: 7,
                          top: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 1,
                            ),
                            color: _green,
                            child: const Text(
                              'X',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .17),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_rounded,
                                  size: 14, color: _navy),
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

class _LaporanPreviewDialog extends StatelessWidget {
  const _LaporanPreviewDialog({
    required this.title,
    required this.date,
    required this.data,
    required this.onDownload,
    required this.rupiah,
  });

  final String title;
  final String date;
  final LaporanPreviewData? data;
  final VoidCallback? onDownload;
  final String Function(num?) rupiah;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;
    final preview = data;
    final rows = preview?.rows ?? const <LaporanPreviewRow>[];

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 36,
        vertical: isPhone ? 18 : 30,
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: MediaQuery.sizeOf(context).height * .92,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFD),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: .30),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _previewHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isPhone ? 14 : 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Ringkasan Keuangan'),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth < 430 ? 2 : 4;
                        const gap = 9.0;
                        final itemWidth =
                            (constraints.maxWidth - gap * (columns - 1)) /
                                columns;
                        final summaries = [
                          _PreviewMetric(
                            label: 'Total Omzet',
                            value: rupiah(preview?.totalOmzet),
                            icon: Icons.payments_outlined,
                          ),
                          _PreviewMetric(
                            label: 'Kas Tunai',
                            value: rupiah(preview?.totalTunai),
                            icon: Icons.point_of_sale_rounded,
                          ),
                          _PreviewMetric(
                            label: 'Non Tunai',
                            value: rupiah(preview?.totalNonTunai),
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          _PreviewMetric(
                            label: 'Transaksi',
                            value: preview?.totalTransaksi?.toString() ?? '-',
                            icon: Icons.receipt_long_rounded,
                          ),
                        ];
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: summaries
                              .map(
                                (item) => SizedBox(
                                  width: itemWidth,
                                  child: _MetricCard(metric: item),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: _sectionTitle('Rincian Transaksi')),
                        Text(
                          '${rows.length} data',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (rows.isEmpty)
                      _emptyPreview()
                    else
                      _transactionTable(context, rows),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD4E2ED)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: _navy2, size: 17),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Periksa ringkasan dan rincian laporan terlebih dahulu. '
                              'File Excel baru dibuat setelah tombol Unduh Laporan ditekan.',
                              style: TextStyle(
                                color: _navy2,
                                fontSize: 11,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _previewFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _previewHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 15, 12, 15),
      decoration: const BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.table_view_rounded,
                color: _green, size: 25),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tutup pratinjau',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _navy,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _emptyPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE6EF)),
      ),
      child: const Column(
        children: [
          Icon(Icons.table_rows_outlined, color: _muted, size: 30),
          SizedBox(height: 8),
          Text(
            'Data transaksi belum tersedia',
            style: TextStyle(
              color: _navy,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Hubungkan data transaksi aplikasi agar ringkasan dan '
            'rincian tampil di halaman ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _transactionTable(
    BuildContext context,
    List<LaporanPreviewRow> rows,
  ) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFDCE6EF)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: .06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                const WidgetStatePropertyAll(Color(0xFFEAF2F8)),
            headingTextStyle: const TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            dataTextStyle: const TextStyle(
              color: _navy2,
              fontSize: 11,
            ),
            columnSpacing: compact ? 18 : 32,
            horizontalMargin: 14,
            columns: const [
              DataColumn(label: Text('Tanggal')),
              DataColumn(label: Text('Keterangan')),
              DataColumn(label: Text('Metode')),
              DataColumn(label: Text('Nominal')),
            ],
            rows: rows
                .map(
                  (row) => DataRow(
                    cells: [
                      DataCell(Text(row.tanggal)),
                      DataCell(Text(row.keterangan)),
                      DataCell(Text(row.metode)),
                      DataCell(
                        Text(
                          rupiah(row.nominal),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _previewFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: .07),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 9,
        runSpacing: 9,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _navy,
              side: const BorderSide(color: Color(0xFFB8C9D8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: onDownload == null
                ? null
                : () {
                    Navigator.pop(context);
                    onDownload!.call();
                  },
            icon: const Icon(Icons.download_rounded, size: 17),
            label: const Text('Unduh Laporan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFB8C5D0),
              disabledForegroundColor: Colors.white,
              elevation: 3,
              shadowColor: _navy.withValues(alpha: .25),
              padding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMetric {
  const _PreviewMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _PreviewMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE1EAF1)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, size: 16, color: _muted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              style: const TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
