import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/features/auth/presentation/pilih_profil_page.dart';
import 'package:kasir_celcious_coffe/features/auth/presentation/owner_pin_page.dart';

class PilihPeranPage extends StatelessWidget {
  const PilihPeranPage({super.key});

  Widget _tombol(BuildContext c, IconData icon, String label, Widget page) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(c).push(MaterialPageRoute(builder: (_) => page)),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
        ),
        child: Column(children: [
          Icon(icon, size: 56, color: const Color(0xff082640)),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff082640))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff103657),
      body: Center(
        child: Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _tombol(context, Icons.point_of_sale_rounded, 'Masuk sebagai Kasir',
                const PilihProfilPage()),
            _tombol(context, Icons.admin_panel_settings_rounded,
                'Masuk sebagai Owner', const OwnerPinPage()),
          ],
        ),
      ),
    );
  }
}