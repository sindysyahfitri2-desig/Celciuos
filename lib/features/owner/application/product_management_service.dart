
import 'dart:typed_data';

import '../../../data/api_service.dart';
import '../../../data/produk_data.dart';

/// Pengelolaan produk dan kategori melalui backend Laravel.
class ProductManagementService {
  ProductManagementService._();

  // ============================================================
  // KATEGORI UTAMA
  // ============================================================

  /// Satu sumber kategori untuk Kasir, Produk, dan Owner.
  static List<String> get kategoriProduk =>
      List<String>.from(ProdukData.kategoriProduk);

  static List<String> get defaultCategories =>
      List<String>.from(ProdukData.kategoriProduk);

  static List<Map<String, dynamic>> _categoryRecords = [];

  static bool _categoriesLoaded = false;

  // ============================================================
  // LOAD KATEGORI
  // ============================================================

  static Future<List<Map<String, dynamic>>> _fetchCategories() async {
    final response = await ApiService.get('kategori');
    final data = response['data'];

    if (data is! List) {
      throw Exception('Format data kategori dari server tidak valid.');
    }

    _categoryRecords = data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    _categoriesLoaded = true;

    return _categoryRecords;
  }

  /// Memastikan tujuh kategori utama tersedia di database.
  /// Kategori lama tidak dihapus.
  static Future<void> _ensureCanonicalCategories() async {
    await _fetchCategories();

    for (final category in ProdukData.kategoriProduk) {
      final exists = _categoryRecords.any((record) {
        final name = record['nama_kategori']?.toString() ?? '';
        return name.toLowerCase() == category.toLowerCase();
      });

      if (!exists) {
        await ApiService.post('kategori', {
          'nama_kategori': category,
        });

        await _fetchCategories();
      }
    }
  }

  static Future<List<String>?> loadCategories() async {
    await _ensureCanonicalCategories();

    // Sinkronkan kategori dari backend ke ProdukData.kategori (ValueNotifier)
    // agar halaman Kasir dapat menampilkan kategori dinamis dari server.
    final backendKategori = _categoryRecords
        .map((r) => (r['nama_kategori'] ?? r['name'] ?? '') as String)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    // Pertahankan hanya 7 kategori kanonik.
    final kanonikal = Set<String>.from(ProdukData.kategoriProduk
        .map((k) => k.toLowerCase()));
    final filtered = backendKategori
        .where((k) => kanonikal.contains(k.toLowerCase()))
        .toList();

    ProdukData.kategori.value =
        filtered.isEmpty ? List<Map<String, dynamic>>.from(
            ProdukData.kategoriProduk.map((k) => {'nama_kategori': k}))
        : filtered.map((k) => {'nama_kategori': k}).toList();

    return List<String>.from(ProdukData.kategoriProduk);
  }

  static Future<void> _ensureCategoriesLoaded() async {
    if (!_categoriesLoaded) {
      await _ensureCanonicalCategories();
    }
  }

  // ============================================================
  // JUMLAH PRODUK PER KATEGORI
  // ============================================================

  static int usageCount(String category) {
    return ProdukData.produk.value.where((product) {
      return product['category']?.toString().toLowerCase() ==
          category.toLowerCase();
    }).length;
  }

  // ============================================================
  // SIMPAN KATEGORI
  // ============================================================

  /// Kategori utama bersifat tetap.
  /// Kategori lama di database tidak dihapus.
  static Future<void> saveCategories(List<String> categories) async {
    await _ensureCanonicalCategories();
  }

  // ============================================================
  // AMBIL ID KATEGORI
  // ============================================================

  static Future<int> _getCategoryId(String category) async {
    await _ensureCanonicalCategories();

    final normalizedCategory = ProdukData.kategoriProduk.firstWhere(
      (item) => item.toLowerCase() == category.trim().toLowerCase(),
      orElse: () => '',
    );

    if (normalizedCategory.isEmpty) {
      throw Exception(
        'Kategori "$category" tidak termasuk kategori utama.',
      );
    }

    final selected = _categoryRecords.where((item) {
      final name = item['nama_kategori']?.toString() ?? '';
      return name.toLowerCase() == normalizedCategory.toLowerCase();
    });

    if (selected.isEmpty) {
      throw Exception(
        'Kategori "$normalizedCategory" tidak ditemukan di server.',
      );
    }

    final id = selected.first['id_kategori'];

    if (id == null) {
      throw Exception('ID kategori tidak ditemukan.');
    }

    return int.parse(id.toString());
  }

  // ============================================================
  // TAMBAH PRODUK
  // ============================================================

  static Future<void> addProduct({
    required String name,
    required String priceText,
    required String? category,
    required Uint8List? image,
  }) async {
    final cleanName = name.trim();

    final price = int.tryParse(
      priceText.replaceAll('.', '').trim(),
    );

    if (cleanName.isEmpty ||
        price == null ||
        price < 0 ||
        category == null ||
        category.trim().isEmpty) {
      throw const FormatException(
        'Isi nama, harga, dan kategori dengan benar.',
      );
    }

    final sudahAda = ProdukData.produk.value.any((p) =>
        (p['name'] ?? '').toString().trim().toLowerCase() == cleanName.toLowerCase());

    if (sudahAda) {
      throw Exception('Produk "$cleanName" sudah ada. Silakan gunakan nama lain.');
    }

    final categoryId = await _getCategoryId(category);

    final response = await ApiService.post('produk', {
      'id_kategori': categoryId,
      'nama_produk': cleanName,
      'harga': price,
      'status': 'aktif',
    });

    final created = response['data'];

    if (created is! Map || created['id_produk'] == null) {
      throw const FormatException(
        'Produk sudah dikirim, tetapi ID produk dari server tidak valid.',
      );
    }

    final createdProduct = Map<String, dynamic>.from(created);

    final id = createdProduct['id_produk'];

    final savedName =
        createdProduct['nama_produk']?.toString() ?? cleanName;

    final savedCategory = createdProduct['kategori'];

    final savedPrice =
        double.tryParse(
          createdProduct['harga']?.toString() ?? '',
        ) ??
        price.toDouble();

    final products = ProdukData.produk.value
        .where(
          (product) =>
              product['id_produk']?.toString() != id.toString() &&
              product['name']?.toString() != savedName,
        )
        .toList();

    products.add({
      'id_produk': id,
      'name': savedName,
      'price': savedPrice,
      'category': savedCategory is Map
          ? savedCategory['nama_kategori']?.toString() ??
              category.trim()
          : category.trim(),
      'image': image ?? '',
      'is_active':
          createdProduct['status']?.toString().trim().toLowerCase() !=
              'nonaktif',
    });

    await ProdukData.saveProducts(products);

    await ProdukData.loadFromApi();
  }

  // ============================================================
  // EDIT PRODUK
  // ============================================================

  static Future<void> updateProduct({
    required Map<String, dynamic> product,
    required String name,
    required int price,
    required String category,
  }) async {
    final id = product['id_produk'];

    if (id == null) {
      throw Exception(
        'ID produk tidak ditemukan. Muat ulang data produk.',
      );
    }

    final cleanName = name.trim();

    if (cleanName.isEmpty || price < 0) {
      throw const FormatException(
        'Nama dan harga produk tidak valid.',
      );
    }

    final categoryId = await _getCategoryId(category);

    await ApiService.put('produk/$id', {
      'id_kategori': categoryId,
      'nama_produk': cleanName,
      'harga': price,
    });

    await ProdukData.loadFromApi();
  }

  // ============================================================
  // HAPUS PRODUK
  // ============================================================

  static Future<void> deleteProduct(
    Map<String, dynamic> product,
  ) async {
    final id = product['id_produk'];

    if (id == null) {
      throw Exception('ID produk tidak ditemukan.');
    }

    await ApiService.delete('produk/$id');

    await ProdukData.loadFromApi();
  }

  // ============================================================
  // AKTIF / NONAKTIF PRODUK
  // ============================================================

  static Future<void> setProductActive(
    Map<String, dynamic> product, {
    required bool isActive,
  }) async {
    await ProdukData.setProductActive(
      product,
      isActive: isActive,
    );
  }
}
