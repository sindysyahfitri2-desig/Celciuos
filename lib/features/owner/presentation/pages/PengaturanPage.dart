import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/app_branding_store.dart';
import 'package:kasir_celcious_coffe/data/qris_store.dart';
import 'package:kasir_celcious_coffe/data/receipt_settings_store.dart';
import 'package:kasir_celcious_coffe/data/sticker_settings_store.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/settings/application/backup_service.dart';
import 'package:kasir_celcious_coffe/features/settings/application/settings_service.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';
import 'package:kasir_celcious_coffe/features/settings/application/print_service.dart';

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

  // Warna khusus halaman Kelola Struk
  final Color _panelNavy = const Color(0xff1f3f5f);
  final Color _tileNavy = const Color(0xff214261);
  final Color _tileMati = const Color(0xff1a3450);
  final Color _judulStruk = const Color(0xff176080);
  final Color _biruSwitch = const Color(0xff55adf5);

  // ==========================================================
  // DATA PENGATURAN
  // ==========================================================

  bool strukAktif = true;
  bool stikerAktif = true;
  bool _showReceiptManagement = false;
  // di bagian DATA PENGATURAN (hapus _showStickerManagement lama, ganti ini bila perlu)
  bool _showStickerManagement = false;

  final TextEditingController captionController = TextEditingController(
    text: 'Selamat menikmati, semoga harimu menyenangkan ☕',
  );
  bool _isSavingPengaturan = false;
  bool _isExporting = false;

  String namaToko = 'Nama Toko';
  String alamatToko = 'Alamat Toko';

  String ppn = '${_formatPercent(TransactionStore.ppnRate.value)}%';
  String biayaPelayanan = '2%';
  String metodePembayaran = 'Qris';

  Uint8List? _qrisImageBytes;
  bool _memuatQris = true;

  // urutan baris untuk animasi masuk bertahap
  int _barisKe = 0;

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
  // INIT STATE
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _muatFotoQris();
    _muatPengaturanStruk();
    _muatPengaturanStiker();
    _muatPengaturanBackend();
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

  Future<void> _muatPengaturanStiker() async {
    try {
      await StickerSettingsStore.initialize();

      if (!mounted) return;

      setState(() {
        stikerAktif = StickerSettingsStore.options.value['enabled'] ?? true;
      });
    } catch (error) {
      debugPrint('Gagal memuat pengaturan stiker: $error');
    }
  }

  // ==========================================================
  // MUAT PENGATURAN DARI BACKEND
  // ==========================================================

  Future<void> _muatPengaturanBackend() async {
    try {
      final res = await ApiService.get('pengaturan-toko');
      final data = res['data'];
      if (data is Map<String, dynamic> && mounted) {
        setState(() {
          if (data['nama_toko'] != null &&
              data['nama_toko'].toString().trim().isNotEmpty) {
            namaTokoController.text = data['nama_toko'].toString().trim();
            namaToko = namaTokoController.text;
          }
          if (data['alamat'] != null) {
            alamatToko = data['alamat'].toString();
          }
          if (data['ppn_persen'] != null) {
            final rate = double.tryParse(data['ppn_persen'].toString()) ?? 11;
            ppnController.text = _formatPercent(rate / 100);
            ppn = '${ppnController.text}%';
            TransactionStore.savePpnRate(rate / 100);
          }
          if (data['biaya_layanan_persen'] != null) {
            final svc =
                double.tryParse(data['biaya_layanan_persen'].toString()) ?? 2;
            pelayananController.text = svc.toStringAsFixed(0);
            biayaPelayanan = '${pelayananController.text}%';
          }
          if (data['printer_struk'] != null) {
            strukAktif = data['printer_struk'] == 'aktif';
            ReceiptSettingsStore.setOption('enabled', strukAktif);
          }
          if (data['printer_stiker'] != null) {
            stikerAktif = data['printer_stiker'] == 'aktif';
            StickerSettingsStore.setOption('enabled', stikerAktif);
          }
          if (data['caption_stiker'] != null) {
            captionController.text = data['caption_stiker'].toString();
          }
          if (data['template_struk'] is String &&
              data['template_struk'].toString().isNotEmpty) {
            try {
              final decoded = jsonDecode(data['template_struk']);
              if (decoded is Map) {
                for (final e in decoded.entries) {
                  if (e.key is String && e.value is bool) {
                    ReceiptSettingsStore.options.value[e.key as String] =
                        e.value as bool;
                  }
                }
              }
            } catch (_) {}
          }
          if (data['template_stiker'] is String &&
              data['template_stiker'].toString().isNotEmpty) {
            try {
              final decoded = jsonDecode(data['template_stiker']);
              if (decoded is Map) {
                for (final e in decoded.entries) {
                  if (e.key is String && e.value is bool) {
                    StickerSettingsStore.options.value[e.key as String] =
                        e.value as bool;
                  }
                }
              }
            } catch (_) {}
          }
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat pengaturan toko dari backend: $e');
    }
  }

  // ==========================================================
  // SIMPAN OPSI STRUK & STIKER
  // ==========================================================

  Future<void> _simpanOpsiStruk(String key, bool value) async {
    try {
      await ReceiptSettingsStore.setOption(key, value);

      if (!mounted) return;

      setState(() {
        if (key == 'enabled') strukAktif = value;
      });

      await _sinkronTemplateBackend();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pengaturan struk: $error')),
      );
    }
  }

  Future<void> _simpanOpsiStiker(String key, bool value) async {
    try {
      await StickerSettingsStore.setOption(key, value);

      if (!mounted) return;

      setState(() {
        if (key == 'enabled') stikerAktif = value;
      });

      await _sinkronTemplateBackend();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pengaturan stiker: $error')),
      );
    }
  }

  // ==========================================================
  // MUAT FOTO QRIS
  // ==========================================================

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

      setState(() {
        _qrisImageBytes = bytes;
      });

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

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    namaTokoController.dispose();
    ppnController.dispose();
    pelayananController.dispose();
    captionController.dispose();
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

      if (!mounted) return;

      setState(() {});
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
      builder: (dialogContext) {
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
                Navigator.pop(dialogContext);
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

                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // SINKRON KE BACKEND
  // ==========================================================

  Future<void> _sinkronTemplateBackend() async {
    try {
      // SESUAIKAN: nama method & endpoint ApiService milikmu (put/post)
      await ApiService.put('pengaturan-toko', {
        'template_struk': jsonEncode(ReceiptSettingsStore.options.value),
        'template_stiker': jsonEncode(StickerSettingsStore.options.value),
        'caption_stiker': captionController.text
            .trim(), // SESUAIKAN: kolom baru di backend
        'printer_struk': strukAktif ? 'aktif' : 'nonaktif',
        'printer_stiker': stikerAktif ? 'aktif' : 'nonaktif',
      });
    } catch (e) {
      debugPrint('Gagal sinkron template ke backend: $e');
    }
  }

  Future<void> _simpanCaption() async {
    await _sinkronTemplateBackend();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Caption stiker disimpan')));
  }

  Map<String, dynamic> get _contohTransaksi => {
    'id_transaksi': 0,
    'kode': 'A201',
    'nama_pelanggan': 'desi',
    'tipe_pesanan': 'Dine In',
    'tanggal': DateTime.now().toIso8601String(),
    'subtotal': '20000',
    'ppn': '2200',
    'biaya_layanan': '400',
    'diskon': '0',
    'total': '22600',
    'pengguna': {'nama': 'Dessy Manurung', 'username': 'CL0101'},
    'metode_pembayaran': {'nama_metode': 'Qris'},
    'detail_transaksi': [
      {
        'jumlah': 2,
        'varian': 'ICE, REGULAR',
        'harga_satuan': '10000',
        'subtotal': '20000',
        'produk': {'nama_produk': 'Americano'},
      },
    ],
  };

  Future<void> _tesCetakStikerDapur() async {
    await _sinkronTemplateBackend(); // pastikan template terbaru sudah di server
    await PrintService.cetakStikerTransaksi(_contohTransaksi);
  }

  Future<void> _tesCetakStruk() async {
    await _sinkronTemplateBackend();
    await PrintService.cetakStruk(_contohTransaksi);
  }

  Future<void> _pilihPrinter(String prefKey, String label) async {
    final nama = await PrintService.pilihPrinter(context, prefKey);
    if (!mounted || nama == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Printer $label: $nama')));
  }
  // ==========================================================
  // EKSPOR BACKUP
  // ==========================================================

  Future<void> _ekspor({required bool excel}) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final path = excel
          ? await BackupService.exportToExcel()
          : await BackupService.exportToJson();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup berhasil disimpan: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal ekspor backup: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _tombolEkspor({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required double size,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: size + 2),
      label: Text(
        label,
        style: TextStyle(fontSize: size - 1, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==========================================================
  // KARTU STIKER (dipakai preview DAN cetak, kirim data pesanan asli)
  // ==========================================================

  Widget _stikerCard({
    required Map<String, bool> options,
    required String nomor,
    required String namaPelanggan,
    required String tipe,
    required String menu,
    required String varian,
    required String waktu,
    required String kode,
    required String urutan,
    required String caption,
    double scale = 1,
  }) {
    bool on(String k) => options[k] ?? true;
    const mono = 'Courier';
    const ink = Color(0xff222222);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0xfffcfbf6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe4e1d6)),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (on('orderNumber'))
                Text(
                  nomor,
                  style: TextStyle(
                    fontFamily: mono,
                    color: ink,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const Spacer(),
              if (on('customerName'))
                Text(
                  namaPelanggan,
                  style: TextStyle(
                    fontFamily: mono,
                    color: ink,
                    fontSize: 14 * scale,
                  ),
                ),
              if (on('customerName') && on('orderType'))
                const SizedBox(width: 4),
              if (on('orderType'))
                Text(
                  tipe,
                  style: TextStyle(
                    fontFamily: mono,
                    color: ink,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (on('productName'))
            Padding(
              padding: EdgeInsets.only(top: 4 * scale),
              child: Text(
                menu,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: mono,
                  color: ink,
                  fontSize: 26 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (on('productVariant'))
            Padding(
              padding: EdgeInsets.only(top: 4 * scale),
              child: Text(
                varian,
                style: TextStyle(
                  fontFamily: mono,
                  color: ink,
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (on('caption') && caption.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 10 * scale),
              child: Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: mono,
                  color: const Color(0xff555555),
                  fontSize: 10 * scale,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          SizedBox(height: 22 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  [
                    if (on('orderTime')) waktu,
                    if (on('cashierCode')) kode,
                  ].join(' '),
                  style: TextStyle(
                    fontFamily: mono,
                    color: ink,
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (on('itemProgress'))
                Text(
                  urutan,
                  style: TextStyle(
                    fontFamily: mono,
                    color: ink,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HALAMAN KELOLA STIKER
  // ==========================================================

  Widget _halamanKelolaStiker({
    required bool isMobile,
    required double maxContentWidth,
  }) {
    final options = StickerSettingsStore.options.value;
    final bool besar = !isMobile;

    final items = <(String, String)>[
      ('orderNumber', 'Nomor Antrian'),
      ('customerName', 'Nama Pelanggan'),
      ('orderType', 'Tipe (Dine In / Take Away)'),
      ('productName', 'Nama Menu'),
      ('productVariant', 'Varian (Ice, Regular)'),
      ('orderTime', 'Tanggal & Jam'),
      ('cashierCode', 'Kode Kasir'),
      ('itemProgress', 'Urutan Item (2/2)'),
      ('caption', 'Caption Pelanggan'),
    ];

    final panel = Container(
      width: double.infinity,
      padding: EdgeInsets.all(besar ? 18 : 12),
      decoration: BoxDecoration(
        color: _panelNavy,
        borderRadius: BorderRadius.circular(besar ? 24 : 14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sell_outlined,
                color: Colors.white,
                size: besar ? 24 : 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Elemen Tampilan Stiker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: besar ? 17 : 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (key, label) in items)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: (options[key] ?? true) ? _tileNavy : _tileMati,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                dense: true,
                title: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: besar ? 15 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                value: options[key] ?? true,
                activeThumbColor: Colors.white,
                activeTrackColor: _biruSwitch,
                onChanged: (v) => _simpanOpsiStiker(key, v),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Caption stiker',
            style: TextStyle(
              color: Colors.white,
              fontSize: besar ? 14 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: captionController,
            maxLength: 60,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Contoh: Kopi enak, hari makin semangat!',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _simpanCaption,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Simpan Caption'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: navy,
                ),
              ),
              ElevatedButton.icon(
                onPressed: stikerAktif ? _tesCetakStikerDapur : null,
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Tes Cetak ke Dapur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _biruSwitch,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _pilihPrinter(PrintService.kPrinterDapur, 'dapur'),
                icon: const Icon(Icons.settings_input_hdmi_outlined, size: 18),
                label: const Text('Pilih Printer Dapur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final preview = _stikerCard(
      options: options,
      nomor: 'A201',
      namaPelanggan: 'desi',
      tipe: 'Di',
      menu: 'Americano',
      varian: 'ICE, REGULAR',
      waktu: 'OCT 18,17:03',
      kode: 'CL0101',
      urutan: '2/2',
      caption: captionController.text,
      scale: besar ? 1 : 0.9,
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: background,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(besar ? 28 : 14, 8, besar ? 28 : 14, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            setState(() => _showStickerManagement = false),
                        tooltip: 'Kembali ke Pengaturan',
                        icon: Icon(Icons.arrow_back_rounded, color: navy),
                      ),
                      Expanded(
                        child: Text(
                          'Pengaturan Stiker',
                          style: TextStyle(
                            color: _judulStruk,
                            fontSize: besar ? 28 : 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (besar)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: panel),
                        const SizedBox(width: 20),
                        SizedBox(width: 340, child: preview),
                      ],
                    )
                  else ...[
                    panel,
                    const SizedBox(height: 16),
                    preview,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
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

        final bool isMobile = width < 600;
        final bool isTablet = width >= 600 && width < 950;
        final bool isDesktop = width >= 950;

        final double horizontalPadding = isMobile
            ? 16
            : isTablet
            ? 29
            : 45;

        final double titleSize = isMobile ? 17 : 16;
        final double contentSize = isMobile
            ? 15
            : isTablet
            ? 16
            : 14;

        final double maxContentWidth = isDesktop ? 1100 : double.infinity;

        _barisKe = 0;

        if (_showReceiptManagement) {
          return _halamanKelolaStruk(
            isMobile: isMobile,
            isTablet: isTablet,
            maxContentWidth: maxContentWidth,
          );
        }
        if (_showStickerManagement) {
          return _halamanKelolaStiker(
            isMobile: isMobile,
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
                        profileSection(
                          isMobile: isMobile,
                          isTablet: isTablet,
                          horizontalPadding: horizontalPadding,
                        ),

                        divider(),

                        // DEVICE
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
                                onChanged: (value) =>
                                    _simpanOpsiStiker('enabled', value),
                              ),
                            ],
                          ),
                        ),

                        // PPN
                        settingRow(
                          title: 'Pengaturan PPN',
                          titleSize: titleSize,
                          horizontalPadding: horizontalPadding,
                          isMobile: isMobile,
                          child: percentageControl(
                            controller: ppnController,
                            size: contentSize,
                            onPressed: simpanPengaturan,
                          ),
                        ),

                        // BIAYA PELAYANAN
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

                        // PEMBAYARAN
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
                              // muncul halus hanya setelah foto QRIS ditambahkan (tombol +)
                              AnimatedSize(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topRight,
                                child: _qrisImageBytes != null
                                    ? SizedBox(
                                        width: isMobile ? 300 : 390,
                                        child: previewFotoQris(
                                          isMobile: isMobile,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),

                        // STRUK
                        settingRow(
                          title: 'Pengaturan Struk',
                          titleSize: titleSize,
                          horizontalPadding: horizontalPadding,
                          isMobile: isMobile,
                          onTap: () {
                            setState(() {
                              _showReceiptManagement = true;
                            });
                          },
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showReceiptManagement = true;
                              });
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

                        // STIKER
                        settingRow(
                          title: 'Pengaturan Stiker',
                          titleSize: titleSize,
                          horizontalPadding: horizontalPadding,
                          isMobile: isMobile,
                          onTap: () =>
                              setState(() => _showStickerManagement = true),
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _showStickerManagement = true),
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

                        // BACKUP
                        settingRow(
                          title: 'Ekspor Semuanya Ke File (Backup)',
                          titleSize: titleSize,
                          horizontalPadding: horizontalPadding,
                          isMobile: isMobile,
                          child: _isExporting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.end,
                                  children: [
                                    _tombolEkspor(
                                      icon: Icons.table_chart_outlined,
                                      label: 'Excel',
                                      size: contentSize,
                                      onPressed: () => _ekspor(excel: true),
                                    ),
                                    _tombolEkspor(
                                      icon: Icons.data_object_rounded,
                                      label: 'JSON',
                                      size: contentSize,
                                      onPressed: () => _ekspor(excel: false),
                                    ),
                                  ],
                                ),
                        ),

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
  // HALAMAN KELOLA STRUK  (DISESUAIKAN: ukuran, tinggi, warna)
  // ==========================================================

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

    final bool besar = !isMobile; // tablet & laptop = ukuran besar
    final double judulSize = isMobile ? 19 : (isTablet ? 25 : 30);
    final double padLuar = isMobile ? 14 : 28;

    // animasi masuk: fade + naik
    Widget masuk(Widget child, int urutan) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 450 + urutan * 150),
        curve: Curves.easeOutCubic,
        builder: (_, v, c) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: c),
        ),
        child: child,
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: background,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(padLuar, 8, padLuar, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool sideBySide = constraints.maxWidth >= 390;

                  final double previewWidth = (constraints.maxWidth * 0.32)
                      .clamp(120.0, 320.0);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // JUDUL
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showReceiptManagement = false;
                              });
                            },
                            tooltip: 'Kembali ke Pengaturan',
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: navy,
                              size: besar ? 28 : 24,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Pengaturan Pengelolaan Struk',
                              style: TextStyle(
                                color: _judulStruk,
                                fontSize: judulSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // STATUS
                      Padding(
                        padding: EdgeInsets.only(
                          left: besar ? 8 : 4,
                          bottom: besar ? 20 : 14,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(
                            horizontal: besar ? 14 : 10,
                            vertical: besar ? 7 : 5,
                          ),
                          decoration: BoxDecoration(
                            color: strukAktif
                                ? const Color(0xffc7f0ce)
                                : const Color(0xffe6e9ec),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: strukAktif
                                  ? const Color(0xff65bd70)
                                  : Colors.grey,
                            ),
                          ),
                          child: Text(
                            strukAktif
                                ? 'Printer Terhubung'
                                : 'Struk Dinonaktifkan',
                            style: TextStyle(
                              color: strukAktif
                                  ? const Color(0xff246a32)
                                  : const Color(0xff5d6871),
                              fontSize: besar ? 12 : 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 14),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pilihPrinter(
                                PrintService.kPrinterStruk,
                                'struk',
                              ),
                              icon: const Icon(Icons.print_outlined, size: 18),
                              label: const Text('Pilih Printer Struk'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _tesCetakStruk,
                              icon: const Icon(
                                Icons.receipt_long_outlined,
                                size: 18,
                              ),
                              label: const Text('Tes Cetak Struk'),
                            ),
                          ],
                        ),
                      ),

                      // PANEL DAN PREVIEW
                      if (sideBySide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: masuk(
                                _panelOpsiStruk(
                                  receiptItems,
                                  options,
                                  besar: besar,
                                ),
                                0,
                              ),
                            ),
                            SizedBox(width: besar ? 20 : 10),
                            SizedBox(
                              width: previewWidth,
                              child: masuk(
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: _previewStruk(
                                    options,
                                    isMobile: previewWidth < 170,
                                  ),
                                ),
                                1,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            masuk(
                              _panelOpsiStruk(
                                receiptItems,
                                options,
                                besar: false,
                              ),
                              0,
                            ),
                            const SizedBox(height: 16),
                            masuk(
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: _previewStruk(options, isMobile: true),
                              ),
                              1,
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // PANEL OPSI STRUK
  // ==========================================================

  Widget _panelOpsiStruk(
    List<(String, String)> receiptItems,
    Map<String, bool> options, {
    bool besar = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(besar ? 18 : 8),
      decoration: BoxDecoration(
        color: _panelNavy,
        borderRadius: BorderRadius.circular(besar ? 24 : 13),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.22),
            blurRadius: besar ? 24 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: besar ? 10 : 5),

          Text(
            namaTokoController.text.trim().isEmpty
                ? 'Celcious Coffee'
                : namaTokoController.text.trim(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: besar ? 34 : 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          Text(
            'Alamat Cafe',
            style: TextStyle(color: Colors.white70, fontSize: besar ? 13 : 9),
          ),

          SizedBox(height: besar ? 28 : 18),

          Container(
            width: double.infinity,
            padding: besar
                ? const EdgeInsets.fromLTRB(18, 16, 18, 20)
                : const EdgeInsets.fromLTRB(9, 10, 9, 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(besar ? 22 : 14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: navy,
                      size: besar ? 24 : 17,
                    ),
                    SizedBox(width: besar ? 10 : 7),
                    Text(
                      'Elemen Tampilan Struk',
                      style: TextStyle(
                        color: navy,
                        fontSize: besar ? 17 : 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                Divider(
                  color: navy.withValues(alpha: 0.35),
                  height: besar ? 28 : 17,
                ),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final double gap = besar ? 14 : 8;
                    final double tileWidth = (constraints.maxWidth - gap) / 2;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final (key, label) in receiptItems)
                          SizedBox(
                            width: tileWidth,
                            child: _receiptOptionTile(
                              key: key,
                              label: label,
                              enabled: options[key] ?? true,
                              besar: besar,
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

  // ==========================================================
  // TILE TOGGLE STRUK
  // ==========================================================

  Widget _receiptOptionTile({
    required String key,
    required String label,
    required bool enabled,
    bool besar = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // seluruh tile bisa diklik, tetap lewat _simpanOpsiStruk
        onTap: () => _simpanOpsiStruk(key, !enabled),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(minHeight: besar ? 98 : 57),
          padding: EdgeInsets.symmetric(
            horizontal: besar ? 14 : 7,
            vertical: besar ? 12 : 6,
          ),
          decoration: BoxDecoration(
            color: enabled ? _tileNavy : _tileMati,
            borderRadius: BorderRadius.circular(besar ? 16 : 10),
            border: Border.all(
              color: enabled
                  ? _biruSwitch.withValues(alpha: 0.55)
                  : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: besar ? 8 : 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white54,
                  fontSize: besar ? 19 : 11,
                  fontWeight: FontWeight.w800,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Text(
                'Tampilkan pada struk',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: besar ? 10 : 6,
                ),
              ),

              SizedBox(height: besar ? 6 : 2),

              Align(
                alignment: Alignment.centerLeft,
                child: Transform.scale(
                  scale: besar ? 0.95 : 0.72,
                  alignment: Alignment.centerLeft,
                  child: Switch(
                    key: ValueKey('receipt-option-$key'),
                    value: enabled,
                    activeThumbColor: Colors.white,
                    activeTrackColor: _biruSwitch,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (value) {
                      _simpanOpsiStruk(key, value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // PREVIEW STRUK
  // ==========================================================

  Widget _previewStruk(Map<String, bool> options, {required bool isMobile}) {
    final storeName = namaTokoController.text.trim().isEmpty
        ? 'Celcious Coffee'
        : namaTokoController.text.trim();

    final double fontSize = isMobile ? 5.5 : 9;
    final double logoSize = isMobile ? 43 : 58;
    final double qrSize = isMobile ? 51 : 84;
    final double padding = isMobile ? 7 : 20;

    Widget detail(String label, String value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 2 : 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: const Color(0xff3f5261),
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: fontSize,
                color: const Color(0xff3f5261),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (options['storeLogo'] ?? true)
            Container(
              width: logoSize,
              height: logoSize,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: AppBrandingLogo(fit: BoxFit.cover, height: logoSize),
            ),

          if (options['storeLogo'] ?? true) SizedBox(height: isMobile ? 4 : 7),

          Text(
            storeName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xff214261),
              fontSize: isMobile ? 7 : 13,
              fontWeight: FontWeight.w800,
            ),
          ),

          Text(
            alamatToko,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xff6a7b88),
              fontSize: isMobile ? 5 : 8,
            ),
          ),

          Divider(height: isMobile ? 10 : 18),

          if (options['orderNumber'] ?? true)
            Text(
              'Order #C001',
              style: TextStyle(
                color: const Color(0xff214261),
                fontSize: isMobile ? 7 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),

          if (options['cashierName'] ?? true)
            Text(
              'Dessy Manurung',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xff526575),
                fontSize: fontSize,
              ),
            ),

          if (options['orderTime'] ?? true) ...[
            SizedBox(height: isMobile ? 5 : 8),
            detail('Order Date:', '05/11/2026'),
            detail('Time:', '14:10'),
          ],

          Divider(height: isMobile ? 10 : 16),

          detail('Pesanan', ''),
          detail('Americano x1', 'Rp20.000'),
          detail('Pajak', 'Rp2.200'),

          if (options['total'] ?? true) ...[
            Divider(height: isMobile ? 10 : 16),
            detail('Total', 'Rp22.200'),
          ],

          if (options['qrCode'] ?? true) ...[
            SizedBox(height: isMobile ? 12 : 16),

            if (_qrisImageBytes != null)
              Image.memory(
                _qrisImageBytes!,
                width: qrSize,
                height: qrSize,
                fit: BoxFit.contain,
              )
            else
              Icon(Icons.qr_code_2_rounded, size: qrSize, color: navy),
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

          SizedBox(width: isMobile ? 13 : 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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

          Flexible(
            flex: 6,
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
        ],
      ),
    );

    final Widget isi = onTap == null
        ? row
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              hoverColor: navy.withValues(alpha: 0.05),
              splashColor: navy.withValues(alpha: 0.08),
              child: row,
            ),
          );

    final int urutan = _barisKe++;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + urutan * 70),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: c),
      ),
      child: isi,
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
                if (value == null) return;

                setState(() {
                  metodePembayaran = value;
                });
              },
            ),
          ),
        ),

        const SizedBox(width: 4),

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
  // PREVIEW QRIS
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
