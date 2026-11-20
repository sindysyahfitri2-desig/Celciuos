
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kasir_celcious_coffe/data/produk_data.dart';
import 'package:kasir_celcious_coffe/features/owner/application/product_management_service.dart';
import 'package:kasir_celcious_coffe/ui/widgets/product_image.dart';

// ============================================================
// WARNA
// ============================================================

const _navy = Color(0xFF082640);
const _navy2 = Color(0xFF103657);
const _background = Color(0xFFDCE9F4);
const _lightBlue = Color(0xFFA8CBE9);
const _muted = Color(0xFF667B8D);
const _imageColor = Color(0xFFD5D0E5);
const _danger = Color(0xFFE05A5A);
const _border = Color(0xFFD0D9E3);

// ============================================================
// SHADOW
// ============================================================

List<BoxShadow> _shadow() => [
  BoxShadow(
    color: _navy.withValues(alpha: 0.12),
    blurRadius: 8,
    offset: const Offset(0, 3),
  ),
];

// ============================================================
// HALAMAN PRODUK
// ============================================================

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final TextEditingController _searchController =
      TextEditingController();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _priceController =
      TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();

  final ImagePicker _picker = ImagePicker();

  String _search = '';
  String? _selectedCategory;

  Uint8List? _pickedImage;

  bool _saving = false;
  bool _loadingCategories = false;

  final List<String> _categories = List<String>.from(
    ProductManagementService.kategoriProduk,
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _loadCategories();
    _loadProducts();

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadProducts(showError: false),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadProducts({bool showError = true}) async {
    try {
      await ProdukData.loadFromApi();
    } catch (error) {
      if (mounted && showError) {
        _snack('Gagal memuat produk: $error');
      }
    }
  }

  Future<void> _loadCategories() async {
  if (_loadingCategories) return;

  _loadingCategories = true;

  try {
    await ProductManagementService.loadCategories();

    if (!mounted) return;

    setState(() {
      _categories
        ..clear()
        ..addAll(ProdukData.kategoriProduk);
    });
  } catch (error) {
    if (mounted) {
      _snack('Gagal memuat kategori: $error');
    }
  } finally {
    _loadingCategories = false;
  }
}

  Future<void> _saveCategories() async {
    await ProductManagementService.saveCategories(_categories);
  }

  int _usageCount(String category) {
    return ProductManagementService.usageCount(category);
  }

  // ============================================================
  // UTILITAS
  // ============================================================

  String _rupiah(Object? value) {
    final amount = value is num
        ? value.toInt()
        : int.tryParse(
              value?.toString().replaceAll('.', '') ?? '',
            ) ??
            0;

    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

      setState(() {
        _pickedImage = bytes;
      });
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

    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _selectedCategory == null) {
      _snack('Lengkapi nama, harga, dan kategori produk.');
      return;
    }

    setState(() => _saving = true);

    try {
      await ProductManagementService.addProduct(
        name: _nameController.text,
        priceText: _priceController.text,
        category: _selectedCategory,
        image: _pickedImage,
      );

      if (!mounted) return;

      _nameController.clear();
      _priceController.clear();

      setState(() {
        _saving = false;
        _pickedImage = null;
        _selectedCategory = null;
      });

      await _loadProducts(showError: false);

      _snack('Produk berhasil ditambahkan.');
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);

      _snack(
        error is FormatException
            ? error.message
            : 'Gagal menyimpan produk: $error',
      );
    }
  }

  // ============================================================
  // EDIT PRODUK
  // ============================================================

  Future<void> _editProduct(
    Map<String, dynamic> product,
  ) async {
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

    try {
      await ProductManagementService.updateProduct(
        product: product,
        name: result.name,
        price: result.price,
        category: result.category,
      );

      await _loadProducts(showError: false);

      if (mounted) {
        _snack('Produk berhasil diperbarui.');
      }
    } catch (error) {
      if (!mounted) return;
      _snack('Gagal menyimpan produk: $error');
    }
  }

  // ============================================================
  // HAPUS PRODUK
  // ============================================================

  Future<void> _deleteProduct(
    Map<String, dynamic> product,
  ) async {
    final name = product['name']?.toString() ?? 'Produk';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: _navy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'Hapus Produk?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Produk "$name" akan dihapus dari katalog dan kasir.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, false),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.white70),
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
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ProductManagementService.deleteProduct(product);

      await _loadProducts(showError: false);

      if (mounted) {
        _snack('Produk "$name" berhasil dihapus.');
      }
    } catch (error) {
      if (!mounted) return;

      if ('$error'.contains('riwayat transaksi')) {
        final nonaktif = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Tidak bisa dihapus'),
            content: const Text(
              'Produk ini sudah punya riwayat transaksi. '
              'Nonaktifkan saja?',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, true),
                child: const Text('Nonaktifkan'),
              ),
            ],
          ),
        );

        if (nonaktif == true) {
          try {
            await ProductManagementService.setProductActive(
              product,
              isActive: false,
            );

            await _loadProducts(showError: false);

            if (mounted) {
              _snack('Produk dinonaktifkan.');
            }
          } catch (error) {
            if (mounted) {
              _snack('Gagal menonaktifkan produk: $error');
            }
          }
        }
      } else {
        _snack('Gagal menghapus produk: $error');
      }
    }
  }

  // ============================================================
  // KATEGORI
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
  // BUILD UTAMA
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
              final category =
                  product['category']?.toString() ?? '';

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
              final category =
                  product['category']?.toString() ?? '';

              return name.toLowerCase().contains(query) ||
                  category.toLowerCase().contains(query);
            }).toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                final isPhone = width < 600;
                final isTablet = width >= 600 && width < 1100;

                final pad = isPhone
                    ? 14.0
                    : isTablet
                        ? 22.0
                        : 26.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    pad,
                    isPhone ? 16 : 24,
                    pad,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(isPhone),
                      SizedBox(height: isPhone ? 20 : 26),
                      _formSection(isPhone),
                      SizedBox(height: isPhone ? 18 : 22),
                      if (visibleProducts.isEmpty)
                        _emptyState()
                      else
                        _productGrid(
                          visibleProducts,
                          isPhone: isPhone,
                          isTablet: isTablet,
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
  // HEADER
  // ============================================================

  Widget _header(bool isPhone) {
    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kontrol Product',
            style: TextStyle(
              color: _navy,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 13),
          _searchField(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            'Kontrol Product',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _navy,
              fontSize: isPhone ? 25 : 32,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 3),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 300,
          child: _searchField(),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _searchField() {
    return Container(
      height: 43,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFE0E8F0),
          width: 1,
        ),
        boxShadow: _shadow(),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _search = value.trim());
        },
        style: const TextStyle(
          color: _navy,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: const TextStyle(
            color: Color(0xFF91A9BD),
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF7896AE),
            size: 19,
          ),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                  icon: const Icon(Icons.close, size: 17),
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  // ============================================================
  // FORM TAMBAH PRODUK
  // ============================================================

  Widget _formSection(bool isPhone) {
    if (isPhone) {
      return Column(
        children: [
          SizedBox(
            height: 104,
            child: _formCard(true),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 40,
                  child: _categoryPill(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: _saveButton(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 78,
                height: 58,
                child: _addCategoryCard(true),
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      height: 112,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _formCard(false),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 100,
            child: _addCategoryCard(false),
          ),
        ],
      ),
    );
  }

  Widget _formCard(bool narrow) {
    return Container(
      padding: EdgeInsets.all(narrow ? 9 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
          width: 1.3,
        ),
        boxShadow: _shadow(),
      ),
      child: Row(
        children: [
          _imagePickerBox(narrow ? 76 : 88),
          SizedBox(width: narrow ? 10 : 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _nameField(),
                const SizedBox(height: 5),
                _priceField(),
              ],
            ),
          ),
          if (!narrow) ...[
            const SizedBox(width: 15),
            SizedBox(
              width: 135,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 35,
                    child: _categoryPill(),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    height: 32,
                    width: double.infinity,
                    child: _saveButton(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Widget _imagePickerBox(double size) {
    return Tooltip(
      message: 'Pilih gambar produk',
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _imageColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: const Color(0xFFE0DBEA),
              width: 1,
            ),
          ),
          child: _pickedImage == null
              ? Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: size * 0.55,
                )
              : Image.memory(
                  _pickedImage!,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  // ============================================================
  // NAMA PRODUK
  // ============================================================

  Widget _nameField() {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                hintText: 'Nama Produk',
                hintStyle: TextStyle(
                  color: _navy,
                  fontSize: 14,
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

  // ============================================================
  // HARGA
  // ============================================================

  Widget _priceField() {
    return SizedBox(
      height: 27,
      child: Row(
        children: [
          const Text(
            'Rp.',
            style: TextStyle(
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
              style: const TextStyle(
                color: _navy,
                fontSize: 12,
              ),
              decoration: const InputDecoration(
                hintText: 'Harga',
                hintStyle: TextStyle(
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
        padding: EdgeInsets.only(left: 5),
        child: Icon(
          Icons.edit_square,
          size: 16,
          color: _navy,
        ),
      ),
    );
  }

  // ============================================================
  // DROPDOWN KATEGORI
  // ============================================================

  Widget _categoryPill() {
    final value = _categories.contains(_selectedCategory)
        ? _selectedCategory
        : null;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFB7CBE0),
          width: 1,
        ),
        boxShadow: _shadow(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: const Text(
            'Kategori',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _navy,
            size: 18,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            color: _navy,
            fontSize: 12,
          ),
          items: _categories.toSet().map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (selected) {
            if (selected != null) {
              setState(() => _selectedCategory = selected);
            }
          },
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON SIMPAN
  // ============================================================

  Widget _saveButton() {
    return ElevatedButton(
      onPressed: _saving ? null : _saveNewProduct,
      style: ElevatedButton.styleFrom(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _navy.withValues(alpha: 0.5),
        elevation: 3,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: FittedBox(
        child: Text(
          _saving ? 'Menyimpan...' : 'Simpan',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TAMBAH KATEGORI
  // ============================================================

  Widget _addCategoryCard(bool narrow) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openCategoryDialog,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _border,
              width: 1.3,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: _shadow(),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tambah\nKategori',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _navy,
                  fontSize: narrow ? 10 : 11,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.add_rounded,
                color: _navy,
                size: narrow ? 27 : 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GRID PRODUK RESPONSIF
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

    final spacing = isPhone ? 12.0 : 15.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        mainAxisExtent: isPhone ? 112 : 112,
      ),
      itemBuilder: (context, index) {
        return _productCard(
          products[index],
          isPhone: isPhone,
        );
      },
    );
  }

  // ============================================================
  // KARTU PRODUK
  // ============================================================

  Widget _productCard(
    Map<String, dynamic> product, {
    required bool isPhone,
  }) {
    final name = product['name']?.toString() ?? 'Produk';
    final aktif = product['is_active'] == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 260;

        final imageSize = isPhone
            ? 82.0
            : compact
                ? 62.0
                : 76.0;

        return Opacity(
          opacity: aktif ? 1 : 0.55,
          child: Container(
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: const Color(0xFFC5D4E1),
                width: 1.2,
              ),
              boxShadow: _shadow(),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(7),
                    child: Row(
                      children: [
                        Container(
                          width: imageSize,
                          height: imageSize,
                          decoration: BoxDecoration(
                            color: _imageColor,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: const Color(0xFFE3DFEB),
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ProductImage(
                            image: product['image'],
                          ),
                        ),
                        const SizedBox(width: 9),
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
                                  fontSize: compact ? 10 : 12,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _rupiah(product['price']),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: compact ? 9 : 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 42,
                                    height: 24,
                                    child: Transform.scale(
                                      scale: 0.78,
                                      alignment: Alignment.centerLeft,
                                      child: Switch(
                                        value: aktif,
                                        onChanged: (value) async {
                                          try {
                                            await ProductManagementService
                                                .setProductActive(
                                              product,
                                              isActive: value,
                                            );
                                          } catch (error) {
                                            if (mounted) {
                                              _snack(
                                                'Gagal mengubah status: $error',
                                              );
                                            }
                                          }
                                        },
                                        activeThumbColor: Colors.white,
                                        activeTrackColor: _navy,
                                        inactiveThumbColor: Colors.white,
                                        inactiveTrackColor:
                                            Colors.grey.shade400,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 25,
                                    height: 23,
                                    child: _AnimatedDeleteButton(
                                      tooltip: 'Hapus $name',
                                      onPressed: () =>
                                          _deleteProduct(product),
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
                SizedBox(
                  width: 32,
                  child: Center(
                    child: IconButton(
                      tooltip: 'Edit $name',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 35,
                      ),
                      onPressed: () => _editProduct(product),
                      icon: const Icon(
                        Icons.edit_square,
                        color: _navy,
                        size: 17,
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _border,
          width: 1,
        ),
        boxShadow: _shadow(),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 42,
            color: _muted,
          ),
          const SizedBox(height: 12),
          const Text(
            'Produk belum tersedia',
            style: TextStyle(
              color: _navy,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _search.isNotEmpty
                ? 'Produk yang kamu cari tidak ditemukan.'
                : 'Tambahkan produk melalui formulir di atas.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TOMBOL HAPUS ANIMASI
// ============================================================

class _AnimatedDeleteButton extends StatefulWidget {
  const _AnimatedDeleteButton({
    required this.tooltip,
    required this.onPressed,
  });

  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_AnimatedDeleteButton> createState() =>
      _AnimatedDeleteButtonState();
}

class _AnimatedDeleteButtonState
    extends State<_AnimatedDeleteButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
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
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _hovered
                  ? const Color(0xFFCA4141)
                  : _danger,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: 0.15),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Transform.scale(
              scale: _pressed ? 0.9 : 1,
              child: const Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HASIL EDIT
// ============================================================

class _EditResult {
  const _EditResult(
    this.name,
    this.price,
    this.category,
  );

  final String name;
  final int price;
  final String category;
}

// ============================================================
// DIALOG EDIT PRODUK
// ============================================================

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

class _EditProductDialogState
    extends State<_EditProductDialog> {
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
      if (!_items.contains(initial)) {
        _items.add(initial);
      }
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Edit Produk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const _DialogLabel('Nama Menu'),
              _DialogTextField(controller: _name),
              const SizedBox(height: 16),
              const _DialogLabel('Harga'),
              _DialogTextField(
                controller: _price,
                keyboardType: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              const SizedBox(height: 16),
              const _DialogLabel('Kategori'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    hint: const Text('Pilih kategori'),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _navy,
                    ),
                    dropdownColor: Colors.white,
                    items: _items.toSet().map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
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
                  style: const TextStyle(
                    color: Color(0xFFFFB4B4),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 22),
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
  State<_CategoryDialog> createState() =>
      _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final TextEditingController _newCategory =
      TextEditingController();

  String? _current;
  String? _error;
  bool _processing = false;

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

  Future<void> _deleteCurrent() async {
    if (_processing) return;

    final current = _current;
    if (current == null) return;

    final used = widget.usageCount(current);

    if (used > 0) {
      setState(() {
        _error = 'Kategori "$current" masih dipakai $used produk.';
      });
      return;
    }

    setState(() => _processing = true);

    try {
      widget.categories.remove(current);
      await widget.onChanged();

      if (!mounted) return;

      setState(() {
        _current = widget.categories.isEmpty
            ? null
            : widget.categories.first;
        _error = null;
        _processing = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = 'Gagal menghapus kategori: $error';
        _processing = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_processing) return;

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

    setState(() => _processing = true);

    try {
      widget.categories.add(value);
      await widget.onChanged();

      if (!mounted) return;

      Navigator.pop(context, value);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = 'Gagal menyimpan kategori: $error';
        _processing = false;
      });
    }
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Tambah Kategori',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const _DialogLabel('Kategori saat ini'),
              _currentDropdown(),
              const SizedBox(height: 16),
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
                  style: const TextStyle(
                    color: Color(0xFFFFB4B4),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Center(
                child: _DialogSaveButton(
                  onPressed: _processing ? () {} : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currentDropdown() {
    return Container(
      height: 44,
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
                hint: const Text('Belum ada kategori'),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _navy,
                ),
                dropdownColor: Colors.white,
                items: widget.categories.toSet().map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
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
                      size: 20,
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
      padding: const EdgeInsets.only(
        bottom: 6,
        left: 2,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
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
      height: 44,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        onChanged: onChanged,
        style: const TextStyle(
          color: _navy,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
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
  const _DialogSaveButton({
    required this.onPressed,
  });

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
          horizontal: 40,
          vertical: 13,
        ),
      ),
      child: const Text(
        'Simpan',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
