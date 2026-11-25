import 'package:kasir_celcious_coffe/data/api_service.dart';

class StockManagementService {
  StockManagementService._();

  static const Duration _cacheTtl = Duration(seconds: 25);
  static Map<String, dynamic>? _dashboardCache;
  static DateTime? _dashboardAt;
  static final Map<String, List<Map<String, dynamic>>> _bahanCache = {};
  static final Map<String, DateTime> _bahanAt = {};
  static final Map<String, List<Map<String, dynamic>>> _resepCache = {};
  static final Map<String, DateTime> _resepAt = {};

  static bool _isFresh(DateTime? at) =>
      at != null && DateTime.now().difference(at) < _cacheTtl;

  static void invalidateCache() {
    _dashboardCache = null;
    _dashboardAt = null;
    _bahanCache.clear();
    _bahanAt.clear();
    _resepCache.clear();
    _resepAt.clear();
  }

  static Future<void> prefetch() async {
    try {
      await Future.wait([
        getDashboard().catchError((_) => <String, dynamic>{}),
        getBahanBaku().catchError((_) => <Map<String, dynamic>>[]),
      ]);
    } catch (_) {}
  }

  // ============================================================
  // DASHBOARD STOK
  // ============================================================

  static Future<Map<String, dynamic>> getDashboard({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _dashboardCache != null && _isFresh(_dashboardAt)) {
      return _dashboardCache!;
    }
    final res = await ApiService.get('stok/dashboard');
    final data = (res['data'] as Map<String, dynamic>?) ?? {};
    _dashboardCache = data;
    _dashboardAt = DateTime.now();
    return data;
  }

  // ============================================================
  // BAHAN BAKU
  // ============================================================

  static Future<List<Map<String, dynamic>>> getBahanBaku({
    String? search,
    String? status,
    String? statusStok,
    bool forceRefresh = false,
  }) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['q'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (statusStok != null && statusStok.isNotEmpty) {
      query['status_stok'] = statusStok;
    }

    final key = '${search ?? ''}|${status ?? ''}|${statusStok ?? ''}';
    if (!forceRefresh && _bahanCache.containsKey(key) && _isFresh(_bahanAt[key])) {
      return _bahanCache[key]!;
    }

    final res = await ApiService.get('bahan-baku', query: query);
    final data = res['data'];
    if (data is List) {
      final list = data.whereType<Map<String, dynamic>>().toList();
      _bahanCache[key] = list;
      _bahanAt[key] = DateTime.now();
      return list;
    }
    return [];
  }

  static Future<Map<String, dynamic>> getBahanBakuDetail(int id) async {
    final res = await ApiService.get('bahan-baku/$id');
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  static Future<Map<String, dynamic>> tambahBahanBaku({
    required String nama,
    required String satuan,
    String? kategori,
    double stok = 0,
    double stokMinimum = 0,
    double hargaBeli = 0,
    String status = 'aktif',
  }) async {
    final res = await ApiService.post('bahan-baku', {
      'nama_bahan_baku': nama,
      'satuan': satuan,
      'kategori': kategori ?? 'Bahan Utama',
      'stok': stok,
      'stok_minimum': stokMinimum,
      'harga_beli': hargaBeli,
      'status': status,
    });
    invalidateCache();
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  static Future<Map<String, dynamic>> updateBahanBaku({
    required int id,
    required String nama,
    required String satuan,
    String? kategori,
    double? stokMinimum,
    double? hargaBeli,
    String? status,
  }) async {
    final body = <String, dynamic>{
      'nama_bahan_baku': nama,
      'satuan': satuan,
    };
    if (kategori != null) body['kategori'] = kategori;
    if (stokMinimum != null) body['stok_minimum'] = stokMinimum;
    if (hargaBeli != null) body['harga_beli'] = hargaBeli;
    if (status != null) body['status'] = status;

    final res = await ApiService.put('bahan-baku/$id', body);
    invalidateCache();
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  static Future<Map<String, dynamic>> deleteBahanBaku(int id) async {
    final res = await ApiService.delete('bahan-baku/$id');
    invalidateCache();
    return res;
  }

  // ============================================================
  // STOK MASUK (RESTOCK / PEMBELIAN)
  // ============================================================

  static Future<Map<String, dynamic>> catatStokMasuk({
    required int idBahanBaku,
    required double jumlah,
    String? satuan,
    double? hargaBeliSatuan,
    double? totalHarga,
    String? supplier,
    String? catatan,
    bool catatKeKas = false,
  }) async {
    final res = await ApiService.post('stok/masuk', {
      'id_bahan_baku': idBahanBaku,
      'jumlah': jumlah,
      if (satuan != null) 'satuan': satuan,
      if (hargaBeliSatuan != null) 'harga_beli_satuan': hargaBeliSatuan,
      if (totalHarga != null) 'total_harga': totalHarga,
      if (supplier != null && supplier.isNotEmpty) 'supplier': supplier,
      if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      'catat_ke_kas': catatKeKas,
    });
    invalidateCache();
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  // ============================================================
  // STOK KELUAR MANUAL (RUSAK / KADALUWARSA / TERBUANG)
  // ============================================================

  static Future<Map<String, dynamic>> catatStokKeluar({
    required int idBahanBaku,
    required double jumlah,
    required String alasan,
    String? satuan,
    String? catatan,
  }) async {
    final res = await ApiService.post('stok/keluar', {
      'id_bahan_baku': idBahanBaku,
      'jumlah': jumlah,
      'alasan': alasan,
      if (satuan != null) 'satuan': satuan,
      if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
    });
    invalidateCache();
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  // ============================================================
  // RIWAYAT STOK (MUTASI BUKU BESAR)
  // ============================================================

  static Future<List<Map<String, dynamic>>> getRiwayatStok({
    int? idBahanBaku,
    String? jenis,
    String? dariTanggal,
    String? sampaiTanggal,
    String? search,
    int limit = 100,
  }) async {
    final query = <String, String>{};
    if (idBahanBaku != null) query['id_bahan_baku'] = idBahanBaku.toString();
    if (jenis != null && jenis.isNotEmpty) query['jenis'] = jenis;
    if (dariTanggal != null && dariTanggal.isNotEmpty) {
      query['dari_tanggal'] = dariTanggal;
    }
    if (sampaiTanggal != null && sampaiTanggal.isNotEmpty) {
      query['sampai_tanggal'] = sampaiTanggal;
    }
    if (search != null && search.isNotEmpty) query['q'] = search;
    query['limit'] = limit.toString();

    final res = await ApiService.get('stok/riwayat', query: query);
    final data = res['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  // ============================================================
  // LAPORAN STOK
  // ============================================================

  static Future<Map<String, dynamic>> getLaporanStok({
    String? dariTanggal,
    String? sampaiTanggal,
  }) async {
    final query = <String, String>{};
    if (dariTanggal != null && dariTanggal.isNotEmpty) {
      query['dari_tanggal'] = dariTanggal;
    }
    if (sampaiTanggal != null && sampaiTanggal.isNotEmpty) {
      query['sampai_tanggal'] = sampaiTanggal;
    }

    final res = await ApiService.get('stok/laporan', query: query);
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  // ============================================================
  // RESEP PRODUK
  // ============================================================

  static Future<List<Map<String, dynamic>>> getResepProduk({
    int? idProduk,
    String? search,
    bool forceRefresh = false,
  }) async {
    final query = <String, String>{};
    if (idProduk != null) query['id_produk'] = idProduk.toString();
    if (search != null && search.isNotEmpty) query['search'] = search;

    final key = '${idProduk ?? ''}|${search ?? ''}';
    if (!forceRefresh && _resepCache.containsKey(key) && _isFresh(_resepAt[key])) {
      return _resepCache[key]!;
    }

    final res = await ApiService.get('resep', query: query);
    final data = res['data'];
    if (data is List) {
      final list = data.whereType<Map<String, dynamic>>().toList();
      _resepCache[key] = list;
      _resepAt[key] = DateTime.now();
      return list;
    }
    return [];
  }

  static Future<Map<String, dynamic>> simpanResepProduk({
    required int idProduk,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await ApiService.post('resep', {
      'id_produk': idProduk,
      'items': items,
    });
    invalidateCache();
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  static Future<void> hapusResepItem(int idResep) async {
    await ApiService.delete('resep/$idResep');
    invalidateCache();
  }
}
