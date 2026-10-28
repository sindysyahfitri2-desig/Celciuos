// ignore_for_file: unused_local_variable

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/produk_data.dart';
import '../../widgets/product_image.dart';

const _navy = Color(0xff082640);
const _background = Color(0xffdce9f4);
const _lightBlue = Color(0xffa8cbe9);
const _muted = Color(0xff667b8d);
const _imageColor = Color(0xffd5d0e5);
const _danger = Color(0xffe05a5a);
const _categoriesKey = 'celcious_categories';

List<BoxShadow> _shadow() => [
  BoxShadow(
    color: _navy.withValues(alpha: 0.10),
    blurRadius: 14,
    offset: const Offset(0, 5),
  ),
];

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();
  final ImagePicker _picker = ImagePicker();

  String _search = '';
  String? _selectedCategory;
  Uint8List? _pickedImage;
  bool _saving = false;

  final List<String> _categories = [
    'Coffee',
    'Non-Coffee',
    'Food',
    'Snack',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  // ============================================================
  // KATEGORI
  // ============================================================

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_categoriesKey);

      if (saved == null || saved.isEmpty || !mounted) return;

      setState(() {
        _categories
          ..clear()
          ..addAll(saved);
      });
    } catch (_) {
      // Gunakan kategori bawaan jika gagal dibaca.
    }
  }

  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _categoriesKey,
        List<String>.from(_categories),
      );
    } catch (_) {
      // Kategori tetap tersedia selama aplikasi terbuka.
    }
  }

  int _usageCount(String category) {
    return ProdukData.produk.value.where((product) {
      final value = product['category']?.toString().toLowerCase();
      return value == category.toLowerCase();
    }).length;
  }

  // ============================================================
  // UTILITAS
  // ============================================================

  String _rupiah(Object? value) {
    final amount = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;

    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // PILIH GAMBAR
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        imageQuality: 80,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (!mounted || bytes.isEmpty) return;

      setState(() => _pickedImage = bytes);
    } catch (error) {
      if (!mounted) return;
      _snack('Gagal memilih gambar: $error');
    }
  }

  // ============================================================
  // TAMBAH PRODUK
  // ============================================================

  Future<void> _saveNewProduct() async {
    if (_saving) return;

    final name = _nameController.text.trim();
    final price = int.tryParse(
      _priceController.text.replaceAll('.', '').trim(),
    );
    final category = _selectedCategory;

    if (name.isEmpty ||
        price == null ||
        price < 0 ||
        category == null) {
      _snack('Isi nama, harga, dan kategori dengan benar.');
      return;
    }

    setState(() => _saving = true);

    try {
      final updated = List<Map<String, dynamic>>.from(
        ProdukData.produk.value,
      )..add({
          'name': name,
          'price': price,
          'category': category,
          'image': _pickedImage,
          'stock': 0,
          'is_active': true,
        });

      await ProdukData.saveProducts(updated);
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);
      _snack('Gagal menyimpan produk: $error');
      return;
    }

    if (!mounted) return;

    _nameController.clear();
    _priceController.clear();

    setState(() {
      _saving = false;
      _pickedImage = null;
      _selectedCategory = null;
    });

    _snack('Produk berhasil ditambahkan.');
  }

  // ============================================================
  // EDIT PRODUK
  // ============================================================

  Future<void> _editProduct(Map<String, dynamic> product) async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (_) => _EditProductDialog(
        initialName: product['name']?.toString() ?? '',
        initialPrice: product['price']?.toString() ?? '',
        initialCategory: product['category']?.toString(),
        categories: List<String>.from(_categories),
      ),
    );

    if (result == null || !mounted) return;

    final list = List<Map<String, dynamic>>.from(
      ProdukData.produk.value,
    );

    final index = list.indexWhere(
      (item) => identical(item, product),
    );

    if (index < 0) return;

    list[index] = {
      ...list[index],
      'name': result.name,
      'price': result.price,
      'category': result.category,
    };

    try {
      await ProdukData.saveProducts(list);
    } catch (error) {
      if (!mounted) return;
      _snack('Gagal menyimpan produk: $error');
      return;
    }

    if (!mounted) return;
    _snack('Produk berhasil diperbarui.');
  }

  // ============================================================
  // HAPUS PRODUK
  // ============================================================

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final name = product['name']?.toString() ?? 'Produk';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: _navy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hapus produk?',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Produk "$name" akan dihapus dari katalog dan kasir.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, false),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _danger,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () =>
                        Navigator.pop(dialogContext, true),
                    child: Text(
                      'Hapus',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final list = List<Map<String, dynamic>>.from(
      ProdukData.produk.value,
    );

    final index = list.indexWhere(
      (item) => identical(item, product),
    );

    if (index < 0) return;

    list.removeAt(index);

    try {
      await ProdukData.saveProducts(list);
    } catch (error) {
      if (!mounted) return;
      _snack('Gagal menghapus produk: $error');
      return;
    }

    if (!mounted) return;
    _snack('Produk "$name" berhasil dihapus.');
  }

  // ============================================================
  // STATUS PRODUK AKTIF/NONAKTIF
  // ============================================================

  Future<void> _setProductActive(
    Map<String, dynamic> product,
    bool isActive,
  ) async {
    final originalList = List<Map<String, dynamic>>.from(
      ProdukData.produk.value,
    );

    final index = originalList.indexWhere(
      (item) => identical(item, product),
    );

    if (index < 0) return;

    final updatedList = List<Map<String, dynamic>>.from(
      originalList,
    );

    updatedList[index] = {
      ...updatedList[index],
      'is_active': isActive,
    };

    try {
      await ProdukData.saveProducts(updatedList);

      if (!mounted) return;

      _snack(
        isActive
            ? 'Produk diaktifkan dan dapat dipilih di kasir.'
            : 'Produk dinonaktifkan dan tidak dapat dipilih di kasir.',
      );
    } catch (error) {
      try {
        await ProdukData.saveProducts(originalList);
      } catch (_) {}

      if (!mounted) return;
      _snack('Gagal mengubah status produk: $error');
    }
  }

  // ============================================================
  // DIALOG KATEGORI
  // ============================================================

  Future<void> _openCategoryDialog() async {
    final added = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryDialog(
        categories: _categories,
        usageCount: _usageCount,
        onChanged: _saveCategories,
      ),
    );

    if (!mounted) return;

    setState(() {
      if (added != null) {
        _selectedCategory = added;
      } else if (_selectedCategory != null &&
          !_categories.contains(_selectedCategory)) {
        _selectedCategory = null;
      }
    });
  }

  // ============================================================
  // HALAMAN UTAMA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: SafeArea(
        child: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: ProdukData.produk,
          builder: (context, products, child) {
            for (final product in products) {
              final category = product['category']?.toString() ?? '';

              if (category.isNotEmpty &&
                  !_categories.any(
                    (item) =>
                        item.toLowerCase() == category.toLowerCase(),
                  )) {
                _categories.add(category);
              }
            }

            final query = _search.toLowerCase();

            final visibleProducts = products.where((product) {
              final name = product['name']?.toString() ?? '';
              return name.toLowerCase().contains(query);
            }).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                final bool isPhone = width < 600;
                final bool isTablet =
                    width >= 600 && width < 1000;
                final bool isLaptop = width >= 1000;

                final double pad = isPhone
                    ? 12
                    : isTablet
                        ? 20
                        : 28;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    pad,
                    14,
                    pad,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _searchField(),
                      const SizedBox(height: 14),
                      _formSection(isPhone),
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
  // PENCARIAN
  // ============================================================

  Widget _searchField() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _search = value.trim());
        },
        style: GoogleFonts.poppins(
          color: _navy,
          fontSize: 12,
        ),
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
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
          ),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                  ),
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
            borderSide: const BorderSide(
              color: _lightBlue,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORM TAMBAH PRODUK
  // ============================================================

  Widget _formSection(bool narrow) {
    return SizedBox(
      height: narrow ? 180 : 118,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _formCard(narrow)),
          const SizedBox(width: 10),
          _addCategoryCard(narrow),
        ],
      ),
    );
  }

  Widget _formCard(bool narrow) {
    final imageSize = narrow ? 76.0 : 94.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _shadow(),
      ),
      child: Row(
        children: [
          _imagePickerBox(imageSize),
          const SizedBox(width: 14),
          Expanded(
            child: narrow
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _nameField(),
                      const SizedBox(height: 2),
                      _priceField(),
                      const SizedBox(height: 6),
                      _categoryPill(),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _saveButton(),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _nameField()),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 150,
                            child: _categoryPill(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _priceField()),
                          const SizedBox(width: 10),
                          _saveButton(),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _imagePickerBox(double size) {
    return Tooltip(
      message: 'Pilih gambar produk',
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _imageColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: _pickedImage == null
              ? const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 38,
                )
              : Image.memory(
                  _pickedImage!,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  Widget _nameField() {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              style: GoogleFonts.poppins(
                color: _navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: 'Nama Produk',
                hintStyle: GoogleFonts.poppins(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
          _editIcon(_nameFocus),
        ],
      ),
    );
  }

  Widget _priceField() {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Text(
            'Rp.',
            style: GoogleFonts.poppins(
              color: _navy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: TextField(
              controller: _priceController,
              focusNode: _priceFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: GoogleFonts.poppins(
                color: _navy,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                hintText: 'Harga',
                hintStyle: GoogleFonts.poppins(
                  color: _muted,
                  fontSize: 12,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
          _editIcon(_priceFocus),
        ],
      ),
    );
  }

  Widget _editIcon(FocusNode focus) {
    return GestureDetector(
      onTap: focus.requestFocus,
      child: const Padding(
        padding: EdgeInsets.only(left: 6),
        child: Icon(
          Icons.edit_square,
          size: 16,
          color: _navy,
        ),
      ),
    );
  }

  Widget _categoryPill() {
    final value = _categories.contains(_selectedCategory)
        ? _selectedCategory
        : null;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            'Kategori',
            style: GoogleFonts.poppins(
              color: _navy,
              fontSize: 12,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _navy,
          ),
          iconSize: 20,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          style: GoogleFonts.poppins(
            color: _navy,
            fontSize: 12,
          ),
          items: _categories
              .map(
                (category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) {
              setState(() => _selectedCategory = selected);
            }
          },
        ),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveNewProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _navy.withValues(alpha: 0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Simpan',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

//Tambah kategori desain
  Widget _addCategoryCard(bool narrow) {
    return Container(
      width: narrow ? 92 : 124,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: _shadow(),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openCategoryDialog,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tambah\nKategori',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: _navy,
                  fontSize: narrow ? 10 : 12,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.add_rounded,
                color: _navy,
                size: narrow ? 30 : 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DAFTAR PRODUK
  // ============================================================

  Widget _productGrid(List<Map<String, dynamic>> products) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;

        final columns = width < 600
            ? 1
            : width < 1000
                ? 2
                : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 126,
          ),
          itemBuilder: (context, index) {
            return _productCard(products[index]);
          },
        );
      },
    );
  }

//card menu
  Widget _productCard(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Produk';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: _shadow(),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: ColoredBox(
                    color: _imageColor,
                    child: ProductImage(image: product['image']),
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
                      style: GoogleFonts.poppins(
                        color: _navy,
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _rupiah(product['price']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: _navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _ProductActiveToggle(
                          value: product['is_active'] != false,
                          onChanged: (value) {
                            _setProductActive(product, value);
                          },
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _AnimatedDeleteButton(
                            onPressed: () => _deleteProduct(product),
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
      ),
    );
  }

  // ============================================================
  // KEADAAN KOSONG
  // ============================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _shadow(),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 34,
            color: _muted,
          ),
          const SizedBox(height: 9),
          Text(
            'Produk belum tersedia',
            style: GoogleFonts.poppins(
              color: _navy,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tambahkan produk melalui formulir di atas.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
} // AKHIR _ProdukPageState

// ============================================================
// TOMBOL DELETE ANIMASI
// Posisi class ini HARUS di luar _ProdukPageState.
// ============================================================

class _AnimatedDeleteButton extends StatefulWidget {
  const _AnimatedDeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AnimatedDeleteButton> createState() =>
      _AnimatedDeleteButtonState();
}

class _AnimatedDeleteButtonState extends State<_AnimatedDeleteButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        setState(() {
          _hovered = false;
          _pressed = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: 36,
          width: _hovered ? 92 : 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color.fromARGB(255, 194, 22, 22), Color.fromARGB(255, 255, 111, 111)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              _hovered ? 12 : 50,
            ),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(
                  alpha: _hovered ? 0.25 : 0.15,
                ),
                blurRadius: _hovered ? 10 : 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Transform.scale(
            scale: _pressed ? 0.92 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                ClipRect(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: _hovered ? 45 : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _hovered ? 1 : 0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text(
                          'Delete',
                          maxLines: 1,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
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
  }
}

// ============================================================
// DIALOG EDIT PRODUK
// ============================================================

class _EditResult {
  const _EditResult(this.name, this.price, this.category);

  final String name;
  final int price;
  final String category;
}

class _EditProductDialog extends StatefulWidget {
  const _EditProductDialog({
    required this.initialName,
    required this.initialPrice,
    required this.initialCategory,
    required this.categories,
  });

  final String initialName;
  final String initialPrice;
  final String? initialCategory;
  final List<String> categories;

  @override
  State<_EditProductDialog> createState() =>
      _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final List<String> _items;

  String? _category;
  String? _error;

  @override
  void initState() {
    super.initState();

    _name = TextEditingController(text: widget.initialName);
    _price = TextEditingController(text: widget.initialPrice);
    _items = List<String>.from(widget.categories);

    final initial = widget.initialCategory;

    if (initial != null && initial.isNotEmpty) {
      if (!_items.contains(initial)) _items.add(initial);
      _category = initial;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final price = int.tryParse(
      _price.text.replaceAll('.', '').trim(),
    );

    if (name.isEmpty ||
        price == null ||
        price < 0 ||
        _category == null) {
      setState(() {
        _error = 'Isi nama, harga, dan kategori dengan benar.';
      });
      return;
    }

    Navigator.pop(
      context,
      _EditResult(name, price, _category!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _navy,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Edit',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _DialogLabel('Nama Menu'),
              _DialogTextField(controller: _name),
              const SizedBox(height: 12),
              const _DialogLabel('Harga'),
              _DialogTextField(
                controller: _price,
                keyboardType: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              const SizedBox(height: 12),
              const _DialogLabel('Kategori'),
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    hint: Text(
                      'Pilih kategori',
                      style: GoogleFonts.poppins(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _navy,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    style: GoogleFonts.poppins(
                      color: _navy,
                      fontSize: 12,
                    ),
                    items: _items
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _category = value;
                        _error = null;
                      });
                    },
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    color: const Color(0xffffb4b4),
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: _DialogSaveButton(onPressed: _submit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DIALOG TAMBAH KATEGORI
// ============================================================

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({
    required this.categories,
    required this.usageCount,
    required this.onChanged,
  });

  final List<String> categories;
  final int Function(String category) usageCount;
  final Future<void> Function() onChanged;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final TextEditingController _newCategory = TextEditingController();

  String? _current;
  String? _error;

  @override
  void initState() {
    super.initState();

    if (widget.categories.isNotEmpty) {
      _current = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _newCategory.dispose();
    super.dispose();
  }

  void _deleteCurrent() {
    final current = _current;
    if (current == null) return;

    final used = widget.usageCount(current);

    if (used > 0) {
      setState(() {
        _error = 'Kategori "$current" masih dipakai $used produk.';
      });
      return;
    }

    widget.categories.remove(current);
    widget.onChanged();

    setState(() {
      _current = widget.categories.isEmpty
          ? null
          : widget.categories.first;
      _error = null;
    });
  }

  void _submit() {
    final value = _newCategory.text.trim();

    if (value.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final exists = widget.categories.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );

    if (exists) {
      setState(() {
        _error = 'Kategori tersebut sudah tersedia.';
      });
      return;
    }

    widget.categories.add(value);
    widget.onChanged();

    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _navy,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Tambah Kategori',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _DialogLabel('kategori saat ini'),
              _currentDropdown(),
              const SizedBox(height: 12),
              const _DialogLabel('Tambah Kategori'),
              _DialogTextField(
                controller: _newCategory,
                onChanged: (_) {
                  if (_error != null) {
                    setState(() => _error = null);
                  }
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: GoogleFonts.poppins(
                    color: const Color(0xffffb4b4),
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Center(
                child: _DialogSaveButton(onPressed: _submit),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currentDropdown() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _current,
                isExpanded: true,
                hint: Text(
                  'Belum ada kategori',
                  style: GoogleFonts.poppins(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _navy,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                style: GoogleFonts.poppins(
                  color: _navy,
                  fontSize: 12,
                ),
                items: widget.categories
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _current = value;
                    _error = null;
                  });
                },
              ),
            ),
          ),
          if (_current != null)
            Positioned(
              right: 34,
              child: Tooltip(
                message: 'Hapus kategori',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _deleteCurrent,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: _danger,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// KOMPONEN DIALOG
// ============================================================

class _DialogLabel extends StatelessWidget {
  const _DialogLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 2),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    this.keyboardType,
    this.formatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        onChanged: onChanged,
        style: GoogleFonts.poppins(
          color: _navy,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: _lightBlue,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogSaveButton extends StatelessWidget {
  const _DialogSaveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: 34,
          vertical: 10,
        ),
      ),
      child: Text(
        'Simpan',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// TOGGLE STATUS PRODUK
// ============================================================

class _ProductActiveToggle extends StatelessWidget {
  const _ProductActiveToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: value
          ? 'Produk aktif di kasir'
          : 'Produk nonaktif di kasir',
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 48,
          height: 26,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 44,
                height: 16,
                decoration: BoxDecoration(
                  color: value
                      ? const Color.fromARGB(255, 10, 4, 100)
                      : const Color(0xFFD13613),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutBack,
                left: value ? 24 : -1,
                top: 1,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFC0C0C0),
                        Colors.white,
                        Color(0xFFC0C0C0),
                        Colors.white,
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFFE5E5E5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 4,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CustomPaint(
                      painter: _ProductTogglePatternPainter(),
                      child: const SizedBox.expand(),
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
}

class _ProductTogglePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45;

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    for (double radius = 2; radius < size.width / 2; radius += 2) {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}