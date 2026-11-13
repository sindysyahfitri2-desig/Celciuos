
import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/features/auth/presentation/pilih_profil_page.dart';
import 'package:kasir_celcious_coffe/features/auth/presentation/owner_pin_page.dart';

class PilihPeranPage extends StatefulWidget {
  const PilihPeranPage({super.key});

  @override
  State<PilihPeranPage> createState() => _PilihPeranPageState();
}

class _PilihPeranPageState extends State<PilihPeranPage> {
  int? selectedIndex;

  static const Color navy = Color(0xff082640);

  Future<void> _pilihPeran(int index) async {
    setState(() {
      selectedIndex = index;
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (!mounted) return;

    if (index == 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PilihProfilPage(),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const OwnerPinPage(),
        ),
      );
    }
  }

  Widget _tombol({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => _pilihPeran(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,

        width: 190,
        height: 225,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),

          // Border hanya ketika dipilih
          border: Border.all(
            color: isSelected
                ? navy
                : Colors.transparent,
            width: 4,
          ),

          // Hanya bayangan biasa, tanpa glow
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Stack(
          children: [
            // Tanda O hanya ketika dipilih
            if (isSelected)
              Positioned(
                top: 9,
                left: 9,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: navy,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: navy,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),

            // Isi card
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 76,
                    color: navy,
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/images/bg_pilih_peran.jpeg',
            fit: BoxFit.cover,
          ),

          // Overlay navy
          Container(
            color: const Color(0xff061e35)
                .withValues(alpha: 0.58),
          ),

          // Konten
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 25,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ikon profil
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Judul
                    const Text(
                      'Selamat Datang !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Silahkan Pilih Peran Anda',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Pilihan peran
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 24,
                      runSpacing: 20,
                      children: [
                        _tombol(
                          index: 0,
                          icon: Icons.point_of_sale_rounded,
                          label: 'Masuk Sebagai Kasir',
                        ),

                        _tombol(
                          index: 1,
                          icon: Icons.admin_panel_settings_rounded,
                          label: 'Masuk Sebagai Owner',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
