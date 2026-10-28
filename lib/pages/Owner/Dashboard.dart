import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/app_branding_logo.dart';
import '../../widgets/Owner/Navigation.dart';
import 'KelolaProduk.dart' as owner_products;
import 'Transaksi/Kelola_Transaksi.dart';

const Color ownerNavy = Color(0xFF103456);
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
  const hari = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];
  const bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
    'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  final now = DateTime.now();
  return '${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month - 1]} '
      '${now.year}';
}

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
  final TextEditingController searchController = TextEditingController();

  static const menuTitles = [
    'Dashboard',
    'Kelola Laporan Keuangan',
    'Kelola Produk',
    'Transaksi',
    'Profil',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void selectMenu(int index) {
    if (index < 0 || index >= menuTitles.length) return;
    setState(() => selectedMenu = index);
  }

  // Laptop (>= 1000): sidebar di kiri.
  // Tablet & HP (< 1000): navigasi pindah ke bawah.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        return Scaffold(
          backgroundColor: ownerBackground,
          body: SafeArea(
            // Di mode bawah, safe area bawah ditangani oleh bottom bar.
            bottom: isDesktop,
            child: Column(
              children: [
                _topBar(showOwner: !isDesktop),
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
                          onProfil: () => selectMenu(4),
                        ),
                      Expanded(child: _content()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : BottomNavigation(
                  selectedIndex: selectedMenu,
                  onDestinationSelected: selectMenu,
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
          0 => _DashboardBody(
              namaOwner: widget.namaOwner,
              searchController: searchController,
              onMessage: _showMessage,
            ),
          1 => _ownerSectionContent(),
          2 => const owner_products.ProdukPage(),
          3 => const KelolaTransaksiPage(),
          4 => _ownerSectionContent(),
          _ => _DashboardBody(
              namaOwner: widget.namaOwner,
              searchController: searchController,
              onMessage: _showMessage,
            ),
        },
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _topBar({bool showOwner = false}) {
    return Container(
      height: 46,
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
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF3979AD),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const ClipOval(
              child: AppBrandingLogo(fallbackIconSize: 18),
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

  // ============================================================
  // HALAMAN MENU YANG BELUM DIBUAT
  // ============================================================

  Widget _ownerSectionContent() {
    final title = menuTitles[selectedMenu];

    return Container(
      key: ValueKey('owner-section-$selectedMenu'),
      color: ownerBackground,
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: ownerNavy,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kelola operasional Celcious Coffee.',
              style: TextStyle(color: _mutedText, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _softShadow(),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.dashboard_customize_rounded,
                      size: 45,
                      color: ownerBlue,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: ownerNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Halaman ini tetap menggunakan struktur '
                        'navigasi yang sudah ada.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _mutedText, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  BottomNavigation({required int selectedIndex, required void Function(int index) onDestinationSelected}) {}
}

// ============================================================
// ISI DASHBOARD — animasi masuk berurutan
// ============================================================

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({
    required this.namaOwner,
    required this.searchController,
    required this.onMessage,
  });

  final String namaOwner;
  final TextEditingController searchController;
  final void Function(String message) onMessage;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Hormati pengaturan "kurangi animasi" milik perangkat.
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Potongan waktu dari satu controller supaya elemen muncul bergantian.
  Animation<double> _stage(double begin, double end) {
    return CurveTween(
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    ).animate(_controller);
  }

  // Contoh data. Ganti dengan data dari API saat backend sudah siap.
  static const List<_SummaryData> _summaries = [
    _SummaryData(
      title: 'Total Omzet Penjualan',
      amount: 3500000,
      prefix: 'Rp. ',
      icon: Icons.payments_outlined,
      accent: ownerDarkNavy,
      detail: 'Target harian Rp. 4.000.000',
      progress: 0.875,
    ),
    _SummaryData(
      title: 'Kas Laci & Non Tunai',
      amount: 3000000,
      prefix: 'Rp. ',
      icon: Icons.account_balance_wallet_outlined,
      accent: Color(0xFF1687A7),
      detail: 'Tunai dan pembayaran digital',
      progress: 0.75,
    ),
    _SummaryData(
      title: 'Total Transaksi',
      amount: 100,
      suffix: 'Struk',
      icon: Icons.receipt_long_outlined,
      accent: Color(0xFF159B76),
      detail: 'Transaksi hari ini',
      progress: 0.8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;

        return Container(
          color: ownerBackground,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 14 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Reveal(
                  animation: _stage(0.0, 0.35),
                  child: _greeting(compact),
                ),
                const SizedBox(height: 26),
                LayoutBuilder(
                  builder: (context, box) {
                    final columns = box.maxWidth >= 800
                        ? 3
                        : box.maxWidth >= 460
                            ? 2
                            : 1;

                    const gap = 14.0;
                    final colWidth =
                        (box.maxWidth - gap * (columns - 1)) / columns;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var i = 0; i < _summaries.length; i++)
                          SizedBox(
                            // Di tablet (2 kolom), kartu ganjil terakhir
                            // dibuat selebar penuh agar tidak timpang.
                            width: (columns == 2 &&
                                    i == _summaries.length - 1 &&
                                    _summaries.length.isOdd)
                                ? box.maxWidth
                                : colWidth,
                            child: _Reveal(
                              animation:
                                  _stage(0.08 + i * 0.1, 0.48 + i * 0.1),
                              child: _SummaryCard(
                                data: _summaries[i],
                                animation: _stage(
                                  0.12 + i * 0.1,
                                  0.62 + i * 0.1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                _Reveal(
                  animation: _stage(0.3, 0.7),
                  child: _SalesChartCard(controller: _controller),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _greeting(bool compact) {
    final title = Text(
      'Halo Bos ${widget.namaOwner}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: ownerNavy,
        fontSize: compact ? 22 : 28,
        fontWeight: FontWeight.w900,
        shadows: const [
          Shadow(
            color: Color(0x6689A7B8),
            offset: Offset(1, 2),
            blurRadius: 3,
          ),
        ],
      ),
    );

    final subtitle = Text(
      '${_tanggalHariIni()}. Ringkasan penjualan hari ini.',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: _mutedText, fontSize: 12),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 2),
          subtitle,
          const SizedBox(height: 12),
          SizedBox(height: 36, child: _searchField()),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 2), subtitle],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 200, height: 36, child: _searchField()),
      ],
    );
  }

  Widget _searchField() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: _softShadow(),
      ),
      child: TextField(
        controller: widget.searchController,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            widget.onMessage('Pencarian "$value" belum terhubung ke data.');
          }
        },
        style: const TextStyle(color: ownerNavy, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Cari',
          hintStyle: const TextStyle(color: Color(0xFF7591A7), fontSize: 12),
          prefixIcon: const Icon(
            Icons.search,
            size: 17,
            color: Color(0xFF7591A7),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 32,
          ),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: ownerBlue),
          ),
        ),
      ),
    );
  }
}

// Fade dan geser naik sedikit saat elemen muncul.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 20),
            child: child,
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
    this.prefix = '',
    this.suffix,
  });

  final String title;
  final double amount;
  final String prefix;
  final String? suffix;
  final IconData icon;
  final Color accent;
  final String detail;
  final double progress;
}

class _SummaryCard extends StatefulWidget {
  const _SummaryCard({required this.data, required this.animation});

  final _SummaryData data;
  final Animation<double> animation;

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 118,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _softShadow(lifted: _hovered),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Garis warna di tepi kiri sebagai penanda jenis kartu.
              Container(width: 5, color: data.accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
                  child: AnimatedBuilder(
                    animation: widget.animation,
                    builder: (context, _) {
                      final t = widget.animation.value;
                      return Column(
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
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: data.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  data.icon,
                                  size: 16,
                                  color: data.accent,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Angka berhitung naik dari 0 sampai nilai akhir.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${data.prefix}'
                                  '${_formatNumber(data.amount * t)}',
                                  style: const TextStyle(
                                    color: ownerNavy,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (data.suffix != null) ...[
                                  const SizedBox(width: 5),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      data.suffix!,
                                      style: const TextStyle(
                                        color: ownerNavy,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            data.detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: data.progress * t,
                              minHeight: 4,
                              backgroundColor: const Color(0xFFE6EDF3),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(data.accent),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GRAFIK PENJUALAN PER JAM
// ============================================================

class _SalesChartCard extends StatefulWidget {
  const _SalesChartCard({required this.controller});

  final AnimationController controller;

  @override
  State<_SalesChartCard> createState() => _SalesChartCardState();
}

class _SalesChartCardState extends State<_SalesChartCard> {
  // Contoh data. Nilai 1.0 = jam tersibuk (Rp 642.500).
  static const List<double> values = [
    0.30, 0.44, 0.55, 0.72, 0.51, 1.00, 0.65, 0.37, 0.22,
  ];

  static const List<String> hours = [
    '16:00', '17:00', '18:00', '19:00', '20:00',
    '21:00', '22:00', '23:00', '24:00',
  ];

  static const double _peakAmount = 642500;
  static const int _peakIndex = 5;

  static const double _hourLabelHeight = 24;
  static const double _valueLabelHeight = 24;

  int? _activeIndex;

  Animation<double> _barAnimation(int index) {
    final begin = 0.30 + index * 0.055;
    return CurveTween(
      curve: Interval(begin, begin + 0.26, curve: Curves.easeOutBack),
    ).animate(widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap: di HP chip "Puncak" turun ke bawah, tidak overflow.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            spacing: 8,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Grafik penjualan Celcious',
                    style: TextStyle(
                      color: ownerNavy,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Penjualan per jam hari ini',
                    style: TextStyle(color: _mutedText, fontSize: 10),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF159B76).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Puncak pukul ${hours[_peakIndex]}',
                  style: const TextStyle(
                    color: Color(0xFF0E7B5C),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, box) {
              final chartHeight = box.maxWidth < 500
                  ? 200.0
                  : box.maxWidth < 900
                      ? 235.0
                      : 290.0;
              final maxBarHeight =
                  chartHeight - _hourLabelHeight - _valueLabelHeight;

              // Setiap batang minimal 46px; kalau layar kurang, bisa digeser.
              const minSlot = 46.0;
              final slot = math.max(box.maxWidth / values.length, minSlot);
              final contentWidth = slot * values.length;

              final chart = SizedBox(
                width: contentWidth,
                height: chartHeight,
                child: Stack(
                  children: [
                    // Garis bantu horizontal.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: _valueLabelHeight,
                      bottom: _hourLabelHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          5,
                          (_) => Container(
                            height: 1,
                            color: const Color(0xFFE3EBF2),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(values.length, (index) {
                          return Expanded(child: _bar(index, maxBarHeight));
                        }),
                      ),
                    ),
                  ],
                ),
              );

              if (contentWidth > box.maxWidth) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: chart,
                );
              }
              return chart;
            },
          ),
        ],
      ),
    );
  }

  Widget _bar(int index, double maxBarHeight) {
    final isPeak = index == _peakIndex;
    final isActive = _activeIndex == index;
    final animation = _barAnimation(index);
    final amount = values[index] * _peakAmount;

    return MouseRegion(
      onEnter: (_) => setState(() => _activeIndex = index),
      onExit: (_) => setState(() => _activeIndex = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Di layar sentuh, ketuk batang untuk melihat nilainya.
        onTap: () => setState(
          () => _activeIndex = _activeIndex == index ? null : index,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                height: _valueLabelHeight,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: (isPeak || isActive) ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ownerNavy,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Rp ${_formatNumber(amount)}',
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final t = animation.value.clamp(0.0, 1.15);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: maxBarHeight * values[index] * t,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isPeak
                            ? const [
                                Color(0xFF36CBA0),
                                Color(0xFF2B9FC0),
                                ownerNavy,
                              ]
                            : isActive
                                ? const [
                                    Color(0xFF5BB0E3),
                                    Color(0xFF2F6A9C),
                                  ]
                                : const [
                                    Color(0xFF3E91C8),
                                    Color(0xFF365D88),
                                  ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ownerNavy.withValues(
                            alpha: isActive || isPeak ? 0.30 : 0.14,
                          ),
                          blurRadius: isActive ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(
                height: _hourLabelHeight,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hours[index],
                      style: TextStyle(
                        color: isActive ? ownerNavy : Colors.black54,
                        fontSize: 9,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}