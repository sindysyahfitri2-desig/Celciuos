
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

  bool isNavigating = false;

  static const Color navy = Color(0xff082640);

  Future<void> _pilihPeran(int index) async {
    if (isNavigating) return;

    setState(() {
      selectedIndex = index;
      isNavigating = true;
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

    if (mounted) {
      setState(() {
        isNavigating = false;
      });
    }
  }

  // TOMBOL PILIH PERAN
  Widget _tombol({
    required int index,
    required IconData icon,
    required String label,
    required double width,
    required double height,
  }) {
    final bool isSelected = selectedIndex == index;

    return _RoleCard(
      index: index,
      icon: icon,
      label: label,
      width: width,
      height: height,
      isSelected: isSelected,
      enabled: !isNavigating,
      onTap: () => _pilihPeran(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND
          Image.asset(
            'assets/images/bg_pilih_peran.jpeg',
            fit: BoxFit.cover,
          ),

          // OVERLAY NAVY
          Container(
            color: const Color(0xff061e35)
                .withValues(alpha: 0.58),
          ),

          // KONTEN
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;

                  // UKURAN CARD RESPONSIVE
                  final bool isPhone = screenWidth < 600;

                  final double cardWidth = isPhone
                      ? ((screenWidth - 44) / 2)
                          .clamp(100.0, 108.0)
                      : ((screenWidth - 48 - 18) / 2)
                          .clamp(120.0, 169.0);

                  final double cardHeight =
                      isPhone ? 120.0 : 182.0;

                  final double cardGap =
                      isPhone ? 12.0 : 18.0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 25,
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
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

                        const SizedBox(height: 12),

                        // JUDUL
                        Text(
                          'Selamat Datang !',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isPhone ? 29 : 40,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Silahkan Pilih Peran Anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isPhone ? 14 : 17,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // CARD KANAN DAN KIRI
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            _tombol(
                              index: 0,
                              icon: Icons.point_of_sale_rounded,
                              label: 'Masuk Sebagai Kasir',
                              width: cardWidth,
                              height: cardHeight,
                            ),

                            SizedBox(width: cardGap),

                            _tombol(
                              index: 1,
                              icon:
                                  Icons.admin_panel_settings_rounded,
                              label: 'Masuk Sebagai Owner',
                              width: cardWidth,
                              height: cardHeight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// CARD ANIMASI
// ==================================================

class _RoleCard extends StatefulWidget {
  final int index;
  final IconData icon;
  final String label;
  final double width;
  final double height;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _RoleCard({
    required this.index,
    required this.icon,
    required this.label,
    required this.width,
    required this.height,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  bool isHovered = false;

  late AnimationController _controller;

  late Animation<double> _clickAnimation;

  static const Color navy = Color(0xff082640);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _clickAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.94),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.06),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;

    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected;

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        setState(() => isHovered = true);
      },
      onExit: (_) {
        setState(() => isHovered = false);
      },
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _clickAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _clickAnimation.value,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                offset: isHovered && widget.enabled
                    ? const Offset(0, -0.035)
                    : Offset.zero,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  scale: isHovered && widget.enabled
                      ? 1.035
                      : 1.0,
                  child: child,
                ),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: navy.withValues(
                    alpha: isHovered ? 0.28 : 0.12,
                  ),
                  blurRadius: isHovered ? 20 : 10,
                  spreadRadius: isHovered ? 2 : 0,
                  offset: Offset(
                    0,
                    isHovered ? 8 : 4,
                  ),
                ),
              ],
            ),
            child: Stack(
              children: [
                // GARIS BIRU BAGIAN DALAM
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  left: active ? 5 : 10,
                  right: active ? 5 : 10,
                  top: active ? 5 : 10,
                  bottom: active ? 5 : 10,
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? navy
                              : Colors.transparent,
                          width: 4.2,
                        ),
                      ),
                    ),
                  ),
                ),

                // TANDA PILIH
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  top: active ? 12 : 17,
                  left: active ? 12 : 17,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: active ? 1 : 0,
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
                ),

                // ISI CARD
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        duration:
                            const Duration(milliseconds: 250),
                        scale: isHovered ? 1.08 : 1.0,
                        child: Icon(
                          widget.icon,
                          size: widget.width * 0.38,
                          color: navy,
                        ),
                      ),

                      SizedBox(height: widget.height * 0.10),

                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: widget.width * 0.078,
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
        ),
      ),
    );
  }
}
