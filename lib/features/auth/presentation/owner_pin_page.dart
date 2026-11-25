import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/owner_profile_store.dart';
import 'package:kasir_celcious_coffe/data/produk_data.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/Dashboard.dart';
import 'package:kasir_celcious_coffe/features/auth/presentation/pilih_peran_page.dart';

const Color navy = Color(0xFF103657);

class OwnerPinPage extends StatefulWidget {
  const OwnerPinPage({super.key});

  static const String bioEnabledKey = 'owner_biometric_enabled';
  static const String bioTokenKey = 'owner_biometric_token';
  static const String bioUserKey = 'owner_biometric_user';

  @override
  State<OwnerPinPage> createState() => _OwnerPinPageState();
}

class _OwnerPinPageState extends State<OwnerPinPage> {
  static const _bioTokenKey = OwnerPinPage.bioTokenKey;
  static const _bioUserKey = OwnerPinPage.bioUserKey;

  final TextEditingController _pin = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _loading = false;
  bool _pinInvalid = false;
  bool _biometricSupported = false;
  bool _biometricEnabled = true;
  bool _biometricEnrolledOnApp = false;
  String _biometricLabel = 'Face ID / Biometrik';
  bool _textPasswordMode = false;

  @override
  void initState() {
    super.initState();
    _cekBiometrik();
  }

  Future<void> _cekBiometrik() async {
    if (kIsWeb) return;
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final types = await _localAuth.getAvailableBiometrics();
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(OwnerPinPage.bioEnabledKey) ?? true;
      final hasSavedOwner =
          enabled &&
          (prefs.getString(_bioTokenKey)?.isNotEmpty ?? false) &&
          (prefs.getString(_bioUserKey)?.isNotEmpty ?? false);

      String label = 'Face ID / Biometrik';
      if (types.contains(BiometricType.face)) {
        label = 'Masuk dengan Face ID';
      } else if (types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong)) {
        label = 'Masuk dengan Biometrik';
      }

      if (!mounted) return;
      setState(() {
        _biometricSupported = supported || canCheck;
        _biometricEnabled = enabled;
        _biometricEnrolledOnApp = hasSavedOwner;
        _biometricLabel = label;
      });
    } catch (_) {
      // Abaikan jika perangkat tidak mendukung biometrik
    }
  }

  Future<void> _resetBiometrik() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OwnerPinPage.bioEnabledKey, false);
    await prefs.remove(_bioTokenKey);
    await prefs.remove(_bioUserKey);
    if (!mounted) return;
    setState(() {
      _biometricEnabled = false;
      _biometricEnrolledOnApp = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Biometrik dinonaktifkan. Anda dapat mengaktifkannya kembali di Pengaturan Owner.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _simpanSesiBiometrik({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(OwnerPinPage.bioEnabledKey) ?? true;
    if (!enabled) return;
    await prefs.setString(_bioTokenKey, token);
    await prefs.setString(_bioUserKey, jsonEncode(user));
  }

  void _bukaDashboardOwner(Map<String, dynamic> user) {
    final nav = Navigator.of(context);
    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DashboardOwner(
          namaOwner: user['nama']?.toString() ?? 'Owner',
          onLogout: () async {
            await ApiService.clearAuth();

            nav.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const PilihPeranPage(),
              ),
              (route) => false,
            );
          },
        ),
      ),
      (route) => false,
    );
    _textPasswordMode = OwnerProfileStore.requiresTextPasswordLogin.value;
    OwnerProfileStore.initialize().then((_) {
      if (!mounted) return;
      final needsText = OwnerProfileStore.requiresTextPasswordLogin.value;
      if (needsText != _textPasswordMode) {
        setState(() => _textPasswordMode = needsText);
      }
    });
  }

  // ============================================================
  // LOGIN OWNER VIA FACE ID / BIOMETRIK
  // ============================================================

  Future<void> _masukDenganBiometrik() async {
    if (_loading) return;

    if (!_biometricEnrolledOnApp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan login dengan PIN Owner 1× terlebih dahulu untuk mengaktifkan Face ID di perangkat ini.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _pinInvalid = false;
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verifikasi Face ID / Biometrik untuk masuk sebagai Owner Celcious Coffee',
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );

      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi biometrik dibatalkan.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_bioTokenKey);
      final savedUserStr = prefs.getString(_bioUserKey);

      if (savedToken == null || savedUserStr == null) {
        throw Exception('Sesi biometrik belum aktif. Masuk dengan PIN terlebih dahulu.');
      }

      final user = Map<String, dynamic>.from(jsonDecode(savedUserStr) as Map);
      await ApiService.saveAuth(token: savedToken, user: user);

      // Verifikasi ke backend bahwa token Owner masih valid & memiliki hak akses owner
      await ApiService.get('owner-test');
      await ProdukData.loadFromApi();

      if (!mounted) return;
      _bukaDashboardOwner(user);
    } catch (e) {
      await ApiService.clearAuth();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verifikasi Face ID gagal atau sesi kedaluwarsa. Silakan masukkan PIN Owner.',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _focusNode.requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ============================================================
  // LOGIN OWNER VIA PIN 6 DIGIT
  // ============================================================

  Future<void> _masuk() async {
    final entered = _pin.text.trim();
    if (_loading) return;
    if (_textPasswordMode ? entered.length < 6 : entered.length != 6) return;

    setState(() {
      _loading = true;
      _pinInvalid = false;
    });

    try {
      final resolution =
          await OwnerProfileStore.resolveOwnerSecretForLogin(entered);

      if (!resolution.allowed) {
        throw Exception(
          resolution.errorMessage ?? 'PIN / password salah, silakan coba lagi.',
        );
      }

      Map<String, dynamic> res;
      var usedFallbackBackend = false;

      try {
        res = await ApiService.post(
          'login-owner-pin',
          {'pin': resolution.primarySecretToTry ?? entered},
        );
      } catch (primaryErr) {
        if (resolution.fallbackBackendSecret != null &&
            resolution.fallbackBackendSecret!.isNotEmpty) {
          res = await ApiService.post(
            'login-owner-pin',
            {'pin': resolution.fallbackBackendSecret!},
          );
          usedFallbackBackend = true;
        } else {
          rethrow;
        }
      }

      final user = Map<String, dynamic>.from(
        res['pengguna'] as Map,
      );
      final token = res['token'].toString();

      await ApiService.saveAuth(
        token: token,
        user: user,
      );

      // Aktifkan sesi biometrik pada perangkat Owner untuk login Face ID berikutnya
      await _simpanSesiBiometrik(token: token, user: user);
      if (usedFallbackBackend) {
        await OwnerProfileStore.recordAuthenticatedSecret(
          entered,
          isBackendSecret: false,
        );
      } else if (resolution.fallbackBackendSecret != null) {
        await OwnerProfileStore.clearLocalPasswordOverride(entered);
      } else {
        await OwnerProfileStore.recordAuthenticatedSecret(
          entered,
          isBackendSecret: true,
        );
      }

      await ProdukData.loadFromApi();

      if (!mounted) return;
      _bukaDashboardOwner(user);
    } catch (e) {
      _pin.clear();

      if (mounted) {
        setState(() {
          _pinInvalid = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _focusNode.requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _pin.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND FOTO KOPI
          Image.asset(
            'assets/images/bg_pilih_peran.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: navy,
              );
            },
          ),

          // OVERLAY NAVY GELAP
          Container(
            color: const Color(0xFF082640).withValues(alpha: 0.82),
          ),

          // TOMBOL KEMBALI
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  tooltip: 'Kembali',
                ),
              ),
            ),
          ),

          // KONTEN PIN OWNER
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 25,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 340,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // IKON OWNER
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            color: Colors.white,
                            size: 76,
                          ),
                          Positioned(
                            bottom: 7,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFF082640),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 25,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),


                      Text(
                        _textPasswordMode ? 'PASSWORD OWNER' : 'PIN OWNER',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // INPUT PIN
                      // ==================================================
                      // INPUT PIN / PASSWORD
                      // ==================================================

                      TextField(
                        controller: _pin,
                        focusNode: _focusNode,
                        autofocus: true,
                        enabled: !_loading,
                        keyboardType: _textPasswordMode
                            ? TextInputType.visiblePassword
                            : TextInputType.number,
                        textInputAction: TextInputAction.done,
                        textAlign: TextAlign.center,
                        obscureText: true,
                        maxLength: _textPasswordMode ? 64 : 6,
                        inputFormatters: _textPasswordMode
                            ? null
                            : [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                        style: TextStyle(
                          color: _pinInvalid ? Colors.red : navy,
                          fontSize: _textPasswordMode ? 16 : 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: _textPasswordMode ? 2 : 9,
                        ),
                        decoration: InputDecoration(
                          hintText: _textPasswordMode
                              ? 'Masukkan password owner'
                              : '',
                          hintStyle: TextStyle(
                            color: navy.withValues(alpha: 0.45),
                            fontSize: 13,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w500,
                          ),
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          if (_pinInvalid) {
                            setState(() {
                              _pinInvalid = false;
                            });
                          }

                          if (!_textPasswordMode && value.length == 6) {
                            _masuk();
                          }
                        },
                        onSubmitted: (_) => _masuk(),
                      ),

                      if (_textPasswordMode) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 160,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _masuk,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA8CBE9),
                              foregroundColor: navy,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // ==================================================
                      // PESAN PIN SALAH
                      if (_pinInvalid) ...[
                        const SizedBox(height: 10),
                        Text(
                          _textPasswordMode
                              ? 'Password salah, silakan coba lagi.'
                              : 'PIN salah, silakan coba lagi.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      // TOMBOL FACE ID / BIOMETRIK (ANDROID / iOS / WINDOWS)
                      if (_biometricSupported && _biometricEnabled) ...[
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _masukDenganBiometrik,
                            icon: const Icon(
                              Icons.face_retouching_natural_rounded,
                              size: 20,
                            ),
                            label: Text(
                              _biometricLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.75),
                                width: 1.3,
                              ),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                          ),
                        ),
                        if (!_biometricEnrolledOnApp) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Login PIN 1× untuk mengaktifkan Face ID di perangkat ini',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 11,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _loading ? null : _resetBiometrik,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Reset Biometrik di perangkat ini',
                              style: TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ] else if (kIsWeb) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: Colors.white.withValues(alpha: 0.72),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Dilindungi PIN 6 Digit (Face ID aktif di HP/Desktop Owner)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // LOADING
                      if (_loading) ...[
                        const SizedBox(height: 16),
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
