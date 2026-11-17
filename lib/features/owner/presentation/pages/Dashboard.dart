
import 'package:flutter/material.dart';

import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaProduk.dart'
    as owner_products;
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaStaf.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/Transaksi/Kelola_Transaksi.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/widgets/Navigation.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/PengaturanPage.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';
import 'package:kasir_celcious_coffe/data/dashboard_service.dart';
import 'package:kasir_celcious_coffe/data/report_service.dart';

import '../../../reports/application/report_service.dart' show ReportService;
import 'KelolaLaporan.dart';

// ============================================================
// WARNA
// ============================================================

const Color ownerNavy = Color(0xFF082640);
const Color ownerDarkNavy = Color(0xFF082640);
const Color ownerBackground = Color(0xFFDCE9F4);
const Color ownerBlue = Color(0xFF4098CE);

const Color _mutedText = Color(0xFF667B8D);

List<BoxShadow> _softShadow({bool lifted = false}) => [
  BoxShadow(
    color: ownerDarkNavy.withValues(alpha: lifted ? 0.20 : 0.10),
    blurRadius: lifted ? 26 : 16,
    offset: Offset(0, lifted ? 12 : 6),
  ),
  BoxShadow(
    color: ownerDarkNavy.withValues(alpha: 0.05),
    blurRadius: 3,
    offset: const Offset(0, 1),
  ),
];

String _formatNumber(num value) {
  return value.round().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
}

String _tanggalHariIni() {
  const hari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

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

  final now = DateTime.now();

  return '${hari[now.weekday - 1]}, ${now.day} '
      '${bulan[now.month - 1]} ${now.year}';
}

// ============================================================
// DASHBOARD OWNER
// ============================================================

class DashboardOwner extends StatefulWidget {
  const DashboardOwner({
    super.key,
    this.namaOwner = 'Daniel',
    this.onLogout,
  });

  final String namaOwner;
  final VoidCallback? onLogout;

  @override
  State<DashboardOwner> createState() => _DashboardOwnerState();
}

class _DashboardOwnerState extends State<DashboardOwner> {
  int selectedMenu = 0;

  static const menuTitles = [
    'Dashboard',
    'Kelola Laporan',
    'Kelola Produk',
    'Transaksi',
    'Kelola Staf',
    'Pengaturan',
  ];

  void selectMenu(int index) {
    if (index < 0 || index >= menuTitles.length) return;

    setState(() => selectedMenu = index);
  }

  void _pilihMenuDariDrawer(int index) {
    Navigator.of(context).pop();
    selectMenu(index);
  }

  // ============================================================
  // DATA LAPORAN DARI REPORT SERVICE
  // ============================================================

  Widget _buildLaporan() {
    final snapshot = ReportService.load(
      cashierFallback: 'Kasir',
    );

    final rows = snapshot.transactionRows
        .where(
          (transaction) =>
              transaction['status']?.toLowerCase() == 'lunas',
        )
        .map((transaction) {
          final nominal = num.tryParse(
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

    final jumlahHari = DateTime(
      now.year,
      now.month + 1,
      0,
    ).day;

    return KelolaLaporanContent(
      judulLaporan: 'Laporan Transaksi',
      tanggalLaporan:
          '1–$jumlahHari ${bulan[now.month - 1]} ${now.year}',
      previewData: LaporanPreviewData(
        rows: rows,
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
                  child: OwnerNavigation(
                    selectedIndex: selectedMenu,
                    ownerName: widget.namaOwner,
                    onDestinationSelected: _pilihMenuDariDrawer,
                    onDashboard: () {},
                    onLaporan: () {},
                    onProduk: () {},
                    onTransaksi: () {},
                    onKelolaStaf: () {},
                    onPengaturan: () {},
                    onLogout: widget.onLogout,
                  ),
                ),
          body: SafeArea(
            child: Column(
              children: [
                _topBar(
                  showOwner: !isDesktop,
                  isDesktop: isDesktop,
                ),
                Expanded(
                  child: Row(
                    children: [
                      if (isDesktop)
                        OwnerNavigation(
                          selectedIndex: selectedMenu,
                          ownerName: widget.namaOwner,
                          onDestinationSelected: selectMenu,
                          onDashboard: () => selectMenu(0),
                          onLaporan: () => selectMenu(1),
                          onProduk: () => selectMenu(2),
                          onTransaksi: () => selectMenu(3),
                          onKelolaStaf: () => selectMenu(4),
                          onPengaturan: () => selectMenu(5),
                        ),
                      Expanded(
                        child: _content(),
                      ),
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

  // ============================================================
  // CONTENT NAVIGATION
  // ============================================================

  Widget _content() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(selectedMenu),
        child: switch (selectedMenu) {
          0 => _DashboardBody(
              namaOwner: widget.namaOwner,
            ),
          1 => _buildLaporan(),
          2 => const owner_products.ProdukPage(),
          3 => const KelolaTransaksiPage(
              pakaiDataContoh: false,
            ),
          4 => const KontrolStafPage(),
          5 => const PengaturanPage(),
          _ => _DashboardBody(
              namaOwner: widget.namaOwner,
            ),
        },
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _topBar({
    bool showOwner = false,
    required bool isDesktop,
  }) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ownerDarkNavy, ownerNavy],
        ),
        boxShadow: [
          BoxShadow(
            color: ownerDarkNavy.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Buka menu',
                onPressed: Scaffold.of(context).openDrawer,
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF3979AD),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white24,
                width: 1,
              ),
            ),
            child: const ClipOval(
              child: AppBrandingLogo(
                fallbackIconSize: 18,
              ),
            ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          if (showOwner)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.white70,
                    child: Icon(
                      Icons.person,
                      color: ownerDarkNavy,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.namaOwner,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            tooltip: 'Notifikasi',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              _showMessage('Belum ada notifikasi baru.');
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Logout',
              visualDensity: VisualDensity.compact,
              onPressed: widget.onLogout,
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================
// DASHBOARD BODY
// ============================================================

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({
    required this.namaOwner,
  });

  final String namaOwner;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _future = _muat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _muat() {
    return DashboardService().ambilDashboard();
  }

  double _num(dynamic value) {
    return double.tryParse('$value') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              color: ownerNavy,
            ),
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
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Terjadi kesalahan:\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ownerNavy),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _future = _muat();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snap.data ?? {};

        final ringkasan =
            (data['ringkasan'] as Map<String, dynamic>?) ?? {};

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

        String detailMetode = '';

        if (metode.isNotEmpty) {
          final rincian = <String>[];

          if (kasLaci > 0) {
            rincian.add(
              'Tunai Rp. ${_formatNumber(kasLaci)}',
            );
          }

          for (final item in metode) {
            final nama =
                (item['metode'] ??
                        item['metode_pembayaran'] ??
                        'Non Tunai')
                    .toString();

            rincian.add(
              '$nama Rp. ${_formatNumber(_num(item['total_nominal']))}',
            );
          }

          detailMetode = rincian.join(' • ');
        } else {
          detailMetode =
              'Tunai Rp. ${_formatNumber(kasLaci)} • '
              'Non Tunai Rp. ${_formatNumber(totalNonTunai)}';
        }

        final summaries = [
          _SummaryData(
            title: 'Total Omset Penjualan',
            amount: omzet,
            icon: Icons.payments_outlined,
            accent: const Color(0xFF082640),
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
            progress: omzet > 0
                ? (totalNonTunai / omzet).clamp(0.0, 1.0)
                : 0,
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

            return Container(
              color: ownerBackground,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  isPhone
                      ? 12
                      : isTablet
                          ? 18
                          : 22,
                  isPhone ? 12 : 18,
                  isPhone
                      ? 12
                      : isTablet
                          ? 18
                          : 22,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo Bos ${widget.namaOwner}',
                      style: TextStyle(
                        color: const Color(0xFF07506D),
                        fontSize: isPhone ? 23 : 30,
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

                    // KARTU DINAIKKAN
                    SizedBox(
                      height: isPhone
                          ? 18
                          : isTablet
                              ? 35
                              : 42,
                    ),

                    // TIGA KARTU
                    if (isPhone)
                      SizedBox(
                        height: 138,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: summaries.length,
                          separatorBuilder: (_, _) {
                            return const SizedBox(width: 10);
                          },
                          itemBuilder: (context, index) {
                            return SizedBox(
                              width: 215,
                              child: _SummaryCard(
                                data: summaries[index],
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < summaries.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryCard(
                                data: summaries[i],
                              ),
                            ),
                          ],
                        ],
                      ),

                    SizedBox(height: isPhone ? 22 : 30),

                    _SalesChartCard(
                      controller: _controller,
                      data: grafik,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ======================================================
// DATA KARTU
// ======================================================

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

// ======================================================
// SUMMARY CARD
// ======================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.data,
  });

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 215).clamp(0.76, 1.12);
        final height = 138 * scale;

        return Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: ownerNavy.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(1, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 94 * scale,
                  height: 10 * scale,
                  decoration: BoxDecoration(
                    color: data.accent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6 * scale),
                      bottomRight: Radius.circular(9 * scale),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12 * scale,
                  16 * scale,
                  12 * scale,
                  10 * scale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ownerNavy,
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          width: 23 * scale,
                          height: 23 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0F5),
                            borderRadius: BorderRadius.circular(4 * scale),
                          ),
                          child: Icon(
                            data.icon,
                            size: 15 * scale,
                            color: ownerNavy,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * scale),
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
                                    fontSize: 34 * scale,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 4 * scale,
                                    left: 3 * scale,
                                  ),
                                  child: Text(
                                    data.suffix!,
                                    style: TextStyle(
                                      color: ownerNavy,
                                      fontSize: 8 * scale,
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
                            fontSize: 28 * scale,
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
                            .map(
                              (line) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: 2 * scale,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 5 * scale,
                                      height: 5 * scale,
                                      decoration: BoxDecoration(
                                        color: data.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 5 * scale),
                                    Expanded(
                                      child: Text(
                                        line,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: ownerNavy,
                                          fontSize: 8 * scale,
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
                            fontSize: 8 * scale,
                          ),
                        ),
                        SizedBox(height: 5 * scale),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: data.progress,
                            minHeight: 3 * scale,
                            backgroundColor: const Color(0xFFE5EAF0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              data.accent,
                            ),
                          ),
                        ),
                      ],
                      if (data.title == 'Total Omset Penjualan')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sisa Rp. ${_formatNumber((4000000 - data.amount).clamp(0, 4000000))}',
                              style: TextStyle(
                                color: _mutedText,
                                fontSize: 7 * scale,
                              ),
                            ),
                            Text(
                              '${(data.progress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: ownerNavy,
                                fontSize: 7 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

// ======================================================
// SALES CHART
// ======================================================

class _SalesChartCard extends StatefulWidget {
  const _SalesChartCard({
    required this.controller,
    required this.data,
  });

  final AnimationController controller;
  final List<Map<String, dynamic>> data;

  @override
  State<_SalesChartCard> createState() => _SalesChartCardState();
}

class _SalesChartCardState extends State<_SalesChartCard> {
  int? activeIndex;

  double _num(dynamic value) {
    return double.tryParse('$value') ?? 0;
  }

  List<Map<String, dynamic>> get chartData {
    final firstActiveHour = widget.data.indexWhere(
      (entry) => _num(entry['total']) > 0,
    );

    if (firstActiveHour == -1) return const [];

    final lastActiveHour = widget.data.lastIndexWhere(
      (entry) => _num(entry['total']) > 0,
    );

    return widget.data.sublist(
      firstActiveHour,
      lastActiveHour + 1,
    );
  }

  List<double> get totals {
    return chartData.map((e) => _num(e['total'])).toList();
  }

  List<String> get hours {
    return chartData.map((e) {
      final jam = '${e['jam']}';
      return jam.length >= 2 ? jam.substring(0, 2) : jam;
    }).toList();
  }

  double get maxTotal {
    return totals.fold<double>(
      0,
      (a, b) => a > b ? a : b,
    );
  }

  int get peakIndex {
    return maxTotal > 0 ? totals.indexOf(maxTotal) : -1;
  }

  double get average {
    final aktif = totals.where((e) => e > 0).toList();

    if (aktif.isEmpty) return 0;

    return aktif.reduce((a, b) => a + b) / aktif.length;
  }

  @override
  Widget build(BuildContext context) {
    final n = totals.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 600;
        final chartHeight = isPhone ? 205.0 : 260.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isPhone ? 12 : 20,
            14,
            isPhone ? 12 : 20,
            12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: ownerNavy.withValues(alpha: 0.20),
                blurRadius: 8,
                offset: const Offset(1, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GRAFIK PENJUALAN CELCIOUS',
                style: TextStyle(
                  color: const Color(0xFF315A80),
                  fontSize: isPhone ? 13 : 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (n == 0 || maxTotal == 0)
                const SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      'Belum ada penjualan hari ini.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: chartHeight,
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final barMaxHeight = chartHeight * 0.76;
                      final slot = box.maxWidth / n;

                      final tooltipWidth = (box.maxWidth * 0.40).clamp(
                        110.0,
                        190.0,
                      );

                      final tooltipLeft =
                          ((peakIndex + 0.5) * slot - tooltipWidth / 2)
                              .clamp(
                        0.0,
                        box.maxWidth - tooltipWidth,
                      );

                      return Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 20 +
                                barMaxHeight * (average / maxTotal),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFF8BA2B8),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  color: const Color(0xFFE5F4FA),
                                  child: Text(
                                    'Rata-rata: Rp. ${_formatNumber(average)}',
                                    style: const TextStyle(
                                      color: Color(0xFF1687C1),
                                      fontSize: 7,
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
                          Positioned(
                            top: 0,
                            left: tooltipLeft,
                            width: tooltipWidth,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ownerNavy,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.20,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🔴 Jam Sibuk Tertinggi (${hours[peakIndex]}:00)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
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
    final barMaxHeight = chartHeight * 0.76;

    return MouseRegion(
      onEnter: (_) {
        setState(() => activeIndex = index);
      },
      onExit: (_) {
        setState(() => activeIndex = null);
      },
      child: GestureDetector(
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
                                : const [
                                    Color(0xFF3D6997),
                                    Color(0xFF365D88),
                                  ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                hours[index],
                style: TextStyle(
                  color: isActive || isPeak
                      ? ownerNavy
                      : Colors.black54,
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
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    color: ownerNavy,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
