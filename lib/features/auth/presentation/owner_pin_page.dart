import 'package:flutter/material.dart';
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
  bool _loading = false;

  Future<void> _masuk() async {
    if (_pin.text.length != 6 || _loading) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.post('login-owner-pin', {'pin': _pin.text});
      final user = Map<String, dynamic>.from(res['pengguna'] as Map);
      await ApiService.saveAuth(token: res['token'].toString(), user: user);
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
                MaterialPageRoute(builder: (_) => const PilihPeranPage()),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff103657),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              const Text(
                'PIN Owner',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _pin,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) {
                  if (v.length == 6) _masuk();
                },
                onSubmitted: (_) => _masuk(),
              ),
              const SizedBox(height: 16),
              if (_loading) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
