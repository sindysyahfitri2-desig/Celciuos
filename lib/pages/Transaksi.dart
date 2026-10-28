import 'package:flutter/material.dart';
import 'checkout_page.dart';
import '../data/transaction_store.dart';

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

  @override
  void initState() {
    super.initState();
    TransactionStore.unfinishedOrders.addListener(_muatPesananTersimpan);
    _muatPesananTersimpan();
  }

  @override
  void dispose() {
    TransactionStore.unfinishedOrders.removeListener(_muatPesananTersimpan);
    super.dispose();
  }

  void _muatPesananTersimpan() {
    final existingIds = pesanan.map((item) => item['id']).toSet();
    final saved = TransactionStore.unfinishedOrders.value
        .where((order) => !existingIds.contains(order['id']))
        .map((order) {
          final jumlah = order['jumlah'] as int? ?? 0;
          final total = (order['total'] as num?)?.toDouble() ?? 0;
          final totalFormat = total.toInt().toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]}.',
          );
          return <String, dynamic>{
            ...order,
            'kode': order['kode']?.toString() ?? order['id'].toString(),
            'jumlah': '$jumlah item',
            'harga': 'Rp.$totalFormat',
            'selesai': order['selesai'] == true,
          };
        })
        .toList();

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
    return pesanan.where((item) {
      final nama = item['nama'].toString().toLowerCase();

      final kode = item['kode'].toString().replaceAll('\n', '').toLowerCase();

      final search = searchQuery.toLowerCase();

      if (!nama.contains(search) && !kode.contains(search)) {
        return false;
      }

      if (filterAktif == 'Belum Bayar') {
        return item['bayar'] == 'Pending';
      }

      if (filterAktif == 'Take Away') {
        return item['tipe'] == 'Take Away';
      }

      if (filterAktif == 'Dine In') {
        return item['tipe'] == 'Dine In';
      }

      return true;
    }).toList();
  }

  // ============================================================
  // DATA CHECKOUT
  // ============================================================

  List<Map<String, dynamic>> checkoutData([Map<String, dynamic>? order]) {
    final savedCart = order?['cart'];
    if (savedCart is List) {
      return savedCart
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String rupiah(double value) {
    final number = value.toInt().toString();

    final result = number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $result';
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
    String metodePembayaran = 'QRIS';

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

  // ============================================================
  // CARD LAPTOP / TABLET
  // ============================================================

  Widget _cardDesktop(Map<String, dynamic> data, bool pending) {
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
              fontSize: 14,
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

            Row(
              children: [
                _tombolSelesai(data, large: true),

                if (pending) ...[
                  const SizedBox(width: 7),
                  _tombolBayar(data, large: true),
                ],
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
                  fontSize: 10,
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

                  Text(
                    '${data['jumlah']} • ${data['harga']}',
                    style: TextStyle(
                      color: navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
    final buttons = [
      filterButton('Semua', value: 'Semua', large: large),

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
        Text(
          '▦ Semua Orderan',
          style: TextStyle(
            color: navy,
            fontSize: large ? 13 : 11,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(width: 14),

        ...buttons.sublist(2),
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
