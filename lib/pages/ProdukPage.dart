import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/produk_data.dart';
import '../widgets/product_image.dart';

const _navy = Color(0xff082640);
const _pageBackground = Color(0xffdce9f4);
const _mutedText = Color(0xff667b8d);
const _priceBlue = Color(0xff24547b);
const _chipBlue = Color(0xffa9cce6);
const _imageBackground = Color(0xffd3cee5);

// Ukuran kartu mengikuti desain: gambar persegi besar di kiri,
// nama dan harga di kanan.
const double _cardHeight = 108;
const double _cardPadding = 8;
const double _imageSize = _cardHeight - (_cardPadding * 2);

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final TextEditingController _searchController = TextEditingController();

  // null = tampilkan semua menu.
  String? _selectedCategory;

  static const List<_CategoryItem> _categories = [
    _CategoryItem('Coffee', Icons.local_cafe_outlined),
    _CategoryItem('Non-Coffee', Icons.local_drink_outlined),
    _CategoryItem('Food', Icons.ramen_dining_outlined),
    _CategoryItem('Snack', Icons.cookie_outlined),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _rupiah(Object? value) {
    final amount = value is num ? value.toInt() : 0;

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
            final normalizedSearch =
                _searchController.text.trim().toLowerCase();

            final visibleProducts = products.where((product) {
              final name = product['name']?.toString() ?? '';
              final category = product['category']?.toString() ?? '';

              final matchesSearch =
                  name.toLowerCase().contains(normalizedSearch);

              final matchesCategory = _selectedCategory == null ||
                  category.toLowerCase() ==
                      _selectedCategory!.toLowerCase();

              return matchesSearch && matchesCategory;
            }).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                final pad = compact ? 12.0 : 16.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _searchField(),
                      const SizedBox(height: 14),
                      _categoryFilters(),
                      const SizedBox(height: 14),
                      if (visibleProducts.isEmpty)
                        _emptyState()
                      else
                        _productGrid(visibleProducts),
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
  // KOTAK CARI — BENTUK PIL
  // ============================================================

  Widget _searchField() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.poppins(color: _navy, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Cari menu',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xff91a9bd),
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xff7896ae),
            size: 18,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: const Color(0xfff8fbff),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xff9bbdd6), width: 1),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BARIS KATEGORI: "Semua Menu" + chip Coffee, Non-Coffee, Food, Snack
  // ============================================================

  Widget _categoryFilters() {
    final allSelected = _selectedCategory == null;

    return SizedBox(
      height: 28,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _selectedCategory = null),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded,
                      color: _navy, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'Semua Menu',
                    style: GoogleFonts.poppins(
                      color: _navy,
                      fontSize: 10,
                      fontWeight:
                          allSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          for (final category in _categories) ...[
            _categoryChip(category),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _categoryChip(_CategoryItem category) {
    final selected = _selectedCategory == category.name;

    return GestureDetector(
      onTap: () {
        setState(() {
          // Menekan chip yang sama sekali lagi kembali ke semua menu.
          _selectedCategory = selected ? null : category.name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : _chipBlue,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _navy : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 12,
              color: selected ? _navy : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: GoogleFonts.poppins(
                color: selected ? _navy : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GRID PRODUK — 2 KOLOM (1 kolom di layar sempit, 3 di layar lebar)
  // ============================================================

  Widget _productGrid(List<Map<String, dynamic>> products) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final columns = width >= 1150
            ? 3
            : width >= 520
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: _cardHeight,
          ),
          itemBuilder: (context, index) => _productCard(products[index]),
        );
      },
    );
  }

  // ============================================================
  // KARTU PRODUK — gambar kiri, nama dan harga kanan, tanpa tombol
  // ============================================================

  Widget _productCard(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Produk';

    return Container(
      padding: const EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _imageSize,
            height: _imageSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: _imageBackground,
                child: ProductImage(image: product['image']),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _navy,
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _rupiah(product['price']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _priceBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUK KOSONG
  // ============================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, color: _mutedText, size: 32),
          const SizedBox(height: 8),
          Text(
            'Produk tidak ditemukan',
            style: GoogleFonts.poppins(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba kata kunci atau kategori lainnya.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: _mutedText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.name, this.icon);

  final String name;
  final IconData icon;
}