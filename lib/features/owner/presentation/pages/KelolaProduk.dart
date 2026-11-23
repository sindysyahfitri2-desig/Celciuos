import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kasir_celcious_coffe/data/produk_data.dart';
import 'package:kasir_celcious_coffe/features/owner/application/product_management_service.dart';
import 'package:kasir_celcious_coffe/ui/widgets/product_image.dart';

// ============================================================
// WARNA & SHADOW
// ============================================================

const _navy = Color(0xFF082640);
const _background = Color(0xFFDCE9F4);
const _lightBlue = Color(0xFFA8CBE9);
const _pillBlue = Color(0xFFB4C8DE);
const _muted = Color(0xFF667B8D);
const _imageColor = Color(0xFFD5D0E5);
const _danger = Color(0xFFE05A5A);
const _border = Color(0xFFD0D9E3);

/// Shadow khas desain: abu-abu lembut jatuh ke kanan-bawah.
List<BoxShadow> _shadow() => const [
  BoxShadow(
    color: Color(0x40000000),
    blurRadius: 4,
    offset: Offset(2, 3),
  ),
];

List<BoxShadow> _shadowSmall() => const [
  BoxShadow(
    color: Color(0x4D000000),
    blurRadius: 3,
    offset: Offset(1, 2),
  ),
];

const _allCategories = '__semua__';

// ============================================================
// HALAMAN PRODUK
// ============================================================

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

  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _gridScrollController = ScrollController();

  final ImagePicker _picker = ImagePicker();

  String _search = '';
  String? _selectedCategory;

  // null berarti semua produk ditampilkan.
  String? _activeCategory;

  Uint8List? _pickedImage;

  bool _saving = false;
  bool _loadingCategories = false;

  // Tujuh kategori utama.
  final List<String> _categories = List<String>.from(
    ProdukData.kategoriProduk,
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
    _categoryScrollController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadProducts({bool showError = true}) async {
    try {
      await ProdukData.loadFromApi();
      if (mounted) setState(() {});
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
      if (mounted) _snack('Gagal memuat kategori: $error');
    } finally {
      _loadingCategories = false;
    }
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
        : int.tryParse(value?.toString().replaceAll('.', '') ?? '') ?? 0;

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

      setState(() => _pickedImage = bytes);
    } catch (error) {
      if (mounted) _snack('Gagal memilih gambar: $error');
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

  Future<void> _editProduct(Map<String, dynamic> product) async {
    final rawPrice = product['price'];
    final cleanPriceText = rawPrice is num
        ? rawPrice.toInt().toString()
        : (double.tryParse(rawPrice?.toString() ?? '')?.toInt().toString() ??
              '');

    final result = await showDialog<_EditResult>(
      context: context,
      builder: (_) => _EditProductDialog(
        initialName: product['name']?.toString() ?? '',
        initialPrice: cleanPriceText,
        initialCategory: product['category']?.toString(),
        initialImage: product['image'],
        categories: _categories,
      ),
    );

    if (result == null || !mounted) return;

    try {
      await ProductManagementService.updateProduct(
        product: product,
        name: result.name,
        price: result.price,
        category: result.category,
        image: result.imageBytes,
      );

      await _loadProducts(showError: false);

      if (mounted) _snack('Produk berhasil diperbarui.');
    } catch (error) {
      if (mounted) _snack('Gagal menyimpan produk: $error');
    }
  }

  // ============================================================
  // HAPUS PRODUK
  // ============================================================

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final name = product['name']?.toString() ?? 'Produk';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _navy,
        title: const Text(
          'Hapus Produk?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Produk "$name" akan dihapus dari katalog dan kasir.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ProductManagementService.deleteProduct(product);
      await _loadProducts(showError: false);

      if (mounted) _snack('Produk "$name" berhasil dihapus.');
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
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
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

            if (mounted) _snack('Produk dinonaktifkan.');
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
  // DAFTAR 7 KATEGORI (juga untuk memfilter produk)
  // ============================================================

  Future<void> _openCategoryDialog() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryDialog(
        categories: _categories,
        usageCount: _usageCount,
        activeCategory: _activeCategory,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _activeCategory = picked == _allCategories ? null : picked;
    });
  }

  // ============================================================
  // BUILD UTAMA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: _background,
        child: SafeArea(
          child: ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: ProdukData.produk,
            builder: (context, products, child) {
              final query = _search.toLowerCase();

              final visibleProducts = products.where((product) {
                final name = product['name']?.toString() ?? '';
                final category = product['category']?.toString() ?? '';

                final matchesSearch =
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
                  final height = constraints.maxHeight;
                  final isPhone = width < 600;
                  final isTablet = width >= 600 && width < 1024;
                  final isShortViewport = height < 460;

                  final pad = isPhone
                      ? 14.0
                      : isTablet
                          ? 20.0
                          : 26.0;

                  final topSection = Padding(
                    padding: EdgeInsets.fromLTRB(
                      pad,
                      isPhone ? 14 : 20,
                      pad,
                      isPhone ? 8 : 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _header(isPhone),
                        SizedBox(height: isPhone ? 14 : 20),
                        _formSection(width < 760),
                        SizedBox(height: isPhone ? 14 : 18),
                        _categoryFilter(isPhone),
                      ],
                    ),
                  );

                  if (isShortViewport) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          topSection,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: pad),
                            child: visibleProducts.isEmpty
                                ? _emptyState()
                                : _productGrid(
                                    visibleProducts,
                                    isPhone: isPhone,
                                    isTablet: isTablet,
                                    shrinkWrap: true,
                                  ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      topSection,
                      Expanded(
                        child: visibleProducts.isEmpty
                            ? SingleChildScrollView(
                                controller: _gridScrollController,
                                padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: _emptyState(),
                                ),
                              )
                            : _productGrid(
                                visibleProducts,
                                isPhone: isPhone,
                                isTablet: isTablet,
                                shrinkWrap: false,
                                padding: EdgeInsets.fromLTRB(pad, 4, pad, 24),
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header(bool isPhone) {
    final title = Text(
      'Kontrol Product',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: _navy,
        fontSize: isPhone ? 22 : 28,
        fontWeight: FontWeight.w900,
        shadows: const [
          Shadow(
            color: Color(0x66000000),
            blurRadius: 4,
            offset: Offset(2, 3),
          ),
        ],
      ),
    );

    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 12),
          _searchField(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: 24),
        SizedBox(width: 240, child: _searchField()),
      ],
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _searchField() {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(25),
        boxShadow: _shadow(),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _search = value.trim()),
        style: const TextStyle(color: _navy, fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Cari',
          hintStyle: const TextStyle(
            color: Color(0xFF91A9BD),
            fontSize: 11,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF7896AE),
            size: 15,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                  icon: const Icon(Icons.close, size: 15),
                ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
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
          SizedBox(height: 96, child: _formCard(true)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 3, child: _categoryPill()),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(height: 36, child: _saveButton()),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 84,
                height: 60,
                child: _addCategoryCard(true),
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      height: 92,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _formCard(false)),
          const SizedBox(width: 16),
          SizedBox(width: 92, child: _addCategoryCard(false)),
        ],
      ),
    );
  }

  Widget _formCard(bool narrow) {
    return Container(
      padding: EdgeInsets.all(narrow ? 9 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _shadow(),
      ),
      child: Row(
        children: [
          _imagePickerBox(narrow ? 76 : 72),
          SizedBox(width: narrow ? 10 : 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _nameField(),
                const SizedBox(height: 4),
                _priceField(),
              ],
            ),
          ),
          if (!narrow) ...[
            const SizedBox(width: 12),
            SizedBox(width: 130, height: 32, child: _categoryPill()),
            const SizedBox(width: 10),
            SizedBox(width: 66, height: 32, child: _saveButton()),
            const SizedBox(width: 6),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _imageColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _pickedImage == null
              ? Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: size * 0.5,
                )
              : Image.memory(_pickedImage!, fit: BoxFit.cover),
        ),
      ),
    );
  }

  // ============================================================
  // NAMA PRODUK (ikon edit tepat di sebelah teks)
  // ============================================================

  Widget _nameField() {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 100,
                  maxWidth: 240,
                ),
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Nama Produk',
                    hintStyle: TextStyle(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
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
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Rp.',
            style: TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 50,
                  maxWidth: 160,
                ),
                child: TextField(
                  controller: _priceController,
                  focusNode: _priceFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: _navy, fontSize: 11),
                  decoration: const InputDecoration(
                    hintText: 'Harga',
                    hintStyle: TextStyle(color: _muted, fontSize: 11),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          _editIcon(_priceFocus, size: 13),
        ],
      ),
    );
  }

  Widget _editIcon(FocusNode focus, {double size = 15}) {
    return GestureDetector(
      onTap: focus.requestFocus,
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Icon(Icons.edit_square, size: size, color: _navy),
      ),
    );
  }

  // ============================================================
  // DROPDOWN KATEGORI (dari 7 kategori utama)
  // ============================================================

  Widget _categoryPill() {
    final value =
        _categories.contains(_selectedCategory) ? _selectedCategory : null;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _pillBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _shadow(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: const Text(
            'Kategori',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
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
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category, overflow: TextOverflow.ellipsis),
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
  // TOMBOL SIMPAN
  // ============================================================

  Widget _saveButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: _shadow(),
      ),
      child: ElevatedButton(
        onPressed: _saving ? null : _saveNewProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _navy.withValues(alpha: 0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: FittedBox(
          child: Text(
            _saving ? 'Menyimpan...' : 'Simpan',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // KARTU "TAMBAH KATEGORI +"
  // ============================================================

  Widget _addCategoryCard(bool narrow) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _shadow(),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _openCategoryDialog,
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
              const SizedBox(height: 2),
              Icon(
                Icons.add_rounded,
                color: _navy,
                size: narrow ? 22 : 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BARIS KATEGORI (Semua + 7 kategori utama)
  // ============================================================

 
Widget _categoryFilter(bool isPhone) {
  if (_categories.isEmpty) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _loadCategories,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _shadow(),
          ),
          child: const Text(
            'Kategori belum termuat. Ketuk untuk muat ulang.',
            style: TextStyle(
              color: _navy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  final items = ['Semua', ..._categories];

  return SizedBox(
    height: 42,
    child: ListView.separated(
      key: const PageStorageKey<String>('owner-product-categories'),
      controller: _categoryScrollController,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8, right: 6),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final label = items[index];

        final selected = index == 0
            ? _activeCategory == null
            : _activeCategory?.toLowerCase() ==
                label.toLowerCase();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (selected) return;

              setState(() {
                _activeCategory =
                    index == 0 ? null : label;
              });
              if (_gridScrollController.hasClients) {
                _gridScrollController.jumpTo(0);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: selected ? Colors.white : _lightBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? _navy : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: _shadow(),
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 11,
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
  // GRID PRODUK RESPONSIF
  // ============================================================

  Widget _productGrid(
    List<Map<String, dynamic>> products, {
    required bool isPhone,
    required bool isTablet,
    bool shrinkWrap = false,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    final columns = isPhone
        ? 1
        : isTablet
        ? 2
        : 3;

    return GridView.builder(
      controller: shrinkWrap ? null : _gridScrollController,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding: padding,
      itemCount: products.length,
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
  // KARTU PRODUK (biru di belakang + kartu putih + strip edit)
  // ============================================================

  Widget _productCard(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Produk';
    final aktif = product['is_active'] == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 260;
        final imageSize = compact ? 62.0 : 82.0;

        return Opacity(
          opacity: aktif ? 1 : 0.55,
          child: Container(
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _shadow(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _shadowSmall(),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: imageSize,
                          height: imageSize,
                          decoration: BoxDecoration(
                            color: _imageColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ProductImage(image: product['image']),
                        ),
                        const SizedBox(width: 10),
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
                                  fontSize: compact ? 9 : 10,
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
                                    width: 26,
                                    height: 22,
                                    child: _AnimatedDeleteButton(
                                      tooltip: 'Hapus $name',
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
                SizedBox(
                  width: 36,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _shadow(),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 42, color: _muted),
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
                : _activeCategory != null
                ? 'Belum ada produk di kategori $_activeCategory.'
                : 'Tambahkan produk melalui formulir di atas.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13),
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
  State<_AnimatedDeleteButton> createState() => _AnimatedDeleteButtonState();
}

class _AnimatedDeleteButtonState extends State<_AnimatedDeleteButton> {
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
              color: _hovered ? const Color(0xFFCA4141) : _danger,
              borderRadius: BorderRadius.circular(6),
              boxShadow: _shadowSmall(),
            ),
            child: Transform.scale(
              scale: _pressed ? 0.9 : 1,
              child: const Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 16,
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
    this.category, {
    this.imageBytes,
  });

  final String name;
  final int price;
  final String category;
  final Uint8List? imageBytes;
}

// ============================================================
// DIALOG EDIT PRODUK (NAMA, HARGA, KATEGORI, & FOTO PRODUK)
// ============================================================

class _EditProductDialog extends StatefulWidget {
  const _EditProductDialog({
    required this.initialName,
    required this.initialPrice,
    required this.initialCategory,
    required this.initialImage,
    required this.categories,
  });

  final String initialName;
  final String initialPrice;
  final String? initialCategory;
  final Object? initialImage;
  final List<String> categories;

  @override
  State<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<_EditProductDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final List<String> _items;
  final ImagePicker _picker = ImagePicker();

  String? _category;
  Uint8List? _newImageBytes;
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

  Future<void> _pickNewImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted || bytes.isEmpty) return;
      setState(() {
        _newImageBytes = bytes;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memilih gambar: $e';
      });
    }
  }

  void _submit() {
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.replaceAll('.', '').trim());

    if (name.isEmpty || price == null || price < 0 || _category == null) {
      setState(() {
        _error = 'Isi nama, harga, dan kategori dengan benar.';
      });
      return;
    }

    Navigator.pop(
      context,
      _EditResult(name, price, _category!, imageBytes: _newImageBytes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewImage = _newImageBytes ?? widget.initialImage;

    return Dialog(
      backgroundColor: _navy,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
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
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    InkWell(
                      onTap: _pickNewImage,
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              color: _imageColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ProductImage(
                              image: previewImage,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: _navy,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickNewImage,
                      style: TextButton.styleFrom(
                        foregroundColor: _lightBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.photo_library_outlined, size: 16),
                      label: Text(
                        _newImageBytes != null
                            ? 'Foto baru dipilih (Ganti lagi)'
                            : 'Ganti Foto Produk',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _DialogLabel('Nama Menu'),
              _DialogTextField(controller: _name),
              const SizedBox(height: 14),
              const _DialogLabel('Harga'),
              _DialogTextField(
                controller: _price,
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 14),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _DialogSaveButton(onPressed: _submit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DIALOG 7 KATEGORI (ketuk untuk memfilter produk)
// ============================================================

class _CategoryDialog extends StatelessWidget {
  const _CategoryDialog({
    required this.categories,
    required this.usageCount,
    required this.activeCategory,
  });

  final List<String> categories;
  final int Function(String category) usageCount;
  final String? activeCategory;

  Widget _row(
    BuildContext context, {
    required String label,
    required String countText,
    required String result,
    required bool selected,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: selected ? _lightBlue : Colors.white,
        borderRadius: BorderRadius.circular(11),
        boxShadow: _shadowSmall(),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => Navigator.pop(context, result),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: _navy, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  countText,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<int>(0, (sum, c) => sum + usageCount(c));

    return Dialog(
      backgroundColor: _navy,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kategori Produk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Tujuh kategori utama Celcious Coffee.\n'
                'Ketuk salah satu untuk memfilter produk.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 20),
              _row(
                context,
                label: 'Semua kategori',
                countText: '$total produk',
                result: _allCategories,
                selected: activeCategory == null,
                icon: Icons.apps_rounded,
              ),
              ...categories.map((category) {
                return _row(
                  context,
                  label: category,
                  countText: '${usageCount(category)} produk',
                  result: category,
                  selected:
                      activeCategory?.toLowerCase() == category.toLowerCase(),
                  icon: Icons.category_rounded,
                );
              }),
              const SizedBox(height: 8),
              const Text(
                'Kategori utama dikelola melalui data master backend.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 18),
              _DialogSaveButton(
                onPressed: () => Navigator.pop(context),
                label: 'Tutup',
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 6, left: 2),
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
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        style: const TextStyle(color: _navy, fontSize: 13),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
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
            borderSide: const BorderSide(color: _lightBlue, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _DialogSaveButton extends StatelessWidget {
  const _DialogSaveButton({
    required this.onPressed,
    this.label = 'Simpan',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 13),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }
}
