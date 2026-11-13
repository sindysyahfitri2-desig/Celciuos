import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaProduk.dart'
    as owner_products;
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaStaf.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/Transaksi/Kelola_Transaksi.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/widgets/Navigation.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/PengaturanPage.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';
import 'KelolaLaporan.dart';

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

  // PERBAIKAN: method kosong "BottomNavigation(...) {}" yang dulu ada di
  // sini sudah dihapus.
}

// ============================================================
// ISI DASHBOARD — animasi masuk berurutan
// ============================================================

// ============================================================
// ISI DASHBOARD
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const List<_SummaryData> _summaries = [
    _SummaryData(
      title: 'Total Omset Penjualan',
      amount: 3500000,
      icon: Icons.payments_outlined,
      accent: Color(0xFF082640),
      detail: 'Target Harian (Rp. 4.000.000)',
      progress: 0.875,
    ),
    _SummaryData(
      title: 'Kas Laci & Non Tunai',
      amount: 3000000,
      icon: Icons.account_balance_wallet_outlined,
      accent: Color(0xFF1687A7),
      detail: 'Tunai Rp. 1.500.000  •  QRIS Rp. 1.500.000',
      progress: 0.75,
    ),
    _SummaryData(
      title: 'Total Transaksi',
      amount: 100,
      suffix: 'Struk',
      icon: Icons.receipt_long_outlined,
      accent: Color(0xFF159B76),
      detail: 'Transaksi hari ini',
      progress: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                        for (final data in _summaries)
                          SizedBox(
                            width: cardWidth,
                            child: _SummaryCard(data: data),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // GRAFIK PENJUALAN
                _SalesChartCard(controller: _controller),
              ],
            ),
          ),
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
                      child: Icon(
                        data.icon,
                        size: 11,
                        color: ownerNavy,
                      ),
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
                              style: TextStyle(
                                color: ownerNavy,
                                fontSize: 7,
                              ),
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
                    style: const TextStyle(
                      color: ownerNavy,
                      fontSize: 6,
                    ),
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

                if (data.amount == 3500000)
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '87.5%',
                      style: TextStyle(
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
  const _SalesChartCard({required this.controller});

  final AnimationController controller;

  @override
  State<_SalesChartCard> createState() => _SalesChartCardState();
}

class _SalesChartCardState extends State<_SalesChartCard> {
  static const List<double> values = [
    0.30,
    0.44,
    0.55,
    0.72,
    0.51,
    1.00,
    0.65,
    0.37,
    0.22,
  ];

  static const List<String> hours = [
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
    '23:00',
    '24:00',
  ];

  static const double peakAmount = 642500;
  static const int peakIndex = 5;

  int? activeIndex;

  @override
  Widget build(BuildContext context) {
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

          LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = constraints.maxWidth < 450 ? 175.0 : 205.0;

              return SizedBox(
                height: chartHeight,
                width: double.infinity,
                child: Stack(
                  children: [
                    // GARIS TARGET RATA-RATA
                    Positioned(
                      left: 0,
                      right: 0,
                      top: chartHeight * 0.60,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Color(0xFF8BA2B8),
                                    width: 0.7,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            color: const Color(0xFFE5F4FA),
                            child: const Text(
                              'Rata-rata Target: Rp. 350.000',
                              style: TextStyle(
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
                        children: List.generate(values.length, (index) {
                          return Expanded(
                            child: _buildBar(index, chartHeight),
                          );
                        }),
                      ),
                    ),

                    // TOOLTIP PUNCAK
                    Positioned(
                      top: 0,
                      left: constraints.maxWidth * 0.48,
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
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '● Jam Sibuk Tertinggi (21:00)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 6,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Rp 642.500',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '25 Struk | Best Order: Aren Latte (8 Cup)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 5,
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

    final amount = values[index] * peakAmount;
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
          padding: const EdgeInsets.symmetric(horizontal: 5),
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
                        height: barMaxHeight * values[index] * progress,
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
                  color: isActive || index == peakIndex
                      ? ownerNavy
                      : Colors.black54,
                  fontSize: 7,
                  fontWeight: isActive || index == peakIndex
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),

              if (isActive)
                Text(
                  'Rp ${_formatNumber(amount)}',
                  maxLines: 1,
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
