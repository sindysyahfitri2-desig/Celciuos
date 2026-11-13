
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

  static const Color navy = Color(0xFF082640);

  // Konfirmasi sebelum mengganti kasir
  Future<void> _konfirmasiGantiKasir() async {
    if (_loading) return;

    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ganti Kasir?'),
        content: const Text(
          'Apakah kamu yakin ingin keluar dari sesi ini '
          'dan kembali ke halaman pilih profil kasir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Ganti Kasir'),
          ),
        ],
      ),
    );

    if (yakin == true && mounted) {
      widget.onLogout();
    }
  }

  // Proses membuka shift
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
        MaterialPageRoute(
          builder: (_) => kasirPage(
            onLogout: widget.onLogout,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('FormatException: ', ''),
          ),
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
    backgroundColor: navy,
    body: Stack(
      fit: StackFit.expand,
      children: [
        // Background memenuhi seluruh layar
        Image.asset(
          'assets/images/Login_bg.jpg',
          fit: BoxFit.cover,
        ),

        // Overlay navy transparan
        Container(
          color: const Color(0xCC082640),
        ),

        // Konten halaman
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxHeight < 600;

              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ganti kasir
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton.icon(
                        onPressed: _loading
                            ? null
                            : _konfirmasiGantiKasir,
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                        label: const Text(
                          'Ganti Kasir',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isSmall ? 5 : 15),

                    // Ikon dompet
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: isSmall ? 60 : 76,
                    ),

                    SizedBox(height: isSmall ? 20 : 38),

                    // Judul
                    Text(
                      'Buka Shift Kasir',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 29 : 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Nama kasir
                    Text(
                      'Selamat Bekerja ${widget.namaKasir}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 16 : 19,
                      ),
                    ),

                    const Spacer(),

                    // Label kas awal
                    const Text(
                      'Masuk Kas Awal Laci',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Input saldo
                    TextField(
                      controller: _kasController,
                      enabled: !_loading,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Isi saldo',
                        hintStyle: const TextStyle(
                          color: Color(0xFF91A0B0),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 1,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: Color(0xFFB8D5EB),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isSmall ? 25 : 44),

                    // Tombol simpan
                    Center(
                      child: SizedBox(
                        width: 220,
                        height: 63,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _bukaShift,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: navy,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CircularProgressIndicator(
                                    color: navy,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
}