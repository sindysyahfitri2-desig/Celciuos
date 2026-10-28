import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/qris_store.dart';
import '../data/app_branding_store.dart';
import '../data/transaction_store.dart';
import '../widgets/app_branding_logo.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  // ==========================================================
  // WARNA
  // ==========================================================

  final Color navy = const Color(0xFF103657);
  final Color background = const Color(0xffdce9f4);

  // ==========================================================
  // DATA PENGATURAN
  // ==========================================================

  bool strukAktif = true;
  bool stikerAktif = false;

  String namaToko = 'Nama Toko';
  String alamatToko = 'Alamat Toko';

  String ppn = '11%';
  String biayaPelayanan = '2%';
  String metodePembayaran = 'Qris';
  Uint8List? _qrisImageBytes;
  bool _memuatQris = true;

  // ==========================================================
  // FOTO PROFIL
  // ==========================================================

  // ==========================================================
  // CONTROLLER
  // ==========================================================

  final TextEditingController namaTokoController = TextEditingController(
    text: 'Celcious Coffe',
  );

  final TextEditingController ppnController = TextEditingController(text: '11');

  final TextEditingController pelayananController = TextEditingController(
    text: '2',
  );

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _muatFotoQris();
  }

  Future<void> _muatFotoQris() async {
    final bytes = await QrisStore.loadImageBytes();
    if (!mounted) return;
    setState(() {
      _qrisImageBytes = bytes;
      _memuatQris = false;
    });
  }

  Future<void> pilihFotoQris() async {
    final XFile? foto = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (foto == null) return;

    try {
      final bytes = await foto.readAsBytes();
      await QrisStore.saveImageBytes(bytes);
      if (!mounted) return;
      setState(() => _qrisImageBytes = bytes);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto QRIS berhasil disimpan')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan foto QRIS: $error')),
      );
    }
  }

  @override
  void dispose() {
    namaTokoController.dispose();
    ppnController.dispose();
    pelayananController.dispose();

    super.dispose();
  }

  // ==========================================================
  // FONT
  // ==========================================================

  TextStyle normalStyle(double size) {
    return TextStyle(color: navy, fontSize: size, fontWeight: FontWeight.w500);
  }

  // ==========================================================
  // PILIH FOTO PROFIL
  // ==========================================================

  Future<void> pilihFotoProfil() async {
    final ImagePicker picker = ImagePicker();

    final XFile? foto = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (foto == null) return;

    try {
      await AppBrandingStore.saveLogo(foto);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan foto toko: $error')),
      );
    }
  }

  // ==========================================================
  // SIMPAN PENGATURAN
  // ==========================================================

  void simpanPengaturan() {
    final ppnValue = double.tryParse(ppnController.text.trim());
    if (ppnValue == null || ppnValue < 0 || ppnValue > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PPN harus berupa angka antara 0 sampai 100.'),
        ),
      );
      return;
    }

    TransactionStore.savePpnRate(ppnValue / 100)
        .then((_) {
          if (!mounted) return;
          setState(() {
            ppn = '${ppnValue}%';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengaturan berhasil disimpan')),
          );
        })
        .catchError((Object error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan PPN: $error')),
          );
        });

    setState(() {
      namaToko = namaTokoController.text.trim().isEmpty
          ? 'Nama Toko'
          : namaTokoController.text.trim();
      ppn = '${ppnController.text.trim()}%';

      biayaPelayanan = '${pelayananController.text.trim()}%';
    });
  }

  // ==========================================================
  // EDIT NAMA TOKO
  // ==========================================================

  void editNamaToko() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit Nama Toko',
            style: TextStyle(color: navy, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: namaTokoController,
            maxLength: 50,
            decoration: const InputDecoration(
              hintText: 'Masukkan nama toko',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  namaToko = namaTokoController.text.trim().isEmpty
                      ? 'Nama Toko'
                      : namaTokoController.text.trim();
                });

                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        // ======================================================
        // RESPONSIVE
        // ======================================================

        final bool isMobile = width < 600;

        final bool isTablet = width >= 600 && width < 950;

        final bool isDesktop = width >= 950;

        // ======================================================
        // PADDING
        // ======================================================

        final double horizontalPadding = isMobile
            ? 16
            : isTablet
            ? 29
            : 45;

        // ======================================================
        // UKURAN FONT
        // ======================================================

        final double titleSize = isMobile
            ? 17
            : isTablet
            ? 16
            : 16;

        final double contentSize = isMobile
            ? 15
            : isTablet
            ? 16
            : 14;

        // ======================================================
        // LEBAR KONTEN DESKTOP
        // ======================================================

        final double maxContentWidth = isDesktop ? 1100 : double.infinity;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: background,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isMobile ? 25 : 35),
                    child: Column(
                      children: [
                        // ==================================================
                        // PROFIL TOKO
                        // ==================================================
                        profileSection(
                          isMobile: isMobile,
                          isTablet: isTablet,
                          horizontalPadding: horizontalPadding,
                        ),

                        divider(),

                        // ==================================================
                        // DEVICE
                        // ==================================================
                        settingRow(
                          title: 'Pengaturan Device',
                          titleSize: titleSize,
                          horizontalPadding: horizontalPadding,
                          isMobile: isMobile,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: isMobile ? 4 : 18,
                            runSpacing: 2,
                            children: [
                              deviceSwitch(
                                label: 'Struk',
                                value: strukAktif,
                                icon: Icons.print_outlined,
                                size: contentSize,
                                onChanged: (value) {
                                  setState(() {
                                    strukAktif = value;
                                  });
                                },
                              ),

                              deviceSwitch(
                                label: 'Stiker',
                                value: stikerAktif,
                                icon: Icons.print_outlined,
                                size: contentSize,
                                onChanged: (value) {
                                  setState(() {
                                    stikerAktif = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        // ==================================================
                        // PPN
                        // ==================================================
                        settingRow(
                          title: 'Pengaturan PPN',
                          titleSize: titleSize,
                          horizontalPadding: horizontalPadding,
                          isMobile: isMobile,
                          child: percentageControl(
                            controller: ppnController,
                            size: contentSize,
                            onPressed: () {
                              simpanPengaturan();
                            },
                          ),
                        ),

                        // ==================================================
                        // BIAYA PELAYANAN
                        // ==================================================
                        settingRow(
                          title: 'Pengaturan Biaya Pelayanan',
                          titleSize: titleSize,
                          horizontalPadding: horizontalPadding,
                          isMobile: isMobile,
                          child: percentageControl(
                            controller: pelayananController,
                            size: contentSize,
                            onPressed: () {
                              setState(() {
                                biayaPelayanan = '${pelayananController.text}%';
                              });
                            },
                          ),
                        ),

                        // ==================================================
                        // PEMBAYARAN
                        // ==================================================
                        settingRow(
                          title: 'Pengaturan Pembayaran',
                          titleSize: titleSize,
                          horizontalPadding: horizontalPadding,
                          isMobile: isMobile,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              paymentControl(
                                size: contentSize,
                                isMobile: isMobile,
                              ),
                              SizedBox(
                                width: isMobile ? 300 : 390,
                                child: previewFotoQris(isMobile: isMobile),
                              ),
                            ],
                          ),
                        ),

                        // ==================================================
                        // STRUK
                        // ==================================================
                        settingRow(
                          title: 'Pengaturan Struk',
                          titleSize: titleSize,
                          horizontalPadding: horizontalPadding,
                          isMobile: isMobile,
                          child: const SizedBox.shrink(),
                        ),

                        // ==================================================
                        // STIKER
                        // ==================================================
                        settingRow(
                          title: 'Pengaturan Stiker',
                          titleSize: titleSize,
                          horizontalPadding: horizontalPadding,
                          isMobile: isMobile,
                          child: const SizedBox.shrink(),
                        ),

                        // ==================================================
                        // BACKUP
                        // ==================================================
                        settingRow(
                          title: 'Ekspor Semuanya Ke File (Backup)',
                          titleSize: titleSize,
                          horizontalPadding: horizontalPadding,
                          isMobile: isMobile,
                          child: const SizedBox.shrink(),
                        ),

                        // ==================================================
                        // BUTTON SIMPAN
                        // ==================================================
                        const SizedBox(height: 24),

                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: SizedBox(
                            width: isMobile ? 190 : 240,
                            height: isMobile ? 42 : 48,
                            child: ElevatedButton(
                              onPressed: simpanPengaturan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: navy,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Simpan Pengaturan',
                                style: TextStyle(
                                  color: navy,
                                  fontSize: contentSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // PROFILE SECTION
  // ==========================================================

  Widget profileSection({
    required bool isMobile,
    required bool isTablet,
    required double horizontalPadding,
  }) {
    final double logoSize = isMobile
        ? 64
        : isTablet
        ? 76
        : 90;

    final double nameSize = isMobile
        ? 15
        : isTablet
        ? 18
        : 21;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isMobile ? 14 : 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ======================================================
          // FOTO PROFIL
          // ======================================================
          GestureDetector(
            onTap: pilihFotoProfil,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF477CA7),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: AppBrandingLogo(
                      fallbackIcon: Icons.camera_alt_outlined,
                      fallbackIconSize: isMobile ? 24 : 32,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Ganti Foto',
                  style: TextStyle(
                    color: navy,
                    fontSize: isMobile ? 9 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // JARAK FOTO
          // ======================================================
          SizedBox(width: isMobile ? 13 : 20),

          // ======================================================
          // NAMA + ALAMAT
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ==================================================
                // NAMA TOKO
                // ==================================================
                GestureDetector(
                  onTap: editNamaToko,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          namaToko,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: navy,
                            fontSize: nameSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 5),

                      Icon(
                        Icons.edit_outlined,
                        size: isMobile ? 13 : 16,
                        color: navy,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SETTING ROW
  // ==========================================================

  Widget settingRow({
    required String title,
    required double titleSize,
    required double horizontalPadding,
    required bool isMobile,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isMobile ? 9 : 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: navy.withOpacity(0.20), width: 0.7),
          bottom: BorderSide(color: navy.withOpacity(0.20), width: 0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ======================================================
          // JUDUL
          // ======================================================
          Expanded(
            flex: 5,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: navy,
                fontSize: titleSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ======================================================
          // KONTEN
          // ======================================================
          Flexible(
            flex: 6,
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DEVICE SWITCH
  // ==========================================================

  Widget deviceSwitch({
    required String label,
    required bool value,
    required IconData icon,
    required double size,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: normalStyle(size)),

        Transform.scale(
          scale: 0.65,
          child: Switch(value: value, activeColor: navy, onChanged: onChanged),
        ),

        Icon(icon, size: size + 5, color: navy),
      ],
    );
  }

  // ==========================================================
  // PERCENTAGE CONTROL
  // ==========================================================

  Widget percentageControl({
    required TextEditingController controller,
    required double size,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // INPUT
        SizedBox(
          width: 52,
          height: 30,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 2,
            style: TextStyle(
              color: navy,
              fontSize: size,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              counterText: '',
              suffixText: '%',
              suffixStyle: TextStyle(
                color: navy,
                fontSize: size,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const SizedBox(width: 4),

        // SIMPAN
        SizedBox(
          height: 30,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Simpan',
              style: TextStyle(fontSize: size - 1, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PAYMENT CONTROL
  // ==========================================================

  Widget paymentControl({required double size, required bool isMobile}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ======================================================
        // QR
        // ======================================================
        Container(
          width: isMobile ? 30 : 36,
          height: isMobile ? 30 : 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.qr_code_2, size: isMobile ? 20 : 25, color: navy),
        ),

        const SizedBox(width: 4),

        // ======================================================
        // DROPDOWN
        // ======================================================
        Container(
          height: isMobile ? 30 : 36,
          constraints: BoxConstraints(
            minWidth: isMobile ? 72 : 100,
            maxWidth: isMobile ? 105 : 150,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: metodePembayaran,
              isDense: true,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: isMobile ? 14 : 18,
                color: navy,
              ),
              style: TextStyle(
                color: navy,
                fontSize: size,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                DropdownMenuItem(value: 'Qris', child: Text('Qris')),
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  metodePembayaran = value;
                });
              },
            ),
          ),
        ),

        const SizedBox(width: 4),

        // ======================================================
        // TAMBAH
        // ======================================================
        Container(
          width: isMobile ? 30 : 36,
          height: isMobile ? 30 : 36,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: pilihFotoQris,
            tooltip: 'Ganti foto QRIS',
            padding: EdgeInsets.zero,
            icon: Icon(Icons.add, color: navy, size: isMobile ? 17 : 22),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PREVIEW QRIS YANG TERSIMPAN
  // ==========================================================

  Widget previewFotoQris({required bool isMobile}) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffc8d9e8)),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 68 : 86,
            height: isMobile ? 68 : 86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _memuatQris
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _qrisImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _qrisImageBytes!,
                          fit: BoxFit.contain,
                          width: isMobile ? 68 : 86,
                          height: isMobile ? 68 : 86,
                        ),
                      )
                    : Icon(Icons.qr_code_2, color: navy, size: isMobile ? 36 : 46),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Foto QRIS pembayaran', style: normalStyle(isMobile ? 12 : 14)),
                const SizedBox(height: 4),
                Text(
                  _qrisImageBytes == null
                      ? 'Belum ada foto QRIS khusus. Tekan tombol + untuk memilih foto.'
                      : 'Foto ini akan ditampilkan saat kasir memilih QRIS.',
                  style: TextStyle(color: navy.withOpacity(0.72), fontSize: isMobile ? 10 : 12),
                ),
                const SizedBox(height: 5),
                TextButton.icon(
                  onPressed: pilihFotoQris,
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Ganti foto'),
                  style: TextButton.styleFrom(foregroundColor: navy, padding: EdgeInsets.zero),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // GARIS
  // ==========================================================

  Widget divider() {
    return Container(height: 1, color: navy.withOpacity(0.25));
  }
}
