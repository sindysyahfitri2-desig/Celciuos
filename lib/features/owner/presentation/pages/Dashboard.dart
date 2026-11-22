import 'package:flutter/material.dart';

import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaProduk.dart'
    as owner_products;
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaStaf.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/Transaksi/Kelola_Transaksi.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/stok/manajemen_stok_page.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/widgets/Navigation.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/PengaturanPage.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';
import 'package:kasir_celcious_coffe/data/dashboard_service.dart';
import 'package:kasir_celcious_coffe/data/owner_profile_store.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import '../../../reports/application/report_service.dart' show ReportService;
import 'KelolaLaporan.dart';

// ============================================================
// WARNA DAN HELPER
// ============================================================

const Color ownerNavy = Color(0xFF082640);
const Color ownerDarkNavy = Color(0xFF082640);
const Color ownerBackground = Color(0xFFDCE9F4);
const Color ownerBlue = Color(0xFF4098CE);
const Color _mutedText = Color(0xFF667B8D);

String _formatNumber(num value) {
  return value.round().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
}

List<BoxShadow> _softShadow({bool lifted = false}) => [
  BoxShadow(
    color: ownerNavy.withValues(alpha: lifted ? 0.18 : 0.10),
    blurRadius: lifted ? 22 : 14,
    offset: Offset(0, lifted ? 9 : 5),
  ),
];

// ============================================================
// DASHBOARD OWNER
// ============================================================

class DashboardOwner extends StatefulWidget {
  const DashboardOwner({super.key, this.namaOwner = 'Daniel', this.onLogout});

  final String namaOwner;
  final VoidCallback? onLogout;

  @override
  State<DashboardOwner> createState() => _DashboardOwnerState();
}

class _DashboardOwnerState extends State<DashboardOwner> {
  int selectedMenu = 0;
  bool _openProfileOnPengaturan = false;
  int _profileRequestId = 0;

  static const menuTitles = [
    'Dashboard',
    'Kelola Laporan',
    'Kelola Produk',
    'Manajemen Stok',
    'Transaksi',
    'Kelola Staf',
    'Pengaturan',
  ];

  @override
  void initState() {
    super.initState();
    OwnerProfileStore.initialize(fallbackName: widget.namaOwner);
    OwnerProfileStore.ownerName.addListener(_onOwnerProfileChanged);
    OwnerProfileStore.photoBytes.addListener(_onOwnerProfileChanged);
    OwnerProfileStore.photoUrl.addListener(_onOwnerProfileChanged);
  }

  @override
  void dispose() {
    OwnerProfileStore.ownerName.removeListener(_onOwnerProfileChanged);
    OwnerProfileStore.photoBytes.removeListener(_onOwnerProfileChanged);
    OwnerProfileStore.photoUrl.removeListener(_onOwnerProfileChanged);
    super.dispose();
  }

  void _onOwnerProfileChanged() {
    if (mounted) setState(() {});
  }

  String get _currentOwnerName {
    final stored = OwnerProfileStore.ownerName.value.trim();
    return stored.isNotEmpty ? stored : widget.namaOwner;
  }

  void selectMenu(int index) {
    if (index < 0 || index >= menuTitles.length) return;
    setState(() {
      selectedMenu = index;
      if (index != 6) {
        _openProfileOnPengaturan = false;
      }
    });
  }

  void _openOwnerProfileSettings({bool closeDrawer = false}) {
    if (closeDrawer) {
      Navigator.of(context).pop();
    }
    setState(() {
      selectedMenu = 6;
      _openProfileOnPengaturan = true;
      _profileRequestId++;
    });
  }

  void _pilihMenuDariDrawer(int index) {
    Navigator.of(context).pop();
    selectMenu(index);
  }

  Widget _buildLaporan() {
    final snapshot = ReportService.load(cashierFallback: 'Kasir');

    final rows = snapshot.transactionRows
        .where((transaction) => transaction['status']?.toLowerCase() == 'lunas')
        .map((transaction) {
          final nominal =
              num.tryParse(
                (transaction['total'] ?? '0')
                    .replaceAll('.', '')
                    .replaceAll(',', ''),
              ) ??
              0;

          final tanggal = transaction['tanggal'] ?? '-';
          final jam = transaction['jam'] ?? '';
          final id = transaction['id'] ?? '-';
          final kasir = transaction['kasir'] ?? 'Kasir';
          final metode = transaction['pembayaran'] ?? '-';

          return LaporanPreviewRow(
            tanggal: '$tanggal $jam'.trim(),
            keterangan: '$id - $kasir',
            metode: metode,
            nominal: nominal,
          );
        })
        .toList();

    final bebanItems = snapshot.drawerRows
        .where((entry) => entry['jenis']?.toLowerCase() == 'keluar')
        .map((entry) {
          final rawNominal = (entry['nominal'] ?? '0')
              .replaceAll('+', '')
              .replaceAll('-', '')
              .replaceAll('.', '')
              .replaceAll(',', '');
          final nominal = num.tryParse(rawNominal) ?? 0;
          final ket = (entry['keterangan'] ?? '').trim();
          return LaporanNominalItem(
            label: ket.isEmpty ? 'Beban Operasional' : ket,
            nominal: nominal,
          );
        })
        .toList();

    final cashierName = snapshot.transactionRows.isNotEmpty
        ? (snapshot.transactionRows.first['kasir'] ?? 'Kasir')
        : (TransactionStore.shiftCashier.value.trim().isNotEmpty
            ? TransactionStore.shiftCashier.value.trim()
            : 'Kasir');

    final now = DateTime.now();
    const bulan = [
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

    return KelolaLaporanContent(
      judulLaporan: 'Laporan Laba Rugi & Keuangan Harian',
      tanggalLaporan: '${now.day} ${bulan[now.month - 1]} ${now.year}',
      previewData: LaporanPreviewData(
        rows: rows,
        bebanItems: bebanItems,
        namaKasir: cashierName,
        namaOwner: _currentOwnerName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        return Scaffold(
          backgroundColor: ownerBackground,
          drawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: ownerNavy,
                  child: SafeArea(
                    child: OwnerNavigation(
                      selectedIndex: selectedMenu,
                      ownerName: _currentOwnerName,
                      onDestinationSelected: _pilihMenuDariDrawer,
                      onDashboard: () => _pilihMenuDariDrawer(0),
                      onLaporan: () => _pilihMenuDariDrawer(1),
                      onProduk: () => _pilihMenuDariDrawer(2),
                      onStok: () => _pilihMenuDariDrawer(3),
                      onTransaksi: () => _pilihMenuDariDrawer(4),
                      onKelolaStaf: () => _pilihMenuDariDrawer(5),
                      onPengaturan: () => _pilihMenuDariDrawer(6),
                      onProfileTap: () =>
                          _openOwnerProfileSettings(closeDrawer: true),
                      onLogout: widget.onLogout,
                    ),
                  ),
                ),
          body: SafeArea(
            child: Column(
              children: [
                _topBar(isDesktop: isDesktop),
                Expanded(
                  child: Row(
                    children: [
                      if (isDesktop)
                        OwnerNavigation(
                          selectedIndex: selectedMenu,
                          ownerName: _currentOwnerName,
                          onDestinationSelected: selectMenu,
                          onDashboard: () => selectMenu(0),
                          onLaporan: () => selectMenu(1),
                          onProduk: () => selectMenu(2),
                          onStok: () => selectMenu(3),
                          onTransaksi: () => selectMenu(4),
                          onKelolaStaf: () => selectMenu(5),
                          onPengaturan: () => selectMenu(6),
                          onProfileTap: () => _openOwnerProfileSettings(),
                          onLogout: widget.onLogout,
                        ),
                      Expanded(child: _content()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _content() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.topLeft,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(selectedMenu),
        child: switch (selectedMenu) {
          0 => _DashboardBody(namaOwner: _currentOwnerName),
          1 => _buildLaporan(),
          2 => const owner_products.ProdukPage(),
          3 => const ManajemenStokPage(),
          4 => KelolaTransaksiPage(
            pakaiDataContoh: false,
            initialTab: 0,
            onNavigasiLaporan: () => selectMenu(1),
          ),
          5 => const KontrolStafPage(),
          6 => PengaturanPage(
            initialOpenProfile: _openProfileOnPengaturan,
            profileRequestId: _profileRequestId,
          ),
          _ => _DashboardBody(namaOwner: _currentOwnerName),
        },
      ),
    );
  }

  Widget _topBar({required bool isDesktop}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ownerNavy,
        boxShadow: [
          BoxShadow(
            color: ownerNavy.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Buka menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
              ),
            ),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF3979AD),
              shape: BoxShape.circle,
            ),
            child: const ClipOval(child: AppBrandingLogo(fallbackIconSize: 18)),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Celcious Coffee',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Dashboard Owner',
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            visualDensity: VisualDensity.compact,
            onPressed: () => _showMessage('Belum ada notifikasi baru.'),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Pengaturan Profil Owner',
            child: InkWell(
              onTap: () => _openOwnerProfileSettings(),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EEF6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: OwnerProfileStore.photoBytes.value != null
                    ? Image.memory(
                        OwnerProfileStore.photoBytes.value!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person,
                          color: ownerNavy,
                          size: 19,
                        ),
                      )
                    : (OwnerProfileStore.photoUrl.value != null &&
                            OwnerProfileStore.photoUrl.value!.isNotEmpty)
                        ? Image.network(
                            OwnerProfileStore.photoUrl.value!,
                            fit: BoxFit.cover,
                            headers: const {
                              'ngrok-skip-browser-warning': 'true',
                            },
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person,
                              color: ownerNavy,
                              size: 19,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: ownerNavy,
                            size: 19,
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// ============================================================
// DASHBOARD BODY
// ============================================================

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({required this.namaOwner});

  final String namaOwner;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody>
    with TickerProviderStateMixin {
  late final AnimationController _chartController;
  late final AnimationController _entryController;
  late final Future<Map<String, dynamic>> _future;

  late final Animation<double> _headerAnimation;
  late final List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );

    _headerAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
    );

    _cardAnimations = List.generate(
      3,
      (index) => CurvedAnimation(
        parent: _entryController,
        curve: Interval(
          0.12 + (index * 0.13),
          0.72 + (index * 0.09),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _future = _muat();
    _entryController.forward();
  }

  @override
  void dispose() {
    _chartController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _muat() async {
    final result = await DashboardService().ambilDashboard();
    if (mounted) _chartController.forward();
    return result;
  }

  double _num(dynamic value) => double.tryParse('$value') ?? 0;

  Future<void> _refresh() async {
    setState(() {
      _entryController
        ..reset()
        ..forward();
    });
    // Data dashboard dimuat ulang melalui Future baru.
    // RefreshIndicator akan selesai setelah request ini.
    await DashboardService().ambilDashboard();
    if (!mounted) return;
    setState(() {});
  }

  Widget _animatedCard(int index, Widget child) {
    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, _) {
        final progress = _cardAnimations[index].value;
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: ownerNavy),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Terjadi kesalahan:\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ownerNavy),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snap.data ?? {};
        final ringkasan = (data['ringkasan'] as Map<String, dynamic>?) ?? {};
        final metode = (data['distribusi_metode'] as List?) ?? [];

        final omzet = _num(ringkasan['omzet_hari_ini']);
        final totalTrx = _num(ringkasan['total_transaksi']);

        final totalNonTunai = metode.fold<double>(
          0,
          (sum, item) => sum + _num(item['total_nominal']),
        );

        final kasLaci = _num(
          ringkasan['kas_laci'] ??
              ringkasan['total_tunai'] ??
              (omzet - totalNonTunai),
        );

        final rincianMetode = <String>[];
        if (kasLaci > 0) {
          rincianMetode.add('Tunai Rp. ${_formatNumber(kasLaci)}');
        }
        for (final item in metode) {
          final nama =
              (item['metode'] ?? item['metode_pembayaran'] ?? 'Non Tunai')
                  .toString();
          rincianMetode.add(
            '$nama Rp. ${_formatNumber(_num(item['total_nominal']))}',
          );
        }

        final detailMetode = rincianMetode.isEmpty
            ? 'Tunai Rp. ${_formatNumber(kasLaci)} • '
                  'Non Tunai Rp. ${_formatNumber(totalNonTunai)}'
            : rincianMetode.join(' • ');

        final summaries = [
          _SummaryData(
            title: 'Total Omset Penjualan',
            amount: omzet,
            icon: Icons.payments_outlined,
            accent: ownerNavy,
            detail: 'Target Harian (Rp. 4.000.000)',
            progress: (omzet / 4000000).clamp(0.0, 1.0),
          ),
          _SummaryData(
            title: 'Kas Laci & Non Tunai',
            amount: kasLaci + totalNonTunai > 0
                ? kasLaci + totalNonTunai
                : omzet,
            icon: Icons.account_balance_wallet_outlined,
            accent: const Color(0xFF1687A7),
            detail: detailMetode,
            progress: omzet > 0 ? (totalNonTunai / omzet).clamp(0.0, 1.0) : 0,
          ),
          _SummaryData(
            title: 'Total Transaksi',
            amount: totalTrx,
            suffix: 'Struk',
            icon: Icons.receipt_long_outlined,
            accent: const Color(0xFF159B76),
            detail: 'Transaksi hari ini',
            progress: 1,
          ),
        ];

        final grafik = ((data['grafik_per_jam'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isPhone = width < 600;
            final isTablet = width >= 600 && width < 1000;

            final horizontalPadding = isPhone
                ? 14.0
                : isTablet
                ? 20.0
                : 24.0;

            return Container(
              color: ownerBackground,
              child: RefreshIndicator(
                color: ownerNavy,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isPhone ? 18 : 22,
                    horizontalPadding,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _headerAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-0.07, 0),
                            end: Offset.zero,
                          ).animate(_headerAnimation),
                          child: Text(
                            'Halo Bos ${widget.namaOwner}',
                            style: TextStyle(
                              color: const Color(0xFF07506D),
                              fontSize: isPhone
                                  ? 23
                                  : isTablet
                                  ? 27
                                  : 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              height: 1.1,
                              shadows: const [
                                Shadow(
                                  color: Color(0x6689A7B8),
                                  offset: Offset(1, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isPhone ? 22 : 34),

                      // 3 kartu selalu horizontal di HP, Tablet, dan Laptop
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < summaries.length; i++) ...[
                            if (i > 0)
                              SizedBox(
                                width: isPhone ? 7 : (isTablet ? 10 : 14),
                              ),
                            Expanded(
                              child: _animatedCard(
                                i,
                                _SummaryCard(
                                  data: summaries[i],
                                  compact: isPhone,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      SizedBox(height: isPhone ? 20 : 28),

                      FadeTransition(
                        opacity: _cardAnimations[2],
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(_cardAnimations[2]),
                          child: _SalesChartCard(
                            controller: _chartController,
                            data: grafik,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// DATA SUMMARY
// ============================================================

class _SummaryData {
  const _SummaryData({
    required this.title,
    required this.amount,
    required this.icon,
    required this.accent,
    required this.detail,
    required this.progress,
    this.suffix,
  });

  final String title;
  final double amount;
  final String? suffix;
  final IconData icon;
  final Color accent;
  final String detail;
  final double progress;
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, this.compact = false});

  final _SummaryData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTiny = compact || width < 145;
        final scale = (width / 270).clamp(0.75, 1.15);
        final isNarrow = width < 230;
        final cardHeight = isTiny
            ? 126.0
            : (data.suffix == null ? (isNarrow ? 146.0 : 154.0) : 146.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: cardHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTiny ? 11 : 14),
            border: Border.all(
              color: const Color(0xFFC5DBEE),
              width: 1,
            ),
            boxShadow: _softShadow(),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: isTiny ? (width * 0.55) : 105 * scale,
                  height: isTiny ? 6 : 8,
                  decoration: BoxDecoration(
                    color: data.accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: isTiny
                    ? const EdgeInsets.fromLTRB(8, 11, 8, 8)
                    : EdgeInsets.fromLTRB(13 * scale, 15, 13 * scale, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            maxLines: isTiny ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ownerNavy,
                              fontSize: isTiny ? 8.8 : 11 * scale,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                        if (!isTiny) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3FB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(data.icon, size: 15, color: ownerNavy),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: isTiny ? 6 : 8),
                    if (data.suffix != null)
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatNumber(data.amount),
                                  style: TextStyle(
                                    color: ownerNavy,
                                    fontSize: isTiny ? 24 : 35 * scale,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 3,
                                    bottom: 3,
                                  ),
                                  child: Text(
                                    data.suffix!,
                                    style: TextStyle(
                                      color: ownerNavy,
                                      fontSize: isTiny ? 8.5 : 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Rp. ${_formatNumber(data.amount)}',
                          style: TextStyle(
                            color: ownerNavy,
                            fontSize: isTiny ? 15 : 27 * scale,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    if (data.suffix == null) ...[
                      const Spacer(),
                      if (data.title == 'Kas Laci & Non Tunai')
                        ...data.detail
                            .split(' • ')
                            .where((line) => line.isNotEmpty)
                            .take(isTiny ? 1 : 2)
                            .map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: data.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        line,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: ownerNavy,
                                          fontSize: isTiny ? 7.5 : 8.5 * scale,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                      else ...[
                        Text(
                          data.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ownerNavy,
                            fontSize: isTiny ? 7.5 : 8.5 * scale,
                          ),
                        ),
                        SizedBox(height: isTiny ? 4 : 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: data.progress,
                            minHeight: isTiny ? 3.5 : 4,
                            backgroundColor: const Color(0xFFE5EAF0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              data.accent,
                            ),
                          ),
                        ),
                      ],
                      if (data.title == 'Total Omset Penjualan' && !isTiny)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Sisa Rp. ${_formatNumber((4000000 - data.amount).clamp(0, 4000000))}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _mutedText,
                                    fontSize: 7.5 * scale,
                                  ),
                                ),
                              ),
                              Text(
                                '${(data.progress * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: ownerNavy,
                                  fontSize: 7.5 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// SALES CHART
// ============================================================

class _SalesChartCard extends StatefulWidget {
  const _SalesChartCard({required this.controller, required this.data});

  final AnimationController controller;
  final List<Map<String, dynamic>> data;

  @override
  State<_SalesChartCard> createState() => _SalesChartCardState();
}

class _SalesChartCardState extends State<_SalesChartCard> {
  int? activeIndex;

  double _num(dynamic value) => double.tryParse('$value') ?? 0;

  List<Map<String, dynamic>> get chartData {
    final first = widget.data.indexWhere((e) => _num(e['total']) > 0);
    if (first == -1) return const [];

    final last = widget.data.lastIndexWhere((e) => _num(e['total']) > 0);
    return widget.data.sublist(first, last + 1);
  }

  List<double> get totals => chartData.map((e) => _num(e['total'])).toList();

  List<String> get hours => chartData.map((e) {
    final value = '${e['jam']}';
    return value.length >= 2 ? value.substring(0, 2) : value;
  }).toList();

  double get maxTotal => totals.fold<double>(0, (a, b) => a > b ? a : b);

  int get peakIndex => maxTotal > 0 ? totals.indexOf(maxTotal) : -1;

  double get average {
    final active = totals.where((e) => e > 0).toList();
    if (active.isEmpty) return 0;
    return active.reduce((a, b) => a + b) / active.length;
  }

  @override
  Widget build(BuildContext context) {
    final n = totals.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 600;
        final chartHeight = isPhone ? 220.0 : 280.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isPhone ? 13 : 20,
            16,
            isPhone ? 13 : 20,
            14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _softShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 21,
                    decoration: BoxDecoration(
                      color: ownerBlue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'GRAFIK PENJUALAN CELCIOUS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF315A80),
                        fontSize: isPhone ? 12 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (n == 0 || maxTotal == 0)
                const SizedBox(
                  height: 160,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 38,
                          color: Color(0xFF9AAFC0),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada penjualan hari ini.',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: chartHeight,
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final barMaxHeight = chartHeight * 0.70;
                      final slot = box.maxWidth / n;
                      final tooltipWidth = (box.maxWidth * 0.48).clamp(
                        125.0,
                        205.0,
                      );
                      final tooltipLeft = peakIndex < 0
                          ? 0.0
                          : ((peakIndex + 0.5) * slot - tooltipWidth / 2).clamp(
                              0.0,
                              box.maxWidth - tooltipWidth,
                            );

                      return Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 24 + barMaxHeight * (average / maxTotal),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFF9BAFC0),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F4FA),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'Rata-rata: Rp. ${_formatNumber(average)}',
                                    style: const TextStyle(
                                      color: Color(0xFF1687C1),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned.fill(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(
                                n,
                                (index) => Expanded(
                                  child: _buildBar(index, chartHeight),
                                ),
                              ),
                            ),
                          ),
                          if (peakIndex >= 0)
                            Positioned(
                              top: 0,
                              left: tooltipLeft,
                              width: tooltipWidth,
                              child: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: ownerNavy,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jam Sibuk Tertinggi (${hours[peakIndex]}:00)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${_formatNumber(maxTotal)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(int index, double chartHeight) {
    final isPeak = index == peakIndex;
    final isActive = activeIndex == index;
    final amount = totals[index];
    final ratio = maxTotal > 0 ? amount / maxTotal : 0.0;
    final barMaxHeight = chartHeight * 0.70;

    return MouseRegion(
      onEnter: (_) => setState(() => activeIndex = index),
      onExit: (_) => setState(() => activeIndex = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            activeIndex = activeIndex == index ? null : index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedBuilder(
                    animation: widget.controller,
                    builder: (context, child) {
                      final progress = Curves.easeOutCubic.transform(
                        widget.controller.value,
                      );

                      return Container(
                        height: barMaxHeight * ratio * progress,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isPeak
                                ? const [
                                    Color(0xFF35CBA0),
                                    Color(0xFF2B9FC0),
                                    Color(0xFF082640),
                                  ]
                                : const [Color(0xFF3D6997), Color(0xFF365D88)],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hours[index],
                maxLines: 1,
                style: TextStyle(
                  color: isActive || isPeak ? ownerNavy : Colors.black54,
                  fontSize: 8,
                  fontWeight: isActive || isPeak
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (isActive)
                Text(
                  _formatNumber(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ownerNavy,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ]
            ,
          ),
        ),
      ),
    );
  }
}
