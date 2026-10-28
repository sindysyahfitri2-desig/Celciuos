import 'package:flutter/material.dart';
import '../widgets/Navigation.dart';
import '/widgets/product_cart.dart';
import '../widgets/app_branding_logo.dart';
import 'checkout_page.dart';
import 'home_page.dart';
import '/data/produk_data.dart';
import '../data/transaction_store.dart';

class kasirPage extends StatefulWidget {
  const kasirPage({super.key});

  @override
  State<kasirPage> createState() => _kasirPageState();
}

class _kasirPageState extends State<kasirPage> {
  // ==========================================================
  // WARNA
  // ==========================================================

  final Color navy = const Color(0xff082640);
  final Color textColor = const Color(0xff102b40);
  final Color modalColor = const Color(0xffa8cbe9);

  // ==========================================================
  // DATA KASIR
  // ==========================================================

  String namaKasir = '';
  double kasAwal = 0;

  bool showWelcome = true;
  bool showJenisPesanan = false;

  String? jenisPesanan;

  bool showCheckout = false;
  bool showPembayaran = false;

  final namaController = TextEditingController();
  final kasController = TextEditingController();

  // ==========================================================
  // DATA KERANJANG
  // ==========================================================

  final List<Map<String, dynamic>> cart = [];

  void tambahKeKeranjang(Map<String, dynamic> product) {
    setState(() {
      final index = cart.indexWhere((item) => item['name'] == product['name']);

      if (index >= 0) {
        cart[index]['quantity'] = cart[index]['quantity'] + 1;
      } else {
        cart.add({
          'name': product['name'],
          'price': product['price'],
          'category': product['category'],
          'image': product['image'],
          'quantity': 1,
        });
      }
    });

    _popupCatatan(product);
  }

  void _popupCatatan(Map<String, dynamic> product) {
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
            width: 160,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 5),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          product['image'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.local_cafe,
                              color: Colors.white,
                              size: 28,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Celcious ${product['name']}',
                            style: const TextStyle(
                              color: Color(0xff102b40),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            rupiah((product['price'] as num).toDouble()),
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
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
        );
      },
    );
  }

  void _popupInputCatatan(Map<String, dynamic> product) {
    final TextEditingController catatanController = TextEditingController();

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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          product['image'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.local_cafe,
                              color: Colors.white,
                              size: 28,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Celcious ${product['name']}',
                            style: const TextStyle(
                              color: Color(0xff102b40),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            rupiah((product['price'] as num).toDouble()),
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
                    border: Border.all(color: const Color(0xffdddddd)),
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
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ),

                    const SizedBox(width: 3),

                    SizedBox(
                      width: 55,
                      height: 23,
                      child: ElevatedButton(
                        onPressed: () {
                          final catatan = catatanController.text.trim();

                          if (catatan.isNotEmpty) {
                            final index = cart.indexWhere(
                              (item) => item['name'] == product['name'],
                            );

                            if (index >= 0) {
                              cart[index]['catatan'] = catatan;
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
    );
  }
  // ==========================================================
  // TAMBAH / KURANG JUMLAH
  // ==========================================================

  void ubahJumlah(int index, int perubahan) {
    setState(() {
      cart[index]['quantity'] += perubahan;

      if (cart[index]['quantity'] <= 0) {
        cart.removeAt(index);
      }
    });
  }

  // ==========================================================
  // TOTAL PESANAN
  // ==========================================================

  double get totalPesanan {
    double total = 0;

    for (final item in cart) {
      total += (item['price'] as num).toDouble() * (item['quantity'] as int);
    }

    return total;
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  String searchQuery = '';

  // ==========================================================
  // CATEGORY
  // ==========================================================

  String selectedCategory = 'Semua Menu';

  @override
  void initState() {
    super.initState();
    final activeShift = TransactionStore.activeShift.value;
    if (activeShift?['status'] == 'open') {
      namaKasir = activeShift?['cashier']?.toString() ?? '';
      kasAwal = (activeShift?['openingCash'] as num?)?.toDouble() ?? 0;
      namaController.text = namaKasir;
      kasController.text = kasAwal.toInt().toString();
      showWelcome = false;
      showJenisPesanan = true;
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    namaController.dispose();
    kasController.dispose();
    super.dispose();
  }

  // ==========================================================
  // SIMPAN KASIR
  // ==========================================================

  Future<void> simpanKasir() async {
    final nama = namaController.text.trim();

    final kasText = kasController.text.replaceAll('.', '').replaceAll(',', '');

    final kas = double.tryParse(kasText);

    if (nama.isEmpty || kas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kasir dan kas awal wajib diisi.')),
      );

      return;
    }

    try {
      await TransactionStore.startShift(cashier: nama, openingCash: kas);
      if (!mounted) return;
      setState(() {
        namaKasir = nama;
        kasAwal = kas;
        showWelcome = false;
        showJenisPesanan = true;
        jenisPesanan = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data shift: $error')),
      );
    }
  }

  void _resetAfterShiftClosed() {
    setState(() {
      namaKasir = '';
      kasAwal = 0;
      namaController.clear();
      kasController.clear();
      cart.clear();
      showWelcome = true;
      showCheckout = false;
      showPembayaran = false;
      showJenisPesanan = false;
      jenisPesanan = null;
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
        headerBuilder: (_) => _header(),
        cashierBuilder: (_) => _cashierContent(),
        onShiftClosed: _resetAfterShiftClosed,
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
            constraints.maxWidth >= 600 && constraints.maxWidth < 950;
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
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16),
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
                child: ClipOval(child: const AppBrandingLogo()),
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
                    '08 Oktober 2026',
                    style: TextStyle(
                      color: Colors.white.withOpacity(.55),
                      fontSize: isMobile ? 9 : 10,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              if (namaKasir.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 13,
                    vertical: isMobile ? 6 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: isMobile ? 14 : 17,
                        color: textColor,
                      ),
                      SizedBox(width: isMobile ? 4 : 7),
                      Text(
                        rupiah(kasAwal),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 10 : 13,
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
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _cashierContent() {
    return _cashierBody();
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
        onLanjutPembayaran: _kembaliKePilihanJenisPesanan,
        onBayarNanti: _kembaliKePilihanJenisPesanan,
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
      cart.clear();
      showCheckout = false;
      showJenisPesanan = true;
      jenisPesanan = null;
    });
  }

  // ==========================================================
  // CHECKOUT BAR
  // ==========================================================

  Widget _checkoutBar() {
    int jumlahItem = 0;

    for (final item in cart) {
      jumlahItem += item['quantity'] as int;
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffa8cbe9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$jumlahItem Item dipilih',
              style: TextStyle(
                color: navy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(
            width: 170,
            height: 65,
            child: ElevatedButton(
              onPressed: cart.isEmpty
                  ? null
                  : () {
                      setState(() {
                        showCheckout = true;
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: navy,
                disabledBackgroundColor: Colors.white70,
                disabledForegroundColor: const Color.fromARGB(
                  255,
                  73,
                  124,
                  153,
                ),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Check Out',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _search() {
    return Container(
      height: 43,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase().trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari menu',
          hintStyle: const TextStyle(color: Color(0xff9aa7b2), fontSize: 14),
          prefixIcon: const Icon(
            Icons.search,
            size: 19,
            color: Color(0xff31566e),
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: navy,
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
  // ==========================================================
  // HALAMAN KASIR
  // ==========================================================

  Widget _cashier() {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(width < 500 ? 9 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pencarian produk
                    _search(),

                    const SizedBox(height: 9),

                    // Kategori menu — cukup satu kali
                    _categories(),

                    const SizedBox(height: 8),

                    // Tombol ubah jenis pesanan di bawah kategori
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            showJenisPesanan = true;
                          });
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(
                          ': ${jenisPesanan ?? "-"}',
                          style: TextStyle(
                            color: navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 9),

                    // Daftar produk
                    _productGrid(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Tombol checkout tetap di bawah
            if (cart.isNotEmpty) _checkoutBar(),
          ],
        );
      },
    );
  }

  // ==========================================================
  // CATEGORIES
  // ==========================================================

  Widget _categories() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _category(Icons.grid_view, 'Semua Menu'),

          _category(Icons.local_drink, 'Coffee'),

          _category(Icons.local_drink, 'Non-Coffee'),

          _category(Icons.fastfood, 'Food'),

          _category(Icons.cookie, 'Snack'),
        ],
      ),
    );
  }

  // ==========================================================
  // CATEGORY
  // ==========================================================

  Widget _category(IconData icon, String title) {
    final bool active = selectedCategory == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        margin: const EdgeInsets.only(right: 9),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          // SEMUA ADA BACKGROUND
          color: active
              ? const Color.fromARGB(255, 253, 254, 255)
              : const Color(0xffa8c8e5),

          borderRadius: BorderRadius.circular(18),

          border: Border.all(
            color: active ? navy : const Color(0xffa8c8e5),
            width: 3.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active
                  ? const Color(0xffa8c8e5)
                  : const Color.fromARGB(255, 255, 255, 255),
            ),

            const SizedBox(width: 5),

            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: active
                    ? const Color(0xffa8c8e5)
                    : const Color.fromARGB(255, 255, 255, 255),
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PRODUCT GRID
  // ==========================================================

  Widget _productGrid() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: ProdukData.produk,
      builder: (context, products, child) {
        return LayoutBuilder(
          builder: (context, box) {
            // Grid lebih padat untuk tablet agar kartu putih tidak terlalu besar.
            int columns = 1;

            if (box.maxWidth >= 1100) {
              columns = 3;
            } else if (box.maxWidth >= 650) {
              columns = 3;
            } else if (box.maxWidth >= 420) {
              columns = 2;
            }

            // ====================================================
            // FILTER KATEGORI + SEARCH
            // ====================================================

            final String search = searchQuery.toLowerCase();

            final List<Map<String, dynamic>> filteredProducts = products.where((
              product,
            ) {
              final String nama = product['name'].toString().toLowerCase();

              final String category = product['category']
                  .toString()
                  .trim()
                  .toLowerCase();

              // SEARCH
              if (search.isNotEmpty && !nama.contains(search)) {
                return false;
              }

              // CATEGORY
              if (selectedCategory == 'Semua Menu') {
                return true;
              }

              if (selectedCategory == 'Coffee') {
                return category == 'coffee' ||
                    category == 'Coffee'.toLowerCase();
              }

              if (selectedCategory == 'Non-Coffee') {
                return category == 'non-coffee';
              }

              if (selectedCategory == 'Food') {
                return category == 'food';
              }

              if (selectedCategory == 'Snack') {
                return category == 'snack';
              }

              return true;
            }).toList();

            // ====================================================
            // TIDAK ADA HASIL
            // ====================================================

            if (filteredProducts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 42,
                      color: navy.withOpacity(.35),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Menu tidak ditemukan',
                      style: TextStyle(
                        color: navy.withOpacity(.65),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            // ====================================================
            // GRID
            // ====================================================

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredProducts.length,
              padding: EdgeInsets.zero,

              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // HP: 1 kolom, tablet/laptop menyesuaikan lebar.
                crossAxisCount: box.maxWidth < 470
                    ? 1
                    : box.maxWidth < 850
                    ? 2
                    : columns,

                crossAxisSpacing: 10,
                mainAxisSpacing: 10,

                // Rasio lebar : tinggi kartu.
                // Nilai lebih besar menghasilkan kartu lebih pendek.
                childAspectRatio: box.maxWidth < 470
                    ? 2.8
                    : box.maxWidth < 850
                    ? 2.5
                    : 2.7,
              ),

              itemBuilder: (context, index) {
                final product = filteredProducts[index];

                final cartIndex = cart.indexWhere(
                  (item) => item['name'] == product['name'],
                );

                final jumlah = cartIndex >= 0
                    ? cart[cartIndex]['quantity'] as int
                    : 0;

                return ProductCard(
                  name: product['name'],

                  price: (product['price'] as num).toDouble(),

                  image: product['image'],

                  category: product['category'],

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
                      setState(() {
                        cart.removeAt(cartIndex);
                      });
                    }
                  },
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

            final double modalWidth;

            if (width < 500) {
              modalWidth = width - 40;
            } else {
              modalWidth = 500;
            }

            final double titleSize;

            if (width < 500) {
              titleSize = 28;
            } else if (width < 900) {
              titleSize = 34;
            } else {
              titleSize = 38;
            }

            final double horizontalPadding = width < 500 ? 16 : 22;

            final double verticalPadding = width < 500 ? 16 : 20;

            final double buttonWidth;

            if (width < 500) {
              buttonWidth = 190;
            } else if (width < 900) {
              buttonWidth = 220;
            } else {
              buttonWidth = 250;
            }

            final double buttonHeight = width < 500 ? 40 : 43;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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

                    SizedBox(height: width < 250 ? 10 : 14),

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _inputLabel('Masukkan Nama Kasir :'),

                          const SizedBox(height: 3),

                          _input(
                            controller: namaController,
                            hint: 'Ketik disini...',
                            keyboardType: TextInputType.text,
                          ),

                          SizedBox(height: width < 500 ? 12 : 15),

                          _inputLabel('Masukkan Kas Kasir :'),

                          const SizedBox(height: 3),

                          _input(
                            controller: kasController,
                            hint: 'Ketik disini...',
                            keyboardType: TextInputType.number,
                          ),

                          SizedBox(height: width < 500 ? 13 : 15),

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
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                                child: Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize: width < 500 ? 15 : 18,
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
          hintStyle: const TextStyle(color: Color(0xffb5b5b5), fontSize: 14),
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
