import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kasir_celcious_coffe/data/receipt_settings_store.dart';
import 'package:kasir_celcious_coffe/features/settings/application/print_service.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Halaman sukses setelah transaksi berhasil disimpan.
/// Menampilkan 2 struk: Struk Customer & Struk Dapur, serta tombol cetak masing-masing.
class TransaksiBerhasilPage extends StatefulWidget {
  final VoidCallback onSelesai;
  final Map<String, dynamic>? receiptData;

  const TransaksiBerhasilPage({
    super.key,
    required this.onSelesai,
    this.receiptData,
  });

  @override
  State<TransaksiBerhasilPage> createState() => _TransaksiBerhasilPageState();
}

class _TransaksiBerhasilPageState extends State<TransaksiBerhasilPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  bool _printingCustomer = false;
  bool _printingKitchen = false;
  bool _printingSticker = false;

  static const Color _background = Color(0xFFDCE9F4);
  static const Color _navy = Color(0xFF0B2846);
  static const Color _lightBlue = Color(0xFFA8CBE9);
  static const Color _softBlue = Color(0xFFEAF3FB);
  static const Color _muted = Color(0xFF56708A);

  static const String _storeAddress =
      'Dusun vak111 kampun, Mekar Sawit, Kec. Sawit Seberang, '
      'Kabupaten Langkat, Sumatera Utara 20852';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
    _putarSuaraSukses();
  }

  Future<void> _putarSuaraSukses() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  Future<void> _cetakStrukCustomer() async {
    if (_printingCustomer || widget.receiptData == null) return;
    setState(() => _printingCustomer = true);
    try {
      await PrintService.cetakStrukCustomer(widget.receiptData!);
    } finally {
      if (mounted) setState(() => _printingCustomer = false);
    }
  }

  Future<void> _cetakStrukDapur() async {
    if (_printingKitchen || widget.receiptData == null) return;
    setState(() => _printingKitchen = true);
    try {
      await PrintService.cetakStrukDapur(widget.receiptData!);
    } finally {
      if (mounted) setState(() => _printingKitchen = false);
    }
  }

  Future<void> _cetakStikerMinuman() async {
    final data = widget.receiptData;
    if (data == null || _printingSticker) return;
    setState(() => _printingSticker = true);
    try {
      final payload = PrintService.buildPrintPayloadFromOrder(data);
      await PrintService.cetakStikerTransaksi(payload);
    } finally {
      if (mounted) setState(() => _printingSticker = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          widget.onSelesai();
        }
      },
      child: Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // Aksen garis atas bertema navy & biru muda
            Container(
              height: 5,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_navy, Color(0xFF28679C), _lightBlue],
                ),
              ),
            ),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final receipt = widget.receiptData;
                  final adaMinuman =
                      receipt != null && PrintService.adaMinuman(receipt);
                  final adaMakanan =
                      receipt != null && PrintService.adaMakanan(receipt);
                  final totalCards =
                      1 + (adaMinuman ? 1 : 0) + (adaMakanan ? 1 : 0);
                  final sideBySide = width >= 760 && totalCards > 1;
                  final pad = width < 600 ? 16.0 : 26.0;

                  final subLabel = adaMinuman && adaMakanan
                      ? 'Struk Transaksi, Stiker Cup Minuman & Struk Dapur siap dicetak'
                      : adaMinuman
                      ? 'Struk Transaksi & Stiker Cup Minuman siap dicetak'
                      : adaMakanan
                      ? 'Struk Transaksi & Struk Dapur siap dicetak'
                      : 'Struk Transaksi siap dicetak';

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(pad, 20, pad, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: totalCards == 3 && sideBySide
                              ? 1140
                              : (sideBySide ? 860 : 440),
                        ),
                        child: Column(
                          children: [
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [_navy, Color(0xFF1F5888)],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _lightBlue,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _navy.withValues(alpha: 0.25),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 46,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Transaksi Berhasil Disimpan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _navy,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            if (receipt != null)
                              ValueListenableBuilder<Map<String, bool>>(
                                valueListenable: ReceiptSettingsStore.options,
                                builder: (context, options, _) {
                                  final cards = <Widget>[
                                    _customerReceiptCard(options),
                                    if (adaMinuman) _stickerReceiptCard(),
                                    if (adaMakanan) _kitchenReceiptCard(),
                                  ];

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 20),
                                    child: sideBySide
                                        ? Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              for (var i = 0;
                                                  i < cards.length;
                                                  i++) ...[
                                                if (i > 0)
                                                  const SizedBox(width: 18),
                                                Expanded(child: cards[i]),
                                              ],
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              for (var i = 0;
                                                  i < cards.length;
                                                  i++) ...[
                                                if (i > 0)
                                                  const SizedBox(height: 18),
                                                cards[i],
                                              ],
                                            ],
                                          ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Tombol Selesai bawah (navy tegas)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: widget.onSelesai,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
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
  // STRUK 1: STRUK CUSTOMER
  // ==========================================================

  Widget _customerReceiptCard(Map<String, bool> options) {
    final receipt = widget.receiptData!;
    final dateValue = receipt['orderedAt'];
    final date = dateValue is DateTime ? dateValue : DateTime.now();
    final items = (receipt['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    String amount(Object? value) {
      final digits = ((value as num?) ?? 0).round().toString();
      return 'Rp ${digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      )}';
    }

    Widget detail(String label, String value, {bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: _navy,
                fontSize: 12,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC5DAEC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _navy,
            child: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: Colors.white, size: 17),
                SizedBox(width: 8),
                Text(
                  'STRUK CUSTOMER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                if (options['storeLogo'] ?? true) ...[
                  Container(
                    width: 52,
                    height: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: const AppBrandingLogo(
                      fit: BoxFit.cover,
                      height: 52,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                const Text(
                  'CELCIOUS COFFEE',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  _storeAddress,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
                const Divider(height: 18, color: Color(0xFFCDE0F0)),
                if (options['orderNumber'] ?? true)
                  detail(
                    'ID Pesanan',
                    receipt['orderId']?.toString() ?? '',
                    bold: true,
                  ),
                if ((receipt['customerName']?.toString().trim() ?? '')
                    .isNotEmpty)
                  detail(
                    'Pelanggan',
                    receipt['customerName']?.toString() ?? '-',
                  ),
                if (options['cashierName'] ?? true)
                  detail('Kasir', receipt['cashierName']?.toString() ?? '-'),
                if (options['orderTime'] ?? true)
                  detail(
                    'Waktu',
                    '${date.day.toString().padLeft(2, '0')}/'
                    '${date.month.toString().padLeft(2, '0')}/'
                    '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
                    '${date.minute.toString().padLeft(2, '0')}',
                  ),
                detail('Jenis Pesanan', receipt['orderType']?.toString() ?? '-'),
                detail(
                  'Pembayaran',
                  receipt['paymentMethod']?.toString() ?? '-',
                ),
                const Divider(height: 18, color: Color(0xFFCDE0F0)),
                for (final item in items)
                  detail(
                    '${item['name'] ?? 'Menu'}  x${item['quantity'] ?? 1}',
                    amount(
                      ((item['price'] as num?) ?? 0) *
                          ((item['quantity'] as num?) ?? 1),
                    ),
                  ),
                const Divider(height: 18, color: Color(0xFFCDE0F0)),
                detail('Subtotal', amount(receipt['subtotal'])),
                detail('Pajak', amount(receipt['tax'])),
                if (((receipt['biaya_layanan'] as num?) ?? 0) > 0)
                  detail('Biaya Layanan', amount(receipt['biaya_layanan'])),
                if (((receipt['discount'] as num?) ?? 0) > 0)
                  detail('Diskon', '-${amount(receipt['discount'])}'),
                if (options['total'] ?? true)
                  detail('Total Bayar', amount(receipt['total']), bold: true),
                if (options['qrCode'] ?? true) ...[
                  const SizedBox(height: 12),
                  QrImageView(
                    data: PrintService.kInstagramUrl,
                    version: QrVersions.auto,
                    size: 76,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Follow Instagram Kami • ${PrintService.kInstagramHandle}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _navy,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Terima kasih atas pesanan Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _printingCustomer ? null : _cetakStrukCustomer,
                    icon: _printingCustomer
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.print_rounded, size: 17),
                    label: const Text(
                      'Cetak Struk Transaksi',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
  // STRUK 2: STIKER CUP MINUMAN (khusus pesanan minuman untuk Barista)
  // ==========================================================

  Widget _stickerReceiptCard() {
    final receipt = widget.receiptData!;
    final orderId = receipt['orderId']?.toString() ?? '-';
    final customerName = receipt['customerName']?.toString().trim() ?? '';
    final orderType = receipt['orderType']?.toString().trim() ?? 'Dine In';
    final tipeKode = orderType == 'Take Away' ? 'Ta' : 'Di';
    final kasir = receipt['cashierName']?.toString() ?? 'Kasir';
    final dateValue = receipt['orderedAt'];
    final date = dateValue is DateTime ? dateValue : DateTime.now();
    const bln = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final waktu =
        '${bln[date.month - 1]} ${date.day}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final drinkItems = (receipt['items'] as List? ?? const [])
        .whereType<Map>()
        .where(PrintService.isMinumanItem)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final cups = <Map<String, String>>[];
    final totalCups = drinkItems.fold<int>(
      0,
      (sum, it) => sum + ((it['quantity'] as num?)?.toInt() ?? 1),
    );
    var cupIndex = 0;
    for (final item in drinkItems) {
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      for (var i = 0; i < qty; i++) {
        cupIndex++;
        cups.add({
          'menu': item['name']?.toString() ?? 'Minuman',
          'catatan': (item['catatan']?.toString() ?? '').trim().toUpperCase(),
          'urutan': '$cupIndex/$totalCups',
        });
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB7D6F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF16558A),
            child: Row(
              children: [
                const Icon(Icons.local_cafe_rounded, color: Colors.white, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'STIKER CUP MINUMAN ($totalCups CUP)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final cup in cups)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FBFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _lightBlue, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              orderId,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                              ),
                            ),
                            Text(
                              '${customerName.isNotEmpty ? '$customerName ' : ''}$tipeKode',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cup['menu'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _navy,
                          ),
                        ),
                        if ((cup['catatan'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            cup['catatan']!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _muted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$waktu • $kasir',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9.5,
                                color: _muted,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _navy,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cup['urutan'] ?? '1/1',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _printingSticker ? null : _cetakStikerMinuman,
                    icon: _printingSticker
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.local_cafe_outlined, size: 17),
                    label: Text(
                      'Cetak Stiker Cup ($totalCups)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16558A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
  // STRUK 3: STRUK DAPUR (khusus pesanan makanan untuk Kitchen)
  // ==========================================================

  Widget _kitchenReceiptCard() {
    final receipt = widget.receiptData!;
    final orderId = receipt['orderId']?.toString() ?? '-';
    final customerName = receipt['customerName']?.toString().trim() ?? '';
    final orderType = receipt['orderType']?.toString().trim() ?? 'Dine In';
    final tableOrCustomer = customerName.isNotEmpty
        ? '$orderType • $customerName'
        : orderType;

    final items = (receipt['items'] as List? ?? const [])
        .whereType<Map>()
        .where(PrintService.isMakananItem)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC5DAEC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _softBlue,
            child: const Row(
              children: [
                Icon(Icons.restaurant_menu_rounded, color: _navy, size: 17),
                SizedBox(width: 8),
                Text(
                  'STRUK DAPUR',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header sesuai gambar ke-2: Order (No.order) + Meja/Customer
                Text(
                  'Order #$orderId',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tableOrCustomer,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Garis pemisah navy solid sesuai gambar ke-2
                Container(height: 1.8, color: _navy),
                const SizedBox(height: 10),

                // Baris judul kolom: Pesanan | Jlh Pesanan
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pesanan',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Jlh Pesanan',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Belum ada item pesanan.',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ),
                  )
                else
                  for (final item in items) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name']?.toString() ?? 'Menu',
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if ((item['catatan']?.toString().trim() ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Catatan: ${item['catatan']}',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            constraints: const BoxConstraints(minWidth: 32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _softBlue,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _lightBlue),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${item['quantity'] ?? 1}',
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _printingKitchen ? null : _cetakStrukDapur,
                    icon: _printingKitchen
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _navy,
                            ),
                          )
                        : const Icon(Icons.print_outlined, size: 17),
                    label: const Text(
                      'Cetak Struk Dapur',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _lightBlue,
                      foregroundColor: _navy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
