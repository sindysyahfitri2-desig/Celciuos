
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
  int? hoveredIndex;

  final Color navy = const Color(0xff082640);
  final Color glowBlue = const Color(0xff38BDF8);

  Future<void> _pilihPeran(int index) async {
    setState(() {
      selectedIndex = index;
    });

    await Future.delayed(const Duration(milliseconds: 300));

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
    final bool isHovered = hoveredIndex == index;

    final bool showBorder = isSelected || isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,

      onEnter: (_) {
        setState(() {
          hoveredIndex = index;
        });
      },

      onExit: (_) {
        setState(() {
          hoveredIndex = null;
        });
      },

      child: GestureDetector(
        onTap: () => _pilihPeran(index),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,

          width: 185,
          height: 210,

          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(12),

            // BORDER BIRU
            border: Border.all(
              color: showBorder
                  ? navy
                  : Colors.transparent,
              width: 2.9,
            ),

            // EFEK GLOWING BIRU
            boxShadow: [
              BoxShadow(
                color: showBorder
                    ? glowBlue.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.15),
                blurRadius: showBorder ? 30 : 6,
                spreadRadius: showBorder ? 5 : 0,
                offset: const Offset(0, 0),
              ),

              // Cahaya tambahan
              BoxShadow(
                color: showBorder
                    ? glowBlue.withValues(alpha: 0.35)
                    : Colors.transparent,
                blurRadius: showBorder ? 45 : 0,
                spreadRadius: showBorder ? 8 : 0,
                offset: const Offset(0, 0),
              ),

              // Bayangan bawah
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Stack(
            children: [
              // INDIKATOR CHECK
              Positioned(
                top: 8,
                left: 8,

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 18,
                  height: 18,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: navy,
                      width: 2,
                    ),
                    color: showBorder
                        ? navy
                        : Colors.transparent,
                  ),

                  child: showBorder
                      ? const Icon(
                          Icons.check,
                          size: 11,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),

              // ISI CARD
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ANIMASI IKON MEMBESAR
                    AnimatedScale(
                      scale: isHovered ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,

                      child: Icon(
                        icon,
                        size: 76,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 13),

                    // TULISAN KASIR / OWNER
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),

                      style: TextStyle(
                        fontSize: isHovered ? 15 : 15,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),

                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),

                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          // BACKGROUND GAMBAR
          Image.asset(
            'assets/images/bg_pilih_peran.jpeg',
            fit: BoxFit.cover,
          ),

          // OVERLAY
          Container(
            color: const Color(0xff061e35)
                .withValues(alpha: 0.58),
          ),

          // KONTEN HALAMAN
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // IKON PROFIL
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

                        const SizedBox(height: 8),

                        // JUDUL
                        const Text(
                          'Selamat Datang !',

                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // SUBJUDUL
                        const Text(
                          'Silahkan Pilih Peran Anda',

                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // PILIHAN PERAN
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 14,

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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
