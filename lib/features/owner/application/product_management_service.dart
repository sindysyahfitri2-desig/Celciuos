import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

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

    final updated = List<Map<String, dynamic>>.from(ProdukData.produk.value)
      ..add({
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

    products.removeAt(index);
    await ProdukData.saveProducts(products);
  }

  static Future<void> setProductActive(
    Map<String, dynamic> product, {
    required bool isActive,
  }) async {
    final products = List<Map<String, dynamic>>.from(ProdukData.produk.value);
    final index = products.indexWhere((item) => identical(item, product));
    if (index < 0) throw StateError('Produk sudah tidak tersedia.');

    products[index] = {...products[index], 'is_active': isActive};
    await ProdukData.saveProducts(products);
  }
}
