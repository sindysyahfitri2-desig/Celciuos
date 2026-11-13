
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/Dashboard.dart';
import 'package:kasir_celcious_coffe/features/auth/presentation/pilih_peran_page.dart';
import 'package:kasir_celcious_coffe/data/produk_data.dart';

class OwnerPinPage extends StatefulWidget {
  const OwnerPinPage({super.key});

  @override
  State<OwnerPinPage> createState() => _OwnerPinPageState();
}

class _OwnerPinPageState extends State<OwnerPinPage> {
  final _pin = TextEditingController();
  final _focusNode = FocusNode();

  bool _loading = false;
  bool _obscurePin = true;
  bool _pinInvalid = false;

  static const Color navy = Color(0xff103657);

  Future<void> _masuk() async {
    if (_pin.text.length != 6 || _loading) return;

    setState(() => _loading = true);

    try {
      final res = await ApiService.post(
        'login-owner-pin',
        {'pin': _pin.text},
      );

      final user = Map<String, dynamic>.from(
        res['pengguna'] as Map,
      );

      await ApiService.saveAuth(
        token: res['token'].toString(),
        user: user,
      );

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
                (r) => false,
              );
            },
          ),
        ),
        (r) => false,
      );
    } catch (e) {
      _pin.clear();

      if (mounted) {
        setState(() => _pinInvalid = true);

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
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _pin.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double cardWidth = math.min(
            constraints.maxWidth - 40,
            380.0,
          ).toDouble();

          return Stack(
            fit: StackFit.expand,
            children: [
              // BACKGROUND FOTO KOPI
              Image.asset(
                'assets/images/bg_pilih_peran.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: navy);
                },
              ),

              // OVERLAY NAVY
              Container(
                color: const Color(0xff082640).withValues(alpha: 0.82),
              ),

              // KONTEN PIN OWNER
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 25,
                    ),
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // IKON OWNER
                          const Icon(
                            Icons.verified_user_rounded,
                            color: navy,
                            size: 82,
                          ),

                          const SizedBox(height: 15),

                          // JUDUL
                          const Text(
                            'PIN OWNER',
                            style: TextStyle(
                              color: navy,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 22),

                          // INPUT PIN
                          TextField(
                            controller: _pin,
                            focusNode: _focusNode,
                            autofocus: true,
                            enabled: !_loading,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            textAlign: TextAlign.center,
                            obscureText: _obscurePin,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            style: TextStyle(
                              color: _pinInvalid ? Colors.red : navy,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan PIN',
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                letterSpacing: 0,
                              ),
                              counterText: '',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(35),
                                borderSide: BorderSide(
                                  color: _pinInvalid ? Colors.red : navy,
                                  width: _pinInvalid ? 2 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(35),
                                borderSide: BorderSide(
                                  color: _pinInvalid ? Colors.red : navy,
                                  width: 2,
                                ),
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePin
                                    ? 'Tampilkan PIN'
                                    : 'Sembunyikan PIN',
                                onPressed: () {
                                  setState(() {
                                    _obscurePin = !_obscurePin;
                                  });
                                },
                                icon: Icon(
                                  _obscurePin
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: _pinInvalid ? Colors.red : navy,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (_pinInvalid) {
                                setState(() => _pinInvalid = false);
                              }

                              if (value.length == 6) {
                                _masuk();
                              }
                            },
                            onSubmitted: (_) => _masuk(),
                          ),

                          if (_pinInvalid) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'PIN salah, silakan coba lagi.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (_loading) ...[
                            const SizedBox(height: 16),
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: navy,
                              ),
                            ),
                          ],
                          const SizedBox(height: 13),
                          const Text(
                            'Masukkan 6 digit PIN Owner',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
