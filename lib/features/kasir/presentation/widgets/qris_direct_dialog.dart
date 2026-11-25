import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/features/kasir/application/cashier_transaction_service.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';

const Color _navy = Color(0xFF082640);
const Color _accentBlue = Color(0xFF16558A);
const Color _muted = Color(0xFF607181);
const Color _background = Color(0xFFF4F7FA);
const Color _border = Color(0xFFE5EAF0);

class QrisDirectDialog extends StatefulWidget {
  const QrisDirectDialog({
    super.key,
    required this.customerName,
    required this.cashierName,
    required this.orderType,
    required this.total,
    required this.subtotal,
    required this.tax,
    required this.taxRate,
    required this.discount,
    required this.discountInput,
    required this.discountType,
    required this.itemCount,
    required this.cart,
    required this.rupiah,
    required this.onSuccess,
    this.onCancel,
  });

  final String customerName;
  final String cashierName;
  final String orderType;
  final double total;
  final double subtotal;
  final double tax;
  final double taxRate;
  final double discount;
  final double discountInput;
  final String discountType;
  final int itemCount;
  final List<Map<String, dynamic>> cart;
  final String Function(double) rupiah;
  final ValueChanged<Map<String, dynamic>> onSuccess;
  final VoidCallback? onCancel;

  @override
  State<QrisDirectDialog> createState() => _QrisDirectDialogState();
}

class _QrisDirectDialogState extends State<QrisDirectDialog> {
  bool _isLoading = true;
  bool _isChecking = false;
  bool _isSimulating = false;
  bool _isPaid = false;
  String? _errorMessage;

  String? _qrUrl;
  String? _qrString;
  dynamic _idTransaksi;
  Map<String, String>? _kodePesanan;
  DateTime? _waktuTransaksi;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _mulaiTransaksiQris();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _mulaiTransaksiQris() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final waktu = DateTime.now();
      _waktuTransaksi = waktu;
      // Gunakan kode harian singkat (mis. CC-1125-001) dan sinkronkan dengan kode resmi server
      final kode = CashierTransactionService.createOrderCode(
        cart: widget.cart,
        time: waktu,
      );
      _kodePesanan = kode;

      final hasil = await CashierTransactionService.createQrisPayment(
        kode: kode['id']!,
        customerName: widget.customerName,
        orderType: widget.orderType,
        discountInput: widget.discountInput,
        discountType: widget.discountType,
        cart: widget.cart,
      );

      final data = hasil['data'] as Map<String, dynamic>?;
      final payment = hasil['payment'] as Map<String, dynamic>?;

      final serverKode = data?['kode']?.toString().trim();
      if (serverKode != null && serverKode.isNotEmpty) {
        _kodePesanan = {'id': serverKode, 'display': serverKode};
      }

      final idTrx = data?['id_transaksi'];
      final qr = payment?['qr_url']?.toString();
      final qrStr = payment?['qr_string']?.toString();

      if (idTrx == null || ((qr == null || qr.isEmpty) && (qrStr == null || qrStr.isEmpty))) {
        throw StateError('Respon pembayaran QRIS dari server tidak lengkap.');
      }

      if (!mounted) return;

      setState(() {
        _idTransaksi = idTrx;
        _qrUrl = qr;
        _qrString = qrStr;
        _isLoading = false;
      });

      // Mulai polling cek status setiap 2 detik
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _cekStatus(manual: false),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cekStatus({bool manual = false}) async {
    if (_isChecking || _isPaid || _idTransaksi == null) return;
    if (manual) setState(() => _isChecking = true);

    try {
      final res = await ApiService.get('transaksi/$_idTransaksi');
      final trx = res['data'] as Map<String, dynamic>?;
      final status = trx?['status_bayar']?.toString().toLowerCase();

      if (status == 'lunas') {
        await _selesaiPembayaran(trx);
        return;
      }

      if (status == 'dibatalkan' || status == 'cancelled') {
        _pollingTimer?.cancel();
        if (mounted) {
          setState(() {
            _errorMessage = 'Pembayaran dibatalkan atau kedaluwarsa.';
            _isChecking = false;
          });
        }
        return;
      }
    } catch (_) {
      // Abaikan error timeout sementara pada polling
    } finally {
      if (mounted && manual) setState(() => _isChecking = false);
    }
  }

  Future<void> _selesaiPembayaran(Map<String, dynamic>? trx) async {
    _pollingTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _isPaid = true;
      _isChecking = false;
    });

    // Simpan transaksi QRIS ke local store
    await CashierTransactionService.saveConfirmedQrisTransaction(
      orderCode: _kodePesanan!,
      time: _waktuTransaksi!,
      customerName: widget.customerName,
      cashierName: widget.cashierName,
      itemCount: widget.itemCount,
      subtotal: widget.subtotal,
      taxRate: widget.taxRate,
      tax: widget.tax,
      discount: widget.discount,
      discountInput: widget.discountInput,
      discountType: widget.discountType,
      total: widget.total,
      orderType: widget.orderType,
      cart: widget.cart,
      idTransaksi: _idTransaksi,
    );

    // Catatan: Struk & stiker tidak dicetak otomatis — kasir klik tombol manual di halaman Transaksi Berhasil.

    // Tunda sebentar (800ms) agar kasir melihat centang hijau sukses
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    Navigator.of(context).pop();

    widget.onSuccess({
      'orderId': _kodePesanan!['id'] ?? '',
      'customerName': widget.customerName,
      'cashierName': widget.cashierName,
      'orderType': widget.orderType,
      'paymentMethod': 'QRIS',
      'orderedAt': _waktuTransaksi!,
      'items': widget.cart.map((i) => Map<String, dynamic>.from(i)).toList(),
      'subtotal': widget.subtotal,
      'tax': widget.tax,
      'discount': widget.discount,
      'total': widget.total,
      if (trx != null) 'rawTransaksi': trx,
    });
  }

  Future<void> _simulasiBayar() async {
    if (_isSimulating || _isPaid || _idTransaksi == null) return;
    setState(() => _isSimulating = true);

    try {
      final res = await ApiService.post('transaksi/$_idTransaksi/simulasi-bayar', {});
      final trx = res['data'] as Map<String, dynamic>?;
      if (trx != null && mounted) {
        await _selesaiPembayaran(trx);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal simulasi bayar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        width: 380,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // HEADER TOKO
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3979AD),
                    shape: BoxShape.circle,
                  ),
                  child: const ClipOval(
                    child: AppBrandingLogo(fallbackIconSize: 20),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QRIS Celcious Coffee',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Scan dari BCA, Mandiri, GoPay, OVO, Dana, dll',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isPaid)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _muted),
                    tooltip: 'Tutup',
                    onPressed: () {
                      _pollingTimer?.cancel();
                      Navigator.pop(context);
                      widget.onCancel?.call();
                    },
                  ),
              ],
            ),
            const Divider(height: 20),

            // NOMINAL TOTAL
            Text(
              'Total Pembayaran',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.rupiah(widget.total),
              style: const TextStyle(
                color: _accentBlue,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            if (_kodePesanan != null) ...[
              const SizedBox(height: 2),
              Text(
                'Order ID: #${_kodePesanan!['id']}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 14),

            // AREA KONTEN: LOADING / ERROR / SUKSES / QR CODE
            if (_isLoading)
              Container(
                height: 250,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _navy),
                    SizedBox(height: 14),
                    Text(
                      'Menghubungkan ke QRIS Midtrans...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
              )
            else if (_errorMessage != null)
              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _mulaiTransaksiQris,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            else if (_isPaid)
              Container(
                height: 250,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 70),
                    SizedBox(height: 12),
                    Text(
                      'Pembayaran Berhasil Diterima!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Mencetak struk transaksi...',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              )
            else ...[
              // QR CODE DARI MIDTRANS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (_qrString != null && _qrString!.isNotEmpty)
                      ? Container(
                          color: Colors.white,
                          width: 210,
                          height: 210,
                          alignment: Alignment.center,
                          child: QrImageView(
                            data: _qrString!,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(4),
                          ),
                        )
                      : (_qrUrl != null && _qrUrl!.isNotEmpty)
                          ? Image.network(
                              _qrUrl!,
                              width: 210,
                              height: 210,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const SizedBox(
                                  width: 210,
                                  height: 210,
                                  child: Center(
                                    child: CircularProgressIndicator(color: _navy),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return SizedBox(
                                  width: 210,
                                  height: 210,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.broken_image_rounded, size: 40, color: _muted),
                                        const SizedBox(height: 6),
                                        const Text('Gagal memuat QR', style: TextStyle(fontSize: 11, color: _muted)),
                                        TextButton(
                                          onPressed: () => setState(() {}),
                                          child: const Text('Muat Ulang'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : const SizedBox(
                              width: 210,
                              height: 210,
                              child: Center(
                                child: Text('QR Code tidak tersedia', style: TextStyle(fontSize: 12, color: _muted)),
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 8),

              // TOMBOL BANTUAN SIMULATOR & TESTING DEMO
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (_qrUrl != null && _qrUrl!.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: _accentBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _qrUrl!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link QR berhasil disalin! Silakan paste di kotak simulator Midtrans.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Salin Link Simulator', style: TextStyle(fontSize: 11)),
                    ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: Colors.green.shade700,
                      backgroundColor: Colors.green.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSimulating ? null : _simulasiBayar,
                    icon: _isSimulating
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.green),
                          )
                        : const Icon(Icons.bolt_rounded, size: 15),
                    label: Text(
                      _isSimulating ? 'Memproses...' : 'Simulasi Bayar (Demo)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // LOGO JARINGAN QRIS
              const Text(
                'BCA • Mandiri • BRI • BNI • GoPay • OVO • DANA • ShopeePay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),

              // STATUS BAR BERJALAN
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _isChecking ? _accentBlue : _navy,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menunggu pembayaran di-scan...',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _navy,
                            ),
                          ),
                          Text(
                            'Struk otomatis keluar begitu pelanggan membayar',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // TOMBOL AKSI
            if (!_isPaid)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      _pollingTimer?.cancel();
                      Navigator.pop(context);
                      widget.onCancel?.call();
                    },
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  ),
                  if (!_isLoading && _errorMessage == null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navy,
                        side: const BorderSide(color: _navy),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: _isChecking ? null : () => _cekStatus(manual: true),
                      icon: _isChecking
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: _navy),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        _isChecking ? 'Mengecek...' : 'Cek Status',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
