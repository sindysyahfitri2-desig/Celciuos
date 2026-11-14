
import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/buka_shift_page.dart';
import 'package:kasir_celcious_coffe/features/kasir/application/cashier_shift_service.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/kasir_page.dart';
import 'package:kasir_celcious_coffe/features/auth/presentation/pilih_peran_page.dart';
import 'package:kasir_celcious_coffe/data/produk_data.dart';

class PilihProfilPage extends StatefulWidget {
  const PilihProfilPage({super.key});

  @override
  State<PilihProfilPage> createState() => _PilihProfilPageState();
}

class _PilihProfilPageState extends State<PilihProfilPage> {
  List<Map<String, dynamic>> _kasir = [];
  bool _loading = true;

  int? hoveredIndex;

  final Color navy = const Color(0xff082640);

  @override
  void initState() {
    super.initState();
    _loadKasir();
  }

  // ==========================================
  // LOAD DATA KASIR
  // ==========================================

  Future<void> _loadKasir() async {
    try {
      final res = await ApiService.get('kasir-profil');

      if (!mounted) return;

      setState(() {
        _kasir = (res['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    }
  }

  // ==========================================
  // DIALOG PIN KASIR + IKON MATA
  // ==========================================

  Future<String?> _askPin(
    BuildContext context,
    String nama,
  ) async {
    final c = TextEditingController();
    bool obscurePin = true;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              elevation: 14,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 25,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                width: 350,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18, 16, 18, 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // JUDUL
                      Text(
                        'PIN Untuk $nama',
                        style: TextStyle(
                          color: navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // INPUT PIN
                      TextField(
                        controller: c,
                        autofocus: true,
                        obscureText: obscurePin,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 5,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Masukkan PIN',
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            vertical: 12,
                          ),

                          // IKON MATA
                          suffixIcon: IconButton(
                            tooltip: obscurePin
                                ? 'Lihat PIN'
                                : 'Sembunyikan PIN',
                            onPressed: () {
                              setDialogState(() {
                                obscurePin = !obscurePin;
                              });
                            },
                            icon: Icon(
                              obscurePin
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: navy,
                              size: 21,
                            ),
                          ),

                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: navy,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: navy,
                              width: 2,
                            ),
                          ),
                        ),

                        // ENTER UNTUK MASUK
                        onSubmitted: (v) {
                          Navigator.pop(
                            dialogContext,
                            v.trim(),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // TOMBOL BATAL DAN MASUK
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: navy,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(
                                    dialogContext,
                                    c.text.trim(),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: navy,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    c.dispose();
    return result;
  }

  // ==========================================
  // LOGIN KASIR
  // ==========================================

  Future<void> _login(Map<String, dynamic> k) async {
    final pin = await _askPin(
      context,
      k['nama'].toString(),
    );

    if (pin == null || pin.isEmpty) return;

    try {
      final res = await ApiService.post('login-pin', {
        'id_pengguna': k['id_pengguna'],
        'pin': pin,
      });

      await ApiService.saveAuth(
        token: res['token'].toString(),
        user: Map<String, dynamic>.from(
          res['pengguna'] as Map,
        ),
      );

      if (!mounted) return;

      final navigator = Navigator.of(context);

      // LOGOUT
      Future<void> logout() async {
        await ApiService.clearAuth();

        if (!navigator.mounted) return;

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const PilihPeranPage(),
          ),
          (route) => false,
        );
      }

      // SINKRONISASI SHIFT
      try {
        await CashierShiftService.syncFromBackend();
      } catch (_) {}

      // LOAD PRODUK
      await ProdukData.loadFromApi();

      if (!mounted) return;

      final shiftAktif =
          CashierShiftService.activeShift() != null;

      // NAVIGASI HALAMAN
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => shiftAktif
              ? kasirPage(onLogout: logout)
              : BukaShiftPage(
                  namaKasir: k['nama'].toString(),
                  onLogout: logout,
                ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================
  // CARD PROFIL KASIR
  // ==========================================

  Widget _cardKasir(
    Map<String, dynamic> k,
    int index,
  ) {
    final bool isHovered = hoveredIndex == index;

    final String nama = k['nama'].toString();
    final String? fotoUrl = k['foto_url']?.toString();

    return MouseRegion(
      cursor: SystemMouseCursors.click,

      onEnter: (_) {
        setState(() {
          hoveredIndex = index;
        });
      },

      onExit: (_) {
        setState(() {
          hoveredIndex = null;
        });
      },

      child: GestureDetector(
        onTap: () => _login(k),

        child: AnimatedScale(
          scale: isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,

            width: 169,

            padding: const EdgeInsets.all(6),

            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(12),

              // BORDER PUTIH SAAT HOVER
              border: Border.all(
                color: isHovered
                    ? Colors.white
                    : Colors.transparent,
                width: 4,
              ),

              // BAYANGAN BIASA TANPA GLOW
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // FOTO KASIR
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),

                  child: Container(
                    width: double.infinity,
                    height: 170,
                    color: Colors.white,

                    child: fotoUrl != null &&
                            fotoUrl.isNotEmpty
                        ? Image.network(
                            fotoUrl,
                            fit: BoxFit.cover,
                            headers: const {
                              'ngrok-skip-browser-warning': 'true',
                            },
                            errorBuilder: (_, __, ___) {
                              return Icon(
                                Icons.person,
                                size: 65,
                                color: navy,
                              );
                            },
                          )
                        : Icon(
                            Icons.person,
                            size: 65,
                            color: navy,
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                // NAMA KASIR
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 7,
                    left: 3,
                    right: 3,
                  ),

                  child: Text(
                    nama,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAMPILAN UTAMA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND GAMBAR
          Image.asset(
            'assets/images/bg_pilih_peran.jpeg',
            fit: BoxFit.cover,
          ),

          // OVERLAY NAVY
          Container(
            color: const Color(0xff061e35)
                .withValues(alpha: 0.58),
          ),

          // KONTEN HALAMAN
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 25,
                  horizontal: 12,
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // IKON KASIR
                    const Icon(
                      Icons.point_of_sale_rounded,
                      size: 65,
                      color: Colors.white,
                    ),

                    const SizedBox(height: 8),

                    // JUDUL
                    const Text(
                      'Selamat Bekerja Kasir !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // LOADING
                    if (_loading)
                      const CircularProgressIndicator(
                        color: Colors.white,
                      )

                    // DATA KASIR KOSONG
                    else if (_kasir.isEmpty)
                      Column(
                        children: [
                          const Text(
                            'Tidak ada data kasir.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 12),

                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _loading = true;
                              });

                              _loadKasir();
                            },
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      )

                    // DAFTAR CARD KASIR
                    else
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 14,
                        runSpacing: 18,

                        children: List.generate(
                          _kasir.length,
                          (index) {
                            return _cardKasir(
                              _kasir[index],
                              index,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
