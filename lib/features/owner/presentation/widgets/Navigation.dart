
import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/data/owner_profile_store.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';

const _ownerNavy = Color(0xFF082640);
const _ownerNavyLight = Color(0xFF0A2E4D);
const _ownerBackground = Color(0xFFDCE9F4);
const _ownerBlue = Color(0xFF4098CE);

class _OwnerDestination {
  const _OwnerDestination(this.title, this.shortTitle, this.icon);

  final String title;
  final String shortTitle;
  final IconData icon;
}

const _destinations = <_OwnerDestination>[
  _OwnerDestination('Dashboard', 'Beranda', Icons.home_outlined),
  _OwnerDestination('Kelola Laporan', 'Laporan', Icons.bar_chart_rounded),
  _OwnerDestination('Kelola Produk', 'Produk', Icons.inventory_2_outlined),
  _OwnerDestination('Transaksi', 'Transaksi', Icons.receipt_long_outlined),
  _OwnerDestination('Kelola Staf', 'Staf', Icons.person_outline_rounded),
  _OwnerDestination(
    'Modal & Keuntungan',
    'Modal',
    Icons.account_balance_wallet_outlined,
  ),
  _OwnerDestination('Pengaturan', 'Atur', Icons.settings_outlined),
];

// ============================================================
// TOP BAR
// ============================================================

class OwnerTopBar extends StatelessWidget {
  const OwnerTopBar({
    super.key,
    required this.ownerName,
    this.showName = false,
    this.onLogout,
    this.onNotifikasi,
    this.onProfileTap,
  });

  final String ownerName;
  final bool showName;
  final VoidCallback? onLogout;
  final VoidCallback? onNotifikasi;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
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
          bottom: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: _ownerNavy.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF3979AD),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: const ClipOval(
              child: AppBrandingLogo(fallbackIconSize: 24),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Celcious Coffee',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (showName)
                  Text(
                    ownerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  )
                else
                  const Text(
                    'Dashboard Owner',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
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
                size: 23,
              ),
            ),
          Tooltip(
            message: 'Pengaturan Profil',
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EEF6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _OwnerAvatarImage(iconSize: 23),
              ),
            ),
          ),
          if (onLogout != null)
            IconButton(
              tooltip: 'Logout',
              onPressed: onLogout,
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.white70,
                size: 19,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SIDEBAR LAPTOP
// ============================================================

class OwnerNavigation extends StatelessWidget {
  const OwnerNavigation({
    super.key,
    required this.selectedIndex,
    required this.ownerName,
    required this.onDestinationSelected,
    required this.onDashboard,
    required this.onTransaksi,
    required this.onProduk,
    required this.onKelolaStaf,
    required this.onLaporan,
    required this.onPengaturan,
    this.onProfileTap,
    this.onLogout,
  });

  final int selectedIndex;
  final String ownerName;
  final ValueChanged<int> onDestinationSelected;

  // Callback dipertahankan agar pemanggilan lama tidak rusak.
  final VoidCallback onDashboard;
  final VoidCallback onLaporan;
  final VoidCallback onProduk;
  final VoidCallback onTransaksi;
  final VoidCallback onKelolaStaf;
  final VoidCallback onPengaturan;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;

  // Navigasi hanya dijalankan satu kali.
  void _navigateTo(int index) {
    onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 275,
      child: Container(
        color: _ownerNavy,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  return _SidebarItem(
                    destination: _destinations[index],
                    selected: selectedIndex == index,
                    onTap: () => _navigateTo(index),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                color: _ownerNavyLight,
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: 'Buka Pengaturan Profil',
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: Colors.white.withValues(alpha: 0.10),
                          onTap: onProfileTap ?? onPengaturan,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 5,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white70,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white30,
                                      width: 1.5,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: const _OwnerAvatarImage(iconSize: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ValueListenableBuilder<String>(
                                    valueListenable:
                                        OwnerProfileStore.ownerName,
                                    builder: (context, storedName, _) {
                                      final displayName =
                                          storedName.trim().isNotEmpty
                                              ? storedName
                                              : ownerName;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            'Owner • Profil',
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (onLogout != null)
                    IconButton(
                      tooltip: 'Logout',
                      onPressed: onLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white70,
                        size: 19,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SIDEBAR ITEM
// ============================================================

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
    final fg = selected ? _ownerNavy : Colors.white;

    return SizedBox(
      width: double.infinity,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: selected
                  ? _ownerBackground
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.transparent,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Row(
              children: [
                Icon(widget.destination.icon, color: fg, size: 21),
                const SizedBox(width: 13),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    child: Text(
                      widget.destination.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
// BOTTOM NAVIGATION HP & TABLET
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
  final double? bottomInset;

  static const double barHeight = 62;
  static const double overhang = 26;

  static double reservedHeight(double bottomInset) {
    return overhang + barHeight + bottomInset;
  }

  @override
  Widget build(BuildContext context) {
    final inset = bottomInset ?? MediaQuery.of(context).padding.bottom;
    final totalHeight = overhang + barHeight + inset;

    return SizedBox(
      width: double.infinity,
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
                pos.round().clamp(0, _destinations.length - 1)
              ];

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _NotchPainter(
                        centerX: centerX,
                        top: overhang,
                      ),
                    ),
                  ),
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
                              visibility: (pos - i).abs().clamp(0.0, 1.0),
                              onTap: () => onDestinationSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ),
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
    );
  }
}

// ============================================================
// NOTCH PAINTER
// ============================================================

class _NotchPainter extends CustomPainter {
  _NotchPainter({
    required this.centerX,
    required this.top,
  });

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
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
        ),
      );

    final notch = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(centerX, top + 4),
          radius: _notchRadius,
        ),
      );

    final path = Path.combine(
      PathOperation.difference,
      bar,
      notch,
    );

    canvas.drawPath(
      path.shift(const Offset(0, -2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          7,
        ),
    );

    canvas.drawPath(path, Paint()..color = _ownerNavy);
  }

  @override
  bool shouldRepaint(_NotchPainter old) {
    return old.centerX != centerX || old.top != top;
  }
}

// ============================================================
// BUBBLE MENU AKTIF
// ============================================================

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
            color: _ownerBlue.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 4),
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

// ============================================================
// BOTTOM ITEM
// ============================================================

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.destination,
    required this.selected,
    required this.visibility,
    required this.onTap,
  });

  final _OwnerDestination destination;
  final bool selected;
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
              Icon(
                destination.icon,
                size: 24,
                color: Colors.white,
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  destination.shortTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
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

class _OwnerAvatarImage extends StatelessWidget {
  const _OwnerAvatarImage({this.iconSize = 20});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: OwnerProfileStore.photoBytes,
      builder: (context, bytes, _) {
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Icon(
              Icons.person,
              color: _ownerNavy,
              size: iconSize,
            ),
          );
        }
        return ValueListenableBuilder<String?>(
          valueListenable: OwnerProfileStore.photoUrl,
          builder: (context, url, _) {
            if (url != null && url.isNotEmpty) {
              return Image.network(
                url,
                fit: BoxFit.cover,
                headers: const {'ngrok-skip-browser-warning': 'true'},
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person,
                  color: _ownerNavy,
                  size: iconSize,
                ),
              );
            }
            return Icon(
              Icons.person,
              color: _ownerNavy,
              size: iconSize,
            );
          },
        );
      },
    );
  }
}
