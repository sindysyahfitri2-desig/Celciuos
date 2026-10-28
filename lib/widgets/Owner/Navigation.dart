import 'package:flutter/material.dart';

// Sesuaikan path ini kalau letak app_branding_logo.dart berbeda.
// (Navigation.dart ada di lib/widgets/Owner/, logo ada di lib/widgets/)
import '../app_branding_logo.dart';

const _ownerNavy = Color(0xFF082640);
const _ownerNavyLight = Color(0xFF0A2E4D);
const _ownerBackground = Color(0xFFDCE9F4);
const _ownerBlue = Color(0xFF4098CE);

class _OwnerDestination {
  const _OwnerDestination(this.title, this.shortTitle, this.icon);

  final String title; // dipakai di sidebar laptop
  final String shortTitle; // dipakai di bottom bar
  final IconData icon;
}

const _destinations = <_OwnerDestination>[
  _OwnerDestination('Dashboard', 'Beranda', Icons.home_outlined),
  _OwnerDestination(
    'Kelola Laporan',
    'Laporan',
    Icons.bar_chart_rounded,
  ),
  _OwnerDestination('Kelola Produk', 'Produk', Icons.inventory_2_outlined),
  _OwnerDestination('Transaksi', 'Transaksi', Icons.receipt_long_outlined),
  _OwnerDestination('Kelola Staf', 'Kelola Staf', Icons.person_outline_rounded),
  _OwnerDestination('Profil', 'Profil', Icons.person_outline_rounded),
];

// ============================================================
// TOP BAR (HEADER) — dipakai di HP, tablet, dan laptop
// ============================================================

class OwnerTopBar extends StatelessWidget {
  const OwnerTopBar({
    super.key,
    required this.ownerName,
    this.showName = false,
    this.onProfil,
    this.onLogout,
    this.onNotifikasi,
  });

  final String ownerName;

  // true di laptop: nama owner ikut tampil di sebelah avatar.
  final bool showName;

  final VoidCallback? onProfil;
  final VoidCallback? onLogout;

  // Kalau null, ikon lonceng tidak ditampilkan.
  final VoidCallback? onNotifikasi;

  @override
  Widget build(BuildContext context) {
    // Header memanjang sampai di belakang status bar (seperti desain).
    final statusBar = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(18, statusBar + 12, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2E4D), Color(0xFF103456)],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: _ownerNavy.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF3979AD),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: const ClipOval(
              child: AppBrandingLogo(fallbackIconSize: 26),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Celcious',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Coffee',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onNotifikasi != null)
            IconButton(
              tooltip: 'Notifikasi',
              onPressed: onNotifikasi,
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          _profileMenu(),
        ],
      ),
    );
  }

  // Avatar + panah kecil; ditekan akan membuka menu Profil / Logout.
  Widget _profileMenu() {
    return PopupMenuButton<int>(
      tooltip: 'Akun',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 0) onProfil?.call();
        if (value == 1) onLogout?.call();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 20, color: _ownerNavy),
              SizedBox(width: 10),
              Text('Profil'),
            ],
          ),
        ),
        if (onLogout != null)
          const PopupMenuItem(
            value: 1,
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('Logout'),
              ],
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showName) ...[
            Text(
              ownerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EEF6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: _ownerNavy, size: 26),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SIDEBAR (LAPTOP)
// ============================================================

class OwnerNavigation extends StatelessWidget {
  const OwnerNavigation({
    super.key,
    required this.selectedIndex,
    required this.ownerName,
    required this.onDestinationSelected,

    // Callback untuk membuka halaman masing-masing menu.
    required this.onDashboard,
    required this.onTransaksi,
    required this.onProduk,
    required this.onKelolaStaf,
    required this.onLaporan,
    required this.onProfil,
    
  });

  final int selectedIndex;
  final String ownerName;

  // Callback utama untuk memperbarui menu yang sedang dipilih.
  final ValueChanged<int> onDestinationSelected;

  // Callback navigasi halaman.
  final VoidCallback onDashboard;
  final VoidCallback onLaporan;
  final VoidCallback onProduk;
  final VoidCallback onTransaksi;
  final VoidCallback onKelolaStaf;
  final VoidCallback onProfil;
  

  // Menentukan halaman tujuan dari menu yang ditekan.
  void _navigateTo(int index) {
    onDestinationSelected(index);

    switch (index) {
      case 0:
        onDashboard();
        break;
      case 1:
        onLaporan();
        break;
      case 2:
        onProduk();
        break;
      case 3:
        onTransaksi();
        break;
      case 4:
        onKelolaStaf();
        break;
        case 5:
        onProfil();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 275,
      color: _ownerNavy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 14),
              itemCount: _destinations.length,
              itemBuilder: (context, index) {
                // Setiap menu masuk bergantian dari kiri.
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 380 + index * 90),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(-24 * (1 - t), 0),
                      child: child,
                    ),
                  ),
                  child: _SidebarItem(
                    destination: _destinations[index],
                    selected: selectedIndex == index,
                    onTap: () => _navigateTo(index),
                  ),
                );
              },
            ),
          ),

          // Informasi akun owner di bagian bawah sidebar.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: _ownerNavyLight,
              border: Border(
                top: BorderSide(color: Colors.white12, width: 1),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white70,
                  child: Icon(Icons.person, color: _ownerNavy, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Owner',
                        style: TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
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

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _OwnerDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final fg = selected ? _ownerNavy : Colors.white70;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 52,
          color: selected
              ? _ownerBackground
              : _hovered
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.transparent,
          child: Row(
            children: [
              // Garis biru di kiri: memanjang saat menu aktif.
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: selected ? 5 : 0,
                color: _ownerBlue,
              ),
              // Isi bergeser sedikit ke kanan saat aktif.
              AnimatedPadding(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(left: selected ? 10 : 15),
                child: AnimatedScale(
                  scale: selected ? 1.12 : 1,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: Icon(widget.destination.icon, color: fg),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                  child: Text(
                    widget.destination.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION (HP & TABLET)
// Bar gelap dengan lekukan melingkar + gelembung biru yang
// meluncur ke menu yang dipilih.
// ============================================================

class OwnerBottomNavigation extends StatelessWidget {
  const OwnerBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.bottomInset,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  // Tinggi area aman bawah (gesture bar). Kalau null, dibaca dari MediaQuery.
  final double? bottomInset;

  // Tinggi bar gelap, dan tinggi gelembung yang menonjol di atas bar.
  static const double barHeight = 62;
  static const double overhang = 26;

  // Tinggi yang harus disisakan di bawah konten halaman.
  static double reservedHeight(double bottomInset) => barHeight + bottomInset;

  @override
  Widget build(BuildContext context) {
    final inset = bottomInset ?? MediaQuery.of(context).padding.bottom;
    final totalHeight = overhang + barHeight + inset;

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        // Di tablet, bar tidak melebar terlalu jauh.
        constraints: const BoxConstraints(maxWidth: 720),
        child: SizedBox(
          height: totalHeight,
          child: LayoutBuilder(
            builder: (context, box) {
              final itemWidth = box.maxWidth / _destinations.length;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: selectedIndex.toDouble()),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, pos, _) {
                  final centerX = (pos + 0.5) * itemWidth;
                  final shown = _destinations[
                      pos.round().clamp(0, _destinations.length - 1)];

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Bar gelap dengan lekukan di bawah gelembung.
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _NotchPainter(
                            centerX: centerX,
                            top: overhang,
                          ),
                        ),
                      ),

                      // Ikon + label semua menu.
                      Positioned(
                        left: 0,
                        right: 0,
                        top: overhang,
                        height: barHeight,
                        child: Row(
                          children: [
                            for (var i = 0; i < _destinations.length; i++)
                              Expanded(
                                child: _BottomItem(
                                  destination: _destinations[i],
                                  selected: selectedIndex == i,
                                  // Makin dekat gelembung, makin pudar.
                                  visibility:
                                      (pos - i).abs().clamp(0.0, 1.0),
                                  onTap: () => onDestinationSelected(i),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Gelembung biru berisi ikon menu aktif.
                      Positioned(
                        left: centerX - 30,
                        top: 0,
                        width: 60,
                        height: 60,
                        child: IgnorePointer(
                          child: _Bubble(destination: shown),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// Menggambar bar gelap berujung membulat, dengan lubang melingkar
// di atas menu yang dipilih.
class _NotchPainter extends CustomPainter {
  _NotchPainter({required this.centerX, required this.top});

  final double centerX;
  final double top;

  static const double _notchRadius = 37;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = Path()
      ..addRRect(
        RRect.fromLTRBAndCorners(
          0,
          top,
          size.width,
          size.height,
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
        ),
      );

    final notch = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(centerX, top + 4),
          radius: _notchRadius,
        ),
      );

    final path = Path.combine(PathOperation.difference, bar, notch);

    // Bayangan lembut ke arah atas.
    canvas.drawPath(
      path.shift(const Offset(0, -3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(path, Paint()..color = _ownerNavy);
  }

  @override
  bool shouldRepaint(_NotchPainter old) =>
      old.centerX != centerX || old.top != top;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.destination});

  final _OwnerDestination destination;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _ownerBlue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(
            color: _ownerBlue.withValues(alpha: 0.50),
            blurRadius: 1400,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(destination.icon, color: Colors.white, size: 25),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              destination.shortTitle,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.destination,
    required this.selected,
    required this.visibility,
    required this.onTap,
  });

  final _OwnerDestination destination;
  final bool selected;

  // 0 = tersembunyi (gelembung ada di atasnya), 1 = tampil penuh.
  final double visibility;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: destination.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: visibility,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(destination.icon, size: 24, color: Colors.white),
              const SizedBox(height: 3),
              Text(
                destination.shortTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}