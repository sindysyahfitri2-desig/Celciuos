
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

  static List<String> _extractSortedNames() {
    final defaults = ProdukData.defaultKategoriProduk;
    // Sembunyikan 3 kategori sisa seeder lama (ID 1, 2, 4: Coffee, Non-Coffee, Snack)
    // yang sudah tidak dipakai (produk_count == 0), sementara kategori baru (ID > 10)
    // yang dibuat Owner akan selalu tampil.
    const legacyUnusedNames = {'coffee', 'non-coffee', 'snack'};
    final fromServer = _categoryRecords
        .where((r) {
          final id = int.tryParse('${r['id_kategori'] ?? 0}') ?? 0;
          final count = int.tryParse('${r['produk_count'] ?? 0}') ?? 0;
          final nameLower = (r['nama_kategori']?.toString() ?? '')
              .trim()
              .toLowerCase();
          if (id > 0 && id <= 4 && count == 0 && legacyUnusedNames.contains(nameLower)) {
            return false;
          }
          return true;
        })
        .map((r) => (r['nama_kategori']?.toString() ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final ordered = <String>[];
    final seen = <String>{};

    // Urutkan kategori utama terlebih dahulu bila ada di database
    for (final d in defaults) {
      final match = fromServer.firstWhere(
        (s) => s.toLowerCase() == d.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty && seen.add(match.toLowerCase())) {
        ordered.add(match);
      }
    }
    // Tambahkan kategori baru/lainnya dari database
    for (final s in fromServer) {
      if (seen.add(s.toLowerCase())) {
        ordered.add(s);
      }
    }

    if (ordered.isNotEmpty) {
      ProdukData.syncCategories(ordered);
    }
    return ordered.isNotEmpty ? ordered : List<String>.from(ProdukData.kategoriProduk);
  }

  /// Mengambil seluruh kategori dinamis dari database Laravel.
  static Future<List<String>> loadCategories() async {
    await _fetchCategories();
    return _extractSortedNames();
  }

  /// Menambahkan kategori baru ke database Laravel (POST /api/kategori).
  static Future<List<String>> addCategory(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      throw const FormatException('Nama kategori wajib diisi.');
    }
    await ApiService.post('kategori', {'nama_kategori': clean});
    await _fetchCategories();
    return _extractSortedNames();
  }

  /// Menghapus kategori dari database Laravel (DELETE /api/kategori/{id}).
  static Future<List<String>> deleteCategory(String name) async {
    if (!_categoriesLoaded || _categoryRecords.isEmpty) {
      await _fetchCategories();
    }
    final clean = name.trim().toLowerCase();
    final matches = _categoryRecords.where((item) {
      final n = (item['nama_kategori']?.toString() ?? '').trim().toLowerCase();
      return n == clean;
    });
    if (matches.isEmpty) {
      throw Exception('Kategori "$name" tidak ditemukan di server.');
    }
    final id = matches.first['id_kategori'];
    if (id == null) {
      throw Exception('ID kategori tidak valid.');
    }
    await ApiService.delete('kategori/$id');
    await _fetchCategories();
    return _extractSortedNames();
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

  static Future<void> saveCategories(List<String> categories) async {
    await loadCategories();
  }

  // ============================================================
  // AMBIL ID KATEGORI
  // ============================================================

  static Future<int> _getCategoryId(String category) async {
    if (!_categoriesLoaded || _categoryRecords.isEmpty) {
      await _fetchCategories();
    }

    final clean = category.trim().toLowerCase();
    var selected = _categoryRecords.where((item) {
      final name = (item['nama_kategori']?.toString() ?? '').trim().toLowerCase();
      return name == clean;
    });

    if (selected.isEmpty) {
      await _fetchCategories();
      selected = _categoryRecords.where((item) {
        final name =
            (item['nama_kategori']?.toString() ?? '').trim().toLowerCase();
        return name == clean;
      });
    }

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

    final categoryId = await _getCategoryId(category);

    final Map<String, dynamic> response;
    if (image != null && image.isNotEmpty) {
      response = await ApiService.postMultipart(
        'produk',
        {
          'id_kategori': '$categoryId',
          'nama_produk': cleanName,
          'harga': '$price',
          'status': 'aktif',
        },
        fileBytes: image,
        fileField: 'gambar',
        fileName: 'produk_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    } else {
      response = await ApiService.post('produk', {
        'id_kategori': categoryId,
        'nama_produk': cleanName,
        'harga': price,
        'status': 'aktif',
      });
    }

    final created = response['data'];

    if (created is! Map || created['id_produk'] == null) {
      throw const FormatException(
        'Produk sudah dikirim, tetapi ID produk dari server tidak valid.',
      );
    }

    await ProdukData.loadFromApi(throwOnError: true);
  }

  // ============================================================
  // EDIT PRODUK
  // ============================================================

  static Future<void> updateProduct({
    required Map<String, dynamic> product,
    required String name,
    required int price,
    required String category,
    Uint8List? image,
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

    if (image != null && image.isNotEmpty) {
      await ApiService.postMultipart(
        'produk/$id',
        {
          'id_kategori': '$categoryId',
          'nama_produk': cleanName,
          'harga': '$price',
        },
        fileBytes: image,
        fileField: 'gambar',
        fileName: 'produk_${id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    } else {
      await ApiService.put('produk/$id', {
        'id_kategori': categoryId,
        'nama_produk': cleanName,
        'harga': price,
      });
    }

    await ProdukData.loadFromApi(throwOnError: true);
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
