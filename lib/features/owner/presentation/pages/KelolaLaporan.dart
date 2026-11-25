import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/features/reports/application/celcious_report_export.dart';
import 'package:kasir_celcious_coffe/features/reports/application/report_service.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';

// ============================================================
// KONSTANTA DESAIN
// ============================================================

const Color _navy = Color(0xFF0B2540);
const Color _navyBar = Color(0xFF102A45);
const Color _logoBlue = Color(0xFF39648B);
const Color _pageBg = Color(0xFFDCE9F4);
const Color _muted = Color(0xFF64788B);
const Color _tableBorder = Color(0xFF8EA4B8);
const Color _subtotalBg = Color(0xFFEDF4FA);
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
// MODEL DATA (kompatibel dengan pemanggilan sebelumnya)
// ============================================================

/// Satu baris transaksi untuk laporan.
class LaporanPreviewRow {
  const LaporanPreviewRow({
    required this.tanggal,
    required this.keterangan,
    required this.metode,
    required this.nominal,
    this.idPemesanan,
    this.jam,
    this.namaKasir,
    this.jumlahPemesanan = 1,
  });

  final String tanggal;
  final String keterangan;
  final String metode;
  final num nominal;
  final String? idPemesanan;
  final String? jam;
  final String? namaKasir;
  final int jumlahPemesanan;
}

/// Item baris rincian pendapatan atau beban (dipertahankan untuk kompatibilitas).
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
    this.drawerRows = const [],
    this.openingCash = 0,
    this.currentCash = 0,
    this.pendapatanItems = const [],
    this.bebanItems = const [],
    this.pajakPersen = 0,
    this.pajakNominal,
    this.namaKasir = 'Kasir',
    this.namaKasirSiang,
    this.namaKasirMalam,
    this.namaOwner = kCelciousDefaultOwner,
    this.alamatToko = kCelciousAddress,
    this.kontakToko = kCelciousContact,
    this.noDokumen,
    this.sysId,
  });

  final num? totalOmzet;
  final num? totalTunai;
  final num? totalNonTunai;
  final int? totalTransaksi;

  final List<LaporanPreviewRow> rows;
  final List<Map<String, String>> drawerRows;
  final num openingCash;
  final num currentCash;
  final List<LaporanNominalItem> pendapatanItems;
  final List<LaporanNominalItem> bebanItems;
  final double pajakPersen;
  final num? pajakNominal;
  final String namaKasir;
  final String? namaKasirSiang;
  final String? namaKasirMalam;
  final String namaOwner;
  final String alamatToko;
  final String kontakToko;
  final String? noDokumen;
  final String? sysId;
}

/// Alias agar pemanggilan lama yang memakai `ComputedFinancialReport` tetap valid.
typedef ComputedFinancialReport = CelciousTransactionReportData;

String _safeFileName(String judul, String periode) {
  final s = '${judul}_$periode'
      .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return s.isEmpty ? 'Laporan_Transaksi_Celcious_Coffee' : s;
}

String _extractJamText(LaporanPreviewRow row) {
  final rawJam = (row.jam ?? '').trim();
  if (rawJam.isNotEmpty && rawJam != '-' && rawJam != '--:--') {
    return rawJam;
  }
  final parsed = DateTime.tryParse(row.tanggal)?.toLocal();
  if (parsed != null) {
    return '${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}';
  }
  final m = RegExp(r'(\d{1,2}[:.]\d{2})').firstMatch(row.tanggal);
  if (m != null) return m.group(1)!.replaceAll('.', ':');
  return '-';
}

String _extractIdPemesanan(LaporanPreviewRow row) {
  final id = (row.idPemesanan ?? '').trim();
  if (id.isNotEmpty) return id;
  final ket = row.keterangan.trim();
  if (ket.contains(' - ')) {
    final left = ket.split(' - ').first.trim();
    if (left.isNotEmpty) return left;
  }
  return ket.isEmpty ? '-' : ket;
}

String _extractKasir(LaporanPreviewRow row, String fallback) {
  final k = (row.namaKasir ?? '').trim();
  if (k.isNotEmpty) return k;
  final ket = row.keterangan.trim();
  if (ket.contains(' - ')) {
    final right = ket.split(' - ').last.trim();
    if (right.isNotEmpty) return right;
  }
  return fallback;
}

ComputedFinancialReport _computeReport({
  required LaporanPreviewData? data,
  required String judul,
  required String tanggalLaporan,
}) {
  final now = DateTime.now();
  final rows = data?.rows ?? const <LaporanPreviewRow>[];
  final fallbackKasir =
      (data?.namaKasir.trim().isNotEmpty == true) ? data!.namaKasir.trim() : 'Kasir';

  final siangList = <CelciousShiftTransactionRow>[];
  final malamList = <CelciousShiftTransactionRow>[];

  for (final row in rows) {
    final id = _extractIdPemesanan(row);
    final jam = _extractJamText(row);
    final kasir = _extractKasir(row, fallbackKasir);
    final qty = row.jumlahPemesanan <= 0 ? 1 : row.jumlahPemesanan;
    if (CelciousReportExport.isShiftMalam(jam: jam, tanggal: row.tanggal)) {
      malamList.add(
        CelciousShiftTransactionRow(
          no: malamList.length + 1,
          idPemesanan: id,
          jam: jam,
          namaKasir: kasir,
          jumlahPemesanan: qty,
          totalHarga: row.nominal,
        ),
      );
    } else {
      siangList.add(
        CelciousShiftTransactionRow(
          no: siangList.length + 1,
          idPemesanan: id,
          jam: jam,
          namaKasir: kasir,
          jumlahPemesanan: qty,
          totalHarga: row.nominal,
        ),
      );
    }
  }

  final totalSiang = siangList.fold<num>(0, (s, e) => s + e.totalHarga);
  final totalMalam = malamList.fold<num>(0, (s, e) => s + e.totalHarga);

  final periodDateText = tanggalLaporan.trim().isEmpty
      ? CelciousReportExport.formatTanggalIndonesia(now)
      : tanggalLaporan.trim();

  final cleanedTitle = judul.trim();
  final reportTitle = cleanedTitle.isEmpty ||
          cleanedTitle.toLowerCase().contains('laba rugi')
      ? 'LAPORAN TRANSAKSI CELCIOUS COFFEE'
      : cleanedTitle.toUpperCase();

  return CelciousTransactionReportData(
    storeName: kCelciousStoreName,
    address: (data?.alamatToko.trim().isNotEmpty == true)
        ? data!.alamatToko.trim()
        : kCelciousAddress,
    contactLine: (data?.kontakToko.trim().isNotEmpty == true)
        ? data!.kontakToko.trim()
        : kCelciousContact,
    reportTitle: reportTitle,
    periodDateText: periodDateText,
    siangRows: siangList,
    malamRows: malamList,
    totalSiang: totalSiang,
    totalMalam: totalMalam,
    kasirSiang: CelciousReportExport.resolveCashierName(
      siangList.map((e) => e.namaKasir),
      explicit: data?.namaKasirSiang,
      fallback: kCelciousDefaultKasirSiang,
    ),
    kasirMalam: CelciousReportExport.resolveCashierName(
      malamList.map((e) => e.namaKasir),
      explicit: data?.namaKasirMalam,
      fallback: kCelciousDefaultKasirMalam,
    ),
    ownerName: CelciousReportExport.resolveOwnerName(data?.namaOwner),
    locationDate: 'Langkat, $periodDateText',
  );
}

CelciousCashDrawerReportData _computeCashDrawerReport({
  required LaporanPreviewData? data,
  required String tanggalLaporan,
}) {
  final now = DateTime.now();
  final periodDateText = tanggalLaporan.trim().isEmpty
      ? CelciousReportExport.formatTanggalIndonesia(now)
      : tanggalLaporan.trim();

  final base = CelciousReportExport.buildCashDrawerDataFromMaps(
    rows: data?.drawerRows ?? const <Map<String, String>>[],
    periodDateText: periodDateText,
    openingCash: data?.openingCash ?? 0,
    currentCash: data?.currentCash ?? 0,
    ownerName: data?.namaOwner,
  );

  return CelciousCashDrawerReportData(
    storeName: kCelciousStoreName,
    address: (data?.alamatToko.trim().isNotEmpty == true)
        ? data!.alamatToko.trim()
        : kCelciousAddress,
    contactLine: (data?.kontakToko.trim().isNotEmpty == true)
        ? data!.kontakToko.trim()
        : kCelciousContact,
    reportTitle: 'LAPORAN KAS LACI CELCIOUS COFFEE',
    periodDateText: periodDateText,
    openingCash: base.openingCash,
    currentCash: base.currentCash,
    siangRows: base.siangRows,
    malamRows: base.malamRows,
    totalSiang: base.totalSiang,
    totalMalam: base.totalMalam,
    kasirSiang: CelciousReportExport.resolveCashierName(
      base.siangRows.map((e) => e.namaKasir),
      explicit: data?.namaKasirSiang,
      fallback: kCelciousDefaultKasirSiang,
    ),
    kasirMalam: CelciousReportExport.resolveCashierName(
      base.malamRows.map((e) => e.namaKasir),
      explicit: data?.namaKasirMalam,
      fallback: kCelciousDefaultKasirMalam,
    ),
    ownerName: base.ownerName,
    locationDate: 'Langkat, $periodDateText',
  );
}

// ============================================================
// HALAMAN KELOLA LAPORAN (ADMIN / OWNER)
// ============================================================

class KelolaLaporanContent extends StatefulWidget {
  const KelolaLaporanContent({
    super.key,
    this.onDownload,
    this.previewData,
    this.judulLaporan = 'LAPORAN TRANSAKSI CELCIOUS COFFEE',
    this.tanggalLaporan = '',
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
  DateTime _selectedDate = DateTime.now();
  bool _userPickedDate = false;
  bool _loadingRemote = false;
  List<LaporanPreviewRow>? _remoteRows;
  List<Map<String, String>>? _remoteDrawerRows;
  num _remoteOpeningCash = 0;
  num _remoteCurrentCash = 0;

  @override
  void initState() {
    super.initState();
    // Jika parent sudah mengirim previewData live (misal dari _OwnerLaporanLivePage),
    // gunakan data tersebut terlebih dahulu; hanya fetch mandiri bila belum dikirim parent.
    if (widget.previewData == null) {
      _syncFromBackend();
    }
  }

  @override
  void didUpdateWidget(covariant KelolaLaporanContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previewData != oldWidget.previewData ||
        widget.tanggalLaporan != oldWidget.tanggalLaporan) {
      _userPickedDate = false;
      _remoteRows = null;
      _remoteDrawerRows = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _syncFromBackend() async {
    try {
      final token = await ApiService.getToken();
      if (token == null || token.trim().isEmpty) return;
      if (mounted) setState(() => _loadingRemote = true);
      final dayStart = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final snapshot = await ReportService.fetch(
        dari: dayStart,
        sampai: dayStart,
        cashierFallback: 'Kasir',
      );
      final fetched = snapshot.transactionRows
          .where((t) => (t['status'] ?? '').toLowerCase() == 'lunas')
          .map((t) {
            final nominal = CelciousReportExport.parseNominal(t['total']);
            final qty = int.tryParse(t['jumlah'] ?? '1') ?? 1;
            final id = t['id'] ?? '-';
            final kasir = t['kasir'] ?? 'Kasir';
            return LaporanPreviewRow(
              tanggal: t['tanggal'] ?? '',
              jam: t['jam'] ?? '-',
              idPemesanan: id,
              namaKasir: kasir,
              jumlahPemesanan: qty <= 0 ? 1 : qty,
              keterangan: '$id - $kasir',
              metode: t['pembayaran'] ?? '-',
              nominal: nominal,
            );
          })
          .toList();
      if (mounted) {
        setState(() {
          _remoteRows = fetched;
          _remoteDrawerRows = snapshot.drawerRows;
          _remoteOpeningCash = snapshot.openingCash;
          _remoteCurrentCash = snapshot.currentCash;
          _loadingRemote = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRemote = false);
    }
  }

  String get _activeTanggalText {
    if (!_userPickedDate && widget.tanggalLaporan.trim().isNotEmpty) {
      return widget.tanggalLaporan.trim();
    }
    return CelciousReportExport.formatTanggalIndonesia(_selectedDate);
  }

  LaporanPreviewData? get _effectivePreviewData {
    if (!_userPickedDate && widget.previewData != null) {
      return widget.previewData;
    }
    if (_remoteRows == null) return widget.previewData;
    final base = widget.previewData;
    return LaporanPreviewData(
      rows: _remoteRows!,
      drawerRows: _remoteDrawerRows ?? base?.drawerRows ?? const [],
      openingCash: _remoteOpeningCash,
      currentCash: _remoteCurrentCash,
      namaKasir: base?.namaKasir ?? 'Kasir',
      namaKasirSiang: base?.namaKasirSiang,
      namaKasirMalam: base?.namaKasirMalam,
      namaOwner: base?.namaOwner ?? kCelciousDefaultOwner,
      alamatToko: base?.alamatToko ?? kCelciousAddress,
      kontakToko: base?.kontakToko ?? kCelciousContact,
      noDokumen: base?.noDokumen,
      sysId: base?.sysId,
    );
  }

  ComputedFinancialReport get _report => _computeReport(
    data: _effectivePreviewData,
    judul: widget.judulLaporan,
    tanggalLaporan: _activeTanggalText,
  );

  CelciousCashDrawerReportData get _cashDrawerReport =>
      _computeCashDrawerReport(
        data: _effectivePreviewData,
        tanggalLaporan: _activeTanggalText,
      );

  bool get _isTransaksiMatch {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return true;
    final r = _report;
    return r.reportTitle.toLowerCase().contains(keyword) ||
        r.periodDateText.toLowerCase().contains(keyword) ||
        r.kasirSiang.toLowerCase().contains(keyword) ||
        r.kasirMalam.toLowerCase().contains(keyword) ||
        'transaksi'.contains(keyword) ||
        'celcious'.contains(keyword);
  }

  bool get _isKasLaciMatch {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) return true;
    final r = _cashDrawerReport;
    return r.reportTitle.toLowerCase().contains(keyword) ||
        r.periodDateText.toLowerCase().contains(keyword) ||
        r.kasirSiang.toLowerCase().contains(keyword) ||
        r.kasirMalam.toLowerCase().contains(keyword) ||
        'kas laci'.contains(keyword) ||
        'laci'.contains(keyword) ||
        'celcious'.contains(keyword);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _userPickedDate = true;
      _remoteRows = null;
      _remoteDrawerRows = null;
    });
    await _syncFromBackend();
  }

  void _openPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LaporanDocumentPreviewPage(
          report: _report,
          judul: _report.reportTitle,
          onExported: widget.onDownload,
        ),
      ),
    );
  }

  void _openCashDrawerPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LaporanKasLaciPreviewPage(
          report: _cashDrawerReport,
          judul: _cashDrawerReport.reportTitle,
          onExported: widget.onDownload,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final cashDrawerReport = _cashDrawerReport;
    final hasAnyMatch = _isTransaksiMatch || _isKasLaciMatch;

    return SizedBox.expand(
      child: ColoredBox(
        color: _pageBg,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isPhone = width < 600;
            final isTablet = width >= 600 && width < 1024;
            final pad = isPhone ? 16.0 : (isTablet ? 24.0 : 30.0);
            final cardWidth = isPhone
                ? ((width - pad * 2 - 14) / 2).clamp(150.0, 210.0)
                : isTablet
                    ? 210.0
                    : 226.0;

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
                        Row(
                          children: [
                            Expanded(child: _searchField()),
                            const SizedBox(width: 8),
                            _datePickerButton(compact: true),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        _title(isPhone),
                        const Spacer(),
                        _datePickerButton(compact: false),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: isTablet ? 220 : 260,
                          child: _searchField(),
                        ),
                      ],
                    ),
                  if (_loadingRemote) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        minHeight: 3,
                        color: _navy,
                        backgroundColor: Colors.white70,
                      ),
                    ),
                  ],
                  SizedBox(height: isPhone ? 18 : 24),
                  if (hasAnyMatch)
                    Wrap(
                      spacing: isPhone ? 14 : 20,
                      runSpacing: isPhone ? 14 : 20,
                      children: [
                        if (_isTransaksiMatch)
                          _ReportDocumentCard(
                            report: report,
                            cardWidth: cardWidth,
                            onTap: _openPreview,
                          ),
                        if (_isKasLaciMatch)
                          _CashDrawerDocumentCard(
                            report: cashDrawerReport,
                            cardWidth: cardWidth,
                            onTap: _openCashDrawerPreview,
                          ),
                      ],
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

  Widget _datePickerButton({required bool compact}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: _kSoftShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_rounded, size: 15, color: _navy),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(
                  _activeTanggalText,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
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
// KARTU PRATINJAU DOKUMEN (desain identik dengan isi saat diklik)
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
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: 660,
                            child: _FinancialReportDocument(
                              report: widget.report,
                              thumbnailPreview: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
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
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Periode ${widget.report.periodDateText}',
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
// KOMPONEN DOKUMEN LAPORAN TRANSAKSI PER SHIFT (BERLOGO)
// ============================================================

class _FinancialReportDocument extends StatelessWidget {
  const _FinancialReportDocument({
    required this.report,
    this.thumbnailPreview = false,
  });

  final ComputedFinancialReport report;
  final bool thumbnailPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(30, 26, 30, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --------------------------------------------------
          // KOP SURAT CELCIOUS COFFEE + LOGO
          // --------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  height: 60,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.local_cafe_rounded,
                  fallbackIconSize: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      report.storeName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      report.address,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.contactLine,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 74),
            ],
          ),

          const SizedBox(height: 14),
          Container(height: 2, color: _navy),
          const SizedBox(height: 14),

          // --------------------------------------------------
          // JUDUL & PERIODE LAPORAN
          // --------------------------------------------------
          Text(
            report.reportTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Periode ${report.periodDateText}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF334B61),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          // --------------------------------------------------
          // 1. SIFT PAGI (SHIFT 1)
          // --------------------------------------------------
          _ShiftReportTable(
            title:
                '1. Sift Pagi ( Pukul 11:00 - 17:00 ) : ${report.kasirSiang}',
            rows: thumbnailPreview
                ? report.siangRows.take(5).toList()
                : report.siangRows,
            totalAmount: report.totalSiang,
            placeholderRows: thumbnailPreview ? 5 : 6,
          ),

          const SizedBox(height: 20),

          // --------------------------------------------------
          // 2. SIFT MALAM (SHIFT 2)
          // --------------------------------------------------
          _ShiftReportTable(
            title:
                '2. Sift Malam ( Pukul 18:00 - 00:00 ) : ${report.kasirMalam}',
            rows: thumbnailPreview
                ? report.malamRows.take(5).toList()
                : report.malamRows,
            totalAmount: report.totalMalam,
            placeholderRows: thumbnailPreview ? 5 : 6,
          ),

          const SizedBox(height: 36),

          // --------------------------------------------------
          // TANDA TANGAN (Owner, Kasir Siang, Kasir Malam)
          // --------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mengetahui :',
                style: TextStyle(
                  color: _navy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                report.locationDate,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 52),
          Row(
            children: [
              _signatureColumn('(${report.ownerName})', 'Owner'),
              _signatureColumn('(${report.kasirSiang})', 'Kasir Pagi'),
              _signatureColumn('(${report.kasirMalam})', 'Kasir Malam'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signatureColumn(String name, String role) {
    return Expanded(
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            role,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftReportTable extends StatelessWidget {
  const _ShiftReportTable({
    required this.title,
    required this.rows,
    required this.totalAmount,
    this.placeholderRows = 6,
  });

  final String title;
  final List<CelciousShiftTransactionRow> rows;
  final num totalAmount;
  final int placeholderRows;

  @override
  Widget build(BuildContext context) {
    final emptyZero = rows.isEmpty && totalAmount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: _tableBorder, width: 0.9),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FlexColumnWidth(2.1),
            2: FixedColumnWidth(62),
            3: FlexColumnWidth(2.0),
            4: FlexColumnWidth(1.6),
            5: FlexColumnWidth(2.0),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: _navyBar),
              children: [
                for (final label in const [
                  'No',
                  'ID Pemesanan',
                  'Jam',
                  'Nama Kasir',
                  'Jumlah Pemesanan',
                  'Total Harga',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            if (rows.isEmpty)
              for (var i = 0; i < placeholderRows; i++)
                TableRow(
                  children: [
                    for (var c = 0; c < 6; c++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 8,
                        ),
                        child: Text(
                          c == 5 ? 'Rp.' : '',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                  ],
                )
            else
              for (final item in rows)
                TableRow(
                  children: [
                    _cell('${item.no}', align: TextAlign.center),
                    _cell(item.idPemesanan),
                    _cell(item.jam, align: TextAlign.center),
                    _cell(item.namaKasir),
                    _cell('${item.jumlahPemesanan}', align: TextAlign.center),
                    _cell(
                      CelciousReportExport.formatRupiah(item.totalHarga),
                      align: TextAlign.right,
                      bold: true,
                    ),
                  ],
                ),
            TableRow(
              decoration: const BoxDecoration(color: _subtotalBg),
              children: [
                _cell('Total', align: TextAlign.center, bold: true),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                _cell(
                  emptyZero
                      ? 'Rp.'
                      : CelciousReportExport.formatRupiah(totalAmount),
                  align: emptyZero ? TextAlign.left : TextAlign.right,
                  bold: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _cell(
    String text, {
    TextAlign align = TextAlign.left,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: bold ? _navy : const Color(0xFF1D3247),
          fontSize: 10.5,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
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
      final logoBytes = await CelciousReportExport.loadBrandLogoBytes();
      final bytes = await CelciousReportExport.buildTransactionReportPdf(
        widget.report,
        logoBytes: logoBytes,
      );
      await _saveExportFile(
        name: _safeFileName(widget.judul, widget.report.periodDateText),
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
      final logoBytes = await CelciousReportExport.loadBrandLogoBytes();
      final bytes = CelciousReportExport.buildTransactionReportExcel(
        widget.report,
        logoBytes: logoBytes,
      );
      await _saveExportFile(
        name: _safeFileName(widget.judul, widget.report.periodDateText),
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
          final availableW = (constraints.maxWidth - pad * 2).clamp(260.0, 760.0);

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
                child: availableW < 600
                    ? FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 660,
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


// ============================================================
// KARTU PRATINJAU DOKUMEN LAPORAN KAS LACI (OWNER)
// ============================================================

class _CashDrawerDocumentCard extends StatefulWidget {
  const _CashDrawerDocumentCard({
    required this.report,
    required this.cardWidth,
    required this.onTap,
  });

  final CelciousCashDrawerReportData report;
  final double cardWidth;
  final VoidCallback onTap;

  @override
  State<_CashDrawerDocumentCard> createState() =>
      _CashDrawerDocumentCardState();
}

class _CashDrawerDocumentCardState extends State<_CashDrawerDocumentCard> {
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
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: 660,
                            child: _CashDrawerReportDocument(
                              report: widget.report,
                              thumbnailPreview: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(9, 7, 9, 9),
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
                          color: const Color(0xFF1A5B82),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
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
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Periode ${widget.report.periodDateText}',
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
// KOMPONEN DOKUMEN LAPORAN KAS LACI PER SHIFT (BERLOGO)
// ============================================================

class _CashDrawerReportDocument extends StatelessWidget {
  const _CashDrawerReportDocument({
    required this.report,
    this.thumbnailPreview = false,
  });

  final CelciousCashDrawerReportData report;
  final bool thumbnailPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(30, 26, 30, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  height: 60,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.local_cafe_rounded,
                  fallbackIconSize: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      report.storeName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      report.address,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      report.contactLine,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 74),
            ],
          ),

          const SizedBox(height: 14),
          Container(height: 2, color: _navy),
          const SizedBox(height: 14),

          Text(
            report.reportTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Periode ${report.periodDateText}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF334B61),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          // Ringkasan Kas Awal & Kas Saat Ini
          Row(
            children: [
              Expanded(
                child: _cashSummaryBox(
                  'Kas Awal Shift',
                  CelciousReportExport.formatRupiah(report.openingCash),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _cashSummaryBox(
                  'Kas Saat Ini (Sistem)',
                  CelciousReportExport.formatRupiah(report.currentCash),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _CashDrawerShiftTable(
            title:
                '1. Sift Pagi ( Pukul 11:00 - 17:00 ) : ${report.kasirSiang}',
            rows: thumbnailPreview
                ? report.siangRows.take(5).toList()
                : report.siangRows,
            totalAmount: report.totalSiang,
            placeholderRows: thumbnailPreview ? 4 : 5,
          ),

          const SizedBox(height: 20),

          _CashDrawerShiftTable(
            title:
                '2. Sift Malam ( Pukul 18:00 - 00:00 ) : ${report.kasirMalam}',
            rows: thumbnailPreview
                ? report.malamRows.take(5).toList()
                : report.malamRows,
            totalAmount: report.totalMalam,
            placeholderRows: thumbnailPreview ? 4 : 5,
          ),

          const SizedBox(height: 36),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mengetahui :',
                style: TextStyle(
                  color: _navy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                report.locationDate,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 52),
          Row(
            children: [
              _signatureColumn('(${report.ownerName})', 'Owner'),
              _signatureColumn('(${report.kasirSiang})', 'Kasir Pagi'),
              _signatureColumn('(${report.kasirMalam})', 'Kasir Malam'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cashSummaryBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _subtotalBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC5D7E8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _signatureColumn(String name, String role) {
    return Expanded(
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            role,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashDrawerShiftTable extends StatelessWidget {
  const _CashDrawerShiftTable({
    required this.title,
    required this.rows,
    required this.totalAmount,
    this.placeholderRows = 5,
  });

  final String title;
  final List<CelciousCashDrawerShiftRow> rows;
  final num totalAmount;
  final int placeholderRows;

  @override
  Widget build(BuildContext context) {
    final emptyZero = rows.isEmpty && totalAmount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: _tableBorder, width: 0.9),
          columnWidths: const {
            0: FixedColumnWidth(36),
            1: FixedColumnWidth(76),
            2: FixedColumnWidth(54),
            3: FlexColumnWidth(1.6),
            4: FlexColumnWidth(2.4),
            5: FlexColumnWidth(1.8),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: _navyBar),
              children: [
                for (final label in const [
                  'No',
                  'Tanggal',
                  'Jam',
                  'Nama Kasir',
                  'Keterangan',
                  'Nominal',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            if (rows.isEmpty)
              for (var i = 0; i < placeholderRows; i++)
                TableRow(
                  children: [
                    for (var c = 0; c < 6; c++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 8,
                        ),
                        child: Text(
                          c == 5 ? 'Rp.' : '',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                  ],
                )
            else
              for (final item in rows)
                TableRow(
                  children: [
                    _cell('${item.no}', align: TextAlign.center),
                    _cell(item.tanggal, align: TextAlign.center),
                    _cell(item.jam, align: TextAlign.center),
                    _cell(item.namaKasir),
                    _cell(item.keterangan),
                    _cell(
                      item.nominalText,
                      align: TextAlign.right,
                      bold: true,
                      color: item.jenis == 'keluar'
                          ? const Color(0xFFC0392B)
                          : const Color(0xFF007A51),
                    ),
                  ],
                ),
            TableRow(
              decoration: const BoxDecoration(color: _subtotalBg),
              children: [
                _cell('Total', align: TextAlign.center, bold: true),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                _cell(
                  emptyZero
                      ? 'Rp.'
                      : CelciousReportExport.formatRupiah(totalAmount),
                  align: emptyZero ? TextAlign.left : TextAlign.right,
                  bold: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _cell(
    String text, {
    TextAlign align = TextAlign.left,
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: color ?? (bold ? _navy : const Color(0xFF1D3247)),
          fontSize: 10.3,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ============================================================
// HALAMAN PRATINJAU DOKUMEN LAPORAN KAS LACI (OWNER)
// ============================================================

class LaporanKasLaciPreviewPage extends StatefulWidget {
  const LaporanKasLaciPreviewPage({
    super.key,
    required this.report,
    required this.judul,
    this.onExported,
  });

  final CelciousCashDrawerReportData report;
  final String judul;
  final VoidCallback? onExported;

  @override
  State<LaporanKasLaciPreviewPage> createState() =>
      _LaporanKasLaciPreviewPageState();
}

class _LaporanKasLaciPreviewPageState extends State<LaporanKasLaciPreviewPage> {
  bool _exportingPdf = false;
  bool _exportingExcel = false;

  Future<void> _exportPdf() async {
    if (_exportingPdf) return;
    setState(() => _exportingPdf = true);
    try {
      final logoBytes = await CelciousReportExport.loadBrandLogoBytes();
      final bytes = await CelciousReportExport.buildCashDrawerReportPdf(
        widget.report,
        logoBytes: logoBytes,
      );
      await _saveExportFile(
        name: _safeFileName(widget.judul, widget.report.periodDateText),
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      widget.onExported?.call();
      _snack('Laporan Kas Laci PDF berhasil diunduh.');
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
      final logoBytes = await CelciousReportExport.loadBrandLogoBytes();
      final bytes = CelciousReportExport.buildCashDrawerReportExcel(
        widget.report,
        logoBytes: logoBytes,
      );
      await _saveExportFile(
        name: _safeFileName(widget.judul, widget.report.periodDateText),
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      widget.onExported?.call();
      _snack('Laporan Kas Laci Excel (.xlsx) berhasil diunduh.');
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
          final availableW = (constraints.maxWidth - pad * 2).clamp(260.0, 760.0);

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
                child: availableW < 600
                    ? FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 660,
                          child: _CashDrawerReportDocument(
                            report: widget.report,
                          ),
                        ),
                      )
                    : _CashDrawerReportDocument(report: widget.report),
              ),
            ),
          );
        },
      ),
    );
  }
}
