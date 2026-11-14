import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';

// Data produk dan penyimpanannya dibagi oleh layar Kasir, Owner, dan katalog.
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

  // Nama produk -> aset gambar lokal (tabel produk tidak punya kolom gambar).
  static const Map<String, String> _gambarPerNama = {
    'Celcious Espresso': 'assets/images/Espreso.jpg',
    'Celcious Cappuccino': 'assets/images/Cappuccino.jpg',
    'Celcious Sanger': 'assets/images/Sanger.jpg',
    'Celcious Americano': 'assets/images/Americano.jpg',
    'Celcious Black Sunkist': 'assets/images/Black_Sunkist.jpg',
    'Celcious Red Velvet': 'assets/images/Red_Velvet.jpg',
    'Celcious Taro Latte': 'assets/images/Taro_Latte.jpg',
    'Celcious Matcha Latte': 'assets/images/Matcha_Latte.jpg',
    'Celcious White Chocolate': 'assets/images/White_Chocolate.jpg',
    'Celcious Indomie Kuah': 'assets/images/Indomie_Kuah.jpg',
    'Celcious Indomie Goreng': 'assets/images/Indomie_Goreng.jpg',
    'Celcious Nasi Goreng': 'assets/images/Nasi_Goreng.jpg',
    'Celcious Nasi Goreng Spesial': 'assets/images/Nasi_Goreng_Spesial.jpg',
    'Celcious Rice Bowl Ayam Geprek': 'assets/images/Rice_Bowl_Sambal_Mata.jpg',
    'Celcious Spagetti Carbonara': 'assets/images/Spagetti_Calbonara.jpg',
    'Celcious Spagetti Bolognese': 'assets/images/Spagetti_Bolognese.jpg',
    'Celcious Tomyam Seafood': 'assets/images/Tomyam_Seafood.jpg',
    'Celcious Cinnamon Roll': 'assets/images/Cinnamon_Roll.jpg',
    'Celcious French Fries': 'assets/images/French_Fries.jpg',
    'Celcious Aren Latte': 'assets/images/Arenn_latte.jpg',
    'Celcious Burger': 'assets/images/Burger.jpg',
    'Celcious Donat': 'assets/images/donat.jpg',
  };

  /// Muat produk dari backend. Gagal -> daftar lama tetap dipakai.
  /// Butuh token login, jadi panggil SETELAH kasir/owner login.
  static Future<void> loadFromApi() async {
    try {
      final res = await ApiService.get('produk');
      final data = res['data'];
      if (data is! List) return;

      final hasil = data.whereType<Map>().map((item) {
        final p = Map<String, dynamic>.from(item);
        final nama = p['nama_produk']?.toString() ?? '';
        final kategori = p['kategori'];
        return <String, dynamic>{
          'id_produk': p['id_produk'],
          'name': nama,
          'price': double.tryParse(p['harga'].toString()) ?? 0,
          'category': kategori is Map
              ? (kategori['nama_kategori']?.toString() ?? '')
              : '',
          'image': _gambarPerNama[nama] ?? '',
          'is_active': p['status'] == 'aktif',
        };
      }).toList();

      produk.value = hasil;
    } catch (e) {
      debugPrint('Gagal memuat produk dari API: $e');
    }
  }

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

  static Future<void> saveProducts(List<Map<String, dynamic>> products) async {
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

  static Future<void> setProductActive(
    Map<String, dynamic> product, {
    required bool isActive,
  }) async {
    final products = List<Map<String, dynamic>>.from(produk.value);
    final index = products.indexWhere((item) => identical(item, product));
    if (index < 0) throw StateError('Produk sudah tidak tersedia.');

    products[index] = {...products[index], 'is_active': isActive};
    await saveProducts(products);
  }
}
