
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

  // ==========================================================
  // KATEGORI UTAMA
  // Nanti kategori ini juga digunakan oleh halaman Kasir.
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

  // ==========================================================
  // DATA PRODUK DEFAULT
  // ==========================================================

  static final ValueNotifier<List<Map<String, dynamic>>> produk =
      ValueNotifier<List<Map<String, dynamic>>>([
    {
      'name': 'Celcious Espresso',
      'price': 20000,
      'category': 'Americano',
      'image': 'assets/images/Espreso.jpg',
    },
    {
      'name': 'Celcious Cappuccino',
      'price': 22000,
      'category': 'Latte',
      'image': 'assets/images/Cappuccino.jpg',
    },
    {
      'name': 'Celcious Sanger',
      'price': 23000,
      'category': 'Sanger',
      'image': 'assets/images/Sanger.jpg',
    },
    {
      'name': 'Celcious Americano',
      'price': 24000,
      'category': 'Americano',
      'image': 'assets/images/Americano.jpg',
    },
    {
      'name': 'Celcious Black Sunkist',
      'price': 26000,
      'category': 'Refresh',
      'image': 'assets/images/Black_Sunkist.jpg',
    },
    {
      'name': 'Celcious Red Velvet',
      'price': 19000,
      'category': 'Non Coffee',
      'image': 'assets/images/Red_Velvet.jpg',
    },
    {
      'name': 'Celcious Taro Latte',
      'price': 25000,
      'category': 'Non Coffee',
      'image': 'assets/images/Taro_Latte.jpg',
    },
    {
      'name': 'Celcious Matcha Latte',
      'price': 27000,
      'category': 'Non Coffee',
      'image': 'assets/images/Matcha_Latte.jpg',
    },
    {
      'name': 'Celcious White Chocolate',
      'price': 28000,
      'category': 'Non Coffee',
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
      'category': 'Food',
      'image': 'assets/images/Cinnamon_Roll.jpg',
    },
    {
      'name': 'Celcious French Fries',
      'price': 18000,
      'category': 'Food',
      'image': 'assets/images/French_Fries.jpg',
    },
    {
      'name': 'Celcious Aren Latte',
      'price': 26000,
      'category': 'Latte',
      'image': 'assets/images/Arenn_latte.jpg',
    },
    {
      'name': 'Celcious Burger',
      'price': 26000,
      'category': 'Food',
      'image': 'assets/images/Burger.jpg',
    },
    {
      'name': 'Celcious Donat',
      'price': 16000,
      'category': 'Food',
      'image': 'assets/images/donat.jpg',
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
  // PENYESUAIAN KATEGORI LAMA KE KATEGORI BARU
  // ==========================================================

  static String kategoriBaru(
    String namaProduk,
    String kategoriLama,
  ) {
    final nama = namaProduk.toLowerCase().trim();
    final kategori = kategoriLama.toLowerCase().trim();

    // Kategori yang sudah sesuai.
    for (final item in kategoriProduk) {
      if (kategori == item.toLowerCase()) {
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

    // Americano dan Espresso.
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
    if (kategori.contains('non-coffee') ||
        kategori.contains('non coffee') ||
        nama.contains('red velvet') ||
        nama.contains('taro') ||
        nama.contains('matcha') ||
        nama.contains('white chocolate')) {
      return 'Non Coffee';
    }

    // Food dan Snack digabung.
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

    // Latte.
    if (nama.contains('latte') ||
        nama.contains('cappuccino') ||
        kategori.contains('latte')) {
      return 'Latte';
    }

    // Produk kategori Coffee lama yang belum terpetakan.
    if (kategori == 'coffee') {
      return 'Latte';
    }

    // Default jika kategori tidak dikenal.
    return 'Food';
  }

  // ==========================================================
  // NORMALISASI SATU PRODUK
  // ==========================================================

  static Map<String, dynamic> _normalisasiProduk(
    Map<String, dynamic> product,
  ) {
    final copy = Map<String, dynamic>.from(product);

    final nama = copy['name']?.toString() ??
        copy['nama_produk']?.toString() ??
        '';

    final kategoriLama = copy['category']?.toString() ??
        copy['kategori']?.toString() ??
        '';

    copy['name'] = nama;
    copy['category'] = kategoriBaru(nama, kategoriLama);

    // Jika gambar kosong, gunakan pencocokan gambar bawaan berdasarkan nama produk.
    final gambar = copy['image'];

    if (gambar == null || gambar.toString().isEmpty) {
      copy['image'] = _gambarFallbackDariNama(nama);
    }

    return copy;
  }

  /// Pencocokan pintar gambar aset bawaan berdasarkan nama produk (case-insensitive)
  /// agar produk di database tetap memiliki foto yang bagus meski belum diunggah foto kustom.
  static String _gambarFallbackDariNama(String namaProduk) {
    final exact = _gambarPerNama[namaProduk];
    if (exact != null && exact.isNotEmpty) return exact;

    final n = namaProduk.toLowerCase().trim();
    if (n.contains('espreso') || n.contains('espresso')) {
      return 'assets/images/Espreso.jpg';
    }
    if (n.contains('americano') || n.contains('americanno')) {
      return 'assets/images/Americano.jpg';
    }
    if (n.contains('sanger')) {
      return 'assets/images/Sanger.jpg';
    }
    if (n.contains('cappuccino') || n.contains('machiato') || n.contains('macchiato')) {
      return 'assets/images/Cappuccino.jpg';
    }
    if (n.contains('aren') || n.contains('butterscotch') || n.contains('buttercream') || n.contains('tiramisu')) {
      return 'assets/images/Arenn_latte.jpg';
    }
    if (n.contains('sunkist') || n.contains('blue') || n.contains('refresh') || n.contains('sunset') || n.contains('lemon') || n.contains('berry')) {
      return 'assets/images/Black_Sunkist.jpg';
    }
    if (n.contains('red velvet')) {
      return 'assets/images/Red_Velvet.jpg';
    }
    if (n.contains('taro')) {
      return 'assets/images/Taro_Latte.jpg';
    }
    if (n.contains('matcha')) {
      return 'assets/images/Matcha_Latte.jpg';
    }
    if (n.contains('chocolate') || n.contains('coklat') || n.contains('cokelat')) {
      return 'assets/images/White_Chocolate.jpg';
    }
    if (n.contains('indomie kuah')) {
      return 'assets/images/Indomie_Kuah.jpg';
    }
    if (n.contains('indomie') || n.contains('mie')) {
      return 'assets/images/Indomie_Goreng.jpg';
    }
    if (n.contains('nasi goreng spesial')) {
      return 'assets/images/Nasi_Goreng_Spesial.jpg';
    }
    if (n.contains('nasi goreng')) {
      return 'assets/images/Nasi_Goreng.jpg';
    }
    if (n.contains('rice bowl') || n.contains('geprek') || n.contains('ayam')) {
      return 'assets/images/Rice_Bowl_Sambal_Mata.jpg';
    }
    if (n.contains('carbonara') || n.contains('calbonara')) {
      return 'assets/images/Spagetti_Calbonara.jpg';
    }
    if (n.contains('bolognese') || n.contains('spagetti') || n.contains('spaghetti')) {
      return 'assets/images/Spagetti_Bolognese.jpg';
    }
    if (n.contains('tomyam')) {
      return 'assets/images/Tomyam_Seafood.jpg';
    }
    if (n.contains('cinnamon')) {
      return 'assets/images/Cinnamon_Roll.jpg';
    }
    if (n.contains('fries') || n.contains('kentang')) {
      return 'assets/images/French_Fries.jpg';
    }
    if (n.contains('burger')) {
      return 'assets/images/Burger.jpg';
    }
    if (n.contains('donat')) {
      return 'assets/images/donat.jpg';
    }
    if (n.contains('latte')) {
      return 'assets/images/Arenn_latte.jpg';
    }
    return 'assets/images/Logo.jpeg';
  }

  /// Resolusi gambar produk: prioritaskan foto dari server (hasil upload Owner),
  /// lalu fallback pintar ke aset bawaan jika produk belum punya foto di server.
  static String _resolveServerImage(Map<String, dynamic> p, String nama) {
    final serverBase = ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    final updatedAt = Uri.encodeComponent(p['updated_at']?.toString() ?? '');
    final cacheQuery = updatedAt.isEmpty ? '' : '?v=$updatedAt';

    final rawUrl = p['gambar_url']?.toString().trim() ?? '';
    final rawPath = p['gambar']?.toString().trim() ?? '';

    if (rawUrl.isNotEmpty) {
      final parsed = Uri.tryParse(rawUrl);
      if (parsed != null && parsed.path.isNotEmpty) {
        return '$serverBase${parsed.path}$cacheQuery';
      }
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        return '$rawUrl$cacheQuery';
      }
      final normalizedPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
      return '$serverBase$normalizedPath$cacheQuery';
    }

    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return '$rawPath$cacheQuery';
    }

    return _gambarFallbackDariNama(nama);
  }

  // ==========================================================
  // MEMUAT PRODUK DARI BACKEND API
  // ==========================================================

  static Future<void> loadFromApi({
    bool throwOnError = false,
  }) async {
    try {
      final res = await ApiService.get('produk');
      final data = res['data'];

      if (data is! List) return;

      final hasil = data.whereType<Map>().map((item) {
        final p = Map<String, dynamic>.from(item);

        final nama = p['nama_produk']?.toString() ?? '';

        final kategori = p['kategori'];

        final kategoriAsli = kategori is Map
            ? kategori['nama_kategori']?.toString() ?? ''
            : kategori?.toString() ?? '';

        final kategoriFinal = kategoriBaru(
          nama,
          kategoriAsli,
        );

        return <String, dynamic>{
          'id_produk': p['id_produk'],
          'name': nama,
          'price': double.tryParse(
                p['harga']?.toString() ?? '0',
              ) ??
              0,
          'category': kategoriFinal,
          'image': _resolveServerImage(p, nama),
          'gambar': p['gambar'],
          'is_active': p['status'] == 'aktif',
        };
      }).toList();

      produk.value = hasil;
    } catch (e) {
      debugPrint('Gagal memuat produk dari API: $e');

      if (throwOnError) {
        rethrow;
      }
    }
  }

  // ==========================================================
  // MEMUAT PRODUK DARI LOCAL STORAGE
  // ==========================================================

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();

    final savedProducts = preferences.getString(_productsKey);

    if (savedProducts == null) return;

    final decoded = jsonDecode(savedProducts);

    if (decoded is! List) {
      throw const FormatException(
        'Data produk tersimpan tidak valid.',
      );
    }

    final hasil = decoded.whereType<Map>().map((item) {
      final product = Map<String, dynamic>.from(item);

      final image = product['image'];

      if (image is Map &&
          image[_imageBytesKey] is String) {
        product['image'] = base64Decode(
          image[_imageBytesKey] as String,
        );
      }

      return _normalisasiProduk(product);
    }).toList();

    produk.value = hasil;

    // Simpan kembali agar kategori lama ikut diperbarui.
    await preferences.setString(
      _productsKey,
      jsonEncode(_encodeProducts(hasil)),
    );
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
    final hasil = products.map((product) {
      return _normalisasiProduk(product);
    }).toList();

    final encodedProducts = _encodeProducts(hasil);

    final preferences = await SharedPreferences.getInstance();

    final saved = await preferences.setString(
      _productsKey,
      jsonEncode(encodedProducts),
    );

    if (!saved) {
      throw StateError(
        'Gagal menyimpan perubahan produk.',
      );
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

    await loadFromApi(
      throwOnError: true,
    );
  }
}
