import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/produk_data.dart';
import '../widgets/product_image.dart';

// ============================================================
// HALAMAN PRODUK KASIR
// Tampilan seragam dengan Kelola Produk Owner (7 kategori resmi,
// kartu putih membulat, foto live dari database), khusus akses Kasir
// (lihat katalog & ubah status tersedia/habis, tanpa tambah/edit/hapus).
// ============================================================

const _navy = Color(0xFF082640);
const _pageBackground = Color(0xFFDCE9F4);
const _lightBlue = Color(0xFFA8CBE9);
const _mutedText = Color(0xFF667B8D);
const _imageBackground = Color(0xFFD5D0E5);

List<BoxShadow> _shadow() => const [
  BoxShadow(
    color: Color(0x33000000),
    blurRadius: 4,
    offset: Offset(2, 3),
  ),
];

List<BoxShadow> _shadowSmall() => const [
  BoxShadow(
    color: Color(0x26000000),
    blurRadius: 3,
    offset: Offset(1, 2),
  ),
];

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();

  String? _activeCategory; // null = Semua
  Timer? _syncTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshProducts(),
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _searchController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await ProdukData.loadFromApi();
      if (mounted) setState(() {});
    } finally {
      _isRefreshing = false;
    }
  }

  String _rupiah(Object? value) {
    final amount = value is num
        ? value.toInt()
        : int.tryParse(value?.toString().replaceAll('.', '') ?? '') ?? 0;

    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _pageBackground,
      child: SafeArea(
        child: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: ProdukData.produk,
          builder: (context, products, child) {
            final query = _searchController.text.trim().toLowerCase();

            final visibleProducts = products.where((product) {
              final name = product['name']?.toString() ?? '';
              final category = product['category']?.toString() ?? '';

              final matchesSearch =
                  query.isEmpty ||
                  name.toLowerCase().contains(query) ||
                  category.toLowerCase().contains(query);

              final matchesCategory =
                  _activeCategory == null ||
                  category.toLowerCase() == _activeCategory!.toLowerCase();

              return matchesSearch && matchesCategory;
            }).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isPhone = width < 600;
                final isTablet = width >= 600 && width < 1024;
                final pad = isPhone
                    ? 14.0
                    : isTablet
                    ? 20.0
                    : 26.0;

                return Padding(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(isPhone),
                      const SizedBox(height: 16),
                      _categoryPills(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: RefreshIndicator(
                          color: _navy,
                          onRefresh: _refreshProducts,
                          child: visibleProducts.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [_emptyState()],
                                )
                              : _productGrid(
                                  visibleProducts,
                                  isPhone: isPhone,
                                  isTablet: isTablet,
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER + SEARCH (Sama seperti Kontrol Product di Owner)
  // ============================================================

  Widget _header(bool isPhone) {
    final title = Text(
      'Daftar Produk',
      style: TextStyle(
        color: _navy,
        fontSize: isPhone ? 22 : 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    );

    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 10),
          _searchField(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        SizedBox(width: 240, child: _searchField()),
      ],
    );
  }

  Widget _searchField() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _shadowSmall(),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: _navy, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: const TextStyle(color: Color(0xFF91A9BD), fontSize: 12),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF7896AE),
            size: 18,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, size: 16, color: _navy),
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ============================================================
  // KATEGORI PILLS (7 KATEGORI RESMI — SAMA DENGAN OWNER)
  // ============================================================

  Widget _categoryPills() {
    final items = <String?>[null, ...ProdukData.kategoriProduk];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = items[index];
          final label = category ?? 'Semua';
          final selected =
              (category == null && _activeCategory == null) ||
              (category != null &&
                  _activeCategory?.toLowerCase() == category.toLowerCase());

          return Material(
            color: selected ? Colors.white : _lightBlue,
            borderRadius: BorderRadius.circular(20),
            elevation: selected ? 2 : 1,
            shadowColor: const Color(0x33000000),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _activeCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _navy : Colors.transparent,
                    width: 1.4,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // GRID PRODUK RESPONSIF (Sama seperti Owner)
  // ============================================================

  Widget _productGrid(
    List<Map<String, dynamic>> products, {
    required bool isPhone,
    required bool isTablet,
  }) {
    final columns = isPhone
        ? 1
        : isTablet
        ? 2
        : 3;

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: products.length,
      padding: const EdgeInsets.only(bottom: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 98,
      ),
      itemBuilder: (context, index) {
        return _productCard(products[index]);
      },
    );
  }

  // ============================================================
  // KARTU PRODUK (Seragam dengan Owner, khusus akses toggle Kasir)
  // ============================================================

  Widget _productCard(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Produk';
    final isActive = product['is_active'] != false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 260;
        final imageSize = compact ? 64.0 : 82.0;

        return Opacity(
          opacity: isActive ? 1 : 0.58,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _shadow(),
            ),
            child: Row(
              children: [
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: _imageBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ColorFiltered(
                    colorFilter: isActive
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          )
                        : const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 1, 0,
                          ]),
                    child: ProductImage(
                      image: product['image'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _navy,
                          fontSize: compact ? 11 : 12.5,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _rupiah(product['price']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _navy,
                          fontSize: compact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SizedBox(
                            width: 42,
                            height: 24,
                            child: Transform.scale(
                              scale: 0.78,
                              alignment: Alignment.centerLeft,
                              child: Switch(
                                value: isActive,
                                onChanged: (value) async {
                                  try {
                                    await ProdukData.setProductActive(
                                      product,
                                      isActive: value,
                                    );
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Gagal mengubah status produk: $error',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                activeThumbColor: Colors.white,
                                activeTrackColor: _navy,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey.shade400,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? 'Tersedia' : 'Habis / Nonaktif',
                            style: TextStyle(
                              color: isActive ? _navy : _mutedText,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PRODUK KOSONG
  // ============================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadowSmall(),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, color: _mutedText, size: 40),
          const SizedBox(height: 10),
          const Text(
            'Produk tidak ditemukan',
            style: TextStyle(
              color: _navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _searchController.text.trim().isNotEmpty
                ? 'Coba kata kunci pencarian lainnya.'
                : _activeCategory != null
                ? 'Belum ada produk di kategori $_activeCategory.'
                : 'Belum ada produk yang tersedia.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mutedText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
