import 'package:flutter/material.dart';

import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaProduk.dart'
    as owner_products;
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaStaf.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/Transaksi/Kelola_Transaksi.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/widgets/Navigation.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/PengaturanPage.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';
import 'KelolaLaporan.dart';
import 'package:kasir_celcious_coffe/data/dashboard_service.dart';

// TODO: Sesuaikan path import DashboardService dengan struktur folder proyek Anda:
// import 'package:kasir_celcious_coffe/features/owner/data/services/dashboard_service.dart';

// Area Owner; komponen bersama berada di lib/widgets dan data di lib/data.
const Color ownerNavy = Color(0xFF082640);
const Color ownerDarkNavy = Color(0xFF082640);
const Color ownerBackground = Color(0xFFDCE9F4);
const Color ownerBlue = Color(0xFF4098CE);

const Color _mutedText = Color(0xFF667B8D);

// Bayangan lembut berwarna navy, dipakai bersama oleh semua kartu.
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
  const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
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
  return '${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month - 1]} '
      '${now.year}';
}

class DashboardOwner extends StatefulWidget {
  const DashboardOwner({super.key, this.namaOwner = 'Daniel', this.onLogout});

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
                _topBar(showOwner: !isDesktop, isDesktop: isDesktop),
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

  // Isi halaman dengan animasi pindah menu.
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
          0 => _DashboardBody(namaOwner: widget.namaOwner),
          1 => const KelolaLaporanContent(),
          2 => const owner_products.ProdukPage(),
          3 => const KelolaTransaksiPage(pakaiDataContoh: false),
          4 => const KontrolStafPage(),
          5 => const PengaturanPage(),
          _ => _DashboardBody(namaOwner: widget.namaOwner),
        },
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _topBar({bool showOwner = false, required bool isDesktop}) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [ownerDarkNavy, ownerNavy]),
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
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
              ),
            ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF3979AD),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 9),
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
                    child: Icon(Icons.person, color: ownerDarkNavy, size: 14),
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
            onPressed: () => _showMessage('Belum ada notifikasi baru.'),
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
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// ============================================================
// ISI DASHBOARD (DENGAN INTEGRASI API SERVICE)
// ============================================================

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({required this.namaOwner});

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

  Future<Map<String, dynamic>> _muat() async {
    // Ganti dengan cara Anda mengambil token autentikasi (misal: SharedPreferences / SecureStorage)
    final token = '171|yEAZ1Mekd8tjy4YJNGQ5smacMjwE9q3SUdEwg0l123d3b55f';
    return DashboardService().ambilDashboard(token);
  }

  // Jaga-jaga: MySQL / PHP kadang mengirim angka SUM sebagai string
  double _num(dynamic v) => double.tryParse('$v') ?? 0;

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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Terjadi kesalahan:\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ownerNavy, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ownerNavy,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => setState(() => _future = _muat()),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Coba lagi'),
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
          (s, m) => s + _num(m['total_nominal']),
        );

        // Ambil nominal kas tunai jika tersedia dari backend atau hitung selisihnya
        final kasLaci = _num(
          ringkasan['kas_laci'] ??
              ringkasan['total_tunai'] ??
              (omzet - totalNonTunai),
        );

        // Format rincian metode pembayaran untuk detail kartu kedua
        String detailMetode = '';
        if (metode.isNotEmpty) {
          final rincianList = <String>[];
          if (kasLaci > 0) {
            rincianList.add('Tunai Rp. ${_formatNumber(kasLaci)}');
          }
          for (final m in metode) {
            final nama = (m['metode'] ?? m['metode_pembayaran'] ?? 'Non Tunai')
                .toString();
            final nom = _formatNumber(_num(m['total_nominal']));
            rincianList.add('$nama Rp. $nom');
          }
          detailMetode = rincianList.join('  •  ');
        } else {
          detailMetode =
              'Tunai Rp. ${_formatNumber(kasLaci)}  •  Non Tunai Rp. ${_formatNumber(totalNonTunai)}';
        }

        // Tiga Kartu Ringkasan Dinamis
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
            amount: (kasLaci + totalNonTunai > 0)
                ? (kasLaci + totalNonTunai)
                : omzet,
            icon: Icons.account_balance_wallet_outlined,
            accent: const Color(0xFF1687A7),
            detail: detailMetode,
            progress: omzet > 0
                ? (totalNonTunai / omzet).clamp(0.0, 1.0)
                : 0.75,
          ),
          _SummaryData(
            title: 'Total Transaksi',
            amount: totalTrx,
            suffix: 'Struk',
            icon: Icons.receipt_long_outlined,
            accent: const Color(0xFF159B76),
            detail: 'Transaksi hari ini',
            progress: 1.0,
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final compact = width < 600;

            return Container(
              color: ownerBackground,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 20,
                  compact ? 10 : 8,
                  compact ? 14 : 20,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SAPAAN OWNER
                    Text(
                      'Halo Bos ${widget.namaOwner}',
                      style: TextStyle(
                        color: const Color(0xFF07506D),
                        fontSize: compact ? 22 : 25,
                        fontWeight: FontWeight.w900,
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

                    SizedBox(height: compact ? 22 : 72),

                    // TIGA KARTU RINGKASAN
                    LayoutBuilder(
                      builder: (context, box) {
                        const gap = 8.0;
                        final columns = box.maxWidth < 480 ? 1 : 3;
                        final cardWidth =
                            (box.maxWidth - gap * (columns - 1)) / columns;

                        return Wrap(
                          spacing: gap,
                          runSpacing: 10,
                          children: [
                            for (final s in summaries)
                              SizedBox(
                                width: cardWidth,
                                child: _SummaryCard(data: s),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // GRAFIK PENJUALAN
                    _SalesChartCard(
                      controller: _controller,
                      data: (data['grafik_per_jam'] as List)
                          .cast<Map<String, dynamic>>(),
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

// ============================================================
// KARTU RINGKASAN
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    final isTransaction = data.suffix != null;

    return Container(
      height: 108,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: ownerNavy.withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // AKSEN WARNA BAGIAN ATAS KARTU
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 70,
              height: 8,
              decoration: BoxDecoration(
                color: data.accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(9, 13, 9, 7),
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
                        style: const TextStyle(
                          color: ownerNavy,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF0F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(data.icon, size: 11, color: ownerNavy),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (isTransaction)
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatNumber(data.amount),
                            style: const TextStyle(
                              color: ownerNavy,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4, left: 3),
                            child: Text(
                              'Struk',
                              style: TextStyle(color: ownerNavy, fontSize: 7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    'Rp. ${_formatNumber(data.amount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ownerNavy,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                if (!isTransaction) const Spacer(),

                if (!isTransaction)
                  Text(
                    data.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ownerNavy, fontSize: 6),
                  ),

                const SizedBox(height: 4),

                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: data.progress,
                    minHeight: 2,
                    backgroundColor: const Color(0xFFE5EAF0),
                    valueColor: AlwaysStoppedAnimation<Color>(data.accent),
                  ),
                ),

                // Persentase dinamis untuk target omset penjualan
                if (data.title == 'Total Omset Penjualan')
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(data.progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: ownerNavy,
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GRAFIK PENJUALAN
// ============================================================

class _SalesChartCard extends StatefulWidget {
  const _SalesChartCard({required this.controller, required this.data});

  final AnimationController controller;
  final List<Map<String, dynamic>> data; // dari data['grafik_per_jam']

  @override
  State<_SalesChartCard> createState() => _SalesChartCardState();
}

class _SalesChartCardState extends State<_SalesChartCard> {
  int? activeIndex;

  double _num(dynamic v) => double.tryParse('$v') ?? 0;

  List<double> get totals => widget.data.map((e) => _num(e['total'])).toList();

  List<String> get hours =>
      widget.data.map((e) => '${e['jam']}'.substring(0, 2)).toList();

  double get maxTotal => totals.fold<double>(0, (a, b) => a > b ? a : b);

  int get peakIndex => maxTotal > 0 ? totals.indexOf(maxTotal) : -1;

  double get average {
    final aktif = totals.where((t) => t > 0).toList();
    if (aktif.isEmpty) return 0;
    return aktif.reduce((a, b) => a + b) / aktif.length;
  }

  @override
  Widget build(BuildContext context) {
    final n = totals.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: ownerNavy.withValues(alpha: 0.22),
            blurRadius: 7,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GRAFIK PENJUALAN CELCIOUS',
            style: TextStyle(
              color: Color(0xFF315A80),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (n == 0 || maxTotal == 0)
            const SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Belum ada penjualan hari ini.',
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxWidth < 450 ? 175.0 : 205.0;
                final barMaxHeight = chartHeight * 0.78;
                final slot = constraints.maxWidth / n;
                final tooltipLeft = ((peakIndex + 0.5) * slot - 55).clamp(
                  0.0,
                  constraints.maxWidth - 110,
                );

                return SizedBox(
                  height: chartHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // GARIS RATA-RATA (dari data asli)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 17 + barMaxHeight * (average / maxTotal),
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
                                horizontal: 5,
                                vertical: 2,
                              ),
                              color: const Color(0xFFE5F4FA),
                              child: Text(
                                'Rata-rata: Rp. ${_formatNumber(average)}',
                                style: const TextStyle(
                                  color: Color(0xFF1687C1),
                                  fontSize: 6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // BATANG GRAFIK
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(n, (index) {
                            return Expanded(
                              child: _buildBar(index, chartHeight),
                            );
                          }),
                        ),
                      ),

                      // TOOLTIP PUNCAK (dari data asli)
                      Positioned(
                        top: 0,
                        left: tooltipLeft,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: ownerNavy,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '● Jam Sibuk Tertinggi (${hours[peakIndex]}:00)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rp ${_formatNumber(maxTotal)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBar(int index, double chartHeight) {
    final isPeak = index == peakIndex;
    final isActive = activeIndex == index;

    final amount = totals[index];
    final ratio = maxTotal > 0 ? amount / maxTotal : 0.0;
    final barMaxHeight = chartHeight * 0.78;

    return MouseRegion(
      onEnter: (_) => setState(() => activeIndex = index),
      onExit: (_) => setState(() => activeIndex = null),
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
                                : const [Color(0xFF3D6997), Color(0xFF365D88)],
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
                  color: isActive || isPeak ? ownerNavy : Colors.black54,
                  fontSize: 7,
                  fontWeight: isActive || isPeak
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (isActive)
                Text(
                  _formatNumber(amount),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    color: ownerNavy,
                    fontSize: 6,
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
