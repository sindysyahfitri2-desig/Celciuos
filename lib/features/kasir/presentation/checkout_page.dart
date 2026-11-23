import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kasir_celcious_coffe/data/payment_methods_store.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/kasir/application/cashier_checkout_pricing.dart';
import 'package:kasir_celcious_coffe/features/kasir/application/cashier_transaction_service.dart';
import 'package:kasir_celcious_coffe/ui/widgets/product_image.dart';

import 'Transaksi_Berhasil.dart';
import 'widgets/qris_direct_dialog.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final String jenisPesanan;
  final String namaKasir;
  final String Function(double) rupiah;

  final VoidCallback onBack;
  final VoidCallback onLanjutPembayaran;

  // Callback khusus untuk menyimpan pesanan yang belum dibayar.
  final VoidCallback? onBayarNanti;
  final String initialPaymentMethod;
  final bool openPaymentImmediately;
  final Map<String, dynamic>? existingOrder;

  const CheckoutPage({
    super.key,
    required this.cart,
    required this.jenisPesanan,
    this.namaKasir = 'Kasir',
    required this.rupiah,
    required this.onBack,
    required this.onLanjutPembayaran,
    this.onBayarNanti,
    this.initialPaymentMethod = '',
    this.openPaymentImmediately = false,
    this.existingOrder,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // ==========================================================
  // WARNA
  // ==========================================================
  static const Color _navy = Color(0xff082640);
  static const Color _merah = Color(0xffdd5b5b);
  static const Color _biruBorder = Color(0xff082640);
  static const Color _biruMuda = Color(0xffa8cbe9);
  static const Color _canvas = Color(0xffdce9f4);
  static const Color _surfaceSoft = Color(0xfff1f7fc);
  static const Color _borderSoft = Color(0xffcde0f0);
  static const Color _muted = Color(0xff5b738b);
  static const Color _hijau = Color(0xff1b8a5a);

  // Nilai yang diketik kasir, bisa berupa persen atau rupiah.
  double diskon = 0;
  String jenisDiskon = 'Rp'; // Pilihan: 'Rp' atau '%'.
  Uint8List? _buktiPembayaranBytes;

  // Mode transaksi.
  String selectedPayment =
      ''; // Belum memilih mode: tombol Langsung Bayar tampil redup.

  bool _menyimpanPesanan = false;
  bool _memulaiPembayaran = false;
  bool _paymentCompleted = false;
  Future<void>? _simpanTransaksiAktif;

  // Metode pembayaran: Cash atau QRIS.
  String metodePembayaran = '';
  String? _namaCustomerPembayaran;

  // Dropdown yang menempel di tombol (bukan pop up).
  final LayerLink _modeLink = LayerLink();
  final LayerLink _bayarLink = LayerLink();
  final GlobalKey _modeKey = GlobalKey();
  final GlobalKey _bayarKey = GlobalKey();
  OverlayEntry? _dropdownEntry;
  Completer<String?>? _dropdownCompleter;

  List<String> _availablePaymentMethods(List<String> raw) {
    final cleaned = raw
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.toLowerCase().contains('transfer'))
        .toList();
    if (cleaned.isEmpty) return const ['QRIS', 'Cash'];
    return cleaned;
  }

  @override
  void initState() {
    super.initState();
    PaymentMethodsStore.initialize();
    TransactionStore.syncStoreRates().then((_) {
      if (mounted) setState(() {});
    });
    selectedPayment = widget.openPaymentImmediately ? 'Langsung Bayar' : '';
    diskon =
        (widget.existingOrder?['diskonInput'] as num?)?.toDouble() ??
        (widget.existingOrder?['diskon'] as num?)?.toDouble() ??
        0;
    jenisDiskon = diskon <= 100 ? '%' : 'Rp';
    final method = widget.initialPaymentMethod.trim().toUpperCase();
    if (method == 'QRIS' || method == 'CASH') {
      metodePembayaran = method == 'CASH' ? 'Cash' : 'QRIS';
    }
    if (widget.openPaymentImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prosesBayar();
      });
    }
  }

  @override
  void dispose() {
    _tutupDropdown(null);
    super.dispose();
  }

  // ==========================================================
  // TOTAL PESANAN
  // ==========================================================

  CashierCheckoutPricing get _pricing => CashierCheckoutPricing.calculate(
    cart: widget.cart,
    existingOrder: widget.existingOrder,
    defaultTaxRate: TransactionStore.ppnRate.value,
    defaultServiceFeeRate: TransactionStore.serviceFeeRate.value,
    discount: diskon,
    discountType: jenisDiskon,
  );

  double get total => _pricing.subtotal;
  double get ppnRate => _pricing.taxRate;
  double get biayaLainnya => _pricing.tax;
  double get serviceFeeRate => _pricing.serviceFeeRate;
  double get biayaLayanan => _pricing.serviceFee;
  double get totalSebelumDiskon => total + biayaLainnya + biayaLayanan;
  double get nominalDiskon => _pricing.discountAmount;
  double get totalAkhir => _pricing.total;
  int get jumlahItem => _pricing.itemCount;

  bool get langsungBayar => selectedPayment == 'Langsung Bayar';
  bool get _mustCompletePayment =>
      widget.openPaymentImmediately &&
      widget.existingOrder != null &&
      !_paymentCompleted;

  // ==========================================================
  // BUILD (sesuai desain awal, dirapikan & responsif HP / Tablet / Laptop)
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_mustCompletePayment,
      child: Container(
        color: _canvas,
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth;
              final isMobile = width < 650;
              final isTablet = width >= 650 && width < 1020;
              final isDesktop = width >= 1020;

              final double sidePad = isMobile
                  ? 14
                  : isTablet
                  ? 22
                  : 32;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // HEADER ATAS (← + Tambah Menu)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            sidePad,
                            isMobile ? 12 : 18,
                            sidePad,
                            12,
                          ),
                          child: Row(
                            children: [
                              Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: _mustCompletePayment
                                      ? null
                                      : widget.onBack,
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: isMobile ? 38 : 40,
                                    height: isMobile ? 38 : 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _navy.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: _navy,
                                      size: 21,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(27),
                                child: InkWell(
                                  onTap: _mustCompletePayment
                                      ? null
                                      : widget.onBack,
                                  borderRadius: BorderRadius.circular(27),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 18 : 22,
                                      vertical: isMobile ? 8 : 9,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(27),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _navy.withValues(alpha: 0.09),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Tambah Menu',
                                      style: TextStyle(
                                        color: _navy,
                                        fontSize: isMobile
                                            ? 14.5
                                            : isTablet
                                            ? 15.5
                                            : 16.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // DAFTAR KARTU PESANAN (selalu rapi rata kiri atas)
                        Expanded(
                          child: widget.cart.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Belum ada pesanan.',
                                    style: TextStyle(
                                      color: _navy,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, listBox) {
                                    final availW =
                                        (listBox.maxWidth - sidePad * 2)
                                            .clamp(240.0, 1440.0);
                                    final int columns;
                                    if (availW < 620) {
                                      columns = 1;
                                    } else if (availW < 980) {
                                      columns = 2;
                                    } else {
                                      columns = 3;
                                    }
                                    const spacing = 16.0;
                                    final cardW = columns == 1
                                        ? availW
                                        : (availW - spacing * (columns - 1)) /
                                            columns;

                                    return SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      padding: EdgeInsets.fromLTRB(
                                        sidePad,
                                        4,
                                        sidePad,
                                        20,
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Wrap(
                                          alignment: WrapAlignment.start,
                                          spacing: spacing,
                                          runSpacing: 14,
                                          children: List.generate(
                                            widget.cart.length,
                                            (index) => SizedBox(
                                              width: cardW,
                                              child: _itemCard(index, isMobile),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  _checkoutBottom(width, isMobile, isTablet, isDesktop),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CARD ITEM (rapi sesuai desain gambar ke-4: foto + info + - qty + + strip hapus merah)
  // ==========================================================

  void _ubahQtyItem(int index, int delta) {
    if (index < 0 || index >= widget.cart.length) return;
    setState(() {
      final current = (widget.cart[index]['quantity'] as num?)?.toInt() ?? 1;
      final next = current + delta;
      if (next <= 0) {
        widget.cart.removeAt(index);
      } else {
        widget.cart[index]['quantity'] = next;
      }
    });
  }

  Widget _qtyBoxButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 28,
  }) {
    return Material(
      color: _navy,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.58),
        ),
      ),
    );
  }

  Widget _itemCard(int index, bool isMobile) {
    final item = widget.cart[index];
    final harga = (item['price'] as num).toDouble();
    final jumlah = (item['quantity'] as num).toInt();
    final subtotal = harga * jumlah;
    final catatan = item['catatan']?.toString().trim() ?? '';
    final terkunci = widget.existingOrder != null;
    final cardHeight = catatan.isEmpty
        ? (isMobile ? 102.0 : 108.0)
        : (isMobile ? 116.0 : 122.0);
    final pad = isMobile ? 8.0 : 9.0;
    final imageSize = (cardHeight - pad * 2).clamp(64.0, 88.0);
    final double tabWidth = isMobile ? 42 : 46;
    final double btnSize = isMobile ? 25 : 27;

    Widget iconCoffee() =>
        const Icon(Icons.coffee_rounded, color: _navy, size: 28);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 45),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: terkunci ? Colors.grey.shade400 : _merah,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // KARTU PUTIH UTAMA (melengkung rapi di sisi kanan menimpa strip merah)
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(pad),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          color: const Color(0xffd5d1e8),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: item['image'] == null
                            ? iconCoffee()
                            : ProductImage(image: item['image']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['name'].toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xff0e2235),
                                      fontSize: isMobile ? 13.5 : 14.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.rupiah(harga),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xff335e84),
                                      fontSize: isMobile ? 11.5 : 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (catatan.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Catatan: $catatan',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xff5b7388),
                                        fontSize: 10.5,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: terkunci
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffeaf2fa),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'x$jumlah • ${widget.rupiah(subtotal)}',
                                        style: const TextStyle(
                                          color: _navy,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _qtyBoxButton(
                                          icon: Icons.remove_rounded,
                                          size: btnSize,
                                          onTap: () =>
                                              _ubahQtyItem(index, -1),
                                        ),
                                        SizedBox(
                                          width: isMobile ? 24 : 28,
                                          child: Center(
                                            child: Text(
                                              '$jumlah',
                                              style: TextStyle(
                                                color: _navy,
                                                fontSize: isMobile ? 13.5 : 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        _qtyBoxButton(
                                          icon: Icons.add_rounded,
                                          size: btnSize,
                                          onTap: () =>
                                              _ubahQtyItem(index, 1),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // STRIP MERAH TOMBOL HAPUS DI KANAN
              SizedBox(
                width: tabWidth,
                child: Material(
                  color: terkunci ? Colors.grey.shade400 : _merah,
                  child: InkWell(
                    onTap: terkunci
                        ? null
                        : () => setState(() => widget.cart.removeAt(index)),
                    child: Center(
                      child: Icon(
                        terkunci
                            ? Icons.lock_outline_rounded
                            : Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
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
  // BAGIAN BAWAH CHECKOUT (sesuai desain awal, rapi & proporsional)
  // ==========================================================

  Widget _checkoutBottom(
    double width,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final double barH = isMobile ? 52 : 64;
    const String labelTotalAkhir = 'Total Setelah diskon\ndan biaya lainnya';

    Widget totalAkhirStrip() => Container(
      height: barH,
      color: Colors.white,
      padding: EdgeInsets.only(left: isMobile ? 14 : 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              labelTotalAkhir,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _navy,
                fontSize: isMobile ? 11 : 12.5,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(width: isMobile ? 10 : 14),
          Container(
            width: isMobile ? 126 : (isTablet ? 156 : 184),
            height: double.infinity,
            color: _navy,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.rupiah(totalAkhir).replaceFirst('Rp ', ''),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 21 : 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final tombol = Container(
      color: _biruMuda,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 10 : 18,
            10,
            isMobile ? 10 : 18,
            12,
          ),
          child: Row(
            children: [
              Expanded(
                flex: isMobile ? 1 : 0,
                child: SizedBox(
                  width: isMobile ? null : (isTablet ? 168 : 196),
                  child: _modePembayaranControl(
                    fontSize: isMobile ? 12.5 : 14,
                    height: isMobile ? 42 : 44,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                flex: isMobile ? 1 : 0,
                child: SizedBox(
                  width: isMobile ? null : (isTablet ? 168 : 196),
                  child: _tombolPembayaran(
                    height: isMobile ? 42 : 44,
                    fontSize: isMobile ? 12.5 : 14,
                  ),
                ),
              ),
              if (!isMobile) const Spacer(),
              if (isMobile) const SizedBox(width: 8),
              Expanded(
                flex: isMobile ? 1 : 0,
                child: SizedBox(
                  width: isMobile ? null : (isTablet ? 168 : 196),
                  child: _tombolProses(height: isMobile ? 42 : 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMobile) ...[
            Row(
              children: [
                Expanded(
                  child: _diskonBox(height: barH, fontSize: 12.5, iconSize: 20),
                ),
                Expanded(child: _totalBox(height: barH, fontSize: 20)),
              ],
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xffdce9f4)),
            totalAkhirStrip(),
          ] else
            SizedBox(
              height: barH,
              child: Row(
                children: [
                  SizedBox(
                    width: isTablet ? 165 : 190,
                    child: _diskonBox(height: barH, fontSize: 13.5, iconSize: 24),
                  ),
                  SizedBox(
                    width: isTablet ? 175 : 210,
                    child: _totalBox(height: barH, fontSize: 24),
                  ),
                  Expanded(child: totalAkhirStrip()),
                ],
              ),
            ),
          tombol,
        ],
      ),
    );
  }

  // ==========================================================
  // DISKON & TOTAL BOX
  // ==========================================================

  Widget _diskonBox({
    required double height,
    required double fontSize,
    required double iconSize,
  }) {
    final aktif = diskon > 0;
    return Material(
      color: _navy,
      child: InkWell(
        onTap: widget.existingOrder == null ? _dialogDiskon : null,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.existingOrder != null
                      ? 'Diskon tetap\n${jenisDiskon == '%' ? '${diskon.toStringAsFixed(0)}%' : widget.rupiah(diskon)}'
                      : aktif
                      ? 'Diskon\n${jenisDiskon == '%' ? '${diskon.toStringAsFixed(0)}% (${widget.rupiah(nominalDiskon)})' : widget.rupiah(diskon)}'
                      : 'Masukkan\nDiskon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalBox({required double height, required double fontSize}) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: _dialogRincianPembayaran,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(color: Color(0xffe1ecf5), width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total :',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.rupiah(total).replaceFirst('Rp ', ''),
                        style: TextStyle(
                          color: _navy,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: _navy, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TOMBOL PILL (Langsung Bayar / Pembayaran / Simpan-Bayar)
  // ==========================================================

  Widget _modePembayaranControl({double fontSize = 14, double height = 44}) {
    return CompositedTransformTarget(
      link: _modeLink,
      child: Container(
        key: _modeKey,
        child: _Pill(
          label: selectedPayment.isEmpty ? 'Langsung Bayar' : selectedPayment,
          selected: selectedPayment.isNotEmpty,
          dim: selectedPayment.isEmpty,
          onTap: _pilihModePembayaran,
          enabled: !widget.openPaymentImmediately,
          height: height,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _tombolPembayaran({required double height, required double fontSize}) {
    return CompositedTransformTarget(
      link: _bayarLink,
      child: Container(
        key: _bayarKey,
        child: _Pill(
          label: metodePembayaran.isEmpty ? 'Pembayaran' : metodePembayaran,
          selected: metodePembayaran.isNotEmpty && langsungBayar,
          dim: !langsungBayar,
          onTap: () {
            if (!langsungBayar) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Pilih "Langsung Bayar" terlebih dahulu.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              return;
            }
            _ubahMetodePembayaran();
          },
          enabled: !widget.openPaymentImmediately,
          height: height,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _tombolProses({required double height}) {
    return _Pill(
      label: langsungBayar ? 'Bayar' : 'Simpan',
      onTap: _prosesBayar,
      enabled: widget.cart.isNotEmpty,
      height: height,
      fontSize: 15,
    );
  }

  Future<void> _ubahMetodePembayaran() async {
    final pembayaran = await _pilihPembayaran();
    if (pembayaran == null || !mounted) return;
    setState(() => metodePembayaran = pembayaran);
  }

  void _pilihModePembayaran() {
    setState(() {
      selectedPayment = selectedPayment.isEmpty ? 'Langsung Bayar' : '';
      if (selectedPayment.isEmpty) metodePembayaran = '';
    });
  }

  Future<String?> _pilihPembayaran() async {
    if (!langsungBayar) return null;

    final options = _availablePaymentMethods(PaymentMethodsStore.methods.value);
    final pilihan = await _bukaDropdown(
      link: _bayarLink,
      targetKey: _bayarKey,
      header: 'Pembayaran',
      options: options,
      selected: metodePembayaran,
      gayaPembayaran: true,
    );

    if (pilihan == null) return null;
    if (pilihan.toLowerCase() == 'qris') return 'QRIS';
    if (pilihan.toLowerCase() == 'cash') return 'Cash';
    return pilihan;
  }

  // ==========================================================
  // DROPDOWN YANG MENEMPEL DI TOMBOL
  // ==========================================================

  Future<String?> _bukaDropdown({
    required LayerLink link,
    required GlobalKey targetKey,
    required List<String> options,
    required String selected,
    required bool gayaPembayaran,
    String? header,
    bool rataKiri = false,
  }) {
    _tutupDropdown(null);

    final box = targetKey.currentContext?.findRenderObject() as RenderBox?;
    final lebarTombol = box?.size.width ?? 190;

    final completer = Completer<String?>();
    _dropdownCompleter = completer;

    _dropdownEntry = OverlayEntry(
      builder: (_) => _AnchoredDropdown(
        link: link,
        width: math.max(lebarTombol, gayaPembayaran ? 130 : 160),
        header: header,
        options: options,
        selected: selected,
        gayaPembayaran: gayaPembayaran,
        rataKiri: rataKiri,
        onClosed: _tutupDropdown,
      ),
    );

    Overlay.of(context).insert(_dropdownEntry!);
    return completer.future;
  }

  void _tutupDropdown(String? hasil) {
    _dropdownEntry?.remove();
    _dropdownEntry = null;

    final completer = _dropdownCompleter;
    _dropdownCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete(hasil);
    }
  }

  // ==========================================================
  // DIALOG DENGAN TANDA X DI BAWAH
  // ==========================================================

  Widget _dialogDenganX({
    required BuildContext dialogContext,
    required Widget child,
    bool bisaTutup = true,
    bool scroll = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        scroll ? Flexible(child: child) : child,
        if (bisaTutup) ...[
          const SizedBox(height: 10),
          _TombolX(onTap: () => Navigator.pop(dialogContext)),
        ],
      ],
    );
  }

  // ==========================================================
  // RINCIAN PEMBAYARAN
  // ==========================================================

  void _dialogRincianPembayaran() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: _dialogDenganX(
          dialogContext: dialogContext,
          child: Container(
            width: 340,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rincian Pembayaran',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _barisRincian('Subtotal', total),
                const SizedBox(height: 8),
                _barisRincian(
                  'PPN ${(ppnRate * 100).toStringAsFixed(ppnRate * 100 % 1 == 0 ? 0 : 2)}%',
                  biayaLainnya,
                ),
                if (biayaLayanan > 0 || serviceFeeRate > 0) ...[
                  const SizedBox(height: 8),
                  _barisRincian(
                    'Biaya Layanan ${(serviceFeeRate * 100).toStringAsFixed(serviceFeeRate * 100 % 1 == 0 ? 0 : 2)}%',
                    biayaLayanan,
                  ),
                ],
                const SizedBox(height: 8),
                _barisRincian(
                  'Diskon${jenisDiskon == '%' ? ' (${diskon.toStringAsFixed(0)}%)' : ''}',
                  -nominalDiskon,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                _barisRincian('Total bayar', totalAkhir, bold: true),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 110,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Tutup'),
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

  Widget _barisRincian(String label, double amount, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ),
        Text(
          amount < 0 ? '-${widget.rupiah(-amount)}' : widget.rupiah(amount),
          style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
        ),
      ],
    );
  }

  // ==========================================================
  // PROSES TRANSAKSI
  // ==========================================================

  Future<void> _prosesBayar() async {
    if (widget.cart.isEmpty || _memulaiPembayaran) return;
    _memulaiPembayaran = true;

    try {
      if (!langsungBayar) {
        if (widget.onBayarNanti == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Callback Bayar Nanti belum dihubungkan ke halaman kasir.',
              ),
            ),
          );
          return;
        }

        await _dialogNamaPesanan();
        return;
      }

      if (metodePembayaran.isEmpty) {
        final pembayaran = await _pilihPembayaran();
        if (pembayaran == null || !mounted) return;
        setState(() => metodePembayaran = pembayaran);
      }

      if (widget.existingOrder == null && _namaCustomerPembayaran == null) {
        final waktu = DateTime.now();
        final nama = await _dialogInputNamaCustomer(
          kodePesanan: _buatKodePesanan(waktu),
          actionLabel: 'Lanjut',
        );
        if (nama == null || !mounted) return;
        _namaCustomerPembayaran = nama;
      }

      if (metodePembayaran.toUpperCase() == 'QRIS') {
        _dialogQRIS();
      } else if (metodePembayaran.toLowerCase() == 'cash') {
        _dialogCash();
      } else {
        _dialogPembayaranCustom(metodePembayaran);
      }
    } finally {
      _memulaiPembayaran = false;
    }
  }

  // Dialog nama customer untuk pesanan yang disimpan / Bayar Nanti.
  Future<void> _dialogNamaPesanan() async {
    final waktu = DateTime.now();
    final kodePesanan = _buatKodePesanan(waktu);
    final nama = await _dialogInputNamaCustomer(
      kodePesanan: kodePesanan,
      actionLabel: 'Simpan',
    );
    if (nama == null || !mounted) return;

    setState(() => _menyimpanPesanan = true);
    try {
      await CashierTransactionService.saveUnfinishedOrder(
        orderCode: kodePesanan,
        time: waktu,
        customerName: nama,
        cashierName: widget.namaKasir,
        itemCount: jumlahItem,
        subtotal: total,
        taxRate: ppnRate,
        tax: biayaLainnya,
        discount: nominalDiskon,
        discountInput: diskon,
        discountType: jenisDiskon,
        total: totalAkhir,
        orderType: widget.jenisPesanan,
        cart: widget.cart,
        paymentProofBytes: _buktiPembayaranBytes,
      );

      if (!mounted) return;
      widget.onBayarNanti?.call();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pesanan: $error')),
      );
    } finally {
      if (mounted) setState(() => _menyimpanPesanan = false);
    }
  }

  Future<String?> _dialogInputNamaCustomer({
    required Map<String, String> kodePesanan,
    required String actionLabel,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: _dialogDenganX(
            dialogContext: dialogContext,
            child: Container(
              width: 390,
              padding: const EdgeInsets.fromLTRB(16, 14, 17, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID transaksi yang akan disimpan bersama nama customer.
                  Text(
                    '#${kodePesanan['id']}',
                    style: const TextStyle(
                      color: Color(0xff16558a),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Nama Customer :',
                    style: TextStyle(
                      color: Color(0xff152532),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    height: 132,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 9,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Ketik Disini...',
                        hintStyle: TextStyle(
                          color: Color(0xffb7b7b7),
                          fontSize: 14,
                        ),
                        contentPadding: EdgeInsets.fromLTRB(24, 18, 18, 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 151,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () {
                          final nama = controller.text.trim();
                          if (nama.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Nama customer wajib diisi.'),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(dialogContext, nama);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff102f50),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xff9aabba),
                          elevation: 0,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          actionLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<void> _simpanPembayaran(BuildContext paymentDialogContext) async {
    if (_menyimpanPesanan) return;
    setState(() => _menyimpanPesanan = true);

    try {
      final waktu = DateTime.now();
      final existingOrder = widget.existingOrder;
      final kodePesanan = existingOrder == null
          ? _buatKodePesanan(waktu)
          : {
              'id': existingOrder['id']?.toString() ?? '',
              'display': existingOrder['kode']?.toString() ?? '',
            };
      final namaCustomer =
          existingOrder?['nama']?.toString() ?? _namaCustomerPembayaran;
      if (namaCustomer == null || namaCustomer.isEmpty) {
        throw StateError('Nama customer belum diisi.');
      }

      await _simpanTransaksi(
        namaCustomer: namaCustomer,
        waktu: waktu,
        kodePesanan: kodePesanan,
      );
      if (!mounted) return;
      setState(() => _paymentCompleted = true);
      _namaCustomerPembayaran = null;

      if (paymentDialogContext.mounted) {
        Navigator.pop(paymentDialogContext);
      }

      var selesaiDipanggil = false;
      void akhiriTransaksi() {
        if (selesaiDipanggil) return;
        selesaiDipanggil = true;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        widget.onLanjutPembayaran();
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => TransaksiBerhasilPage(
            receiptData: {
              'orderId': kodePesanan['id'] ?? '',
              'customerName': namaCustomer,
              'cashierName': widget.namaKasir,
              'orderType': widget.jenisPesanan,
              'paymentMethod': metodePembayaran,
              'orderedAt': waktu,
              'items': widget.cart
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList(),
              'subtotal': total,
              'tax': biayaLainnya,
              'biaya_layanan': biayaLayanan,
              'discount': nominalDiskon,
              'total': totalAkhir,
            },
            onSelesai: akhiriTransaksi,
          ),
        ),
      );
      if (!selesaiDipanggil && mounted) {
        selesaiDipanggil = true;
        widget.onLanjutPembayaran();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi gagal disimpan: $error')),
      );
    } finally {
      if (mounted) setState(() => _menyimpanPesanan = false);
    }
  }

  Future<void> _simpanTransaksi({
    required String namaCustomer,
    required DateTime waktu,
    required Map<String, String> kodePesanan,
  }) async {
    final simpanAktif = _simpanTransaksiAktif;
    if (simpanAktif != null) {
      await simpanAktif;
      return;
    }

    final operasi = _buatTransaksiTersimpan(
      namaCustomer: namaCustomer,
      waktu: waktu,
      kodePesanan: kodePesanan,
    );
    _simpanTransaksiAktif = operasi;
    try {
      await operasi;
    } catch (_) {
      _simpanTransaksiAktif = null;
      rethrow;
    }
  }

  Future<void> _buatTransaksiTersimpan({
    required String namaCustomer,
    required DateTime waktu,
    required Map<String, String> kodePesanan,
  }) async {
    await CashierTransactionService.savePaidTransaction(
      orderCode: kodePesanan,
      time: waktu,
      customerName: namaCustomer,
      cashierName: widget.namaKasir,
      itemCount: jumlahItem,
      subtotal: total,
      taxRate: ppnRate,
      tax: biayaLainnya,
      discount: nominalDiskon,
      discountInput: diskon,
      discountType: jenisDiskon,
      total: totalAkhir,
      paymentMethod: metodePembayaran,
      orderType: widget.jenisPesanan,
      cart: widget.cart,
      existingOrder: widget.existingOrder,
      paymentProofName: null,
      paymentProofBytes: _buktiPembayaranBytes,
    );
  }

  Map<String, String> _buatKodePesanan(DateTime waktu) {
    return CashierTransactionService.createOrderCode(
      cart: widget.cart,
      time: waktu,
    );
  }

  void _dialogPembayaranCustom(String metode) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: _dialogDenganX(
          dialogContext: dialogContext,
          child: Container(
            width: 360,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _biruMuda, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _navy,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pembayaran $metode',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total yang harus dibayar:\n${widget.rupiah(totalAkhir)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF45647E),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _menyimpanPesanan
                        ? null
                        : () => _simpanPembayaran(dialogContext),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text(
                      'Konfirmasi Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  void _dialogQRIS() {
    final namaCustomer = _namaCustomerPembayaran ?? 'Pelanggan';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: !_mustCompletePayment,
          child: QrisDirectDialog(
            customerName: namaCustomer,
            cashierName: widget.namaKasir,
            orderType: widget.jenisPesanan,
            total: totalAkhir,
            subtotal: total,
            tax: biayaLainnya,
            taxRate: ppnRate,
            discount: nominalDiskon,
            discountInput: diskon,
            discountType: jenisDiskon,
            itemCount: jumlahItem,
            cart: widget.cart,
            rupiah: widget.rupiah,
            onSuccess: (receiptData) async {
              setState(() => _paymentCompleted = true);
              _namaCustomerPembayaran = null;

              var selesaiDipanggil = false;
              void akhiriQrisDirect() {
                if (selesaiDipanggil) return;
                selesaiDipanggil = true;
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                widget.onLanjutPembayaran();
              }

              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => TransaksiBerhasilPage(
                    receiptData: receiptData,
                    onSelesai: akhiriQrisDirect,
                  ),
                ),
              );
              if (!selesaiDipanggil && mounted) {
                selesaiDipanggil = true;
                widget.onLanjutPembayaran();
              }
            },
          ),
        );
      },
    );
  }

  // ==========================================================
  // DIALOG PEMBAYARAN CASH
  // ==========================================================

  void _dialogCash() {
    final TextEditingController nominalController = TextEditingController();
    double nominalCash = 0;

    double parseNominal(String value) {
      final angka = value.replaceAll(RegExp(r'[^0-9]'), '');
      return double.tryParse(angka) ?? 0;
    }

    String formatRibuan(double val) {
      final digits = val.round().toString();
      return digits.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
    }

    final quickAmounts = <double>{
      totalAkhir.ceilToDouble(),
      if (totalAkhir <= 20000) 20000,
      if (totalAkhir <= 50000) 50000,
      100000,
    }.toList()
      ..sort();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double kembalian = nominalCash - totalAkhir;
            final bool cukup = nominalCash >= totalAkhir;

            void setQuick(double val) {
              final formatted = formatRibuan(val);
              nominalController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
              setDialogState(() => nominalCash = val);
            }

            return PopScope(
              canPop: !_mustCompletePayment,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: _dialogDenganX(
                  dialogContext: dialogContext,
                  bisaTutup: !_mustCompletePayment,
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _borderSoft),
                      boxShadow: [
                        BoxShadow(
                          color: _navy.withValues(alpha: 0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _surfaceSoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _borderSoft),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Total Pembayaran Cash',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.rupiah(totalAkhir),
                                style: const TextStyle(
                                  color: _navy,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Nominal Diterima',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nominalController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [_RibuanFormatter()],
                          onChanged: (value) {
                            setDialogState(() {
                              nominalCash = parseNominal(value);
                            });
                          },
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            prefixStyle: const TextStyle(
                              color: _muted,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            hintText: '0',
                            hintStyle: const TextStyle(
                              color: Color(0xff9ab0c4),
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: _surfaceSoft,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _borderSoft),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _borderSoft),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _navy,
                                width: 1.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final amt in quickAmounts)
                              ActionChip(
                                label: Text(
                                  amt == totalAkhir.ceilToDouble()
                                      ? 'Uang Pas'
                                      : 'Rp ${formatRibuan(amt)}',
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                backgroundColor: _surfaceSoft,
                                side: const BorderSide(color: _borderSoft),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onPressed: () => setQuick(amt),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: nominalCash == 0
                                ? _surfaceSoft
                                : cukup
                                ? const Color(0xffeaf8f1)
                                : const Color(0xffffefef),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: nominalCash == 0
                                  ? _borderSoft
                                  : cukup
                                  ? const Color(0xffa9e0c3)
                                  : const Color(0xfff3b3b3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                nominalCash > 0 && !cukup
                                    ? 'Kekurangan'
                                    : 'Kembalian',
                                style: TextStyle(
                                  color: nominalCash > 0 && !cukup
                                      ? _merah
                                      : _muted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                nominalCash == 0
                                    ? 'Rp 0'
                                    : cukup
                                    ? widget.rupiah(kembalian)
                                    : widget.rupiah(-kembalian),
                                style: TextStyle(
                                  color: nominalCash == 0
                                      ? _navy
                                      : cukup
                                      ? _hijau
                                      : _merah,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed:
                                cukup && nominalCash > 0 && !_menyimpanPesanan
                                    ? () => _simpanPembayaran(dialogContext)
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _navy,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xffb8c5cf),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 19,
                            ),
                            label: const Text(
                              'Konfirmasi & Bayar',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      nominalController.dispose();
    });
  }

  // ==========================================================
  // DIALOG DISKON
  // ==========================================================

  void _dialogDiskon() {
    final controller = TextEditingController(
      text: diskon == 0 ? '' : diskon.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Diskon',
          style: TextStyle(color: _navy, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Masukkan diskon',
              hintText: 'Contoh: 3 atau 6000',
              filled: true,
              fillColor: const Color(0xffdce9f4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xff607181)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final input =
                  double.tryParse(
                    controller.text.trim().replaceAll(',', '.'),
                  ) ??
                  0;
              if (input < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Diskon tidak boleh negatif.')),
                );
                return;
              }
              setState(() {
                diskon = input;
                // 0 sampai 100 = persen; lebih dari 100 = nominal rupiah.
                jenisDiskon = input <= 100 ? '%' : 'Rp';
              });
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan Diskon'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}

// ============================================================
// TOMBOL PILL (redup / normal / border biru) + efek hover & tekan
// ============================================================

class _Pill extends StatefulWidget {
  const _Pill({
    required this.label,
    required this.onTap,
    required this.height,
    required this.fontSize,
    this.selected = false,
    this.enabled = true,
    this.dim = false,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final bool selected;
  final bool enabled;
  final bool dim;

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  bool _hover = false;
  bool _press = false;

  @override
  Widget build(BuildContext context) {
    final redup = widget.dim || !widget.enabled;
    final aktifBorder = widget.selected && !redup;

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => setState(() => _press = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _press = false) : null,
        onTapCancel: () => setState(() => _press = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _press
              ? 0.96
              : (_hover && widget.enabled && !redup)
              ? 1.02
              : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: widget.height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: redup ? const Color(0xffc5d3df) : Colors.white,
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(
                color: aktifBorder
                    ? _CheckoutPageState._biruBorder
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: redup
                  ? const []
                  : [
                      BoxShadow(
                        color: _CheckoutPageState._navy.withValues(
                          alpha: _hover ? 0.18 : 0.09,
                        ),
                        blurRadius: _hover ? 10 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: redup
                      ? const Color(0xff7d90a1)
                      : _CheckoutPageState._navy,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.bold,
                ),
                child: Text(widget.label, maxLines: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DROPDOWN YANG MENEMPEL DI ATAS TOMBOL (bukan pop up)
// ============================================================

class _AnchoredDropdown extends StatefulWidget {
  const _AnchoredDropdown({
    required this.link,
    required this.width,
    required this.options,
    required this.selected,
    required this.gayaPembayaran,
    required this.onClosed,
    this.header,
    this.rataKiri = false,
  });

  final LayerLink link;
  final double width;
  final String? header;
  final List<String> options;
  final String selected;
  final bool gayaPembayaran;
  final bool rataKiri;
  final ValueChanged<String?> onClosed;

  @override
  State<_AnchoredDropdown> createState() => _AnchoredDropdownState();
}

class _AnchoredDropdownState extends State<_AnchoredDropdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    reverseDuration: const Duration(milliseconds: 130),
  )..forward();

  bool _closing = false;

  Future<void> _close(String? value) async {
    if (_closing) return;
    _closing = true;
    await _c.reverse();
    if (mounted) widget.onClosed(value);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _opsiPembayaran(String label) {
    final sel = label == widget.selected;
    return InkWell(
      onTap: () => _close(label),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? _CheckoutPageState._navy : const Color(0xffdce9f4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.white : _CheckoutPageState._navy,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _opsiMode(String label) {
    final sel = label == widget.selected;
    return InkWell(
      onTap: () => _close(label),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: sel ? _CheckoutPageState._biruBorder : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: sel ? _CheckoutPageState._navy : const Color(0xffb8c3cf),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel() {
    final isi = <Widget>[];

    if (widget.header != null) {
      isi.add(
        Container(
          width: double.infinity,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            widget.header!,
            style: const TextStyle(
              color: _CheckoutPageState._navy,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      isi.add(const SizedBox(height: 6));
    }

    for (var i = 0; i < widget.options.length; i++) {
      final label = widget.options[i];
      isi.add(
        widget.gayaPembayaran ? _opsiPembayaran(label) : _opsiMode(label),
      );
      if (i != widget.options.length - 1) {
        isi.add(SizedBox(height: widget.gayaPembayaran ? 6 : 8));
      }
    }

    return Container(
      padding: EdgeInsets.all(widget.gayaPembayaran ? 7 : 8),
      decoration: BoxDecoration(
        color: _CheckoutPageState._biruMuda,
        borderRadius: BorderRadius.circular(widget.gayaPembayaran ? 18 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: isi),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _c,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _close(null),
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: widget.link,
          showWhenUnlinked: false,
          targetAnchor: widget.rataKiri
              ? Alignment.topLeft
              : Alignment.topCenter,
          followerAnchor: widget.rataKiri
              ? Alignment.bottomLeft
              : Alignment.bottomCenter,
          offset: const Offset(0, -8),
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                alignment: widget.rataKiri
                    ? Alignment.bottomLeft
                    : Alignment.bottomCenter,
                scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
                child: SizedBox(
                  width: widget.width,
                  child: Material(color: Colors.transparent, child: _panel()),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TANDA X DI BAWAH DIALOG
// ============================================================

class _TombolX extends StatefulWidget {
  const _TombolX({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_TombolX> createState() => _TombolXState();
}

class _TombolXState extends State<_TombolX> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: _hover ? 1.15 : 1,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            turns: _hover ? 0.25 : 0,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 34,
                shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FORMAT RIBUAN: 60000 -> 60.000
// ============================================================

class _RibuanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    if (digits.length > 10) return oldValue;

    final text = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
