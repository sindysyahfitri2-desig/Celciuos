import 'package:flutter/material.dart';

import '../pages/LaporanPage.dart';
import '../pages/ProdukPage.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/Transaksi.dart';

// Navigasi bersama untuk membuka layar tiap area aplikasi.
// ============================================================
// WARNA APLIKASI
// ============================================================

const appPageBackground = Color(0xffdce9f4);
const appNavy = Color(0xff103456);

// ============================================================
// DAFTAR MENU
// ============================================================

const _navigationItems = <_NavigationItem>[
  _NavigationItem('Kasir', Icons.point_of_sale_rounded),
  _NavigationItem('Laporan keuangan', Icons.bar_chart_rounded),
  _NavigationItem('Produk', Icons.local_drink_outlined),
  _NavigationItem('Transaksi', Icons.account_balance_wallet_rounded),
];

// ============================================================
// SIDEBAR DESKTOP
// ============================================================

class AppNavigation extends StatelessWidget {
  const AppNavigation({
    super.key,
    required this.selectedMenu,
    required this.namaKasir,
    required this.onMenuSelected,
    this.onLogout,
    this.shiftKe = 1,
    this.fotoUrl,
    this.onAksiShift,
  });

  final int selectedMenu;
  final String namaKasir;
  final ValueChanged<int> onMenuSelected;
  final VoidCallback? onLogout;
  final int shiftKe;
  final String? fotoUrl;
  final VoidCallback? onAksiShift;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 275,
      color: const Color(0xff082640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 0),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = selectedMenu == index;

                return Padding(
                  padding: const EdgeInsets.only(left: 0, top: 0, bottom: 1),

                  child: Material(
                    color: isSelected ? appPageBackground : Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(
                        left: 15,
                        right: 20,
                      ),
                      leading: Icon(
                        item.icon,
                        color: isSelected
                            ? const Color(0xff082640)
                            : Colors.white70,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xff082640)
                              : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () => onMenuSelected(index),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xff0a2e4d),
              border: Border(top: BorderSide(color: Colors.white12, width: 1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white70,
                  backgroundImage: fotoUrl != null
                      ? NetworkImage(
                          fotoUrl!,
                          headers: const {'ngrok-skip-browser-warning': 'true'},
                        )
                      : null,
                  child: fotoUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 22,
                          color: Color(0xff082640),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        namaKasir.isNotEmpty ? namaKasir : 'Nama Kasir',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Shift $shiftKe',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onAksiShift != null)
                  IconButton(
                    tooltip: shiftKe == 1 ? 'Ganti shift' : 'Logout',
                    icon: Icon(
                      shiftKe == 1
                          ? Icons.switch_account_outlined
                          : Icons.logout,
                      color: Colors.white,
                    ),
                    onPressed: onAksiShift,
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
// SHELL UTAMA: SIDEBAR + HALAMAN
// ============================================================

class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({
    super.key,
    required this.namaKasir,
    required this.headerBuilder,
    required this.cashierBuilder,
    this.onLogout,
    this.shiftKe = 1, // baru
    this.fotoUrl, // baru
    this.onAksiShift, // baru
  });

  final String namaKasir;
  final WidgetBuilder headerBuilder;
  final WidgetBuilder cashierBuilder;
  final VoidCallback? onLogout;
  final int shiftKe; // baru
  final String? fotoUrl; // baru
  final VoidCallback? onAksiShift; // baru

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  int selectedMenu = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _selectMenu(int index) {
    setState(() {
      selectedMenu = index;
    });
  }

  @override
  Widget _sidebar() {
    return AppNavigation(
      selectedMenu: selectedMenu,
      namaKasir: widget.namaKasir,
      shiftKe: widget.shiftKe,
      fotoUrl: widget.fotoUrl,
      onAksiShift: widget.onAksiShift,
      onMenuSelected: _selectMenu,
      onLogout: widget.onLogout,
    );
  }

  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 950;

        return Scaffold(
          key: _scaffoldKey,
          drawer: isDesktop
              ? null
              : Drawer(
                  child: SafeArea(
                    child: AppNavigation(
                      selectedMenu: selectedMenu,
                      namaKasir: widget.namaKasir,
                      shiftKe: widget.shiftKe,
                      fotoUrl: widget.fotoUrl,
                      onAksiShift: widget.onAksiShift == null
                          ? null
                          : () {
                              _scaffoldKey.currentState?.closeDrawer();
                              widget.onAksiShift!();
                            },
                      onMenuSelected: (index) {
                        _selectMenu(index);
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                      onLogout: widget.onLogout,
                    ),
                  ),
                ),
          body: Column(
            children: [
              widget.headerBuilder(context),
              Expanded(
                child: isDesktop
                    ? Row(
                        children: [
                          _sidebar(),
                          Expanded(child: _animatedContent()),
                        ],
                      )
                    : _animatedContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _animatedContent() {
    return ColoredBox(
      color: appPageBackground,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(
          key: ValueKey<int>(selectedMenu),
          child: _selectedPage(),
        ),
      ),
    );
  }

  Widget _selectedPage() {
    switch (selectedMenu) {
      case 0:
        return widget.cashierBuilder(context);

      case 1:
        return LaporanPage(namaKasir: widget.namaKasir);

      case 2:
        return const ProdukPage();

      case 3:
        return PesananBelumSelesaiPage(
          onKeLaporan: () {
            _selectMenu(1);
          },
        );

      default:
        return widget.cashierBuilder(context);
    }
  }
}

// ============================================================
// BOTTOM NAVIGATION UNTUK LAYAR KECIL
// ============================================================

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedMenu,
    required this.onMenuSelected,
  });

  final int selectedMenu;
  final ValueChanged<int> onMenuSelected;

  static const labels = ['Kasir', 'Laporan', 'Produk', 'Transaksi', 'Kas'];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedMenu,
      onTap: onMenuSelected,
      type: BottomNavigationBarType.fixed,
      backgroundColor: appPageBackground,
      elevation: 0,
      selectedItemColor: const Color(0xff082640),
      unselectedItemColor: Colors.black54,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      selectedLabelStyle: const TextStyle(fontSize: 10),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      items: [
        for (var index = 0; index < _navigationItems.length; index++)
          BottomNavigationBarItem(
            icon: Icon(_navigationItems[index].icon),
            label: labels[index],
          ),
      ],
    );
  }
}

// ============================================================
// MODEL ITEM NAVIGASI
// ============================================================

class _NavigationItem {
  const _NavigationItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
