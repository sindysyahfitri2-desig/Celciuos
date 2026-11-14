import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'Transaksi_Berhasil.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:kasir_celcious_coffe/data/qris_store.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/kasir/application/cashier_checkout_pricing.dart';
import 'package:kasir_celcious_coffe/features/kasir/application/cashier_transaction_service.dart';

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
  // Warna border biru saat tombol dipilih. Ganti jika ingin biru lebih terang,
  // misalnya Color(0xff1f6fb2).
  static const Color _biruBorder = Color(0xff082640);
  static const Color _biruMuda = Color(0xffa8cbe9);

  // Nilai yang diketik kasir, bisa berupa persen atau rupiah.
  double diskon = 0;
  String jenisDiskon = 'Rp'; // Pilihan: 'Rp' atau '%'.
  Uint8List? _buktiPembayaranBytes; // Bytes agar aman di Chrome/Web.
  Uint8List? _qrisImageBytes;

  // Mode transaksi.
  String selectedPayment =
      ''; // Belum memilih mode: tombol Langsung Bayar tampil redup.

  final ImagePicker _picker = ImagePicker();
  XFile? _buktiPembayaran;
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

  @override
  void initState() {
    super.initState();
    _muatFotoQris();
    selectedPayment = widget.openPaymentImmediately ? 'Langsung Bayar' : '';
    diskon =
        (widget.existingOrder?['diskonInput'] as num?)?.toDouble() ??
        (widget.existingOrder?['diskon'] as num?)?.toDouble() ??
        0;
    jenisDiskon = widget.existingOrder?['jenisDiskon']?.toString() ?? 'Rp';
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

  Future<void> _muatFotoQris() async {
    final bytes = await QrisStore.loadImageBytes();
    if (!mounted) return;
    setState(() => _qrisImageBytes = bytes);
  }

  // ==========================================================
  // TOTAL PESANAN
  // ==========================================================

  CashierCheckoutPricing get _pricing => CashierCheckoutPricing.calculate(
    cart: widget.cart,
    existingOrder: widget.existingOrder,
    defaultTaxRate: TransactionStore.ppnRate.value,
    discount: diskon,
    discountType: jenisDiskon,
  );

  double get total => _pricing.subtotal;
  double get ppnRate => _pricing.taxRate;
  double get biayaLainnya => _pricing.tax;
  double get totalSebelumDiskon => total + biayaLainnya;
  double get nominalDiskon => _pricing.discountAmount;
  double get totalAkhir => _pricing.total;
  int get jumlahItem => _pricing.itemCount;

  bool get langsungBayar => selectedPayment == 'Langsung Bayar';
  bool get _mustCompletePayment =>
      widget.openPaymentImmediately &&
      widget.existingOrder != null &&
      !_paymentCompleted;

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_mustCompletePayment,
      child: Container(
        color: const Color(0xffdce9f4),
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;
            final isMobile = width < 600;
            final isTablet = width >= 600 && width < 1000;
            final isDesktop = width >= 1000;

            final double sidePad = isMobile
                ? 12
                : isTablet
                ? 24
                : 35;

            return Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          sidePad,
                          isMobile
                              ? 12
                              : isTablet
                              ? 16
                              : 20,
                          sidePad,
                          10,
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: _mustCompletePayment
                                  ? null
                                  : widget.onBack,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: isMobile ? 36 : 38,
                                height: isMobile ? 36 : 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(19),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: _navy,
                                  size: 21,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Judul berbentuk pill putih seperti desain.
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 22,
                                vertical: isMobile ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(27),
                                boxShadow: [
                                  BoxShadow(
                                    color: _navy.withValues(alpha: 0.10),
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
                                      ? 17
                                      : isTablet
                                      ? 19
                                      : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

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
                            : SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  sidePad,
                                  4,
                                  sidePad,
                                  15,
                                ),
                                child: Align(
                                  alignment: isMobile
                                      ? Alignment.topCenter
                                      : Alignment.topLeft,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isMobile
                                          ? math.min(width, 380.0)
                                          : isTablet
                                          ? 540
                                          : 560,
                                    ),
                                    child: Column(
                                      children: List.generate(
                                        widget.cart.length,
                                        (index) => _itemCard(index, isMobile),
                                      ),
                                    ),
                                  ),
                                ),
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
    );
  }

  // ==========================================================
  // CARD ITEM (card putih + tab merah di ujung kanan)
  // ==========================================================

  Widget _itemCard(int index, bool isMobile) {
    final item = widget.cart[index];
    final harga = (item['price'] as num).toDouble();
    final jumlah = item['quantity'] as int;
    final subtotal = harga * jumlah;
    final catatan = item['catatan']?.toString().trim() ?? '';
    final terkunci = widget.existingOrder != null;
    final imagePath = item['image']?.toString() ?? '';

    Widget iconCoffee() =>
        const Icon(Icons.coffee_rounded, color: _navy, size: 28);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: terkunci ? Colors.grey : _merah,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 135,
                        height: 125,
                        decoration: BoxDecoration(
                          color: const Color(0xffd9d6e8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: imagePath.isNotEmpty
                            ? Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => iconCoffee(),
                              )
                            : iconCoffee(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xff081d2e),
                                fontSize: isMobile ? 14 : 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$jumlah X ${widget.rupiah(harga).replaceFirst('Rp ', '')}',
                              style: TextStyle(
                                color: const Color(0xff315b76),
                                fontSize: isMobile ? 11 : 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Subtotal : ${widget.rupiah(subtotal).replaceFirst('Rp ', '')}',
                              style: TextStyle(
                                color: const Color(0xff16558a),
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (catatan.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.sticky_note_2_rounded,
                                    color: _navy,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Catatan: $catatan',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _navy,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: terkunci
                    ? null
                    : () => setState(() => widget.cart.removeAt(index)),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: SizedBox(
                  width: isMobile ? 40 : 58,
                  child: Center(
                    child: Icon(
                      terkunci ? Icons.lock_outline : Icons.close,
                      color: Colors.white,
                      size: 22,
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
  // BAGIAN BAWAH CHECKOUT
  // ==========================================================

  Widget _checkoutBottom(
    double width,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final double barH = isMobile ? 48 : 62;
    const String labelTotalAkhir = 'Total Setelah diskon\ndan biaya lainnya';

    Widget totalAkhirStrip() => Container(
      height: barH,
      color: Colors.white,
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              labelTotalAkhir,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _navy,
                fontSize: isMobile ? 9 : 12,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: isMobile ? 112 : 170,
            height: double.infinity,
            color: _navy,
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.rupiah(totalAkhir).replaceFirst('Rp ', ''),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 22 : 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final tombol = Container(
      color: _biruMuda,
      padding: EdgeInsets.fromLTRB(isMobile ? 8 : 14, 8, isMobile ? 8 : 14, 10),
      child: Row(
        children: [
          Expanded(
            flex: isMobile ? 1 : 0,
            child: SizedBox(
              width: isMobile ? null : 190,
              child: _modePembayaranControl(
                fontSize: isMobile ? 12 : 14,
                height: isMobile ? 42 : 44,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: isMobile ? 1 : 0,
            child: SizedBox(
              width: isMobile ? null : 190,
              child: _tombolPembayaran(
                height: isMobile ? 42 : 44,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          if (!isMobile) const Spacer(),
          if (isMobile) const SizedBox(width: 8),
          Expanded(
            flex: isMobile ? 1 : 0,
            child: SizedBox(
              width: isMobile ? null : 190,
              child: _tombolProses(height: isMobile ? 42 : 44),
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _diskonBox(height: barH, fontSize: 12, iconSize: 20),
              ),
              Expanded(child: _totalBox(height: barH, fontSize: 20)),
            ],
          ),
          totalAkhirStrip(),
          tombol,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: barH,
          child: Row(
            children: [
              SizedBox(
                width: 175,
                child: _diskonBox(height: barH, fontSize: 14, iconSize: 26),
              ),
              SizedBox(
                width: 190,
                child: _totalBox(height: barH, fontSize: 26),
              ),
              Expanded(child: totalAkhirStrip()),
            ],
          ),
        ),
        tombol,
      ],
    );
  }

  // ==========================================================
  // TOMBOL PILL
  // - redup        : belum aktif (warna pudar)
  // - border biru  : sedang dipilih
  // ==========================================================

  // Langsung Bayar / Bayar Nanti.
  // Awalnya REDUP. Ketuk sekali -> langsung aktif (Langsung Bayar, border biru).
  // Setelah aktif, ketuk lagi untuk membuka dropdown pilihan mode.
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

  // Pembayaran (Cash / QRIS). Redup jika mode belum "Langsung Bayar".
  // Saat aktif, daftar pilihan muncul sebagai dropdown di atas tombol.
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

  // Bayar / Simpan
  Widget _tombolProses({required double height}) {
    return _Pill(
      label: langsungBayar ? 'Bayar' : 'Simpan',
      onTap: _prosesBayar,
      enabled: widget.cart.isNotEmpty && selectedPayment.isNotEmpty,
      height: height,
      fontSize: 15,
    );
  }

  // Dipanggil tombol "Pembayaran": pilih Cash/QRIS lalu simpan ke state.
  Future<void> _ubahMetodePembayaran() async {
    final pembayaran = await _pilihPembayaran();
    if (pembayaran == null || !mounted) return;
    setState(() => metodePembayaran = pembayaran);
  }

  // ==========================================================
  // PILIH MODE TRANSAKSI (dropdown)
  // ==========================================================

  Future<void> _pilihModePembayaran() async {
    // Ketukan pertama: langsung aktifkan "Langsung Bayar".
    if (selectedPayment.isEmpty) {
      setState(() => selectedPayment = 'Langsung Bayar');
      return;
    }

    final mode = await _bukaDropdown(
      link: _modeLink,
      targetKey: _modeKey,
      options: const ['Bayar Nanti', 'Langsung Bayar'],
      selected: selectedPayment,
      gayaPembayaran: false,
      rataKiri: true,
    );

    if (mode == null || !mounted) return;

    setState(() {
      selectedPayment = mode;

      if (mode == 'Bayar Nanti') {
        metodePembayaran = '';
      }
    });
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

      if (metodePembayaran == 'QRIS') {
        _dialogQRIS();
      } else if (metodePembayaran == 'Cash') {
        _dialogCash();
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
              'discount': nominalDiskon,
              'total': totalAkhir,
            },
            onSelesai: () {
              Navigator.of(context).pop();
              widget.onLanjutPembayaran();
            },
          ),
        ),
      );
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
      paymentProofName: _buktiPembayaran?.name,
      paymentProofBytes: _buktiPembayaranBytes,
    );
  }

  Map<String, String> _buatKodePesanan(DateTime waktu) {
    return CashierTransactionService.createOrderCode(
      cart: widget.cart,
      time: waktu,
    );
  }

  // ==========================================================
  // PILIH METODE PEMBAYARAN (dropdown di atas tombol Pembayaran)
  // ==========================================================

  Future<String?> _pilihPembayaran() async {
    if (!langsungBayar) return null;

    final pilihan = await _bukaDropdown(
      link: _bayarLink,
      targetKey: _bayarKey,
      header: 'Pembayaran',
      options: const ['Qris', 'Cash'],
      selected: metodePembayaran == 'QRIS' ? 'Qris' : metodePembayaran,
      gayaPembayaran: true,
    );

    if (pilihan == null) return null;
    // Nilai internal tetap 'QRIS' / 'Cash' agar tersambung ke kode lama.
    return pilihan == 'Qris' ? 'QRIS' : pilihan;
  }

  // ==========================================================
  // DIALOG QRIS + FOTO BUKTI PEMBAYARAN
  // ==========================================================

  Future<void> _ambilBuktiPembayaran(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: dialogContext,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
           
          ),
        ),
      );
      if (source == null || !mounted || !dialogContext.mounted) return;

      final foto = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1280,
        maxHeight: 1280,
        requestFullMetadata: false,
      );
      if (foto == null || !mounted || !dialogContext.mounted) return;

      final bytes = await foto.readAsBytes();
      if (!mounted || !dialogContext.mounted) return;
      setState(() {
        _buktiPembayaran = foto;
        _buktiPembayaranBytes = bytes;
      });
      setDialogState(() {});
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kamera gagal dibuka: ${error.message ?? error.code}'),
        ),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $error')));
    }
  }

  void _dialogQRIS() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PopScope(
              canPop: !_mustCompletePayment,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
                child: _dialogDenganX(
                  dialogContext: dialogContext,
                  bisaTutup: !_mustCompletePayment,
                  scroll: true,
                  child: Container(
                    width: 520,
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              color: Color(0xff102b40),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.rupiah(totalAkhir),
                            style: const TextStyle(
                              color: Color(0xff16558a),
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // QRIS TETAP DITAMPILKAN
                          Container(
                            width: 250,
                            height: 156,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xffe8e8e8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 7,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _qrisImageBytes != null
                                ? Image.memory(
                                    _qrisImageBytes!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text(
                                        'Foto QRIS tidak dapat dibuka',
                                        style: TextStyle(
                                          color: _navy,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/QRIS2.jpg',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) {
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.qr_code_2_rounded,
                                              size: 250,
                                              color: _navy,
                                            ),
                                            Text(
                                              'QRIS belum diatur di Pengaturan',
                                              style: TextStyle(
                                                color: _navy,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          const SizedBox(height: 10),

                          
                          // TOMBOL BATAL DAN SIMPAN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!_mustCompletePayment)
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                  },
                                  child: const Text(
                                    'Batal',
                                    style: TextStyle(color: Color(0xff607181)),
                                  ),
                                ),
                              if (!_mustCompletePayment)
                                const SizedBox(width: 6),
                              SizedBox(
                                width: 88,
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_buktiPembayaran == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Ambil foto bukti pembayaran terlebih dahulu.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    await _simpanPembayaran(dialogContext);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _navy,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: const Text(
                                    'Simpan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
                ),
              ),
            );
          },
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double kembalian = nominalCash - totalAkhir;
            final bool cukup = nominalCash >= totalAkhir;

            return PopScope(
              canPop: !_mustCompletePayment,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
                child: _dialogDenganX(
                  dialogContext: dialogContext,
                  bisaTutup: !_mustCompletePayment,
                  child: Container(
                    width: 340,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TOTAL PEMBAYARAN
                        const Center(
                          child: Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              color: Color(0xff102b40),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 2),

                        Center(
                          child: Text(
                            widget.rupiah(totalAkhir),
                            style: const TextStyle(
                              color: Color(0xff16558a),
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // NOMINAL CASH
                        const Text(
                          'Nominal Cash :',
                          style: TextStyle(
                            color: Color(0xff263746),
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xffe0e0e0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
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
                              color: Color(0xff263746),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Masukkan nominal cash',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // KEMBALIAN
                        Row(
                          children: [
                            const Text(
                              'Kembalian : ',
                              style: TextStyle(
                                color: Color(0xff263746),
                                fontSize: 15,
                              ),
                            ),
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 180),
                                style: TextStyle(
                                  color: nominalCash > 0 && !cukup
                                      ? Colors.red
                                      : const Color(0xff263746),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                child: Text(
                                  nominalCash == 0
                                      ? '0'
                                      : cukup
                                      ? widget
                                            .rupiah(kembalian)
                                            .replaceFirst('Rp ', '')
                                      : 'Kurang ${widget.rupiah(-kembalian)}',
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // TOMBOL SIMPAN
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 96,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: cukup && nominalCash > 0
                                  ? () => _simpanPembayaran(dialogContext)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _navy,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xffb8c5cf,
                                ),
                                elevation: 5,
                                padding: EdgeInsets.zero,
                                shape: const StadiumBorder(),
                              ),
                              child: const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontSize: 14,
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
  // DISKON
  // ==========================================================

  Widget _diskonBox({
    required double height,
    required double fontSize,
    required double iconSize,
  }) {
    final aktif = diskon > 0;
    return InkWell(
      onTap: widget.existingOrder == null ? _dialogDiskon : null,
      child: Container(
        height: height,
        color: _navy,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  fontWeight: FontWeight.bold,
                  height: 1.1,
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
    );
  }

  // ==========================================================
  // TOTAL (subtotal sebelum PPN & diskon, klik untuk lihat rincian)
  // ==========================================================

  Widget _totalBox({required double height, required double fontSize}) {
    return InkWell(
      onTap: _dialogRincianPembayaran,
      child: Container(
        height: height,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      // Ganti `total` menjadi `totalAkhir` jika ingin
                      // kotak ini menampilkan total setelah PPN & diskon.
                      widget.rupiah(total).replaceFirst('Rp ', ''),
                      style: TextStyle(
                        color: _navy,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _navy, size: 27),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DIALOG DISKON
  // ==========================================================

  void _dialogDiskon() {
    // Isi awal mengikuti jenis diskon yang sedang dipakai.
    final controller = TextEditingController(
      text: diskon == 0 ? '' : diskon.toStringAsFixed(0),
    );
    String pilihan = jenisDiskon;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Diskon',
              style: TextStyle(color: _navy, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kasir dapat memilih persen atau nominal rupiah.
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Rp', label: Text('Rupiah (Rp)')),
                      ButtonSegment(value: '%', label: Text('Persen (%)')),
                    ],
                    selected: {pilihan},
                    onSelectionChanged: (nilai) {
                      setDialogState(() => pilihan = nilai.first);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: pilihan == '%'
                          ? 'Persentase diskon'
                          : 'Nominal diskon',
                      hintText: pilihan == '%' ? 'Contoh: 3' : 'Contoh: 2500',
                      suffixText: pilihan == '%' ? '%' : null,
                      prefixText: pilihan == 'Rp' ? 'Rp ' : null,
                      filled: true,
                      fillColor: const Color(0xffdce9f4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pilihan == '%' && controller.text.trim().isNotEmpty
                        ? 'Perkiraan potongan: ${widget.rupiah(((double.tryParse(controller.text.replaceAll(',', '.')) ?? 0).clamp(0, 100) / 100) * totalSebelumDiskon)}'
                        : 'Total sebelum diskon: ${widget.rupiah(totalSebelumDiskon)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff607181),
                    ),
                  ),
                ],
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
                  if (input < 0 || (pilihan == '%' && input > 100)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Persentase harus 0–100 dan nominal tidak boleh negatif.',
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    jenisDiskon = pilihan;
                    diskon = input;
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
        );
      },
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
  final bool selected; // border biru
  final bool enabled; // false = tidak bisa diketuk
  final bool dim; // true = tampil redup (tetap bisa diketuk jika enabled)

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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: redup ? const Color(0xffc5d3df) : Colors.white,
              borderRadius: BorderRadius.circular(widget.height / 2),
              // Border selalu 2px (transparan jika tidak dipilih) agar ukuran tidak bergeser.
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
                          alpha: _hover ? 0.18 : 0.08,
                        ),
                        blurRadius: _hover ? 10 : 5,
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
                      ? const Color(0xff8799a8)
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
  final bool gayaPembayaran; // true: header + pil biru muda; false: pil putih
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
        height: 36,
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
          height: 34,
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
      isi.add(const SizedBox(height: 5));
    }

    for (var i = 0; i < widget.options.length; i++) {
      final label = widget.options[i];
      isi.add(
        widget.gayaPembayaran ? _opsiPembayaran(label) : _opsiMode(label),
      );
      if (i != widget.options.length - 1) {
        isi.add(SizedBox(height: widget.gayaPembayaran ? 5 : 8));
      }
    }

    return Container(
      padding: EdgeInsets.all(widget.gayaPembayaran ? 6 : 8),
      decoration: BoxDecoration(
        color: _CheckoutPageState._biruMuda,
        borderRadius: BorderRadius.circular(widget.gayaPembayaran ? 16 : 24),
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
        // Ketuk di luar dropdown untuk menutup.
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
                  child: Material(
                    color: Colors.transparent,
                    child: _panel(),
                  ),
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
