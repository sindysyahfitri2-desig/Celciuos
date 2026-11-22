
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/data/produk_data.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/kasir/application/cashier_cart_controller.dart';
import 'package:kasir_celcious_coffe/features/kasir/application/cashier_shift_service.dart';
import 'package:kasir_celcious_coffe/ui/pages/home_page.dart';
import 'package:kasir_celcious_coffe/ui/widgets/Navigation.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';
import 'package:kasir_celcious_coffe/ui/widgets/product_cart.dart';

import 'checkout_page.dart';
import 'widgets/cash_drawer_panel.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/ganti_shift_dialog.dart';

class kasirPage extends StatefulWidget {
  const kasirPage({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<kasirPage> createState() => _kasirPageState();
}

class _kasirPageState extends State<kasirPage> {
  // ==========================================================
  // WARNA
  // ==========================================================

  final Color navy = const Color(0xff082640);
  final Color textColor = const Color(0xff102b40);

  // ==========================================================
  // DATA KASIR
  // ==========================================================

  String namaKasir = '';
  int shiftKe = 1;
  int? _idKasir;
  String? _fotoUrl;

  double kasAwal = 0;

  bool _showCashDrawerPanel = false;

  DateTime _today = DateTime.now();
  Timer? _dateRefreshTimer;

  bool showWelcome = true;
  bool showJenisPesanan = false;
  bool showCheckout = false;
  bool showPembayaran = false;

  String? jenisPesanan;

  final namaController = TextEditingController();
  final kasController = TextEditingController();
  final _searchController = TextEditingController();
  final _categoryScrollController = ScrollController();

  // ==========================================================
  // KERANJANG
  // ==========================================================

  final CashierCartController _cartController =
      CashierCartController();

  List<Map<String, dynamic>> get cart => _cartController.items;

  void tambahKeKeranjang(Map<String, dynamic> product) {
    _cartController.addProduct(product);
    _popupCatatan(product);
  }

  // ==========================================================
  // HELPER PRODUK
  // ==========================================================

  String _normalisasiKategori(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_-]+'), ' ');
  }

  String _namaAsli(Map<String, dynamic> product) {
    return (
      product['name'] ??
      product['nama_produk'] ??
      ''
    ).toString().trim();
  }

  String _namaTampilan(Map<String, dynamic> product) {
    final nama = _namaAsli(product);

    if (nama.isEmpty) return 'Produk';

    if (nama.toLowerCase().startsWith('celcious ')) {
      return nama;
    }

    return 'Celcious $nama';
  }

  double _hargaProduk(Map<String, dynamic> product) {
    final value = product['price'] ?? product['harga'] ?? 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().replaceAll(',', '.'),
        ) ??
        0;
  }

  int _jumlahProduk(dynamic value) {
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _produkAktif(Map<String, dynamic> product) {
    final status = product['is_active'];

    if (status == false ||
        status == 0 ||
        status == '0' ||
        status == 'false' ||
        status == 'nonaktif') {
      return false;
    }

    return true;
  }

  dynamic _gambarProdukData(Map<String, dynamic> product) {
    return product['image'] ??
        product['gambar'] ??
        product['foto'] ??
        product['gambar_produk'];
  }

  Widget _gambarProduk(dynamic image) {
    if (image is Uint8List) {
      return Image.memory(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderGambar(),
      );
    }

    final path = image?.toString().trim() ?? '';

    if (path.isEmpty) return _placeholderGambar();

    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholderGambar(),
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholderGambar(),
    );
  }

  Widget _placeholderGambar() {
    return const Center(
      child: Icon(
        Icons.local_cafe,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  // ==========================================================
  // POPUP CATATAN
  // ==========================================================

  void _popupCatatan(Map<String, dynamic> product) {
    final nama = _namaTampilan(product);
    final harga = _hargaProduk(product);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(.08),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 75,
                      decoration: BoxDecoration(
                        color: const Color(0xffd6d3e6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _gambarProduk(_gambarProdukData(product)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(
                              color: Color(0xff102b40),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rupiah(harga),
                            style: const TextStyle(
                              color: Color(0xff31566e),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tambah catatan baru?',
                    style: TextStyle(
                      color: Color(0xff102b40),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color.fromARGB(255, 133, 132, 132),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    SizedBox(
                      width: 45,
                      height: 23,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _popupInputCatatan(product);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Ya',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
  }

  void _popupInputCatatan(Map<String, dynamic> product) {
    final TextEditingController catatanController =
        TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(.08),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          child: Container(
            width: 330,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xffd6d3e6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _gambarProduk(_gambarProdukData(product)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _namaTampilan(product),
                            style: const TextStyle(
                              color: Color(0xff102b40),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rupiah(_hargaProduk(product)),
                            style: const TextStyle(
                              color: Color(0xff31566e),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xffdddddd),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.08),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: catatanController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Tambahkan catatan...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(8),
                    ),
                    style: const TextStyle(
                      color: Color(0xff102b40),
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    SizedBox(
                      width: 55,
                      height: 23,
                      child: ElevatedButton(
                        onPressed: () {
                          final catatan =
                              catatanController.text.trim();

                          if (catatan.isNotEmpty) {
                            final namaProduk = _namaAsli(product);

                            final index = cart.indexWhere((item) {
                              return _namaAsli(item) == namaProduk;
                            });

                            if (index >= 0) {
                              _cartController.setNote(index, catatan);
                            }
                          }

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      catatanController.dispose();
    });
  }

  // ==========================================================
  // JUMLAH DAN TOTAL
  // ==========================================================

  void ubahJumlah(int index, int perubahan) {
    _cartController.changeQuantity(index, perubahan);
  }

  double get totalPesanan => _cartController.total;

  // ==========================================================
  // SEARCH DAN KATEGORI
  // ==========================================================

  String searchQuery = '';

  String selectedCategory = 'Semua Menu';

  List<String> get _categoryLabels => [
        'Semua Menu',
        ...ProdukData.kategoriProduk,
      ];

  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _scheduleDateRefresh();

    _cartController.addListener(_onCartChanged);

    TransactionStore.cashDrawerEntries.addListener(_onCashDrawerChanged);
    TransactionStore.transactions.addListener(_onCashDrawerChanged);
    TransactionStore.unfinishedOrders.addListener(_onCashDrawerChanged);

    final shift = CashierShiftService.activeShift();

    if (shift != null) {
      namaKasir = shift.cashier;
      kasAwal = shift.openingCash;
      namaController.text = shift.cashier;
      kasController.text = shift.openingCash.toInt().toString();

      showWelcome = false;
      showJenisPesanan = true;
    }

    ApiService.getUser().then((u) {
      if (!mounted || u == null) return;

      setState(() {
        _idKasir = u['id_pengguna'] is num
            ? (u['id_pengguna'] as num).toInt()
            : int.tryParse(
                u['id_pengguna']?.toString() ?? '',
              );

        _fotoUrl = u['foto_url']?.toString();
        namaKasir = u['nama']?.toString() ?? namaKasir;
      });
    });

    _muatProdukKasir();
  }

  Future<void> _muatProdukKasir() async {
    try {
      await ProdukData.initialize();

      if (!mounted) return;

      await ProdukData.loadFromApi();

      if (!mounted) return;

      setState(() {});
    } catch (error) {
      debugPrint('Gagal memuat produk kasir: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memuat produk. Periksa koneksi internet.'),
        ),
      );
    }
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onCashDrawerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ==========================================================
  // TANGGAL
  // ==========================================================

  void _scheduleDateRefresh() {
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);

    _dateRefreshTimer = Timer(nextDay.difference(now), () {
      if (!mounted) return;

      setState(() {
        _today = DateTime.now();
      });

      _scheduleDateRefresh();
    });
  }

  String _formatHeaderDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  double get _cashDrawerBalance {
    final shift = TransactionStore.activeShift.value;

    if (shift?['status'] != 'open') return kasAwal;

    final expectedCash =
        TransactionStore.activeShiftSummary()['expectedCash'];

    if (expectedCash is num) {
      return expectedCash.toDouble();
    }

    return kasAwal;
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _dateRefreshTimer?.cancel();

    _cartController
      ..removeListener(_onCartChanged)
      ..dispose();

    TransactionStore.cashDrawerEntries.removeListener(
      _onCashDrawerChanged,
    );

    TransactionStore.transactions.removeListener(
      _onCashDrawerChanged,
    );

    TransactionStore.unfinishedOrders.removeListener(
      _onCashDrawerChanged,
    );

    namaController.dispose();
    kasController.dispose();
    _searchController.dispose();
    _categoryScrollController.dispose();

    super.dispose();
  }

  // ==========================================================
  // SIMPAN KASIR
  // ==========================================================

  Future<void> simpanKasir() async {
    try {
      final shift = await CashierShiftService.startShift(
        cashier: namaController.text,
        openingCashText: kasController.text,
      );

      if (!mounted) return;

      setState(() {
        namaKasir = shift.cashier;
        kasAwal = shift.openingCash;
        showWelcome = false;
        showJenisPesanan = true;
        jenisPesanan = null;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : 'Gagal menyimpan data shift: $error',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // GANTI SHIFT
  // ==========================================================

  Future<void> _gantiShift() async {
    final user = await showGantiShiftDialog(
      context,
      idKasirSaatIni: _idKasir,
    );

    if (user == null || !mounted) return;

    setState(() {
      shiftKe = 2;
      namaKasir = user['nama'].toString();

      _idKasir = user['id_pengguna'] is num
          ? (user['id_pengguna'] as num).toInt()
          : int.tryParse(
              user['id_pengguna']?.toString() ?? '',
            );

      _fotoUrl = user['foto_url']?.toString();
    });
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> _konfirmasiLogout() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: navy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Apakah anda yakin shift sudah berakhir semua?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffE06060),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0F8A5A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (ya == true) {
      try {
        await CashierShiftService.closeShift();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menutup shift: $e'),
          ),
        );

        return;
      }

      widget.onLogout?.call();
    }
  }

  void _toggleCashDrawerPanel() {
    setState(() {
      _showCashDrawerPanel = !_showCashDrawerPanel;
    });
  }

  // ==========================================================
  // FORMAT RUPIAH
  // ==========================================================

  String rupiah(double value) {
    final number = value.toInt().toString();

    String result = '';
    int count = 0;

    for (int i = number.length - 1; i >= 0; i--) {
      result = number[i] + result;
      count++;

      if (count == 3 && i != 0) {
        result = '.$result';
        count = 0;
      }
    }

    return 'Rp $result';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appPageBackground,
      body: AppNavigationShell(
        namaKasir: namaKasir,
        shiftKe: shiftKe,
        fotoUrl: _fotoUrl,
        onAksiShift: shiftKe == 1
            ? _gantiShift
            : _konfirmasiLogout,
        headerBuilder: (_) => _header(),
        cashierBuilder: (_) => _cashierContent(),
        onLogout: widget.onLogout,
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _header() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final isTablet =
            constraints.maxWidth >= 600 &&
            constraints.maxWidth < 950;

        final logoSize = isMobile
            ? 34.0
            : isTablet
                ? 40.0
                : 46.0;

        return Container(
          height: isMobile
              ? 64
              : isTablet
                  ? 70
                  : 75,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 16,
          ),
          color: navy,
          child: Row(
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white54),
                ),
                child: ClipOval(
                  child: AppBrandingLogo(height: logoSize),
                ),
              ),
              SizedBox(width: isMobile ? 7 : 9),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Celcious Coffee',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile
                          ? 14
                          : isTablet
                              ? 16
                              : 17,
                    ),
                  ),
                  Text(
                    _formatHeaderDate(_today),
                    style: TextStyle(
                      color: Colors.white.withOpacity(.55),
                      fontSize: isMobile ? 9 : 10,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (namaKasir.isNotEmpty)
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: _toggleCashDrawerPanel,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 13,
                        vertical: isMobile ? 6 : 7,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: isMobile ? 14 : 17,
                            color: textColor,
                          ),
                          SizedBox(width: isMobile ? 4 : 7),
                          if (!isMobile)
                            Text(
                              rupiah(_cashDrawerBalance),
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          if (!isMobile) ...[
                            const SizedBox(width: 10),
                            const Text(
                              'Kas Laci',
                              style: TextStyle(
                                color: Color(0xff607181),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (!isMobile)
                            Icon(
                              _showCashDrawerPanel
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: const Color(0xff607181),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isMobile || isTablet) ...[
                const SizedBox(width: 4),
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Buka menu',
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // CASHIER CONTENT
  // ==========================================================

  Widget _cashierContent() {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned.fill(
          child: _cashierBody(),
        ),
        if (_showCashDrawerPanel && !showWelcome) ...[
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleCashDrawerPanel,
              child: ColoredBox(
                color: Colors.black.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                elevation: 12,
                borderRadius: BorderRadius.circular(16),
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 200),
                  child: const CashDrawerPanel(),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _cashierBody() {
    if (showWelcome) {
      return _welcomePage();
    }

    if (showCheckout) {
      return CheckoutPage(
        cart: cart,
        jenisPesanan: jenisPesanan ?? '-',
        namaKasir: namaKasir,
        rupiah: rupiah,
        onBack: () {
          setState(() {
            showCheckout = false;
          });
        },
        onLanjutPembayaran: _kembaliKeMenu,
        onBayarNanti: _kembaliKeMenu,
      );
    }

    if (showJenisPesanan) {
      return HomePage(
        selectedOrderType: jenisPesanan,
        onOrderTypeSelected: (value) {
          setState(() {
            jenisPesanan = value;
          });
        },
        onContinue: () {
          setState(() {
            showJenisPesanan = false;
          });
        },
      );
    }

    return _cashier();
  }

  void _kembaliKePilihanJenisPesanan() {
    setState(() {
      _cartController.clear();
      showCheckout = false;
      showJenisPesanan = true;
      jenisPesanan = null;
    });
  }

  void _kembaliKeMenu() {
    setState(() {
      _cartController.clear();
      showCheckout = false;
      showJenisPesanan = false;
    });
  }

  // ==========================================================
  // CHECKOUT BAR
  // ==========================================================

  Widget _checkoutBar(bool isCompact) {
    final jumlahItem = _cartController.itemCount;

    return Container(
      height: isCompact ? 62 : 68,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 22,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffa8cbe9),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$jumlahItem Item dipilih',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: navy,
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  rupiah(totalPesanan),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: navy.withValues(alpha: 0.8),
                    fontSize: isCompact ? 11.5 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: isCompact ? 140 : 176,
            height: isCompact ? 42 : 46,
            child: _AnimatedTouch(
              scale: 0.96,
              child: ElevatedButton(
                onPressed: cart.isEmpty
                    ? null
                    : () {
                        if (jenisPesanan == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pilih Dine In atau Take Away terlebih dahulu.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );

                          return;
                        }

                        setState(() {
                          showCheckout = true;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: navy,
                  disabledBackgroundColor: Colors.white70,
                  disabledForegroundColor: const Color(0xFF497C99),
                  elevation: 3,
                  shadowColor: navy.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Check Out',
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  Widget _search(bool isCompact) {
    return Container(
      height: isCompact ? 38 : 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase().trim();
          });
        },
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          color: Color(0xff102b40),
        ),
        decoration: InputDecoration(
          hintText: 'Cari menu',
          hintStyle: const TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xff9aa7b2),
            fontSize: 12.5,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xff31566e),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 38,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: navy,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
              : null,
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HALAMAN KASIR
  // ==========================================================

  Widget _cashier() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 600;
        final isTablet = width >= 600 && width < 1024;
        final horizontalPadding = isCompact
            ? 14.0
            : isTablet
                ? 20.0
                : 26.0;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isCompact ? 12 : 16,
                horizontalPadding,
                0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: isCompact ? 38 : 40,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  showJenisPesanan = true;
                                });
                              },
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 16,
                              ),
                              label: const Text('Kembali'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffa8cbe9),
                                foregroundColor: navy,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isCompact ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: _search(isCompact)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _categories(),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  12,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 1280,
                    ),
                    child: _productGrid(),
                  ),
                ),
              ),
            ),
            if (cart.isNotEmpty) _checkoutBar(isCompact),
          ],
        );
      },
    );
  }

  // ==========================================================
  // KATEGORI
  // ==========================================================

  Widget _categories() {
    return SizedBox(
      height: 36,
      child: ListView(
        key: const PageStorageKey<String>('kasir-categories'),
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        children: [
          for (final title in _categoryLabels)
            _category(_iconForCategory(title), title),
        ],
      ),
    );
  }

  IconData _iconForCategory(String title) {
    switch (_normalisasiKategori(title)) {
      case 'semua menu':
        return Icons.grid_view_rounded;
      case 'americano':
        return Icons.coffee_rounded;
      case 'sanger':
        return Icons.coffee_maker_rounded;
      case 'refresh':
        return Icons.local_drink_rounded;
      case 'best selling':
        return Icons.local_fire_department_rounded;
      case 'latte':
        return Icons.local_cafe_rounded;
      case 'non coffee':
        return Icons.emoji_food_beverage_rounded;
      case 'food':
        return Icons.lunch_dining_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Widget _category(IconData icon, String title) {
    final active =
        _normalisasiKategori(selectedCategory) ==
        _normalisasiKategori(title);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: active
            ? Colors.white
            : const Color(0xffa8cbe9),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              selectedCategory = title;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? navy
                    : const Color(0xffa8cbe9),
                width: active ? 1.3 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: navy,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11.5,
                    color: navy,
                    fontWeight: active
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // GRID PRODUK (proporsional untuk HP, Tablet, dan Laptop)
  // ==========================================================

  Widget _productGrid() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ProdukData.produk,
      builder: (context, products, child) {
        return LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;
            final int columns;
            final double cardHeight;
            if (width < 580) {
              columns = 1;
              cardHeight = 104;
            } else if (width < 920) {
              columns = 2;
              cardHeight = 108;
            } else if (width < 1260) {
              columns = 3;
              cardHeight = 110;
            } else {
              columns = 4;
              cardHeight = 112;
            }

            final filteredProducts = products.where((product) {
              if (!_produkAktif(product)) return false;

              final nama = _namaAsli(product).toLowerCase();

              final category = _normalisasiKategori(
                product['category'] ?? product['kategori'],
              );

              if (searchQuery.isNotEmpty &&
                  !nama.contains(searchQuery)) {
                return false;
              }

              final selected =
                  _normalisasiKategori(selectedCategory);

              if (selected != 'semua menu' &&
                  category != selected) {
                return false;
              }

              return true;
            }).toList();

            if (filteredProducts.isEmpty) {
              return Center(
                child: Text(
                  products.isEmpty
                      ? 'Belum ada produk tersedia'
                      : 'Menu tidak ditemukan',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: navy.withValues(alpha: 0.65),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredProducts.length,
              padding: const EdgeInsets.only(bottom: 8),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: cardHeight,
              ),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];

                final namaProduk = _namaAsli(product);

                final cartIndex = cart.indexWhere((item) {
                  return _namaAsli(item) == namaProduk;
                });

                final jumlah = cartIndex >= 0
                    ? _jumlahProduk(
                        cart[cartIndex]['quantity'],
                      )
                    : 0;

                return _AnimatedTouch(
                  scale: 0.985,
                  child: ProductCard(
                    name: _namaTampilan(product),
                    price: _hargaProduk(product),
                    image: _gambarProdukData(product),
                    category: (
                      product['category'] ??
                      product['kategori'] ??
                      ''
                    ).toString(),
                    quantity: jumlah,
                    onAdd: () {
                      tambahKeKeranjang(product);
                    },
                    onMinus: () {
                      if (cartIndex >= 0) {
                        ubahJumlah(cartIndex, -1);
                      }
                    },
                    onDelete: () {
                      if (cartIndex >= 0) {
                        _cartController.removeAt(cartIndex);
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // WELCOME MODAL
  // ==========================================================

  Widget _welcomePage() {
    return Container(
      color: appPageBackground,
      child: Center(
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;

            final double modalWidth =
                width < 500 ? width - 40 : 500;

            final double titleSize = width < 500
                ? 28
                : width < 900
                    ? 34
                    : 38;

            final double horizontalPadding =
                width < 500 ? 16 : 22;

            final double verticalPadding =
                width < 500 ? 16 : 20;

            final double buttonWidth = width < 500
                ? 190
                : width < 900
                    ? 220
                    : 250;

            final double buttonHeight =
                width < 500 ? 40 : 43;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 10,
              ),
              child: SizedBox(
                width: modalWidth,
                child: Column(
                  children: [
                    Text(
                      'Selamat Datang !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        verticalPadding,
                        horizontalPadding,
                        verticalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: navy,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _inputLabel('Masukkan Nama Kasir :'),
                          const SizedBox(height: 3),
                          _input(
                            controller: namaController,
                            hint: 'Ketik disini...',
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 15),
                          _inputLabel('Masukkan Kas Kasir :'),
                          const SizedBox(height: 3),
                          _input(
                            controller: kasController,
                            hint: 'Ketik disini...',
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 15),
                          Center(
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: ElevatedButton(
                                onPressed: simpanKasir,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: navy,
                                  elevation: 10,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(22),
                                  ),
                                ),
                                child: Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize:
                                        width < 500 ? 15 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // LABEL INPUT
  // ==========================================================

  Widget _inputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ==========================================================
  // INPUT
  // ==========================================================

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xffb5b5b5),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 11,
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// ANIMASI SENTUH
// ==========================================================

class _AnimatedTouch extends StatefulWidget {
  final Widget child;
  final double scale;

  const _AnimatedTouch({
    required this.child,
    this.scale = 0.97,
  });

  @override
  State<_AnimatedTouch> createState() => _AnimatedTouchState();
}

class _AnimatedTouchState extends State<_AnimatedTouch> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
