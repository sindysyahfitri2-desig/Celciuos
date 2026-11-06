import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/buka_shift_page.dart';

class PilihProfilPage extends StatefulWidget {
  const PilihProfilPage({super.key});

  @override
  State<PilihProfilPage> createState() => _PilihProfilPageState();
}

class _PilihProfilPageState extends State<PilihProfilPage> {
  List<Map<String, dynamic>> _kasir = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKasir();
  }

  Future<void> _loadKasir() async {
    try {
      final res = await ApiService.get('kasir-profil');
      setState(() {
        _kasir = (res['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  // <-- _askPin ditaruh DI SINI, di dalam class _PilihProfilPageState
  Future<String?> _askPin(BuildContext context, String nama) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('PIN untuk $nama'),
        content: TextField(
          controller: c,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('Masuk'),
          ),
        ],
      ),
    );
  }

  Future<void> _login(Map<String, dynamic> k) async {
    final pin = await _askPin(context, k['nama'].toString());
    if (pin == null || pin.isEmpty) return;

    try {
      final res = await ApiService.post('login-pin', {
        'id_pengguna': k['id_pengguna'],
        'pin': pin,
      });

      await ApiService.saveAuth(
        token: res['token'].toString(),
        user: Map<String, dynamic>.from(res['pengguna'] as Map),
      );

      if (!mounted) return;

      final navigator = Navigator.of(context);

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => BukaShiftPage(
            namaKasir: k['nama'].toString(),
            onLogout: () async {
              await ApiService.clearAuth();

              if (!navigator.mounted) return;

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const PilihProfilPage()),
                (route) => false,
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffdce7f2),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _kasir.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tidak ada data kasir / gagal memuat.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _loading = true);
                      _loadKasir();
                    },
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            )
          : Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _kasir.map((k) {
                  return InkWell(
                    onTap: () => _login(k),
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 136,
                              height: 136,
                              child: k['foto_url'] != null
                                  ? Image.network(
                                      k['foto_url'],
                                      fit: BoxFit.cover,
                                      headers: const {
                                        'ngrok-skip-browser-warning': 'true',
                                      },
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person, size: 60),
                                    )
                                  : const Icon(Icons.person, size: 60),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(k['nama'].toString()),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
