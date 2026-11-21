import 'package:kasir_celcious_coffe/data/api_service.dart';

class StockManagementService {
  StockManagementService._();

  // ============================================================
  // DASHBOARD STOK
  // ============================================================

  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await ApiService.get('stok/dashboard');
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  // ============================================================
  // BAHAN BAKU
  // ============================================================

  static Future<List<Map<String, dynamic>>> getBahanBaku({
    String? search,
    String? status,
    String? statusStok,
  }) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['q'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (statusStok != null && statusStok.isNotEmpty) {
      query['status_stok'] = statusStok;
    }

    final res = await ApiService.get('bahan-baku', query: query);
    final data = res['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
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
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  static Future<Map<String, dynamic>> deleteBahanBaku(int id) async {
    return await ApiService.delete('bahan-baku/$id');
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
  }) async {
    final query = <String, String>{};
    if (idProduk != null) query['id_produk'] = idProduk.toString();
    if (search != null && search.isNotEmpty) query['search'] = search;

    final res = await ApiService.get('resep', query: query);
    final data = res['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
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
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  static Future<void> hapusResepItem(int idResep) async {
    await ApiService.delete('resep/$idResep');
  }
}
