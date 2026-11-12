
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
  final Color whiteGlow = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadKasir();
  }

  // LOAD DATA KASIR
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

  // DIALOG PIN KASIR
  Future<String?> _askPin(BuildContext context, String nama) async {
    final c = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 14,
          insetPadding: const EdgeInsets.symmetric(horizontal: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          child: SizedBox(
            width: 350,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // JUDUL DIALOG
                  Text(
                    'PIN Untuk Kasir',
                    style: TextStyle(
                      color: navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 13),

                  // INPUT PIN
                  TextField(
                    controller: c,
                    autofocus: true,
                    obscureText: true,
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
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 9,
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

                    onSubmitted: (v) {
                      Navigator.pop(dialogContext, v.trim());
                    },
                  ),

                  const SizedBox(height: 8),

                  // TOMBOL BATAL DAN MASUK
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 35,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: navy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: const StadiumBorder(),
                            ),

                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: SizedBox(
                          height: 34,
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
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: const StadiumBorder(),
                            ),

                            child: const Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 14,
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

    c.dispose();
    return result;
  }

  // LOGIN KASIR
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

      try {
        await CashierShiftService.syncFromBackend();
      } catch (_) {}

      await ProdukData.loadFromApi();

      if (!mounted) return;

      final shiftAktif =
          CashierShiftService.activeShift() != null;

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

  // CARD PROFIL KASIR
  Widget _cardKasir(
    Map<String, dynamic> k,
    int index,
  ) {
    final bool isHovered = hoveredIndex == index;

    final String nama = k['nama'].toString();
    final String? fotoUrl = k['foto_url']?.toString();

    return MouseRegion(
      cursor: SystemMouseCursors.click,

      // KURSOR MASUK
      onEnter: (_) {
        setState(() {
          hoveredIndex = index;
        });
      },

      // KURSOR KELUAR
      onExit: (_) {
        setState(() {
          hoveredIndex = null;
        });
      },

      child: GestureDetector(
        onTap: () => _login(k),

        child: AnimatedScale(
          scale: isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,

            width: 200,

            padding: const EdgeInsets.all(5),

            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(10),

              // BORDER PUTIH SAAT HOVER
              border: Border.all(
                color: isHovered
                    ? Colors.white
                    : Colors.transparent,
                width: 6,
              ),

              // GLOWING PUTIH LEMBUT
              boxShadow: [
                BoxShadow(
                  color: isHovered
                      ? whiteGlow.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.18),
                  blurRadius: isHovered ? 12 : 6,
                  spreadRadius: isHovered ? 1 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // FOTO KASIR
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),

                  child: Container(
                    width: double.infinity,
                    height: 185,
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
                                size: 55,
                                color: navy,
                              );
                            },
                          )
                        : Icon(
                            Icons.person,
                            size: 55,
                            color: navy,
                          ),
                  ),
                ),

                const SizedBox(height: 7),

                // NAMA KASIR
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 4,
                    left: 2,
                    right: 2,
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
                        spacing: 5,
                        runSpacing: 14,

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
