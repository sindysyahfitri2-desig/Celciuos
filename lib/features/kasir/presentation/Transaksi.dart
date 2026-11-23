import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';

import 'package:kasir_celcious_coffe/features/kasir/application/cashier_order_service.dart';
import 'package:kasir_celcious_coffe/features/settings/application/print_service.dart';
import 'checkout_page.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';

class PesananBelumSelesaiPage extends StatefulWidget {
  const PesananBelumSelesaiPage({super.key, this.onKeLaporan});

  final VoidCallback? onKeLaporan;

  @override
  State<PesananBelumSelesaiPage> createState() =>
      _PesananBelumSelesaiPageState();
}

class _PesananBelumSelesaiPageState extends State<PesananBelumSelesaiPage> {
  // ============================================================
  // WARNA
  // ============================================================

  final Color navy = const Color(0xff103654);
  final Color background = const Color(0xffdce9f4);
  final Color lightBlue = const Color(0xffa8c8e5);
  final Color green = const Color(0xff00875a);
  final Color red = const Color(0xffd85c5c);

  // ============================================================
  // DATA PESANAN
  // ============================================================

  List<Map<String, dynamic>> pesanan = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    TransactionStore.unfinishedOrders.addListener(_muatPesananTersimpan);
    _muatPesananTersimpan();
    _sinkronisasiPesananDariServer();
    // Sinkronisasi otomatis setiap 4 detik agar pesanan dari customer web langsung muncul di kasir
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _sinkronisasiPesananDariServer();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    TransactionStore.unfinishedOrders.removeListener(_muatPesananTersimpan);
    super.dispose();
  }

  bool _deteksiSelfOrder(String nama) {
    final trimmed = nama.trim().toLowerCase();
    return trimmed.startsWith('meja ') && trimmed.contains(' - ');
  }

  int get _jumlahOrderMeja =>
      pesanan.where((o) => o['isSelfOrder'] == true && o['selesai'] != true).length;

  Future<void> _cetakStrukOrder(Map<String, dynamic> data) async {
    try {
      final payload = PrintService.buildPrintPayloadFromOrder(data);
      await PrintService.cetakStruk(payload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal cetak struk: $e')),
      );
    }
  }

  Future<void> _cetakStikerOrder(Map<String, dynamic> data) async {
    try {
      final payload = PrintService.buildPrintPayloadFromOrder(data);
      await PrintService.cetakStikerTransaksi(payload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal cetak stiker: $e')),
      );
    }
  }

  Future<void> _cetakDapurOrder(Map<String, dynamic> data) async {
    try {
      final payload = PrintService.buildPrintPayloadFromOrder(data);
      await PrintService.cetakStrukDapur(payload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal cetak struk dapur: $e')),
      );
    }
  }

  double _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  int _parseInt(dynamic v, {int fallback = 0}) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  Future<void> _sinkronisasiPesananDariServer() async {
    try {
      final res = await ApiService.get('transaksi');
      final list = res['data'];
      if (list is List) {
        final serverOrders = <Map<String, dynamic>>[];
        final selesaiIds = <String>{};
        final selesaiTrxIds = <dynamic>{};

        for (final item in list) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final selesai = map['selesai'] == true || map['selesai'] == 1;
            final statusBayar = map['status_bayar']?.toString().toLowerCase();
            final kode =
                map['kode']?.toString() ?? map['id_transaksi']?.toString() ?? '';

            if (statusBayar == 'dibatalkan' || (selesai && statusBayar == 'lunas')) {
              selesaiIds.add(kode);
              if (map['id_transaksi'] != null) {
                selesaiTrxIds.add(map['id_transaksi']);
              }
              continue;
            }

            // Tampilkan pesanan yang belum selesai atau belum lunas
            if (!selesai || statusBayar == 'belum_lunas') {
              final detailList = map['detail_transaksi'];
              final cart = <Map<String, dynamic>>[];
              int totalItemCount = 0;

              if (detailList is List) {
                for (final d in detailList) {
                  if (d is Map) {
                    final dMap = Map<String, dynamic>.from(d);
                    final qty = _parseInt(dMap['jumlah'], fallback: 1);
                    totalItemCount += qty;
                    final produk = dMap['produk'];
                    final prodName = produk is Map
                        ? produk['nama_produk']?.toString()
                        : 'Menu';
                    final kategori = (produk is Map && produk['kategori'] is Map)
                        ? produk['kategori']['nama_kategori']?.toString() ?? ''
                        : '';
                    final prodPrice = _parseDouble(dMap['harga_satuan']);
                    cart.add({
                      'id_produk': dMap['id_produk'],
                      'name': prodName ?? 'Menu',
                      'category': kategori,
                      'price': prodPrice,
                      'quantity': qty,
                      'catatan': dMap['varian']?.toString() ?? '',
                    });
                  }
                }
              }

              final total = _parseDouble(map['total']);
              final subtotal = _parseDouble(map['subtotal']);
              final ppn = _parseDouble(map['ppn']);
              final namaPelanggan =
                  map['nama_pelanggan']?.toString() ?? 'Pelanggan';
              final metode = map['metode_pembayaran'] is Map
                  ? map['metode_pembayaran']['nama_metode']?.toString() ?? 'Cash'
                  : (map['midtrans_order_id'] != null ? 'QRIS' : 'Cash');

              serverOrders.add({
                'id': kode,
                'kode': kode,
                'tanggal':
                    map['tanggal']?.toString() ?? DateTime.now().toIso8601String(),
                'nama': namaPelanggan,
                'kasir': map['pengguna'] is Map
                    ? map['pengguna']['nama']?.toString() ?? 'Kasir'
                    : 'Kasir',
                'jumlah': totalItemCount,
                'subtotal': subtotal,
                'ppn': ppn,
                'total': total,
                'tipe': map['tipe_pesanan']?.toString() ?? 'Dine In',
                'bayar': statusBayar == 'lunas' ? 'Lunas' : 'Pending',
                'pembayaran': metode,
                'selesai': selesai,
                'cart': cart,
                'idTransaksi': map['id_transaksi'],
                'isSelfOrder': _deteksiSelfOrder(namaPelanggan),
                'rawTransaksi': map,
              });
            }
          }
        }

        if (!mounted) return;

        bool changed = false;

        // 1. Hapus order yang sudah selesai / dibatalkan di server
        final beforeLen = pesanan.length;
        pesanan.removeWhere((p) {
          final idMatch = selesaiIds.contains(p['id']?.toString());
          final trxMatch =
              p['idTransaksi'] != null && selesaiTrxIds.contains(p['idTransaksi']);
          return idMatch || trxMatch;
        });
        if (pesanan.length != beforeLen) changed = true;

        // 2. Update order existing (anti-duplikat by idTransaksi atau id/kode) & kumpulkan order baru
        final brandNew = <Map<String, dynamic>>[];
        for (final srv in serverOrders) {
          final idx = pesanan.indexWhere((p) {
            final sameTrx = p['idTransaksi'] != null &&
                srv['idTransaksi'] != null &&
                p['idTransaksi'].toString() == srv['idTransaksi'].toString();
            final sameCode = (p['id']?.toString() ?? '') ==
                (srv['id']?.toString() ?? '');
            return sameTrx || sameCode;
          });

          if (idx >= 0) {
            final cur = pesanan[idx];
            if (cur['bayar'] != srv['bayar'] ||
                cur['pembayaran'] != srv['pembayaran'] ||
                cur['rawTransaksi'] == null ||
                cur['isSelfOrder'] != srv['isSelfOrder']) {
              cur['bayar'] = srv['bayar'];
              cur['pembayaran'] = srv['pembayaran'];
              cur['selesai'] = srv['selesai'];
              cur['cart'] = srv['cart'];
              cur['isSelfOrder'] = srv['isSelfOrder'];
              cur['rawTransaksi'] = srv['rawTransaksi'];
              cur['idTransaksi'] = srv['idTransaksi'];
              changed = true;
            }
          } else {
            brandNew.add(srv);
          }
        }

        if (brandNew.isNotEmpty) {
          final formattedNew = CashierOrderService.mergeSavedOrders(pesanan, brandNew);
          if (formattedNew.isNotEmpty) {
            pesanan.insertAll(0, formattedNew);
            changed = true;
          }
        }

        if (changed && mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Gagal sinkronisasi pesanan dari server: $e');
    }
  }

  void _muatPesananTersimpan() {
    final normalized = TransactionStore.unfinishedOrders.value.map((o) {
      final nama = o['nama']?.toString() ?? '';
      return <String, dynamic>{
        ...o,
        'isSelfOrder': o['isSelfOrder'] == true || _deteksiSelfOrder(nama),
      };
    }).toList();

    final saved = CashierOrderService.mergeSavedOrders(pesanan, normalized);

    if (saved.isNotEmpty && mounted) {
      setState(() => pesanan.insertAll(0, saved));
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  String searchQuery = '';

  // ============================================================
  // FILTER
  // ============================================================

  String filterAktif = 'Semua';

  List<Map<String, dynamic>> get pesananTampil {
    return CashierOrderService.filterOrders(
      orders: pesanan,
      searchQuery: searchQuery,
      activeFilter: filterAktif,
    );
  }

  // ============================================================
  // DATA CHECKOUT
  // ============================================================

  List<Map<String, dynamic>> checkoutData([Map<String, dynamic>? order]) {
    return CashierOrderService.cartForCheckout(order);
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String rupiah(double value) {
    return CashierOrderService.formatRupiah(value);
  }

  // ============================================================
  // BUKA CHECKOUT
  // ============================================================

  void bukaCheckout(
    Map<String, dynamic> data, {
    String initialPaymentMethod = 'QRIS',
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            body: CheckoutPage(
              cart: checkoutData(data),
              jenisPesanan: data['tipe'].toString(),
              namaKasir: data['kasir']?.toString() ?? 'Kasir',
              rupiah: rupiah,
              initialPaymentMethod: initialPaymentMethod,
              openPaymentImmediately: true,
              existingOrder: data,
              onBack: () {
                Navigator.pop(context);
              },
              onLanjutPembayaran: () {
                setState(() {
                  data['bayar'] = 'Lunas';
                  data['pembayaran'] = initialPaymentMethod;
                });
                Navigator.pop(context);
                _sinkronisasiPesananDariServer();
              },
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // POPUP DETAIL PESANAN
  // ============================================================

  void tampilkanDetailPesanan(int index) {
    if (index < 0 || index >= pesanan.length) return;

    final data = pesanan[index];
    final items = checkoutData(data);
    final metodeAwal = data['pembayaran']?.toString().toLowerCase() ?? '';
    String metodePembayaran = metodeAwal.contains('cash') ? 'Cash' : 'QRIS';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.35),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 370),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==================================================
                      // JUDUL
                      // ==================================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Detail Pesanan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xff103654),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // ==================================================
                      // ISI PESANAN
                      // ==================================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                        decoration: const BoxDecoration(
                          color: Color(0xff103654),
                        ),
                        child: Column(
                          children: [
                            if (items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Rincian item pesanan tidak tersedia.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            else
                              for (final item in items)
                                _detailItem(
                                  '${item['name'] ?? 'Item'} x${item['quantity'] ?? 1}',
                                  rupiah(
                                    ((item['price'] as num?)?.toDouble() ?? 0) *
                                        ((item['quantity'] as num?)?.toInt() ??
                                            1),
                                  ),
                                ),

                            const SizedBox(height: 10),

                            const Divider(height: 1, color: Colors.white),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                Text(
                                  data['harga']?.toString() ?? rupiah(0),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // PEMBAYARAN
                      // ==================================================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pembayaran',
                              style: TextStyle(
                                color: navy,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 7),

                            Container(
                              height: 42,
                              width: 160,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: navy,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: metodePembayaran,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                  ),
                                  dropdownColor: navy,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'QRIS',
                                      child: Text(
                                        'QRIS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Cash',
                                      child: Text(
                                        'Cash',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setPopupState(() {
                                        metodePembayaran = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // TOMBOL
                      // ==================================================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              child: Text(
                                'Batal',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            SizedBox(
                              height: 38,
                              child: ElevatedButton(
                                onPressed: items.isEmpty
                                    ? null
                                    : () {
                                        Navigator.pop(dialogContext);
                                        bukaCheckout(
                                          data,
                                          initialPaymentMethod:
                                              metodePembayaran,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: navy,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lanjut Bayar',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 5),

                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 17,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  // ============================================================
  // POPUP KONFIRMASI BAYAR
  // ============================================================

  void konfirmasiBayar(Map<String, dynamic> data, int index) {
    if (index < 0 || index >= pesanan.length) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            width: 340,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 22),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apakah anda yakin pesanan\nsudah keluar semua?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.05,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['nama'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xff102b40),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 1),

                      Text(
                        data['jumlah'].toString(),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            'Tidak',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            tampilkanDetailPesanan(index);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            'Ya',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }

  void konfirmasiPesananSelesai(Map<String, dynamic> data, int index) {
    if (index < 0 || data['selesai'] == true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Pesanan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah pesanan ${data['nama']} sudah selesai disiapkan dan diserahkan?',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Tidak',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final id = data['id']?.toString();
                try {
                  final idTrx = data['idTransaksi'];
                  if (idTrx != null) {
                    await ApiService.patch('transaksi/$idTrx/selesai', {});
                  }
                  if (id != null) {
                    await TransactionStore.completeUnfinishedOrder(id);
                  }
                  if (!mounted) return;
                  setState(() {
                    pesanan.removeAt(index);
                  });
                  Navigator.pop(dialogContext);
                  widget.onKeLaporan?.call();
                } catch (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menyelesaikan pesanan: $error'),
                    ),
                  );
                }
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }
  // ============================================================
  // ITEM DETAIL
  // ============================================================

  Widget _detailItem(String nama, String harga) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              nama,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            harga,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD PESANAN
  // ============================================================

  Widget kartuPesanan(int index, {bool mobile = false}) {
    final data = pesananTampil[index];
    final pending = data['bayar'] == 'Pending';
    final selesai = data['selesai'] == true;

    return InkWell(
      onTap: selesai || data['bayar'] == 'Lunas'
          ? null
          : () {
              final realIndex = pesanan.indexOf(data);
              tampilkanDetailPesanan(realIndex);
            },
      borderRadius: BorderRadius.circular(13),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selesai ? const Color(0xffedf0f2) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: selesai ? Border.all(color: Colors.grey.shade400) : null,
        ),
        child: Stack(
          children: [
            mobile ? _cardMobile(data, pending) : _cardDesktop(data, pending),

            if (selesai)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SELESAI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badgeSelfOrder({bool mobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 6 : 8,
        vertical: mobile ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffe0f2fe),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff4098ce), width: 0.9),
      ),
      child: Text(
        'ORDER MEJA',
        style: TextStyle(
          color: navy,
          fontSize: mobile ? 8 : 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _tombolCetakStruk(
    Map<String, dynamic> data, {
    bool mobile = false,
    bool large = false,
  }) {
    return SizedBox(
      height: mobile ? 29 : (large ? 34 : 31),
      child: OutlinedButton.icon(
        onPressed: () => _cetakStrukOrder(data),
        icon: Icon(Icons.receipt_long_rounded, size: mobile ? 12 : 14),
        label: Text(
          'Cetak Struk',
          style: TextStyle(
            fontSize: mobile ? 8.5 : (large ? 11 : 10),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: BorderSide(color: navy, width: 1.2),
          padding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _tombolCetakStiker(
    Map<String, dynamic> data, {
    bool mobile = false,
    bool large = false,
  }) {
    return SizedBox(
      height: mobile ? 29 : (large ? 34 : 31),
      child: OutlinedButton.icon(
        onPressed: () => _cetakStikerOrder(data),
        icon: Icon(Icons.local_cafe_outlined, size: mobile ? 12 : 14),
        label: Text(
          'Cetak Stiker',
          style: TextStyle(
            fontSize: mobile ? 8.5 : (large ? 11 : 10),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xff16558a),
          side: const BorderSide(color: Color(0xff4098ce), width: 1.2),
          backgroundColor: const Color(0xfff0f7fd),
          padding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _tombolCetakDapur(
    Map<String, dynamic> data, {
    bool mobile = false,
    bool large = false,
  }) {
    return SizedBox(
      height: mobile ? 29 : (large ? 34 : 31),
      child: OutlinedButton.icon(
        onPressed: () => _cetakDapurOrder(data),
        icon: Icon(Icons.restaurant_menu_rounded, size: mobile ? 12 : 14),
        label: Text(
          'Struk Dapur',
          style: TextStyle(
            fontSize: mobile ? 8.5 : (large ? 11 : 10),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xff9a5000),
          side: const BorderSide(color: Color(0xffe0963b), width: 1.2),
          backgroundColor: const Color(0xfffff7eb),
          padding: EdgeInsets.symmetric(horizontal: mobile ? 8 : 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // ============================================================
  // CARD LAPTOP / TABLET
  // ============================================================

  Widget _cardDesktop(Map<String, dynamic> data, bool pending) {
    final isSelfOrder = data['isSelfOrder'] == true;
    final adaMinuman = PrintService.adaMinuman(data);
    final adaMakanan = PrintService.adaMakanan(data);

    return Row(
      children: [
        Container(
          width: 65,
          height: 78,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xffdce8f2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            data['kode'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      data['nama'],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  _tipePesanan(data['tipe'], large: true),

                  if (isSelfOrder) ...[
                    const SizedBox(width: 6),
                    _badgeSelfOrder(),
                  ],
                ],
              ),

              const SizedBox(height: 7),

              Text(
                'Total Pemesanan : ${data['jumlah']}',
                style: TextStyle(
                  color: navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Harga Total : ${data['harga']}',
                style: TextStyle(
                  color: navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _statusPembayaran(pending, large: true),

            const SizedBox(height: 9),

            Wrap(
              spacing: 7,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                if (!pending) ...[
                  _tombolCetakStruk(data, large: true),
                  if (adaMinuman) _tombolCetakStiker(data, large: true),
                  if (adaMakanan) _tombolCetakDapur(data, large: true),
                ],

                _tombolSelesai(data, large: true),

                if (pending) _tombolBayar(data, large: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // CARD HP
  // ============================================================

  Widget _cardMobile(Map<String, dynamic> data, bool pending) {
    final isSelfOrder = data['isSelfOrder'] == true;
    final adaMinuman = PrintService.adaMinuman(data);
    final adaMakanan = PrintService.adaMakanan(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 55,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xffdce8f2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data['kode'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: navy,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['nama'],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: navy,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 5),

                      _tipePesanan(data['tipe'], mobile: true),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${data['jumlah']} • ${data['harga']}',
                          style: TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isSelfOrder) _badgeSelfOrder(mobile: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        Row(
          children: [
            Expanded(child: _statusPembayaran(pending, mobile: true)),

            const SizedBox(width: 6),

            _tombolSelesai(data, mobile: true),

            if (pending) ...[
              const SizedBox(width: 6),
              _tombolBayar(data, mobile: true),
            ],
          ],
        ),

        if (!pending) ...[
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tombolCetakStruk(data, mobile: true),
              if (adaMinuman) _tombolCetakStiker(data, mobile: true),
              if (adaMakanan) _tombolCetakDapur(data, mobile: true),
            ],
          ),
        ],
      ],
    );
  }

  // ============================================================
  // TIPE PESANAN
  // ============================================================

  Widget _tipePesanan(String tipe, {bool mobile = false, bool large = false}) {
    final dineIn = tipe == 'Dine In';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile
            ? 7
            : large
            ? 11
            : 9,
        vertical: mobile
            ? 4
            : large
            ? 6
            : 5,
      ),
      decoration: BoxDecoration(
        color: dineIn ? navy : lightBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipe,
        style: TextStyle(
          color: dineIn ? Colors.white : navy,
          fontSize: mobile
              ? 9
              : large
              ? 11
              : 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS PEMBAYARAN
  // ============================================================

  Widget _statusPembayaran(
    bool pending, {
    bool mobile = false,
    bool large = false,
  }) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: navy,
          fontSize: mobile
              ? 9
              : large
              ? 13
              : 11,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: 'Status : ',
            style: TextStyle(
              color: navy,
              fontSize: mobile
                  ? 9
                  : large
                  ? 13
                  : 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          TextSpan(
            text: pending ? 'Pending' : 'Lunas',
            style: TextStyle(
              color: pending ? red : green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOMBOL SELESAI
  // ============================================================

  Widget _tombolSelesai(
    Map<String, dynamic> data, {
    bool mobile = false,
    bool large = false,
  }) {
    final selesai = data['selesai'] == true;

    return SizedBox(
      height: mobile
          ? 29
          : large
          ? 34
          : 31,
      child: ElevatedButton(
        onPressed: selesai
            ? null
            : () {
                final index = pesanan.indexOf(data);
                konfirmasiPesananSelesai(data, index);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: selesai ? Colors.grey : navy,
          disabledBackgroundColor: Colors.grey.shade400,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: mobile
                ? 9
                : large
                ? 14
                : 12,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          selesai ? 'Selesai' : 'Pesanan Selesai',
          style: TextStyle(
            fontSize: mobile
                ? 8
                : large
                ? 11
                : 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  // ============================================================
  // TOMBOL BAYAR
  // ============================================================

  Widget _tombolBayar(
    Map<String, dynamic> data, {
    bool mobile = false,
    bool large = false,
  }) {
    final index = pesanan.indexOf(data);

    return SizedBox(
      height: mobile
          ? 29
          : large
          ? 34
          : 31,
      width: mobile
          ? 54
          : large
          ? 70
          : 65,
      child: ElevatedButton(
        onPressed: () {
          konfirmasiBayar(data, index);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Bayar',
          style: TextStyle(
            fontSize: mobile
                ? 9
                : large
                ? 11
                : 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget filterButton(
    String text, {
    required String value,
    bool large = false,
  }) {
    final selected = filterAktif == value;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          filterAktif = value;
        });
      },
      child: Container(
        height: large ? 34 : 30,
        padding: EdgeInsets.symmetric(horizontal: large ? 16 : 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : lightBlue,
          borderRadius: BorderRadius.circular(20),
          border: selected ? Border.all(color: navy, width: 1.2) : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? navy : Colors.white,
            fontSize: large ? 12 : 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _search({bool large = false}) {
    return Container(
      height: large ? 45 : 42,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xfff5f8fc),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        style: TextStyle(color: navy, fontSize: large ? 14 : 13),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: navy, size: large ? 21 : 19),
          hintText: 'Cari Orderan',
          hintStyle: TextStyle(
            color: Colors.blueGrey.shade300,
            fontSize: large ? 14 : 13,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  Widget _filter({bool mobile = false, bool large = false}) {
    final jmlMeja = _jumlahOrderMeja;
    final labelMeja = jmlMeja > 0 ? 'Order Meja ($jmlMeja)' : 'Order Meja';

    final buttons = [
      filterButton('Semua', value: 'Semua', large: large),

      const SizedBox(width: 8),

      filterButton(labelMeja, value: 'Order Meja', large: large),

      const SizedBox(width: 8),

      filterButton('Belum Bayar', value: 'Belum Bayar', large: large),

      const SizedBox(width: 8),

      filterButton('Take Away', value: 'Take Away', large: large),

      const SizedBox(width: 8),

      filterButton('Dine In', value: 'Dine In', large: large),
    ];

    if (mobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: buttons),
      );
    }

    return Row(
      children: [


        const SizedBox(width: 14),

        ...buttons,
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width >= 950) {
            return _desktop();
          }

          if (width >= 600) {
            return _tablet();
          }

          return _mobile();
        },
      ),
    );
  }

  // ============================================================
  // LAPTOP
  // ============================================================

  Widget _desktop() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Column(
        children: [
          _search(large: true),

          const SizedBox(height: 12),

          _filter(large: true),

          const SizedBox(height: 12),

          Expanded(
            child: pesananTampil.isEmpty
                ? _kosong()
                : ListView.builder(
                    itemCount: pesananTampil.length,
                    itemBuilder: (context, index) {
                      return kartuPesanan(index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLET
  // ============================================================

  Widget _tablet() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        children: [
          _search(large: true),

          const SizedBox(height: 11),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _filter(large: true),
          ),

          const SizedBox(height: 11),

          Expanded(
            child: pesananTampil.isEmpty
                ? _kosong()
                : ListView.builder(
                    itemCount: pesananTampil.length,
                    itemBuilder: (context, index) {
                      return kartuPesanan(index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HP
  // ============================================================

  Widget _mobile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 7),
      child: Column(
        children: [
          _search(),

          const SizedBox(height: 10),

          _filter(mobile: true),

          const SizedBox(height: 10),

          Expanded(
            child: pesananTampil.isEmpty
                ? _kosong()
                : ListView.builder(
                    itemCount: pesananTampil.length,
                    itemBuilder: (context, index) {
                      return kartuPesanan(index, mobile: true);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KOSONG
  // ============================================================

  Widget _kosong() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: navy.withOpacity(.35),
          ),

          const SizedBox(height: 9),

          Text(
            'Tidak ada pesanan',
            style: TextStyle(
              color: navy.withOpacity(.6),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
