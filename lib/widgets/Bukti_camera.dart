import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class BuktiKamera extends StatefulWidget {
  const BuktiKamera({super.key});

  @override
  State<BuktiKamera> createState() => _BuktiKameraState();
}

class _BuktiKameraState extends State<BuktiKamera> {
  CameraController? _controller;
  bool _memuat = true;
  bool _mengambilFoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mulaiKamera();
  }

  Future<void> _mulaiKamera() async {
    try {
      final daftarKamera = await availableCameras();
      if (daftarKamera.isEmpty) {
        throw Exception('Kamera tidak ditemukan.');
      }

      final kameraBelakang = daftarKamera.where(
        (kamera) => kamera.lensDirection == CameraLensDirection.back,
      );
      final kamera = kameraBelakang.isNotEmpty
          ? kameraBelakang.first
          : daftarKamera.first;

      final controller = CameraController(
        kamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _memuat = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _error = 'Kamera gagal dibuka.\\n$error';
      });
    }
  }

  Future<void> _ambilFoto() async {
    final kamera = _controller;
    if (kamera == null ||
        !kamera.value.isInitialized ||
        _mengambilFoto) {
      return;
    }

    setState(() => _mengambilFoto = true);
    try {
      final XFile foto = await kamera.takePicture();
      final Uint8List bytes = await foto.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop<Uint8List>(bytes);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _mengambilFoto = false;
        _error = 'Gagal mengambil foto: $error';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kamera = _controller;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Foto Bukti Pembayaran',
              style: TextStyle(
                color: Color(0xff082640),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 300,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xffdce9f4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _memuat
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xff082640)),
                            ),
                          ),
                        )
                      : kamera != null && kamera.value.isInitialized
                          ? CameraPreview(kamera)
                          : const Center(child: Text('Kamera tidak tersedia')),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final lama = _controller;
                    _controller = null;
                    await lama?.dispose();
                    if (!mounted) return;
                    setState(() {
                      _memuat = true;
                      _error = null;
                    });
                    _mulaiKamera();
                  },
                  child: const Text('Coba Lagi'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _memuat || _mengambilFoto ? null : _ambilFoto,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(
                    _mengambilFoto ? 'Mengambil Foto...' : 'Ambil Foto',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff082640),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _mengambilFoto
                    ? null
                    : () => Navigator.of(context).pop<Uint8List>(null),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
