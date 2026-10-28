import 'package:flutter/material.dart';

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
  _OwnerDestination('Dashboard', 'Dashboard', Icons.dashboard_outlined),
  _OwnerDestination(
    'Kelola Laporan Keuangan',
    'Laporan',
    Icons.bar_chart_rounded,
  ),
  _OwnerDestination('Kelola Produk', 'Produk', Icons.local_cafe_outlined),
  _OwnerDestination('Transaksi', 'Transaksi', Icons.receipt_long_outlined),
  _OwnerDestination('Profil', 'Profil', Icons.settings_outlined),
];

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
    required this.onLaporan,
    required this.onProduk,
    required this.onTransaksi,
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
              padding: const EdgeInsets.only(top: 6),
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
              // Isi bergeser sedikit ke kanan saat hover / aktif.
              AnimatedPadding(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(
                  left: selected ? 10 : (_hovered ? 15 : 15),
                  right: 0,
                ),
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
// ============================================================

class OwnerBottomNavigation extends StatelessWidget {
  const OwnerBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const double _barHeight = 66;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ownerNavy,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            // Di tablet, menu tidak melebar terlalu jauh.
            constraints: const BoxConstraints(maxWidth: 640),
            child: SizedBox(
              height: _barHeight,
              child: LayoutBuilder(
                builder: (context, box) {
                  final itemWidth = box.maxWidth / _destinations.length;
                  final pillWidth = (itemWidth - 14).clamp(44.0, 74.0);

                  return Stack(
                    children: [
                      // Pil biru yang meluncur ke menu yang dipilih.
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutBack,
                        left: selectedIndex * itemWidth +
                            (itemWidth - pillWidth) / 2,
                        top: 8,
                        width: pillWidth,
                        height: 30,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _ownerBlue,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _ownerBlue.withValues(alpha: 0.45),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < _destinations.length; i++)
                            Expanded(
                              child: _BottomItem(
                                destination: _destinations[i],
                                selected: selectedIndex == i,
                                onTap: () => onDestinationSelected(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _OwnerDestination destination;
  final bool selected;
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
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              child: Center(
                // Ikon membesar dan berubah warna saat dipilih.
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    end: selected ? Colors.white : Colors.white70,
                  ),
                  duration: const Duration(milliseconds: 250),
                  builder: (context, color, _) => AnimatedScale(
                    scale: selected ? 1.18 : 1,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    child: Icon(destination.icon, size: 22, color: color),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text(
                destination.shortTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}