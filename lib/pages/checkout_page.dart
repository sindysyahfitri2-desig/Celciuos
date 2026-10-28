import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'Transaksi_Berhasil.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../data/qris_store.dart';
import 'package:image_picker/image_picker.dart';
import '../data/transaction_store.dart';
import '../data/payment_proof_store.dart';

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
  // Warna border biru saat tombol dipilih. Ganti jika ingin biru lebih terang,
  // misalnya Color(0xff1f6fb2).
  static const Color _biruBorder = Color(0xff082640);
  static const Color _biruMuda = Color(0xffa8cbe9);
  static const Color _merah = Color(0xffdd5b5b);

  // Nilai yang diketik kasir, bisa berupa persen atau rupiah.
  double diskon = 0;
  String jenisDiskon = 'Rp'; // Pilihan: 'Rp' atau '%'.
  Uint8List? _buktiPembayaranBytes; // Bytes agar aman di Chrome/Web.
  Uint8List? _qrisImageBytes;

  // Mode transaksi.
  String selectedPayment =
      ''; // Belum memilih mode: tombol utama menampilkan Simpan.

  final ImagePicker _picker = ImagePicker();
  XFile? _buktiPembayaran;
  bool _menyimpanPesanan = false;
  bool _memulaiPembayaran = false;
  bool _paymentCompleted = false;
  Future<void>? _simpanTransaksiAktif;

  // Metode pembayaran: Cash atau QRIS.
  String metodePembayaran = '';
  String? _namaCustomerPembayaran;

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

  Future<void> _muatFotoQris() async {
    final bytes = await QrisStore.loadImageBytes();
    if (!mounted) return;
    setState(() => _qrisImageBytes = bytes);
  }

  // ==========================================================
  // TOTAL PESANAN
  // ==========================================================

  double get total {
    final savedSubtotal = (widget.existingOrder?['subtotal'] as num?)
        ?.toDouble();
    if (savedSubtotal != null) return savedSubtotal;

    double hasil = 0;

    for (final item in widget.cart) {
      hasil += (item['price'] as num).toDouble() * (item['quantity'] as int);
    }

    return hasil;
  }

  double get ppnRate =>
      (widget.existingOrder?['ppnRate'] as num?)?.toDouble() ??
      TransactionStore.ppnRate.value;

  double get biayaLainnya =>
      (widget.existingOrder?['ppn'] as num?)?.toDouble() ?? total * ppnRate;

  double get totalSebelumDiskon => total + biayaLainnya;

  // Ubah diskon persen menjadi nominal rupiah untuk hitung total.
  double get nominalDiskon {
    final hasil = jenisDiskon == '%'
        ? totalSebelumDiskon * diskon / 100
        : diskon;
    return hasil.clamp(0, totalSebelumDiskon).toDouble();
  }

  double get totalAkhir {
    // Hitung ulang total agar perubahan diskon selalu langsung diterapkan.
    final hasil = totalSebelumDiskon - nominalDiskon;
    return hasil < 0 ? 0 : hasil;
  }

  int get jumlahItem {
    int jumlah = 0;

    for (final item in widget.cart) {
      jumlah += item['quantity'] as int;
    }

    return jumlah;
  }

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
                            Text(
                              'Tambah Menu',
                              style: TextStyle(
                                color: _navy,
                                fontSize: isMobile
                                    ? 20
                                    : isTablet
                                    ? 22
                                    : 23,
                                fontWeight: FontWeight.bold,
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
                                  alignment: Alignment.topLeft,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isMobile
                                          ? width
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
  // CARD ITEM (card putih + tab X merah di kanan)
  // ==========================================================

  Widget _itemCard(int index, bool isMobile) {
    final item = widget.cart[index];
    final harga = (item['price'] as num).toDouble();
    final jumlah = item['quantity'] as int;
    final subtotal = harga * jumlah;
    final catatan = item['catatan']?.toString().trim() ?? '';
    final terkunci = widget.existingOrder != null;
    final imagePath = item['image']?.toString() ?? '';
    final thumb = isMobile ? 64.0 : 84.0;

    Widget iconCoffee() =>
        const Icon(Icons.coffee_rounded, color: _navy, size: 28);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: terkunci ? Colors.grey : _merah,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card putih
            Expanded(
              child: Container(
                padding: EdgeInsets.all(isMobile ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: thumb,
                      height: thumb,
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
                              fontSize: isMobile ? 15 : 18,
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

            // Tab X merah
            InkWell(
              onTap: terkunci
                  ? null
                  : () => setState(() => widget.cart.removeAt(index)),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: SizedBox(
                width: isMobile ? 46 : 58,
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
    final double barH = isMobile ? 56 : 62;
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
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: isMobile ? 130 : 170,
            height: double.infinity,
            color: _navy,
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.rupiah(totalAkhir).replaceFirst('Rp ', ''),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 26 : 32,
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
      padding: EdgeInsets.fromLTRB(
        isMobile ? 8 : 14,
        8,
        isMobile ? 8 : 14,
        10,
      ),
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
                child: _diskonBox(height: barH, fontSize: 13, iconSize: 22),
              ),
              Expanded(child: _totalBox(height: barH, fontSize: 22)),
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
  // TOMBOL PILL (putih; kalau aktif/dipilih -> border biru)
  // ==========================================================

  Widget _pillButton({
    required String label,
    required VoidCallback? onTap,
    required double height,
    required double fontSize,
    bool selected = false,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(height / 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xffc5d3df),
          borderRadius: BorderRadius.circular(height / 2),
          // Border selalu 2px (transparan jika tidak dipilih) agar ukuran tidak bergeser.
          border: Border.all(
            color: selected && enabled ? _biruBorder : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: enabled ? _navy : const Color(0xff8799a8),
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Langsung Bayar / Bayar Nanti
  Widget _modePembayaranControl({double fontSize = 14, double height = 44}) {
    return _pillButton(
      label: selectedPayment.isEmpty ? 'Pilih Mode' : selectedPayment,
      selected: selectedPayment.isNotEmpty,
      onTap: _pilihModePembayaran,
      enabled: !widget.openPaymentImmediately,
      height: height,
      fontSize: fontSize,
    );
  }

  // Pembayaran (Cash / QRIS)
  Widget _tombolPembayaran({required double height, required double fontSize}) {
    return _pillButton(
      label: metodePembayaran.isEmpty ? 'Pembayaran' : metodePembayaran,
      selected: metodePembayaran.isNotEmpty,
      onTap: _ubahMetodePembayaran,
      enabled: langsungBayar && !widget.openPaymentImmediately,
      height: height,
      fontSize: fontSize,
    );
  }

  // Bayar / Simpan
  Widget _tombolProses({required double height}) {
    return _pillButton(
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
  // PILIH MODE TRANSAKSI
  // ==========================================================


Future<void> _pilihModePembayaran() async {
  final String? mode = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFFA8CBE9),
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 120,
            vertical: 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pilihanMode(
                label: 'Langsung Bayar',
                selected: selectedPayment == 'Langsung Bayar',
                onTap: () {
                  Navigator.pop(context, 'Langsung Bayar');
                },
              ),
              const SizedBox(height: 18),
              _pilihanMode(
                label: 'Bayar Nanti',
                selected: selectedPayment == 'Bayar Nanti',
                onTap: () {
                  Navigator.pop(context, 'Bayar Nanti');
                },
              ),
            ],
          ),
        ),
      );
    },
  );

  if (mode == null || !mounted) return;

  setState(() {
    selectedPayment = mode;

    if (mode == 'Bayar Nanti') {
      metodePembayaran = '';
    }
  });
}

Widget _pilihanMode({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  const navy = Color(0xFF103456);

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(40),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: selected ? navy : Colors.transparent,
          width: 4,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected
              ? navy
              : const Color(0xFFB8C3CF),
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
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
    final items = widget.cart.map((item) {
      return <String, dynamic>{
        'name': item['name'].toString(),
        'price': (item['price'] as num).toDouble(),
        'quantity': item['quantity'] as int,
        'category': item['category']?.toString() ?? '',
        'image': item['image']?.toString() ?? '',
        'catatan': item['catatan']?.toString() ?? '',
      };
    }).toList();

    try {
      await TransactionStore.addUnfinishedOrder({
        'id': kodePesanan['id'],
        'kode': kodePesanan['display'],
        'tanggal': waktu.toIso8601String(),
        'nama': nama,
        'kasir': widget.namaKasir,
        'jumlah': jumlahItem,
        'subtotal': total,
        'ppnRate': ppnRate,
        'ppn': biayaLainnya,
        'diskon': nominalDiskon,
        'diskonInput': diskon,
        'jenisDiskon': jenisDiskon,
        if (_buktiPembayaranBytes != null)
          'buktiPembayaranBase64': base64Encode(_buktiPembayaranBytes!),
        'total': totalAkhir,
        'tipe': widget.jenisPesanan,
        'bayar': 'Pending',
        'selesai': false,
        'cart': items,
      });

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
    final cart = widget.cart.map((item) {
      return <String, dynamic>{
        'name': item['name'].toString(),
        'price': (item['price'] as num).toDouble(),
        'quantity': item['quantity'] as int,
        'category': item['category']?.toString() ?? '',
        'catatan': item['catatan']?.toString() ?? '',
      };
    }).toList();
    final jam =
        '${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}';
    final proofPath = _buktiPembayaran == null
        ? null
        : await PaymentProofStore.save(
            transactionId: kodePesanan['id']!,
            imageName: _buktiPembayaran!.name,
            bytes: _buktiPembayaranBytes!,
          );
    final transaksi = <String, dynamic>{
      'id': kodePesanan['id'],
      'kode': kodePesanan['display'],
      'tanggal': waktu.toIso8601String(),
      'jam': jam,
      'kasir': widget.namaKasir.trim().isEmpty ? 'Kasir' : widget.namaKasir,
      'nama': namaCustomer,
      'jumlah': jumlahItem.toString(),
      'pembayaran': metodePembayaran,
      'subtotal': total,
      'ppnRate': ppnRate,
      'ppn': biayaLainnya,
      'diskon': nominalDiskon,
      'diskonInput': diskon,
      'jenisDiskon': jenisDiskon,
      if (proofPath != null) 'buktiPembayaranPath': proofPath,
      if (kIsWeb && _buktiPembayaranBytes != null)
        'buktiPembayaranBase64': base64Encode(_buktiPembayaranBytes!),
      'total': totalAkhir,
    };
    final existingOrder = widget.existingOrder;
    try {
      if (existingOrder != null) {
        await TransactionStore.markUnfinishedOrderPaid(
          id: kodePesanan['id']!,
          paymentMethod: metodePembayaran,
          transaction: transaksi,
        );
      } else {
        await TransactionStore.addPaidOrder(
          order: {
            ...transaksi,
            'jumlah': jumlahItem,
            'tipe': widget.jenisPesanan,
            'bayar': 'Lunas',
            'selesai': false,
            'cart': cart,
          },
          transaction: {},
        );
      }
    } catch (_) {
      if (proofPath != null) await PaymentProofStore.delete(proofPath);
      rethrow;
    }
  }

  Map<String, String> _buatKodePesanan(DateTime waktu) {
    const kodeKategori = {
      'coffee': 'CF',
      'non-coffee': 'NC',
      'food': 'FD',
      'snack': 'SN',
    };
    final tagKategori =
        widget.cart
            .map((item) {
              final kategori = item['category']
                  ?.toString()
                  .trim()
                  .toLowerCase();
              if (kategori == null || kategori.isEmpty) return 'OT';
              return kodeKategori[kategori] ??
                  kategori
                      .substring(0, kategori.length >= 2 ? 2 : 1)
                      .toUpperCase();
            })
            .toSet()
            .toList()
          ..sort();
    final tanggal =
        '${waktu.day.toString().padLeft(2, '0')}${waktu.month.toString().padLeft(2, '0')}';
    final dasar = '${tagKategori.join('-')}-$tanggal-';
    final kodeTersimpan = [
      ...TransactionStore.unfinishedOrders.value,
      ...TransactionStore.transactions.value,
    ].map((order) => order['id']?.toString() ?? '');
    var nomor = 1;
    for (final kodeLama in kodeTersimpan) {
      if (!kodeLama.startsWith(dasar)) continue;
      final nomorLama = int.tryParse(kodeLama.substring(dasar.length));
      if (nomorLama != null && nomorLama >= nomor) nomor = nomorLama + 1;
    }
    final urut = nomor.toString().padLeft(2, '0');
    return {
      'id': '$dasar$urut',
      'display': '-${tagKategori.join('-')}\n-$tanggal-\n$urut',
    };
  }

  // ==========================================================
  // PILIH METODE PEMBAYARAN
  // ==========================================================

  Future<String?> _pilihPembayaran() async {
    if (!langsungBayar) return null;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _biruMuda,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.all(6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER PEMBAYARAN
              Container(
                width: double.infinity,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Pembayaran',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // QRIS
              _opsiPembayaran(
                title: 'Qris',
                selected: metodePembayaran == 'QRIS',
                onTap: () {
                  Navigator.pop(dialogContext, 'QRIS');
                },
              ),

              const SizedBox(height: 5),

              // CASH
              _opsiPembayaran(
                title: 'Cash',
                selected: metodePembayaran == 'Cash',
                onTap: () {
                  Navigator.pop(dialogContext, 'Cash');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // OPSI PEMBAYARAN
  // ==========================================================

  Widget _opsiPembayaran({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _navy : const Color(0xffdce9f4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : _navy,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Ambil foto dengan kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih foto dari galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
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
                          width: double.infinity,
                          height: 300,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xffe8e8e8)),
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
                                      style: TextStyle(color: _navy, fontSize: 12),
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/QRIS2.jpg',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) {
                                    return const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.qr_code_2_rounded,
                                            size: 125,
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

                        // PREVIEW FOTO BUKTI TERPISAH DARI QRIS
                        if (_buktiPembayaran != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xffdce9f4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Bukti Pembayaran',
                                  style: TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _buktiPembayaranBytes == null
                                      ? const SizedBox(
                                          height: 100,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : Image.memory(
                                          _buktiPembayaranBytes!,
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox(
                                                height: 100,
                                                child: Center(
                                                  child: Text(
                                                    'Foto bukti tidak dapat ditampilkan.',
                                                  ),
                                                ),
                                              ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // TOMBOL FOTO BUKTI
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: () => _ambilBuktiPembayaran(
                                    dialogContext,
                                    setDialogState,
                                  ),
                                  icon: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 19,
                                  ),
                                  label: const Text(
                                    'Foto Bukti Pembayaran',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _biruMuda,
                                    foregroundColor: _navy,
                                    side: BorderSide.none,
                                    shape: const StadiumBorder(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

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
                            if (!_mustCompletePayment) const SizedBox(width: 6),
                            SizedBox(
                              width: 88,
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_buktiPembayaran == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                            fontSize: 16,
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
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // NOMINAL CASH
                      const Text(
                        'Nominal Cash :',
                        style: TextStyle(
                          color: Color(0xff263746),
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Container(
                        height: 31,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
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
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setDialogState(() {
                              nominalCash = parseNominal(value);
                            });
                          },
                          style: const TextStyle(
                            color: Color(0xff263746),
                            fontSize: 12,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Masukkan nominal cash',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),

                      const SizedBox(height: 9),

                      // KEMBALIAN
                      Row(
                        children: [
                          const Text(
                            'Kembalian : ',
                            style: TextStyle(
                              color: Color(0xff263746),
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              nominalCash == 0
                                  ? 'Rp 0'
                                  : cukup
                                  ? widget.rupiah(kembalian)
                                  : 'Kurang ${widget.rupiah(-kembalian)}',
                              style: TextStyle(
                                color: nominalCash > 0 && !cukup
                                    ? Colors.red
                                    : const Color(0xff263746),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // TOMBOL SIMPAN
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 88,
                          height: 31,
                          child: ElevatedButton(
                            onPressed: cukup && nominalCash > 0
                                ? () => _simpanPembayaran(dialogContext)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _navy,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xffb8c5cf),
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