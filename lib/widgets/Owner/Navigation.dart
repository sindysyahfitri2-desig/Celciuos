
import 'package:flutter/material.dart';

const _ownerNavy = Color(0xFF082640);
const _ownerBackground = Color(0xFFDCE9F4);

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

  static const _destinations = <_OwnerDestination>[
    _OwnerDestination('Dashboard', Icons.dashboard_outlined),
    _OwnerDestination(
      'Kelola Laporan Keuangan',
      Icons.bar_chart_rounded,
    ),
    _OwnerDestination('Kelola Produk', Icons.local_cafe_outlined),
    _OwnerDestination('Transaksi', Icons.receipt_long_outlined),
    _OwnerDestination('Profil', Icons.settings_outlined),
  ];

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
              padding: EdgeInsets.zero,
              itemCount: _destinations.length,
              itemBuilder: (context, index) {
                final destination = _destinations[index];
                final selected = selectedIndex == index;

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: selected
                        ? _ownerBackground
                        : Colors.transparent,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(
                      left: 15,
                      right: 20,
                    ),
                    leading: Icon(
                      destination.icon,
                      color: selected
                          ? _ownerNavy
                          : Colors.white70,
                    ),
                    title: Text(
                      destination.title,
                      style: TextStyle(
                        color: selected
                            ? _ownerNavy
                            : Colors.white70,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () => _navigateTo(index),
                  ),
                );
              },
            ),
          ),

          // Informasi akun owner di bagian bawah sidebar.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0A2E4D),
              border: Border(
                top: BorderSide(
                  color: Colors.white12,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.white70,
                  child: Icon(
                    Icons.person,
                    color: _ownerNavy,
                    size: 20,
                  ),
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
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
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

class _OwnerDestination {
  const _OwnerDestination(this.title, this.icon);

  final String title;
  final IconData icon;
}
