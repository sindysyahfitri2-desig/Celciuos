
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

  static const Color navy = Color(0xff103657);
  static const Color background = Color(0xff103657);
  static const Color cardBlue = Color(0xffD5EAFC);
  static const Color green = Color(0xff20D5A3);
  static const Color textBlue = Color(0xff103657);
  static const Color mutedBlue = Color(0xff52799F);

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
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

  Widget _pinBox(int index, double boxHeight) {
    final filled = index < _pin.text.length;
    final active = index == _pin.text.length &&
        _pin.text.length < 6;

    return Expanded(
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: boxHeight,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled || active
                  ? green
                  : const Color(0xff9CC5E9),
              width: filled || active ? 1.8 : 1.5,
            ),
          ),
          child: Center(
            child: filled
                ? Container(
                    width: 11,
                    height: 11,
                    decoration: const BoxDecoration(
                      color: green,
                      shape: BoxShape.circle,
                    ),
                  )
                : active
                    ? Container(
                        width: 13,
                        height: 3,
                        decoration: BoxDecoration(
                          color: green,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      )
                    : const SizedBox(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required double width,
    required bool compact,
  }) {
    final horizontalPadding = width < 350 ? 20.0 : 30.0;
    final boxHeight = width < 350 ? 44.0 : 51.0;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compact ? 23 : 30,
      ),
      decoration: BoxDecoration(
        color: cardBlue,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ikon gembok
          Container(
            width: compact ? 56 : 64,
            height: compact ? 56 : 64,
            decoration: BoxDecoration(
              color: const Color(0xff3D72A5),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: compact ? 28 : 32,
            ),
          ),

          SizedBox(height: compact ? 13 : 16),

          // Label owner
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xffB7DDF5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_rounded,
                  color: textBlue,
                  size: 16,
                ),
                SizedBox(width: 7),
                Text(
                  'AREA KHUSUS OWNER',
                  style: TextStyle(
                    color: textBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 7),
                Icon(
                  Icons.circle,
                  color: textBlue,
                  size: 9,
                ),
              ],
            ),
          ),

          SizedBox(height: compact ? 13 : 17),

          // Judul
          Text(
            'Masukkan PIN Owner',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textBlue,
              fontSize: width < 350 ? 19 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Ketuk 6 digit PIN keamanan untuk melanjutkan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedBlue,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: compact ? 22 : 27),

          // TextField tersembunyi untuk menerima input PIN
          SizedBox(
            height: 1,
            width: 1,
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _pin,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {});

                  if (value.length == 6) {
                    _masuk();
                  }
                },
                onSubmitted: (_) => _masuk(),
              ),
            ),
          ),

          // Enam kotak PIN
          GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            child: Row(
              children: List.generate(
                6,
                (index) => _pinBox(index, boxHeight),
              ),
            ),
          ),

          SizedBox(height: compact ? 21 : 25),

          // Tombol navy
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : () {
                      if (_pin.text.length == 6) {
                        _masuk();
                      } else {
                        _focusNode.requestFocus();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    navy.withOpacity(0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Konfirmasi PIN',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            final compact = screenHeight < 620;

            final double cardWidth;

            if (screenWidth < 600) {
              cardWidth = math.min(screenWidth - 32, 390);
            } else if (screenWidth < 1024) {
              cardWidth = 420;
            } else {
              cardWidth = 440;
            }

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: compact ? 12 : 24,
                ),
                child: _buildCard(
                  width: cardWidth,
                  compact: compact,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
