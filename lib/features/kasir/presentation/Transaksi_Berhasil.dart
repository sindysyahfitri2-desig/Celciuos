import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Halaman sukses setelah transaksi berhasil disimpan.
/// onSelesai dipanggil saat kasir menekan tombol "Selesai".
class TransaksiBerhasilPage extends StatefulWidget {
  final VoidCallback onSelesai;

  const TransaksiBerhasilPage({
    super.key,
    required this.onSelesai,
  });

  @override
  State<TransaksiBerhasilPage> createState() => _TransaksiBerhasilPageState();
}

class _TransaksiBerhasilPageState extends State<TransaksiBerhasilPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  static const Color _background = Color(0xffd8e5f1);
  static const Color _navy = Color(0xff103456);
  static const Color _successGreen = Color(0xff00665d);

  @override
  void initState() {
    super.initState();

    // Animasi ikon centang: muncul dari kecil menjadi normal.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Suara sistem sederhana tanpa perlu menambah package atau file audio.
    // Bunyi yang terdengar mengikuti dukungan perangkat/platform.
    _putarSuaraSukses();
  }

  Future<void> _putarSuaraSukses() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Jika perangkat tidak mendukung suara sistem, animasi tetap berjalan.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // Garis tipis di bagian atas, mengikuti gambar contoh.
            Container(
              height: 4,
              width: double.infinity,
              color: const Color(0xff505050),
            ),

            // Isi utama ditempatkan di tengah layar.
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: _successGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: _background,
                              size: 68,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 58),

                      // Teks dibuat dua baris seperti desain referensi.
                      const Text(
                        'Transaksi Berhasil\nDisimpan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 23,
                          height: 1.05,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tombol bawah memenuhi lebar layar.
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.onSelesai,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: _background,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
