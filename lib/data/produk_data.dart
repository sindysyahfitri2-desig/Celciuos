import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProdukData {
  static const _productsKey = 'celcious_products';
  static const _imageBytesKey = '__productImageBytesBase64';

  static final ValueNotifier<List<Map<String, dynamic>>> produk =
      ValueNotifier<List<Map<String, dynamic>>>([
        {
          'name': 'Celcious Espresso',
          'price': 20000,
          'category': 'Coffee',
          'image': 'assets/images/Espreso.jpg',
        },
        {
          'name': 'Celcious Cappuccino',
          'price': 22000,
          'category': 'Coffee',
          'image': 'assets/images/Cappuccino.jpg',
        },
        {
          'name': 'Celcious Sanger',
          'price': 23000,
          'category': 'Coffee',
          'image': 'assets/images/Sanger.jpg',
        },
        {
          'name': 'Celcious Americano',
          'price': 24000,
          'category': 'Coffee',
          'image': 'assets/images/Americano.jpg',
        },
        {
          'name': 'Celcious Black Sunkist',
          'price': 26000,
          'category': 'Coffee',
          'image': 'assets/images/Black_Sunkist.jpg',
        },
        {
          'name': 'Celcious Red Velvet',
          'price': 19000,
          'category': 'Non-Coffee',
          'image': 'assets/images/Red_Velvet.jpg',
        },
        {
          'name': 'Celcious Taro Latte',
          'price': 25000,
          'category': 'Non-Coffee',
          'image': 'assets/images/Taro_Latte.jpg',
        },
        {
          'name': 'Celcious Matcha Latte',
          'price': 27000,
          'category': 'Non-Coffee',
          'image': 'assets/images/Matcha_Latte.jpg',
        },
        {
          'name': 'Celcious White Chocolate',
          'price': 28000,
          'category': 'Non-Coffee',
          'image': 'assets/images/White_Chocolate.jpg',
        },
        {
          'name': 'Celcious Indomie Kuah',
          'price': 12000,
          'category': 'Food',
          'image': 'assets/images/Indomie_Kuah.jpg',
        },
        {
          'name': 'Celcious Indomie Goreng',
          'price': 12000,
          'category': 'Food',
          'image': 'assets/images/Indomie_Goreng.jpg',
        },
        {
          'name': 'Celcious Nasi Goreng',
          'price': 19000,
          'category': 'Food',
          'image': 'assets/images/Nasi_Goreng.jpg',
        },
        {
          'name': 'Celcious Nasi Goreng Spesial',
          'price': 22000,
          'category': 'Food',
          'image': 'assets/images/Nasi_Goreng_Spesial.jpg',
        },
        {
          'name': 'Celcious Rice Bowl Ayam Geprek',
          'price': 17000,
          'category': 'Food',
          'image': 'assets/images/Rice_Bowl_Sambal_Mata.jpg',
        },
        {
          'name': 'Celcious Spagetti Carbonara',
          'price': 22000,
          'category': 'Food',
          'image': 'assets/images/Spagetti_Calbonara.jpg',
        },
        {
          'name': 'Celcious Spagetti Bolognese',
          'price': 22000,
          'category': 'Food',
          'image': 'assets/images/Spagetti_Bolognese.jpg',
        },
        {
          'name': 'Celcious Tomyam Seafood',
          'price': 22000,
          'category': 'Food',
          'image': 'assets/images/Tomyam_Seafood.jpg',
        },
        {
          'name': 'Celcious Cinnamon Roll',
          'price': 15000,
          'category': 'Snack',
          'image': 'assets/images/Cinnamon_Roll.jpg',
        },
        {
          'name': 'Celcious French Fries',
          'price': 18000,
          'category': 'Snack',
          'image': 'assets/images/French_Fries.jpg',
        },
        {
          'name': 'Celcious Aren Latte',
          'price': 26000,
          'category': 'Coffee',
          'image': 'assets/images/Arenn_latte.jpg',
        },
        {
          'name': 'Celcious Burger',
          'price': 26000,
          'category': 'Snack',
          'image': 'assets/images/Burger.jpg',
        },
        {
          'name': 'Celcious Donat',
          'price': 16000,
          'category': 'Snack',
          'image': 'assets/images/donat.jpg',
        },
      ]);

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final savedProducts = preferences.getString(_productsKey);
    if (savedProducts == null) return;

    final decoded = jsonDecode(savedProducts);
    if (decoded is! List) {
      throw const FormatException('Data produk tersimpan tidak valid.');
    }

    produk.value = decoded.whereType<Map>().map((item) {
      final product = Map<String, dynamic>.from(item);
      final image = product['image'];
      if (image is Map && image[_imageBytesKey] is String) {
        product['image'] = base64Decode(image[_imageBytesKey] as String);
      }
      return product;
    }).toList();
  }

  static Future<void> saveProducts(
    List<Map<String, dynamic>> products,
  ) async {
    final encodedProducts = products.map((product) {
      final copy = Map<String, dynamic>.from(product);
      final image = copy['image'];
      if (image is Uint8List) {
        copy['image'] = {_imageBytesKey: base64Encode(image)};
      }
      return copy;
    }).toList();
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _productsKey,
      jsonEncode(encodedProducts),
    );
    if (!saved) {
      throw StateError('Gagal menyimpan perubahan produk.');
    }
    produk.value = products;
  }
}
