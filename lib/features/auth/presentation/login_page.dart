
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

  bool get _isVerifying => _loginController.isVerifying;

  static const Color navy = Color(0xff082640);
  static const Color inputBlue = Color(0xff2196f3);

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

    if (_ownsLoginController) {
      _loginController.dispose();
    }

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

  // LOGIN TANPA DIALOG KONFIRMASI IDENTITAS
  Future<void> _submit() async {
    final result = await _loginController.submit(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted ||
        result.status == LoginSubmissionStatus.ignored) {
      return;
    }

    if (result.isError) {
      _showMessage(
        result.message ?? 'Login gagal.',
        isError: true,
      );
      return;
    }

    if (result.status != LoginSubmissionStatus.authenticated) {
      return;
    }

    final role = result.role;
    final displayName = result.displayName ??
        _usernameController.text.trim();

    // ROLE OWNER: LANGSUNG KE DASHBOARD
    if (role == 'Owner') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardOwner(
            namaOwner: displayName,
            onLogout: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
                (route) => false,
              );
            },
          ),
        ),
      );
    }

    // ROLE KASIR: LANGSUNG KE HALAMAN KASIR
    else if (role == 'Kasir') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const kasirPage(),
        ),
      );
    } else {
      _showMessage(
        'Role akun tidak dikenali.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 67, 112, 151),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isMobile = screenWidth < 600;
            final isTablet =
                screenWidth >= 600 && screenWidth < 1000;

            final cardWidth = isMobile
                ? math.max(0.0, screenWidth - 32)
                : isTablet
                    ? 440.0
                    : 460.0;

            return Stack(
              children: [
                // BACKGROUND GRADASI
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
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
                    final t =
                        _borderController.value * 2 * math.pi;

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

                // DEKORASI KOPI
                AnimatedBuilder(
                  animation: _borderController,
                  builder: (context, child) {
                    final t =
                        _borderController.value * 2 * math.pi;

                    return Stack(
                      children: [
                        Positioned(
                          top: constraints.maxHeight * 0.13 +
                              math.sin(t) * 12,
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
                          bottom: constraints.maxHeight * 0.15 +
                              math.cos(t) * 14,
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
                          top: constraints.maxHeight * 0.23 +
                              math.cos(t + 1) * 10,
                          left: screenWidth * 0.17,
                          child: Transform.rotate(
                            angle: t * 0.3,
                            child: _floatingDecoration(
                              Icons.auto_awesome_rounded,
                              isMobile ? 15 : 24,
                              0.25,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: constraints.maxHeight * 0.25 +
                              math.sin(t + 1) * 12,
                          right: screenWidth * 0.15,
                          child: Transform.rotate(
                            angle: -t * 0.25,
                            child: _floatingDecoration(
                              Icons.auto_awesome_rounded,
                              isMobile ? 20 : 30,
                              0.20,
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
                      horizontal: isMobile ? 16 : 16,
                      vertical: 35,
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.96, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
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
                          constraints:
                              const BoxConstraints(maxWidth: 299),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xff58b9f5)
                                    .withValues(alpha: 0.15),
                                blurRadius: 25,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.30,
                                ),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Stack(
                              children: [
                                // GAMBAR BACKGROUND
                                Positioned.fill(
                                  child: Image.asset(
                                    'assets/images/Login_bg.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return const ColoredBox(
                                        color: Color(0xff273b4b),
                                      );
                                    },
                                  ),
                                ),

                                // LAPISAN GELAP
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          navy.withValues(alpha: 0.78),
                                          navy.withValues(alpha: 0.73),
                                          Colors.black.withValues(
                                            alpha: 0.900,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // EFEK KACA
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
                                      // LOGO
                                      AnimatedBuilder(
                                        animation: _borderController,
                                        builder: (context, child) {
                                          final pulse = 1 +
                                              math.sin(
                                                    _borderController
                                                            .value *
                                                        2 *
                                                        math.pi,
                                                  ) *
                                                  0.025;

                                          return Transform.scale(
                                            scale: pulse,
                                            child: child,
                                          );
                                        },
                                        child: Container(
                                          width: isMobile ? 66 : 76,
                                          height: isMobile ? 66 : 76,
                                          padding:
                                              const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(
                                              0xff3979ad,
                                            ).withValues(alpha: 0.65),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(
                                                alpha: 0.70,
                                              ),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xff58b9f5,
                                                ).withValues(
                                                  alpha: 0.28,
                                                ),
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

                                      const SizedBox(height: 24),

                                      // USERNAME
                                      _inputField(
                                        controller:
                                            _usernameController,
                                        hint: 'Username',
                                        icon: Icons
                                            .person_outline_rounded,
                                      ),

                                      const SizedBox(height: 18),

                                      // PASSWORD
                                      _inputField(
                                        controller:
                                            _passwordController,
                                        hint: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: _hidePassword,
                                        suffix: IconButton(
                                          tooltip: _hidePassword
                                              ? 'Tampilkan password'
                                              : 'Sembunyikan password',
                                          onPressed: () {
                                            setState(() {
                                              _hidePassword =
                                                  !_hidePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _hidePassword
                                                ? Icons
                                                    .visibility_off_outlined
                                                : Icons
                                                    .visibility_outlined,
                                            size: 19,
                                            color: navy,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // TOMBOL LOGIN
                                      Center(
                                        child: SizedBox(
                                          width: 140,
                                          height: 40,
                                          child: _LoginButton(
                                            isLoading: _isVerifying,
                                            onPressed: _submit,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // LUPA PASSWORD
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
                                      ),

                                      const SizedBox(height: 4),
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

  // CAHAYA BACKGROUND
  Widget _ambientGlow({
    required double size,
    required Color color,
  }) {
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

  // IKON DEKORASI
  Widget _floatingDecoration(
    IconData icon,
    double size,
    double opacity,
  ) {
    return IgnorePointer(
      child: Icon(
        icon,
        size: size,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  // INPUT USERNAME DAN PASSWORD
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: !obscure,
      style: const TextStyle(
        color: navy,
        fontSize: 14,
      ),
      cursorColor: const Color.fromRGBO(33, 150, 243, 1),
      decoration: InputDecoration(
        labelText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.auto,

        // LABEL SAAT DI DALAM INPUT
        labelStyle: const TextStyle(
          color: Color(0xff8d8d8d),
          fontSize: 17,
          height: 1.1,
        ),

        // LABEL SAAT NAIK: TETAP TERBACA
        floatingLabelStyle: const TextStyle(
          color:   Color.fromARGB(255, 5, 117, 192),
          fontSize: 21,
          fontWeight: FontWeight.w600,
          height: 1.9,
        ),

        suffixIcon: suffix,

        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.96),
        isDense: true,

        // UKURAN INPUT SEDANG
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 19,
        ),

        // BORDER NORMAL
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(78),
          borderSide: const BorderSide(
            color: Color.fromARGB(192, 199, 199, 199),
            width: 1.1,
          ),
        ),

        // BORDER BIRU SAAT DIKLIK ATAU DIKETIK
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(78),
          borderSide: const BorderSide(
            color:   Color.fromARGB(255, 5, 117, 192),
            width: 1.9 ,
          ),
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xffb0b7bd),
            width: 9,
          ),
        ),
      ),
      onSubmitted: (_) {
        if (controller == _passwordController) {
          _submit();
        }
      },
    );
  }
}

// TOMBOL LOGIN DENGAN EFEK HOVER
class _LoginButton extends StatefulWidget {
  const _LoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _pressed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
            0,
            _pressed ? -1 : active ? -4 : 0,
            0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(45),
            color: active
                ? const Color.fromARGB(255, 1, 61, 77)
                : const Color(0xff082640),
            boxShadow: [
              BoxShadow(
                color: (active
                        ? const Color.fromARGB(255, 142, 208, 248)
                        : Colors.black)
                    .withValues(alpha: active ? 0.30 : 0.18),
                blurRadius: active ? 14 : 6,
                offset: Offset(0, active ? 8 : 3),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 19,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ANIMASI BORDER CAHAYA
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
  bool shouldRepaint(
    covariant _GlowBorderPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}
