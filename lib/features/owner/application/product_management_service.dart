import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/api_service.dart';
import '../../../data/produk_data.dart';

/// Product and category rules used by the Owner product-management screens.
class ProductManagementService {
  ProductManagementService._();

  static const _categoriesKey = 'celcious_categories';

  static const defaultCategories = ['Coffee', 'Non-Coffee', 'Food', 'Snack'];

  static Future<List<String>?> loadCategories() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_categoriesKey);
  }

  static Future<void> saveCategories(List<String> categories) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(
      _categoriesKey,
      List<String>.from(categories),
    );
    if (!saved) throw StateError('Gagal menyimpan kategori produk.');
  }

  static int usageCount(String category) {
    return ProdukData.produk.value.where((product) {
      return product['category']?.toString().toLowerCase() ==
          category.toLowerCase();
    }).length;
  }

  static Future<void> addProduct({
    required String name,
    required String priceText,
    required String? category,
    required Uint8List? image,
  }) async {
    final cleanName = name.trim();
    final price = int.tryParse(priceText.replaceAll('.', '').trim());
    if (cleanName.isEmpty || price == null || price < 0 || category == null) {
      throw const FormatException(
        'Isi nama, harga, dan kategori dengan benar.',
      );
    }

    final categoryId = await _categoryId(category);
    final response = await ApiService.post('produk', {
      'id_kategori': categoryId,
      'nama_produk': cleanName,
      'harga': price,
      'status': 'aktif',
    });
    final savedProduct = Map<String, dynamic>.from(response['data'] as Map);

    final updated = List<Map<String, dynamic>>.from(ProdukData.produk.value)
      ..add({
        'id_produk': savedProduct['id_produk'],
        'name': cleanName,
        'price': price,
        'category': category,
        'image': image,
        'stock': 0,
        'is_active': true,
      });
    await ProdukData.saveProducts(updated);
  }

  static Future<void> updateProduct({
    required Map<String, dynamic> product,
    required String name,
    required int price,
    required String category,
  }) async {
    final products = List<Map<String, dynamic>>.from(ProdukData.produk.value);
    final index = products.indexWhere((item) => identical(item, product));
    if (index < 0) throw StateError('Produk sudah tidak tersedia.');

    final id = product['id_produk'];
    if (id is! num) throw StateError('Produk belum tersinkron dengan server.');
    final categoryId = await _categoryId(category);
    await ApiService.put('produk/${id.toInt()}', {
      'nama_produk': name,
      'harga': price,
      'id_kategori': categoryId,
    });

    products[index] = {
      ...products[index],
      'name': name,
      'price': price,
      'category': category,
    };
    await ProdukData.saveProducts(products);
  }

  static Future<void> deleteProduct(Map<String, dynamic> product) async {
    final products = List<Map<String, dynamic>>.from(ProdukData.produk.value);
    final index = products.indexWhere((item) => identical(item, product));
    if (index < 0) throw StateError('Produk sudah tidak tersedia.');

    final id = product['id_produk'];
    if (id is! num) throw StateError('Produk belum tersinkron dengan server.');
    await ApiService.delete('produk/${id.toInt()}');

    products.removeAt(index);
    await ProdukData.saveProducts(products);
  }

  static Future<void> setProductActive(
    Map<String, dynamic> product, {
    required bool isActive,
  }) async {
    await ProdukData.setProductActive(product, isActive: isActive);
  }

  static Future<int> _categoryId(String name) async {
    final response = await ApiService.get('kategori');
    final categories = response['data'];
    if (categories is List) {
      for (final item in categories.whereType<Map>()) {
        if (item['nama_kategori']?.toString().toLowerCase() ==
            name.toLowerCase()) {
          final id = item['id_kategori'];
          if (id is num) return id.toInt();
        }
      }
    }
    throw StateError('Kategori "$name" tidak ditemukan di server.');
  }
}
