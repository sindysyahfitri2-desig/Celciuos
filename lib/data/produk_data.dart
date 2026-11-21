
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';

// ============================================================
// DATA PRODUK CELCIOUS COFFEE
// Satu sumber data untuk halaman Produk, Kasir, dan Owner.
// ============================================================

class ProdukData {
  ProdukData._();

  static const String _productsKey = 'celcious_products';
  static const String _imageBytesKey = '__productImageBytesBase64';
  static const String _kategoriKey = 'celcious_kategori';

  // ==========================================================
  // KATEGORI UTAMA
  // ==========================================================

  static const List<String> kategoriProduk = [
    'Americano',
    'Sanger',
    'Refresh',
    'Best Selling',
    'Latte',
    'Non Coffee',
    'Food',
  ];

  static const Map<String, String> gambarPerKategori = {
    'Americano': 'assets/images/Americano.jpg',
    'Sanger': 'assets/images/Sanger.jpg',
    'Refresh': 'assets/images/Black_Sunkist.jpg',
    'Best Selling': 'assets/images/Cappuccino.jpg',
    'Latte': 'assets/images/Matcha_Latte.jpg',
    'Non Coffee': 'assets/images/Red_Velvet.jpg',
    'Food': 'assets/images/Nasi_Goreng.jpg',
  };

  static String? gambarKategori(String category) {
    return gambarPerKategori[category];
  }

  // ==========================================================
  // DATA KATEGORI DARI BACKEND
  // ==========================================================

  static final ValueNotifier<List<Map<String, dynamic>>> kategori =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  // ==========================================================
  // DATA PRODUK
  // ==========================================================

  static final ValueNotifier<List<Map<String, dynamic>>> produk =
      ValueNotifier<List<Map<String, dynamic>>>([
    {
      'name': 'Celcious Espresso',
      'price': 20000,
      'category': 'Americano',
      'image': 'assets/images/Espreso.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Cappuccino',
      'price': 22000,
      'category': 'Latte',
      'image': 'assets/images/Cappuccino.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Sanger',
      'price': 23000,
      'category': 'Sanger',
      'image': 'assets/images/Sanger.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Americano',
      'price': 24000,
      'category': 'Americano',
      'image': 'assets/images/Americano.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Black Sunkist',
      'price': 26000,
      'category': 'Refresh',
      'image': 'assets/images/Black_Sunkist.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Red Velvet',
      'price': 19000,
      'category': 'Non Coffee',
      'image': 'assets/images/Red_Velvet.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Taro Latte',
      'price': 25000,
      'category': 'Non Coffee',
      'image': 'assets/images/Taro_Latte.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Matcha Latte',
      'price': 27000,
      'category': 'Non Coffee',
      'image': 'assets/images/Matcha_Latte.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious White Chocolate',
      'price': 28000,
      'category': 'Non Coffee',
      'image': 'assets/images/White_Chocolate.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Indomie Kuah',
      'price': 12000,
      'category': 'Food',
      'image': 'assets/images/Indomie_Kuah.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Indomie Goreng',
      'price': 12000,
      'category': 'Food',
      'image': 'assets/images/Indomie_Goreng.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Nasi Goreng',
      'price': 19000,
      'category': 'Food',
      'image': 'assets/images/Nasi_Goreng.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Nasi Goreng Spesial',
      'price': 22000,
      'category': 'Food',
      'image': 'assets/images/Nasi_Goreng_Spesial.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Rice Bowl Ayam Geprek',
      'price': 17000,
      'category': 'Food',
      'image': 'assets/images/Rice_Bowl_Sambal_Mata.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Spagetti Carbonara',
      'price': 22000,
      'category': 'Food',
      'image': 'assets/images/Spagetti_Calbonara.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Spagetti Bolognese',
      'price': 22000,
      'category': 'Food',
      'image': 'assets/images/Spagetti_Bolognese.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Tomyam Seafood',
      'price': 22000,
      'category': 'Food',
      'image': 'assets/images/Tomyam_Seafood.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Cinnamon Roll',
      'price': 15000,
      'category': 'Food',
      'image': 'assets/images/Cinnamon_Roll.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious French Fries',
      'price': 18000,
      'category': 'Food',
      'image': 'assets/images/French_Fries.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Aren Latte',
      'price': 26000,
      'category': 'Latte',
      'image': 'assets/images/Arenn_latte.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Burger',
      'price': 26000,
      'category': 'Food',
      'image': 'assets/images/Burger.jpg',
      'is_active': true,
    },
    {
      'name': 'Celcious Donat',
      'price': 16000,
      'category': 'Food',
      'image': 'assets/images/donat.jpg',
      'is_active': true,
    },
  ]);

  // ==========================================================
  // GAMBAR PRODUK
  // ==========================================================

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
    'Celcious Nasi Goreng Spesial':
        'assets/images/Nasi_Goreng_Spesial.jpg',
    'Celcious Rice Bowl Ayam Geprek':
        'assets/images/Rice_Bowl_Sambal_Mata.jpg',
    'Celcious Spagetti Carbonara':
        'assets/images/Spagetti_Calbonara.jpg',
    'Celcious Spagetti Bolognese':
        'assets/images/Spagetti_Bolognese.jpg',
    'Celcious Tomyam Seafood':
        'assets/images/Tomyam_Seafood.jpg',
    'Celcious Cinnamon Roll':
        'assets/images/Cinnamon_Roll.jpg',
    'Celcious French Fries':
        'assets/images/French_Fries.jpg',
    'Celcious Aren Latte':
        'assets/images/Arenn_latte.jpg',
    'Celcious Burger':
        'assets/images/Burger.jpg',
    'Celcious Donat':
        'assets/images/donat.jpg',
  };

  // ==========================================================
  // NORMALISASI NAMA KATEGORI
  // ==========================================================

  static String _normalisasiTeks(String value) {
    return value.trim().toLowerCase().replaceAll(
          RegExp(r'[\s_-]+'),
          ' ',
        );
  }

  static String kategoriBaru(
    String namaProduk,
    String kategoriLama,
  ) {
    final nama = _normalisasiTeks(namaProduk);
    final kategori = _normalisasiTeks(kategoriLama);

    // Cocokkan dengan tujuh kategori utama.
    for (final item in kategoriProduk) {
      if (_normalisasiTeks(item) == kategori) {
        return item;
      }
    }

    // Best Selling.
    if (nama.contains('butterscotch') ||
        nama.contains('buttercream') ||
        nama.contains('tiramisu') ||
        nama.contains('caramel machiato') ||
        nama.contains('caramel macchiato')) {
      return 'Best Selling';
    }

    // Sanger.
    if (nama.contains('sanger') || kategori.contains('sanger')) {
      return 'Sanger';
    }

    // Americano.
    if (nama.contains('americano') ||
        nama.contains('espresso') ||
        nama.contains('espreso') ||
        kategori.contains('americano')) {
      return 'Americano';
    }

    // Refresh.
    if (nama.contains('black sunkist') ||
        nama.contains('refresh') ||
        nama.contains('sunset orange') ||
        nama.contains('blue motions') ||
        nama.contains('lemon tea') ||
        kategori.contains('refresh')) {
      return 'Refresh';
    }

    // Non Coffee.
    if (kategori == 'non coffee' ||
        nama.contains('red velvet') ||
        nama.contains('taro') ||
        nama.contains('matcha') ||
        nama.contains('white chocolate')) {
      return 'Non Coffee';
    }

    // Latte.
    if (nama.contains('latte') ||
        nama.contains('cappuccino') ||
        kategori == 'latte') {
      return 'Latte';
    }

    // Food dan Snack.
    if (kategori == 'food' ||
        kategori == 'snack' ||
        nama.contains('indomie') ||
        nama.contains('nasi goreng') ||
        nama.contains('rice bowl') ||
        nama.contains('spagetti') ||
        nama.contains('spaghetti') ||
        nama.contains('tomyam') ||
        nama.contains('cinnamon') ||
        nama.contains('french fries') ||
        nama.contains('burger') ||
        nama.contains('donat')) {
      return 'Food';
    }

    // Kategori Coffee lama.
    if (kategori == 'coffee') {
      return 'Latte';
    }

    // Kategori tidak dikenal tidak langsung dibuang.
    return 'Food';
  }

  // ==========================================================
  // HILANGKAN DUPLIKAT PRODUK
  // ==========================================================

  static List<Map<String, dynamic>> deduplicate(
    List<Map<String, dynamic>> products,
  ) {
    final seenId = <String>{};
    final seenName = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final product in products) {
      final id = (product['id_produk'] ?? '').toString().trim();
      final name =
          (product['name'] ?? '').toString().trim().toLowerCase();

      if (id.isNotEmpty) {
        if (!seenId.add(id)) continue;
      } else {
        if (!seenName.add(name)) continue;
      }

      result.add(product);
    }

    return result;
  }

  // ==========================================================
  // STATUS PRODUK
  // ==========================================================

  static bool _statusAktif(dynamic status) {
    if (status == null) return true;

    if (status is bool) return status;

    if (status is num) return status == 1;

    final value = status.toString().trim().toLowerCase();

    return value == 'aktif' ||
        value == 'active' ||
        value == '1' ||
        value == 'true' ||
        value == 'yes';
  }

  // ==========================================================
  // NORMALISASI SATU PRODUK
  // ==========================================================

  static Map<String, dynamic> _normalisasiProduk(
    Map<String, dynamic> product,
  ) {
    final copy = Map<String, dynamic>.from(product);

    final nama = (
      copy['name'] ??
      copy['nama_produk'] ??
      ''
    ).toString().trim();

    final kategoriRaw = copy['category'] ?? copy['kategori'] ?? '';

    final kategoriLama = kategoriRaw is Map
        ? (
            kategoriRaw['nama_kategori'] ??
            kategoriRaw['nama'] ??
            ''
          ).toString()
        : kategoriRaw.toString();

    copy['name'] = nama;
    copy['category'] = kategoriBaru(nama, kategoriLama);

    final image = copy['image'];

    if (image == null || image.toString().isEmpty) {
      copy['image'] = _gambarPerNama[nama] ?? '';
    }

    copy['is_active'] = _statusAktif(
      copy['is_active'] ?? copy['status'],
    );

    return copy;
  }

  // ==========================================================
  // MEMUAT PRODUK DARI BACKEND API
  // ==========================================================

  static Future<void> loadFromApi({
    bool throwOnError = false,
  }) async {
    try {
      final res = await ApiService.get('produk');

      if (res is! Map) {
        debugPrint('Respons API produk tidak valid: $res');
        return;
      }

      final data = res['data'];

      if (data is! List) {
        debugPrint('Data produk API bukan List: $data');
        return;
      }

      final hasil = <Map<String, dynamic>>[];

      for (final item in data) {
        if (item is! Map) continue;

        final p = Map<String, dynamic>.from(item);

        final nama = (
          p['nama_produk'] ??
          p['name'] ??
          ''
        ).toString().trim();

        if (nama.isEmpty) continue;

        final kategori = p['kategori'];

        final kategoriAsli = kategori is Map
            ? (
                kategori['nama_kategori'] ??
                kategori['nama'] ??
                ''
              ).toString()
            : (
                kategori ??
                p['category'] ??
                ''
              ).toString();

        final kategoriFinal = kategoriBaru(
          nama,
          kategoriAsli,
        );

        final hargaRaw = p['harga'] ?? p['price'] ?? 0;

        final harga = hargaRaw is num
            ? hargaRaw.toDouble()
            : double.tryParse(
                  hargaRaw.toString().replaceAll(',', '.'),
                ) ??
                0;

        final gambar = _gambarPerNama[nama] ?? '';

        hasil.add({
          'id_produk': p['id_produk'],
          'name': nama,
          'price': harga,
          'category': kategoriFinal,
          'image': gambar,
          'is_active': _statusAktif(p['status']),
        });
      }

      final produkBersih = deduplicate(hasil);

      // Jangan menghapus produk lokal jika API kosong.
      if (produkBersih.isEmpty) {
        debugPrint(
          'API tidak memiliki produk valid. Data lokal dipertahankan.',
        );

        await loadKategoriFromApi();
        return;
      }

      // Perbarui data produk untuk seluruh halaman.
      produk.value = produkBersih;

      // Simpan produk ke local storage.
      final preferences = await SharedPreferences.getInstance();

      final berhasilSimpan = await preferences.setString(
        _productsKey,
        jsonEncode(_encodeProducts(produkBersih)),
      );

      if (!berhasilSimpan) {
        debugPrint('Gagal menyimpan produk ke local storage.');
      }

      // Perbarui kategori dari backend.
      await loadKategoriFromApi();

      debugPrint(
        'Produk berhasil dimuat: ${produkBersih.length} produk',
      );
    } catch (e, stackTrace) {
      debugPrint('Gagal memuat produk dari API: $e');
      debugPrint('$stackTrace');

      if (throwOnError) {
        rethrow;
      }
    }
  }

  // ==========================================================
  // MEMUAT KATEGORI DARI BACKEND API
  // ==========================================================

  static Future<void> loadKategoriFromApi() async {
    try {
      final res = await ApiService.get('kategori');

      if (res is! Map) return;

      final data = res['data'];

      if (data is! List) return;

      final hasil = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      kategori.value = hasil;

      final preferences = await SharedPreferences.getInstance();

      await preferences.setString(
        _kategoriKey,
        jsonEncode(hasil),
      );
    } catch (e) {
      debugPrint('Gagal memuat kategori dari API: $e');
    }
  }

  // ==========================================================
  // MEMUAT KATEGORI DARI LOCAL STORAGE
  // ==========================================================

  static void _loadKategoriFromPrefs(
    SharedPreferences preferences,
  ) {
    final saved = preferences.getString(_kategoriKey);

    if (saved == null) return;

    try {
      final decoded = jsonDecode(saved);

      if (decoded is List) {
        kategori.value = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Gagal membaca kategori lokal: $e');
    }
  }

  // ==========================================================
  // MEMUAT PRODUK DARI LOCAL STORAGE
  // ==========================================================

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();

    _loadKategoriFromPrefs(preferences);

    final savedProducts = preferences.getString(_productsKey);

    if (savedProducts == null) return;

    try {
      final decoded = jsonDecode(savedProducts);

      if (decoded is! List) {
        throw const FormatException(
          'Data produk tersimpan tidak valid.',
        );
      }

      final hasil = decoded.whereType<Map>().map((item) {
        final product = Map<String, dynamic>.from(item);

        final image = product['image'];

        if (image is Map && image[_imageBytesKey] is String) {
          product['image'] = base64Decode(
            image[_imageBytesKey] as String,
          );
        }

        return _normalisasiProduk(product);
      }).toList();

      final produkBersih = deduplicate(hasil);

      if (produkBersih.isNotEmpty) {
        produk.value = produkBersih;
      }

      await preferences.setString(
        _productsKey,
        jsonEncode(_encodeProducts(produk.value)),
      );
    } catch (e) {
      debugPrint('Gagal membaca produk lokal: $e');
    }
  }

  // ==========================================================
  // FORMAT GAMBAR UNTUK DISIMPAN
  // ==========================================================

  static List<Map<String, dynamic>> _encodeProducts(
    List<Map<String, dynamic>> products,
  ) {
    return products.map((product) {
      final copy = Map<String, dynamic>.from(product);

      final image = copy['image'];

      if (image is Uint8List) {
        copy['image'] = {
          _imageBytesKey: base64Encode(image),
        };
      }

      return copy;
    }).toList();
  }

  // ==========================================================
  // MENYIMPAN PRODUK
  // ==========================================================

  static Future<void> saveProducts(
    List<Map<String, dynamic>> products,
  ) async {
    final hasil = deduplicate(
      products.map(_normalisasiProduk).toList(),
    );

    final preferences = await SharedPreferences.getInstance();

    final saved = await preferences.setString(
      _productsKey,
      jsonEncode(_encodeProducts(hasil)),
    );

    if (!saved) {
      throw StateError('Gagal menyimpan perubahan produk.');
    }

    produk.value = hasil;
  }

  // ==========================================================
  // MENGUBAH STATUS AKTIF PRODUK
  // ==========================================================

  static Future<void> setProductActive(
    Map<String, dynamic> product, {
    required bool isActive,
  }) async {
    final id = product['id_produk'];

    if (id is! num) {
      throw StateError(
        'ID produk tidak ditemukan. Muat ulang data produk.',
      );
    }

    await ApiService.patch(
      'produk/${id.toInt()}/status',
      {
        'status': isActive ? 'aktif' : 'nonaktif',
      },
    );

    await loadFromApi(throwOnError: true);
  }
}
