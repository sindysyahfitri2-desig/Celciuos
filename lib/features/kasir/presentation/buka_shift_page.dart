import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/features/kasir/application/cashier_shift_service.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/kasir_page.dart';

class BukaShiftPage extends StatefulWidget {
  const BukaShiftPage({
    super.key,
    required this.namaKasir,
    required this.onLogout,
  });

  final String namaKasir;
  final VoidCallback onLogout;

  @override
  State<BukaShiftPage> createState() => _BukaShiftPageState();
}

class _BukaShiftPageState extends State<BukaShiftPage> {
  final TextEditingController _kasController = TextEditingController();
  bool _loading = false;

  static const Color navy = Color(0xff082640);

  Future<void> _bukaShift() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await CashierShiftService.startShift(
        cashier: widget.namaKasir,
        openingCashText: _kasController.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => kasirPage(onLogout: widget.onLogout)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('FormatException: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _kasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffdce7f2),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 55,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Buka Shift Kasir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat bekerja, ${widget.namaKasir}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Masukkan Kas Laci Awal',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _kasController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 100000',
                      prefixText: 'Rp ',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _loading ? null : _bukaShift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Simpan dan Mulai Shift',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
