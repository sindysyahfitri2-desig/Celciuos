
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/owner_profile_store.dart';
import 'package:kasir_celcious_coffe/data/produk_data.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/Dashboard.dart';
import 'package:kasir_celcious_coffe/features/auth/presentation/pilih_peran_page.dart';

const Color navy = Color(0xFF103657);

class OwnerPinPage extends StatefulWidget {
  const OwnerPinPage({super.key});

  @override
  State<OwnerPinPage> createState() => _OwnerPinPageState();
}

class _OwnerPinPageState extends State<OwnerPinPage> {
  final TextEditingController _pin = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _loading = false;
  bool _pinInvalid = false;
  bool _textPasswordMode = false;

  @override
  void initState() {
    super.initState();
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
  // LOGIN OWNER
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

      await ApiService.saveAuth(
        token: res['token'].toString(),
        user: user,
      );

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
            'assets/images/bg_pilih_peran.jpg',
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
                      // ==================================================
                      // IKON OWNER
                      // ==================================================

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

                      // ==================================================
                      // JUDUL
                      // ==================================================

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
                          color: _pinInvalid
                              ? Colors.red
                              : navy,
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
                      // ==================================================

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

                      // ==================================================
                      // LOADING
                      // ==================================================

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
