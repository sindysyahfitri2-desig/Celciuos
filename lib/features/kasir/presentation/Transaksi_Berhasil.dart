import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kasir_celcious_coffe/data/receipt_settings_store.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';

/// Halaman sukses setelah transaksi berhasil disimpan.
/// onSelesai dipanggil saat kasir menekan tombol "Selesai".
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

  static const Color _background = Color(0xffd8e5f1);
  static const Color _navy = Color(0xff103456);
  static const Color _successGreen = Color(0xff00665d);

  @override
  void initState() {
    super.initState();

    // Animasi ikon centang: muncul dari kecil menjadi normal.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
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

    // Suara sistem sederhana tanpa perlu menambah package atau file audio.
    // Bunyi yang terdengar mengikuti dukungan perangkat/platform.
    _putarSuaraSukses();
  }

  Future<void> _putarSuaraSukses() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Jika perangkat tidak mendukung suara sistem, animasi tetap berjalan.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // Garis tipis di bagian atas, mengikuti gambar contoh.
            Container(
              height: 4,
              width: double.infinity,
              color: const Color(0xff505050),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: const BoxDecoration(
                                color: _successGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: _background,
                                size: 52,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Transaksi Berhasil Disimpan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.receiptData != null)
                          ValueListenableBuilder<Map<String, bool>>(
                            valueListenable: ReceiptSettingsStore.options,
                            builder: (context, options, _) => Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: _receiptCard(options),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Tombol bawah memenuhi lebar layar.
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.onSelesai,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: _background,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptCard(Map<String, bool> options) {
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
                  fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: _navy,
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (options['storeLogo'] ?? true) ...[
            const SizedBox(
              height: 48,
              child: AppBrandingLogo(height: 48),
            ),
            const SizedBox(height: 6),
          ],
          const Text(
            'CELCIOUS COFFEE',
            style: TextStyle(
              color: _navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Divider(height: 18),
          if (options['orderNumber'] ?? true)
            detail('ID Pesanan', receipt['orderId']?.toString() ?? '', bold: true),
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
          detail('Pembayaran', receipt['paymentMethod']?.toString() ?? '-'),
          const Divider(height: 18),
          for (final item in items)
            detail(
              '${item['name'] ?? 'Menu'}  x${item['quantity'] ?? 1}',
              amount(
                ((item['price'] as num?) ?? 0) *
                    ((item['quantity'] as num?) ?? 1),
              ),
            ),
          const Divider(height: 18),
          detail('Subtotal', amount(receipt['subtotal'])),
          detail('Pajak', amount(receipt['tax'])),
          if (((receipt['discount'] as num?) ?? 0) > 0)
            detail('Diskon', '-${amount(receipt['discount'])}'),
          if (options['total'] ?? true)
            detail('Total Bayar', amount(receipt['total']), bold: true),
          if (options['qrCode'] ?? true) ...[
            const SizedBox(height: 12),
            Icon(Icons.qr_code_2_rounded, color: _navy, size: 58),
            const Text(
              'Terima kasih atas pesanan Anda',
              textAlign: TextAlign.center,
              style: TextStyle(color: _navy, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
