
import 'dart:typed_data';

import '../../../data/api_service.dart';
import '../../../data/produk_data.dart';

/// Pengelolaan produk dan kategori melalui backend Laravel.
class ProductManagementService {
  ProductManagementService._();

  static const defaultCategories = [
    'Coffee',
    'Non-Coffee',
    'Food',
    'Snack',
  ];

  static List<Map<String, dynamic>> _categoryRecords = [];

  static bool _categoriesLoaded = false;

  // ============================================================
  // KATEGORI
  // ============================================================

  static Future<List<String>?> loadCategories() async {
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

    return _categoryRecords
        .map((item) => item['nama_kategori']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static Future<void> _ensureCategoriesLoaded() async {
    if (!_categoriesLoaded) {
      await loadCategories();
    }
  }

  static int usageCount(String category) {
    return ProdukData.produk.value.where((product) {
      return product['category']?.toString().toLowerCase() ==
          category.toLowerCase();
    }).length;
  }

  static Future<void> saveCategories(List<String> categories) async {
    await _ensureCategoriesLoaded();

    final desired = categories
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final removed = _categoryRecords.where((record) {
      final name = record['nama_kategori']?.toString() ?? '';
      return !desired.any(
        (item) => item.toLowerCase() == name.toLowerCase(),
      );
    }).toList();

    for (final category in removed) {
      final id = category['id_kategori'];

      if (id == null) {
        throw Exception('ID kategori tidak ditemukan.');
      }

      await ApiService.delete('kategori/$id');
    }

    for (final name in desired) {
      final exists = _categoryRecords.any((record) {
        final oldName = record['nama_kategori']?.toString() ?? '';
        return oldName.toLowerCase() == name.toLowerCase();
      });

      if (!exists) {
        await ApiService.post('kategori', {
          'nama_kategori': name,
        });
      }
    }

    await loadCategories();
  }

  static Future<int> _getCategoryId(String category) async {
    await _ensureCategoriesLoaded();

    final selected = _categoryRecords.where((item) {
      final name = item['nama_kategori']?.toString() ?? '';
      return name.toLowerCase() == category.trim().toLowerCase();
    });

    if (selected.isEmpty) {
      throw Exception('Kategori "$category" tidak ditemukan di server.');
    }

    final id = selected.first['id_kategori'];

    if (id == null) {
      throw Exception('ID kategori tidak ditemukan.');
    }

    return int.parse(id.toString());
  }

  // ============================================================
  // PRODUK
  // ============================================================

  static Future<void> addProduct({
    required String name,
    required String priceText,
    required String? category,
    required Uint8List? image,
  }) async {
    final cleanName = name.trim();
    final price = int.tryParse(priceText.replaceAll('.', '').trim());

    if (cleanName.isEmpty ||
        price == null ||
        price < 0 ||
        category == null ||
        category.trim().isEmpty) {
      throw const FormatException(
        'Isi nama, harga, dan kategori dengan benar.',
      );
    }

    final categoryId = await _getCategoryId(category);

    await ApiService.post('produk', {
      'id_kategori': categoryId,
      'nama_produk': cleanName,
      'harga': price,
      'status': 'aktif',
    });

    await ProdukData.loadFromApi();
  }

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

  static Future<void> setProductActive(
    Map<String, dynamic> product, {
    required bool isActive,
  }) async {
    final id = product['id_produk'];

    if (id == null) {
      throw Exception('ID produk tidak ditemukan.');
    }

    await ApiService.put('produk/$id', {
      'status': isActive ? 'aktif' : 'nonaktif',
    });

    await ProdukData.loadFromApi();
  }
}
