import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:kasir_celcious_coffe/features/auth/application/login_controller.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/kasir_page.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/Dashboard.dart';

import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.controller});

  final LoginController? controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _borderController;

  late final LoginController _loginController;
  late final bool _ownsLoginController;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;

  bool get _isLogin => _loginController.isLogin;
  bool get _isVerifying => _loginController.isVerifying;

  static const Color navy = Color(0xff082640);

  @override
  void initState() {
    super.initState();
    _ownsLoginController = widget.controller == null;
    _loginController = widget.controller ?? LoginController();
    _loginController.addListener(_onLoginStateChanged);

    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _loginController.removeListener(_onLoginStateChanged);
    if (_ownsLoginController) _loginController.dispose();
    _borderController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginStateChanged() {
    if (mounted) setState(() {});
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // ORKESTRASI LOGIN (UI) DAN KONFIRMASI ROLE
  // ==========================================

  Future<void> _submit() async {
    final result = await _loginController.submit(
      _usernameController.text,
      _passwordController.text,
    );
    if (!mounted || result.status == LoginSubmissionStatus.ignored) return;

    if (result.isError) {
      _showMessage(result.message ?? 'Login gagal.', isError: true);
      return;
    }

    if (result.status == LoginSubmissionStatus.registered) {
      _passwordController.clear();
      _showMessage(result.message ?? 'Pendaftaran berhasil.');
      return;
    }

    if (result.status != LoginSubmissionStatus.authenticated) return;

    final role = result.role!;
    final displayName = result.displayName!;
    final username = result.username!;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 55,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  shape: BoxShape.circle,
                  border: Border.all(color: navy.withValues(alpha: 0.15)),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Konfirmasi Identitas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pastikan akun dan role berikut sudah benar '
                'sebelum melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    249,
                    250,
                    252,
                  ).withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_circle_rounded,
                      size: 34,
                      color: navy,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: navy,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            role == 'Owner'
                                ? Icons.verified_user_rounded
                                : Icons.badge_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Role $role',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
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
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: navy,
                      side: const BorderSide(color: navy),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Konfirmasi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;
    // NAVIGASI BERDASARKAN ROLE
    if (role == 'Owner') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardOwner(
            namaOwner: displayName,
            onLogout: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ),
      );
    } else if (role == 'Kasir') {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const kasirPage()));
    } else {
      _showMessage('Role akun tidak dikenali.', isError: true);
    }
  }

  // ==========================================
  // HALAMAN LOGIN + ANIMASI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isMobile = screenWidth < 600;
            final isTablet = screenWidth >= 600 && screenWidth < 1000;

            final cardWidth = isMobile
                ? math.max(0.0, screenWidth - 32)
                : isTablet
                ? 440.0
                : 460.0;

            return Stack(
              children: [
                // LATAR GRADASI
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(-0.7, -0.8),
                        radius: 1.5,
                        colors: [
                          Color(0xff285d83),
                          Color(0xff103657),
                          Color(0xff061725),
                        ],
                      ),
                    ),
                  ),
                ),

                // CAHAYA BERGERAK
                AnimatedBuilder(
                  animation: _borderController,
                  builder: (context, child) {
                    final t = _borderController.value * 2 * math.pi;

                    return Stack(
                      children: [
                        Positioned(
                          left: -90 + math.sin(t) * 30,
                          top: -90 + math.cos(t) * 20,
                          child: _ambientGlow(
                            size: isMobile ? 200 : 340,
                            color: const Color(0xff42baff),
                          ),
                        ),
                        Positioned(
                          right: -100 + math.cos(t) * 25,
                          bottom: -100 + math.sin(t) * 35,
                          child: _ambientGlow(
                            size: isMobile ? 240 : 380,
                            color: const Color(0xff568cff),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // IKON KOPI BERGOYANG
                AnimatedBuilder(
                  animation: _borderController,
                  builder: (context, child) {
                    final t = _borderController.value * 2 * math.pi;

                    return Stack(
                      children: [
                        Positioned(
                          top: constraints.maxHeight * 0.13 + math.sin(t) * 12,
                          right: screenWidth * 0.10,
                          child: Transform.rotate(
                            angle: math.sin(t) * 0.18,
                            child: _floatingDecoration(
                              Icons.coffee_rounded,
                              isMobile ? 30 : 49,
                              0.16,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom:
                              constraints.maxHeight * 0.15 + math.cos(t) * 14,
                          left: screenWidth * 0.08,
                          child: Transform.rotate(
                            angle: math.cos(t) * 0.15,
                            child: _floatingDecoration(
                              Icons.coffee_outlined,
                              isMobile ? 32 : 55,
                              0.13,
                            ),
                          ),
                        ),
                        Positioned(
                          top:
                              constraints.maxHeight * 0.23 +
                              math.cos(t + 1) * 10,
                          left: screenWidth * 0.17,
                          child: Transform.rotate(
                            angle: t * 0.3,
                            child: _floatingDecoration(
                              Icons.auto_awesome_rounded,
                              isMobile ? 15 : 24,
                              0.38,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom:
                              constraints.maxHeight * 0.25 +
                              math.sin(t + 1) * 12,
                          right: screenWidth * 0.15,
                          child: Transform.rotate(
                            angle: -t * 0.25,
                            child: _floatingDecoration(
                              Icons.auto_awesome_rounded,
                              isMobile ? 20 : 30,
                              0.30,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // CARD LOGIN
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 12,
                      vertical: 14,
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.88, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: AnimatedBuilder(
                        animation: _borderController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _GlowBorderPainter(
                              progress: _borderController.value,
                            ),
                            child: child,
                          );
                        },
                        child: Container(
                          width: cardWidth,
                          constraints: const BoxConstraints(maxWidth: 335),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xff58b9f5,
                                ).withValues(alpha: 0.15),
                                blurRadius: 25,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: const Color.fromARGB(
                                  255,
                                  102,
                                  100,
                                  100,
                                ).withValues(alpha: 0.30),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    'assets/images/Login_bg.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const ColoredBox(
                                        color: Color(0xff273b4b),
                                      );
                                    },
                                  ),
                                ),

                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          navy.withValues(alpha: 0.78),
                                          navy.withValues(alpha: 0.73),
                                          Colors.black.withValues(alpha: 0.86),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // EFEK KACA TRANSPARAN
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 1,
                                      sigmaY: 1,
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                ),

                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    isMobile ? 23 : 35,
                                    isMobile ? 25 : 32,
                                    isMobile ? 23 : 35,
                                    24,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // LOGO BERDENYUT
                                      AnimatedBuilder(
                                        animation: _borderController,
                                        builder: (context, child) {
                                          final pulse =
                                              1 +
                                              math.sin(
                                                    _borderController.value *
                                                        2 *
                                                        math.pi,
                                                  ) *
                                                  0.035;

                                          return Transform.scale(
                                            scale: pulse,
                                            child: child,
                                          );
                                        },
                                        child: Container(
                                          width: isMobile ? 76 : 86,
                                          height: isMobile ? 76 : 86,
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(
                                              0xff3979ad,
                                            ).withValues(alpha: 0.65),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.70,
                                              ),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xff58b9f5,
                                                ).withValues(alpha: 0.28),
                                                blurRadius: 22,
                                              ),
                                            ],
                                          ),
                                          child: const ClipOval(
                                            child: AppBrandingLogo(
                                              fit: BoxFit.cover,
                                              fallbackIconSize: 38,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 25),

                                      // TOMBOL LOGIN / DAFTAR
                                      Container(
                                        height: 45,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.28,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            _modeButton('Login', true),
                                            _modeButton('Daftar', false),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 50),

                                      _inputField(
                                        controller: _usernameController,
                                        hint: 'Username',
                                        icon: Icons.person_outline_rounded,
                                      ),

                                      const SizedBox(height: 13),

                                      _inputField(
                                        controller: _passwordController,
                                        hint: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: _hidePassword,
                                        suffix: IconButton(
                                          tooltip: _hidePassword
                                              ? 'Tampilkan password'
                                              : 'Sembunyikan password',
                                          onPressed: () {
                                            setState(() {
                                              _hidePassword = !_hidePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _hidePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 19,
                                            color: navy,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // TOMBOL MASUK
                                      Center(
                                        child: SizedBox(
                                          width:
                                              220, // Atur lebar tombol di sini
                                          height: 45,
                                          child: ElevatedButton(
                                            onPressed: _isVerifying
                                                ? null
                                                : _submit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xff082640,
                                              ),
                                              disabledBackgroundColor:
                                                  const Color(0xff082640),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                // Tidak ada stroke atau garis tepi
                                                side: BorderSide.none,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: _isVerifying
                                                ? const SizedBox(
                                                    height: 19,
                                                    width: 17,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : Text(
                                                    _isLogin
                                                        ? 'Login'
                                                        : 'Daftar',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      if (_isLogin)
                                        TextButton(
                                          onPressed: () {
                                            _showMessage(
                                              'Fitur lupa password '
                                              'belum tersedia.',
                                            );
                                          },
                                          child: const Text(
                                            'Lupa Password?',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Text(
                                            'Username 4–20 karakter dan '
                                            'password minimal 6 karakter.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.78,
                                              ),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),

                                      const SizedBox(height: 7),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // DEKORASI ANIMASI
  // ==========================================

  Widget _ambientGlow({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _floatingDecoration(IconData icon, double size, double opacity) {
    return IgnorePointer(
      child: Icon(
        icon,
        size: size,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  // ==========================================
  // TOMBOL MODE LOGIN / DAFTAR
  // ==========================================

  Widget _modeButton(String label, bool loginMode) {
    final selected = _isLogin == loginMode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _loginController.setLoginMode(loginMode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? navy.withValues(alpha: 0.95) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xff58b9f5).withValues(alpha: 0.20),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              color: Colors.white.withValues(alpha: selected ? 1 : 0.72),
              fontSize: 19,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // INPUT FIELD
  // ==========================================

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: !obscure,
        style: const TextStyle(color: navy, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color.fromARGB(255, 183, 185, 185),
            fontSize: 17,
          ),

          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 14,
          ),
        ),

        onSubmitted: (_) {
          if (controller == _passwordController) {
            _submit();
          }
        },
      ),
    );
  }
}

// ==========================================
// ANIMASI BORDER CAHAYA
// ==========================================

class _GlowBorderPainter extends CustomPainter {
  _GlowBorderPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = BorderRadius.circular(28).toRRect(rect);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = SweepGradient(
        transform: GradientRotation(progress * 2 * math.pi),
        colors: const [
          Colors.transparent,
          Color(0xffdce9f4),
          Color(0xff58b9f5),
          Color(0xff3979ad),
          Colors.transparent,
          Colors.transparent,
        ],
        stops: const [0.15, 0.35, 0.42, 0.48, 0.58, 1],
      ).createShader(rect);

    canvas.drawRRect(radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
