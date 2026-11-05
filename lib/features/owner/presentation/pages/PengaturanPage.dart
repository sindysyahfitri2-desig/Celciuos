import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasir_celcious_coffe/data/app_branding_store.dart';
import 'package:kasir_celcious_coffe/data/qris_store.dart';
import 'package:kasir_celcious_coffe/data/receipt_settings_store.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/settings/application/settings_service.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';

String _formatPercent(double rate) =>
    (rate * 100).toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

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
  bool _showReceiptManagement = false;

  String namaToko = 'Nama Toko';
  String alamatToko = 'Alamat Toko';

  String ppn = '${_formatPercent(TransactionStore.ppnRate.value)}%';
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

  final TextEditingController ppnController = TextEditingController(
    text: _formatPercent(TransactionStore.ppnRate.value),
  );

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
    _muatPengaturanStruk();
  }

  Future<void> _muatPengaturanStruk() async {
    try {
      await ReceiptSettingsStore.initialize();
      if (!mounted) return;
      setState(() {
        strukAktif = ReceiptSettingsStore.options.value['enabled'] ?? true;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat pengaturan struk: $error')),
      );
    }
  }

  Future<void> _simpanOpsiStruk(String key, bool value) async {
    try {
      await ReceiptSettingsStore.setOption(key, value);
      if (!mounted) return;
      setState(() {
        if (key == 'enabled') strukAktif = value;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pengaturan struk: $error')),
      );
    }
  }

  Future<void> _muatFotoQris() async {
    try {
      final bytes = await QrisStore.loadImageBytes();
      if (!mounted) return;
      setState(() {
        _qrisImageBytes = bytes;
        _memuatQris = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _memuatQris = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat foto QRIS: $error')));
    }
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

  Future<void> simpanPengaturan() async {
    try {
      final ppnValue = await SettingsService.saveTaxRate(ppnController.text);
      if (!mounted) return;
      setState(() {
        namaToko = namaTokoController.text.trim().isEmpty
            ? 'Nama Toko'
            : namaTokoController.text.trim();
        ppn = '${ppnValue}%';
        biayaPelayanan = '${pelayananController.text.trim()}%';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan berhasil disimpan')),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan PPN: $error')));
    }
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

        if (_showReceiptManagement) {
          return _halamanKelolaStruk(
            isMobile: isMobile,
            isTablet: isTablet,
            maxContentWidth: maxContentWidth,
          );
        }

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
                                onChanged: (value) =>
                                    _simpanOpsiStruk('enabled', value),
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
                          onTap: () {
                            setState(() => _showReceiptManagement = true);
                          },
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() => _showReceiptManagement = true);
                            },
                            icon: Icon(
                              Icons.tune_rounded,
                              size: contentSize + 2,
                            ),
                            label: Text(
                              'Kelola',
                              style: TextStyle(fontSize: contentSize - 1),
                            ),
                            style: TextButton.styleFrom(foregroundColor: navy),
                          ),
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

  Widget _halamanKelolaStruk({
    required bool isMobile,
    required bool isTablet,
    required double maxContentWidth,
  }) {
    final options = ReceiptSettingsStore.options.value;
    final receiptItems = <(String, String)>[
      ('storeLogo', 'Logo Toko'),
      ('orderNumber', 'Nomor Antri'),
      ('cashierName', 'Nama Kasir'),
      ('orderTime', 'Waktu Pesan'),
      ('qrCode', 'QR Code'),
      ('total', 'Total Bayar'),
    ];

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 14 : 22,
            isMobile ? 14 : 20,
            isMobile ? 14 : 22,
            28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() => _showReceiptManagement = false);
                        },
                        tooltip: 'Kembali ke Pengaturan',
                        icon: Icon(Icons.arrow_back_rounded, color: navy),
                      ),
                      Expanded(
                        child: Text(
                          'Pengaturan Pengelolaan Struk',
                          style: TextStyle(
                            color: navy,
                            fontSize: isMobile ? 19 : 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: isMobile ? 4 : 58,
                      bottom: 14,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: strukAktif
                            ? const Color(0xffc7f0ce)
                            : const Color(0xffe6e9ec),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        strukAktif ? 'Pratinjau aktif' : 'Struk dinonaktifkan',
                        style: TextStyle(
                          color: strukAktif
                              ? const Color(0xff246a32)
                              : const Color(0xff5d6871),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (isMobile || isTablet)
                    Column(
                      children: [
                        _panelOpsiStruk(receiptItems, options),
                        const SizedBox(height: 16),
                        _previewStruk(options, isMobile: isMobile),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _panelOpsiStruk(receiptItems, options)),
                        const SizedBox(width: 18),
                        SizedBox(
                          width: 285,
                          child: _previewStruk(options, isMobile: false),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _panelOpsiStruk(
    List<(String, String)> receiptItems,
    Map<String, bool> options,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            namaTokoController.text.trim().isEmpty
                ? 'Celcious Coffee'
                : namaTokoController.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Atur elemen yang ditampilkan pada struk',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 14),
            decoration: BoxDecoration(
              color: const Color(0xffdce9f4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: navy, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Elemen Tampilan Struk',
                      style: TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Divider(color: navy.withValues(alpha: 0.3), height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tileWidth = (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final (key, label) in receiptItems)
                          SizedBox(
                            width: tileWidth,
                            child: _receiptOptionTile(
                              key: key,
                              label: label,
                              enabled: options[key] ?? true,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptOptionTile({
    required String key,
    required String label,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xff214261),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tampilkan pada struk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 8),
                ),
              ],
            ),
          ),
          Switch(
            key: ValueKey('receipt-option-$key'),
            value: enabled,
            activeThumbColor: const Color(0xff55adf5),
            onChanged: (value) => _simpanOpsiStruk(key, value),
          ),
        ],
      ),
    );
  }

  Widget _previewStruk(Map<String, bool> options, {required bool isMobile}) {
    final storeName = namaTokoController.text.trim().isEmpty
        ? 'Celcious Coffee'
        : namaTokoController.text.trim();

    Widget detail(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 9, color: Color(0xff3f5261)),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 9, color: Color(0xff3f5261)),
            ),
          ],
        ),
      );
    }

    return Container(
      width: isMobile ? double.infinity : null,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (options['storeLogo'] ?? true)
            Container(
              width: 58,
              height: 58,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: const AppBrandingLogo(fit: BoxFit.cover, height: 58),
            ),
          if (options['storeLogo'] ?? true) const SizedBox(height: 7),
          Text(
            storeName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff214261),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Alamat Cafe',
            style: TextStyle(color: Color(0xff6a7b88), fontSize: 8),
          ),
          const Divider(height: 18),
          if (options['orderNumber'] ?? true)
            const Text(
              'Order #C001',
              style: TextStyle(
                color: Color(0xff214261),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (options['cashierName'] ?? true)
            const Text(
              'Kasir: Admin',
              style: TextStyle(color: Color(0xff526575), fontSize: 8),
            ),
          if (options['orderTime'] ?? true) ...[
            const SizedBox(height: 8),
            detail('Tanggal / Waktu', '05/11/2026 14:10'),
          ],
          const Divider(height: 16),
          detail('Americano  x1', 'Rp 20.000'),
          detail('Pajak', 'Rp 2.200'),
          if (options['total'] ?? true) ...[
            const Divider(height: 12),
            detail('Total', 'Rp 22.200'),
          ],
          if (options['qrCode'] ?? true) ...[
            const SizedBox(height: 16),
            if (_qrisImageBytes != null)
              Image.memory(
                _qrisImageBytes!,
                width: 84,
                height: 84,
                fit: BoxFit.contain,
              )
            else
              Icon(Icons.qr_code_2_rounded, size: 84, color: navy),
          ],
        ],
      ),
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
    VoidCallback? onTap,
  }) {
    final row = Container(
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
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
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
                Text(
                  'Foto QRIS pembayaran',
                  style: normalStyle(isMobile ? 12 : 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _qrisImageBytes == null
                      ? 'Belum ada foto QRIS khusus. Tekan tombol + untuk memilih foto.'
                      : 'Foto ini akan ditampilkan saat kasir memilih QRIS.',
                  style: TextStyle(
                    color: navy.withOpacity(0.72),
                    fontSize: isMobile ? 10 : 12,
                  ),
                ),
                const SizedBox(height: 5),
                TextButton.icon(
                  onPressed: pilihFotoQris,
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Ganti foto'),
                  style: TextButton.styleFrom(
                    foregroundColor: navy,
                    padding: EdgeInsets.zero,
                  ),
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
