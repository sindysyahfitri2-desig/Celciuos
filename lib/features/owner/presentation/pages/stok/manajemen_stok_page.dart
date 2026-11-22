import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/features/owner/application/stock_management_service.dart';

// ============================================================
// WARNA & TEMA
// ============================================================

const Color _navy = Color(0xFF082640);
const Color _navyLight = Color(0xFF103657);
const Color _background = Color(0xFFDCE9F4);
const Color _lightBlue = Color(0xFFA8CBE9);
const Color _accentBlue = Color(0xFF4098CE);
const Color _muted = Color(0xFF667B8D);
const Color _danger = Color(0xFFE05A5A);
const Color _warning = Color(0xFFF59E0B);
const Color _success = Color(0xFF10B981);
const Color _border = Color(0xFFD0D9E3);

String _formatRupiah(num value) {
  final str = value.round().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
  return 'Rp $str';
}

String _formatNumber(num value) {
  if (value % 1 == 0) {
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
  return value.toStringAsFixed(2);
}

List<BoxShadow> _softShadow() => [
  BoxShadow(
    color: _navy.withValues(alpha: 0.08),
    blurRadius: 10,
    offset: const Offset(0, 4),
  ),
];

// ============================================================
// HALAMAN UTAMA MANAJEMEN STOK
// ============================================================

class ManajemenStokPage extends StatefulWidget {
  const ManajemenStokPage({super.key});

  @override
  State<ManajemenStokPage> createState() => _ManajemenStokPageState();
}

class _ManajemenStokPageState extends State<ManajemenStokPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Map<String, dynamic>> _tabs = [
    {'title': 'Ringkasan', 'icon': Icons.dashboard_outlined},
    {'title': 'Bahan Baku', 'icon': Icons.inventory_2_outlined},
    {'title': 'Stok Masuk', 'icon': Icons.add_circle_outline_rounded},
    {'title': 'Stok Keluar', 'icon': Icons.remove_circle_outline_rounded},
    {'title': 'Resep Produk', 'icon': Icons.menu_book_outlined},
    {'title': 'Riwayat Stok', 'icon': Icons.history_rounded},
    {'title': 'Laporan', 'icon': Icons.analytics_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _tabController.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RingkasanStokView(onPindahTab: _navigateToTab),
                  const _BahanBakuView(),
                  _StokMasukView(onSuccess: () => setState(() {})),
                  _StokKeluarView(onSuccess: () => setState(() {})),
                  const _ResepProdukView(),
                  const _RiwayatStokView(),
                  const _LaporanStokView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warehouse_rounded, color: _navy, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manajemen Stok Celcious Coffee',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Kelola bahan baku, resep, pencatatan masuk/keluar, dan laporan mutasi',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: _accentBlue,
        indicatorWeight: 3,
        labelColor: _navy,
        unselectedLabelColor: _muted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: _tabs.map((tab) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab['icon'] as IconData, size: 18),
                const SizedBox(width: 8),
                Text(tab['title'] as String),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// 1. VIEW RINGKASAN / DASHBOARD STOK
// ============================================================

class _RingkasanStokView extends StatefulWidget {
  const _RingkasanStokView({required this.onPindahTab});
  final ValueChanged<int> onPindahTab;

  @override
  State<_RingkasanStokView> createState() => _RingkasanStokViewState();
}

class _RingkasanStokViewState extends State<_RingkasanStokView> {
  bool _loading = true;
  Map<String, dynamic> _data = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await StockManagementService.getDashboard();
      if (mounted) {
        setState(() {
          _data = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _danger, size: 48),
            const SizedBox(height: 10),
            Text('Gagal memuat ringkasan stok: $_error'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetch, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    final totalBahan = _data['total_jenis_bahan'] ?? 0;
    final stokAman = _data['stok_aman'] ?? 0;
    final stokMenipis = _data['stok_menipis'] ?? 0;
    final stokHabis = _data['stok_habis'] ?? 0;
    final nilaiPersediaan = (num.tryParse(_data['nilai_persediaan']?.toString() ?? '0')) ?? 0;
    final mutasiHariIni = _data['mutasi_hari_ini'] ?? 0;
    final peringatan = (_data['peringatan'] as List?) ?? [];
    final mutasiTerakhir = (_data['mutasi_terakhir'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _fetch,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI CARDS
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _buildKpiCard('Total Bahan Baku', '$totalBahan jenis', Icons.category_rounded, _navy, null),
                _buildKpiCard('Nilai Persediaan', _formatRupiah(nilaiPersediaan), Icons.account_balance_wallet_rounded, _accentBlue, null),
                _buildKpiCard('Stok Aman', '$stokAman', Icons.check_circle_rounded, _success, () => widget.onPindahTab(1)),
                _buildKpiCard('Stok Menipis', '$stokMenipis', Icons.warning_amber_rounded, _warning, () => widget.onPindahTab(1)),
                _buildKpiCard('Stok Habis', '$stokHabis', Icons.cancel_rounded, _danger, () => widget.onPindahTab(1)),
                _buildKpiCard('Mutasi Hari Ini', '$mutasiHariIni aktivitas', Icons.swap_horiz_rounded, _navyLight, () => widget.onPindahTab(5)),
              ],
            ),
            const SizedBox(height: 24),

            // QUICK ACTIONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => widget.onPindahTab(2),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('+ Catat Stok Masuk', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => widget.onPindahTab(3),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    label: const Text('- Catat Stok Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // PERINGATAN STOK MENIPIS / HABIS
            if (peringatan.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _warning.withValues(alpha: 0.3)),
                  boxShadow: _softShadow(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: _warning, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Peringatan Stok Menipis & Habis',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _navy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...peringatan.map((item) {
                      final status = item['status']?.toString();
                      final isHabis = status == 'habis';
                      final color = isHabis ? _danger : _warning;
                      final stok = (num.tryParse(item['stok']?.toString() ?? '0')) ?? 0;
                      final min = (num.tryParse(item['stok_minimum']?.toString() ?? '0')) ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(isHabis ? Icons.cancel_rounded : Icons.info_outline_rounded, color: color, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${item['nama_bahan_baku']} (${_formatNumber(stok)} ${item['satuan']}) - Batas Min: ${_formatNumber(min)} ${item['satuan']}',
                                style: TextStyle(fontWeight: FontWeight.w600, color: _navy, fontSize: 13),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isHabis ? 'HABIS' : 'MENIPIS',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              onPressed: () => widget.onPindahTab(2),
                              child: const Text('Beli', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 5 MUTASI TERAKHIR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _softShadow(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Aktivitas Stok Terkini',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _navy),
                      ),
                      TextButton(
                        onPressed: () => widget.onPindahTab(5),
                        child: const Text('Lihat Semua Riwayat >'),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (mutasiTerakhir.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text('Belum ada aktivitas mutasi stok.', style: TextStyle(color: _muted)),
                      ),
                    )
                  else
                    ...mutasiTerakhir.map((m) {
                      final jenis = m['jenis']?.toString() ?? '-';
                      final jumlah = (num.tryParse(m['jumlah']?.toString() ?? '0')) ?? 0;
                      final namaBahan = m['bahan_baku']?['nama_bahan_baku'] ?? 'Bahan';
                      final satuan = m['bahan_baku']?['satuan'] ?? '';
                      final ket = m['keterangan'] ?? '-';
                      final waktu = m['created_at']?.toString() ?? '';

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: _buildJenisBadge(jenis),
                        title: Text('$namaBahan - ${_formatNumber(jumlah)} $satuan', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        subtitle: Text(ket, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _muted)),
                        trailing: Text(waktu.length >= 16 ? waktu.substring(0, 16).replaceAll('T', ' ') : waktu, style: const TextStyle(fontSize: 10, color: _muted)),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: _softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _muted),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _navy)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 2. VIEW DAFTAR BAHAN BAKU
// ============================================================

class _BahanBakuView extends StatefulWidget {
  const _BahanBakuView();

  @override
  State<_BahanBakuView> createState() => _BahanBakuViewState();
}

class _BahanBakuViewState extends State<_BahanBakuView> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  String _filterStatus = 'aktif';
  String _filterStok = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await StockManagementService.getBahanBaku(
        search: _searchCtrl.text.trim(),
        status: _filterStatus,
        statusStok: _filterStok.isEmpty ? null : _filterStok,
      );
      if (mounted) setState(() => _list = res);
    } catch (e) {
      if (mounted) _snack('Gagal memuat bahan baku: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _danger : _navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(text: item?['nama_bahan_baku'] ?? '');
    final kategoriCtrl = TextEditingController(text: item?['kategori'] ?? 'Bahan Utama');
    final satuanCtrl = TextEditingController(text: item?['satuan'] ?? 'gram');
    final stokCtrl = TextEditingController(text: item?['stok']?.toString() ?? '0');
    final minCtrl = TextEditingController(text: item?['stok_minimum']?.toString() ?? '0');
    final hargaCtrl = TextEditingController(text: item?['harga_beli']?.toString() ?? '0');
    String status = item?['status'] ?? 'aktif';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: Text(
                isEdit ? 'Edit Bahan Baku' : 'Tambah Bahan Baku Baru',
                style: const TextStyle(fontWeight: FontWeight.w800, color: _navy),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: namaCtrl,
                        decoration: const InputDecoration(labelText: 'Nama Bahan Baku *', hintText: 'Contoh: Susu Full Cream, Biji Kopi'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: kategoriCtrl,
                              decoration: const InputDecoration(labelText: 'Kategori', hintText: 'Kopi, Dairy, Sirup, Cup'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: ['gram', 'kg', 'ml', 'liter', 'pcs'].contains(satuanCtrl.text.toLowerCase())
                                  ? satuanCtrl.text.toLowerCase()
                                  : 'gram',
                              decoration: const InputDecoration(labelText: 'Satuan Dasar *'),
                              items: const [
                                DropdownMenuItem(value: 'gram', child: Text('gram (gr)')),
                                DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')),
                                DropdownMenuItem(value: 'ml', child: Text('Mililiter (ml)')),
                                DropdownMenuItem(value: 'liter', child: Text('Liter (l)')),
                                DropdownMenuItem(value: 'pcs', child: Text('Pcs / Buah')),
                              ],
                              onChanged: (v) {
                                if (v != null) satuanCtrl.text = v;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (!isEdit)
                            Expanded(
                              child: TextField(
                                controller: stokCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Stok Awal'),
                              ),
                            ),
                          if (!isEdit) const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: minCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Stok Minimum *'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hargaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Harga Beli per Satuan (Rp)', prefixText: 'Rp '),
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                            DropdownMenuItem(value: 'nonaktif', child: Text('Nonaktif')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDlgState(() => status = v);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white),
                  onPressed: () async {
                    final nama = namaCtrl.text.trim();
                    final satuan = satuanCtrl.text.trim();
                    if (nama.isEmpty || satuan.isEmpty) {
                      _snack('Nama dan satuan bahan baku wajib diisi!', isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      if (isEdit) {
                        await StockManagementService.updateBahanBaku(
                          id: item['id_bahan_baku'],
                          nama: nama,
                          satuan: satuan,
                          kategori: kategoriCtrl.text.trim(),
                          stokMinimum: double.tryParse(minCtrl.text.trim()) ?? 0,
                          hargaBeli: double.tryParse(hargaCtrl.text.trim()) ?? 0,
                          status: status,
                        );
                        _snack('Bahan baku berhasil diperbarui.');
                      } else {
                        await StockManagementService.tambahBahanBaku(
                          nama: nama,
                          satuan: satuan,
                          kategori: kategoriCtrl.text.trim(),
                          stok: double.tryParse(stokCtrl.text.trim()) ?? 0,
                          stokMinimum: double.tryParse(minCtrl.text.trim()) ?? 0,
                          hargaBeli: double.tryParse(hargaCtrl.text.trim()) ?? 0,
                        );
                        _snack('Bahan baku baru berhasil ditambahkan.');
                      }
                      _fetch();
                    } catch (e) {
                      _snack('Gagal menyimpan: $e', isError: true);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Konfirmasi Hapus / Nonaktifkan', style: TextStyle(fontWeight: FontWeight.w800, color: _navy)),
          content: Text('Apakah Anda yakin ingin menghapus atau menonaktifkan bahan "${item['nama_bahan_baku']}"?\n\nJika bahan sudah memiliki riwayat mutasi, sistem akan menonaktifkannya untuk menjaga integritas data.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _danger, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final res = await StockManagementService.deleteBahanBaku(item['id_bahan_baku']);
                  _snack(res['message']?.toString() ?? 'Berhasil memproses.');
                  _fetch();
                } catch (e) {
                  _snack('Gagal: $e', isError: true);
                }
              },
              child: const Text('Hapus / Nonaktifkan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // BAR FILTER DAN TAMBAH
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau kategori bahan...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  ),
                  onSubmitted: (_) => _fetch(),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _filterStatus,
                items: const [
                  DropdownMenuItem(value: 'aktif', child: Text('Status: Aktif')),
                  DropdownMenuItem(value: 'nonaktif', child: Text('Status: Nonaktif')),
                  DropdownMenuItem(value: 'semua', child: Text('Status: Semua')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _filterStatus = v);
                    _fetch();
                  }
                },
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _filterStok,
                items: const [
                  DropdownMenuItem(value: '', child: Text('Stok: Semua')),
                  DropdownMenuItem(value: 'aman', child: Text('Stok: Aman')),
                  DropdownMenuItem(value: 'menipis', child: Text('Stok: Menipis')),
                  DropdownMenuItem(value: 'habis', child: Text('Stok: Habis')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _filterStok = v);
                    _fetch();
                  }
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Bahan Baku', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // LIST DATA
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inbox_rounded, size: 56, color: _muted),
                            const SizedBox(height: 10),
                            const Text('Tidak ada bahan baku ditemukan.', style: TextStyle(color: _muted)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetch, child: const Text('Muat Ulang')),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _softShadow(),
                        ),
                        child: ListView.separated(
                          itemCount: _list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final b = _list[i];
                            final stok = (num.tryParse(b['stok']?.toString() ?? '0')) ?? 0;
                            final min = (num.tryParse(b['stok_minimum']?.toString() ?? '0')) ?? 0;
                            final harga = (num.tryParse(b['harga_beli']?.toString() ?? '0')) ?? 0;
                            final statusStok = b['status_stok']?.toString() ?? 'aman';
                            final isNonaktif = b['status'] == 'nonaktif';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isNonaktif ? _muted.withValues(alpha: 0.2) : _navy.withValues(alpha: 0.1),
                                child: Icon(Icons.local_cafe_rounded, color: isNonaktif ? _muted : _navy),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    b['nama_bahan_baku'] ?? '-',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: isNonaktif ? _muted : _navy,
                                      decoration: isNonaktif ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(4)),
                                    child: Text(b['kategori'] ?? 'Bahan Utama', style: const TextStyle(fontSize: 10, color: _navy, fontWeight: FontWeight.w600)),
                                  ),
                                  if (isNonaktif) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: _muted, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('NONAKTIF', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                'Batas Min: ${_formatNumber(min)} ${b['satuan']}  |  Harga Beli: ${_formatRupiah(harga)}/${b['satuan']}',
                                style: const TextStyle(fontSize: 12, color: _muted),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${_formatNumber(stok)} ${b['satuan']}',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _navy),
                                      ),
                                      const SizedBox(height: 2),
                                      _buildStatusStokChip(statusStok),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: _navy, size: 20),
                                    tooltip: 'Edit Bahan',
                                    onPressed: () => _showFormDialog(item: b),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: _danger, size: 20),
                                    tooltip: 'Hapus / Nonaktifkan',
                                    onPressed: () => _confirmDelete(b),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 3. VIEW STOK MASUK (PEMBELIAN / RESTOCK)
// ============================================================

class _StokMasukView extends StatefulWidget {
  const _StokMasukView({required this.onSuccess});
  final VoidCallback onSuccess;

  @override
  State<_StokMasukView> createState() => _StokMasukViewState();
}

class _StokMasukViewState extends State<_StokMasukView> {
  List<Map<String, dynamic>> _bahanList = [];
  int? _selectedBahanId;
  final TextEditingController _jumlahCtrl = TextEditingController();
  final TextEditingController _satuanCtrl = TextEditingController();
  final TextEditingController _hargaBeliCtrl = TextEditingController();
  final TextEditingController _supplierCtrl = TextEditingController();
  final TextEditingController _catatanCtrl = TextEditingController();
  bool _catatKeKas = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBahan();
  }

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _satuanCtrl.dispose();
    _hargaBeliCtrl.dispose();
    _supplierCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBahan() async {
    try {
      final res = await StockManagementService.getBahanBaku(status: 'aktif');
      if (mounted) {
        setState(() {
          _bahanList = res;
          if (_bahanList.isNotEmpty && _selectedBahanId == null) {
            _selectedBahanId = _bahanList.first['id_bahan_baku'];
            _satuanCtrl.text = _bahanList.first['satuan'] ?? '';
          }
        });
      }
    } catch (_) {}
  }

  void _onBahanChanged(int? id) {
    if (id == null) return;
    final item = _bahanList.firstWhere((b) => b['id_bahan_baku'] == id, orElse: () => {});
    setState(() {
      _selectedBahanId = id;
      _satuanCtrl.text = item['satuan'] ?? '';
      _hargaBeliCtrl.text = (item['harga_beli']?.toString()) ?? '';
    });
  }

  Future<void> _submit() async {
    if (_selectedBahanId == null) {
      _snack('Pilih bahan baku terlebih dahulu.', isError: true);
      return;
    }
    final jumlah = double.tryParse(_jumlahCtrl.text.trim()) ?? 0;
    if (jumlah <= 0) {
      _snack('Jumlah stok masuk harus lebih dari 0.', isError: true);
      return;
    }

    final totalHarga = double.tryParse(_hargaBeliCtrl.text.trim()) ?? 0;

    setState(() => _submitting = true);
    try {
      await StockManagementService.catatStokMasuk(
        idBahanBaku: _selectedBahanId!,
        jumlah: jumlah,
        satuan: _satuanCtrl.text.trim(),
        totalHarga: totalHarga,
        supplier: _supplierCtrl.text.trim(),
        catatan: _catatanCtrl.text.trim(),
        catatKeKas: _catatKeKas,
      );

      _snack('Stok masuk berhasil dicatat!');
      _jumlahCtrl.clear();
      _supplierCtrl.clear();
      _catatanCtrl.clear();
      widget.onSuccess();
    } catch (e) {
      _snack('Gagal mencatat stok masuk: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _danger : _navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _softShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_business_rounded, color: _success, size: 28),
                  SizedBox(width: 10),
                  Text('Pencatatan Stok Masuk (Restock / Pembelian)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _navy)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Data bahan baku yang masuk akan menambah jumlah stok secara otomatis.', style: TextStyle(fontSize: 12, color: _muted)),
              const Divider(height: 28),

              // PILIH BAHAN BAKU
              DropdownButtonFormField<int>(
                value: _selectedBahanId,
                decoration: const InputDecoration(labelText: 'Pilih Bahan Baku *', prefixIcon: Icon(Icons.coffee_rounded)),
                items: _bahanList.map((b) {
                  return DropdownMenuItem<int>(
                    value: b['id_bahan_baku'] as int,
                    child: Text('${b['nama_bahan_baku']} (Stok Saat Ini: ${_formatNumber((num.tryParse(b['stok']?.toString() ?? '0')) ?? 0)} ${b['satuan']})'),
                  );
                }).toList(),
                onChanged: _onBahanChanged,
              ),
              const SizedBox(height: 16),

              // JUMLAH & SATUAN
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _jumlahCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Jumlah Masuk *', hintText: 'Misal: 10, 5, 2000'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _satuanCtrl,
                      decoration: const InputDecoration(labelText: 'Satuan', hintText: 'gram, liter, ml, pcs'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TOTAL HARGA & SUPPLIER
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hargaBeliCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Total Biaya Pembelian (Rp)', prefixText: 'Rp '),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _supplierCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Supplier', hintText: 'Toko Sumber Jaya, dll'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CATATAN
              TextField(
                controller: _catatanCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Catatan / Nomor Faktur', hintText: 'Opsional'),
              ),
              const SizedBox(height: 16),

              // INTEGRASI KEUANGAN / KAS LACI
              CheckboxListTile(
                value: _catatKeKas,
                contentPadding: EdgeInsets.zero,
                activeColor: _navy,
                title: const Text('Catat biaya pembelian ke pengeluaran Kas Laci Shift Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Bila dicentang dan shift kasir sedang buka, pengeluaran kas dicatat otomatis.', style: TextStyle(fontSize: 11, color: _muted)),
                onChanged: (v) => setState(() => _catatKeKas = v ?? false),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(_submitting ? 'Menyimpan...' : 'Simpan Stok Masuk', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 4. VIEW STOK KELUAR MANUAL
// ============================================================

class _StokKeluarView extends StatefulWidget {
  const _StokKeluarView({required this.onSuccess});
  final VoidCallback onSuccess;

  @override
  State<_StokKeluarView> createState() => _StokKeluarViewState();
}

class _StokKeluarViewState extends State<_StokKeluarView> {
  List<Map<String, dynamic>> _bahanList = [];
  int? _selectedBahanId;
  final TextEditingController _jumlahCtrl = TextEditingController();
  final TextEditingController _catatanCtrl = TextEditingController();
  String _alasan = 'rusak';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBahan();
  }

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBahan() async {
    try {
      final res = await StockManagementService.getBahanBaku(status: 'aktif');
      if (mounted) {
        setState(() {
          _bahanList = res;
          if (_bahanList.isNotEmpty && _selectedBahanId == null) {
            _selectedBahanId = _bahanList.first['id_bahan_baku'];
          }
        });
      }
    } catch (_) {}
  }

  Map<String, dynamic>? get _currentBahan {
    if (_selectedBahanId == null) return null;
    return _bahanList.firstWhere((b) => b['id_bahan_baku'] == _selectedBahanId, orElse: () => {});
  }

  Future<void> _submit() async {
    if (_selectedBahanId == null) {
      _snack('Pilih bahan baku terlebih dahulu.', isError: true);
      return;
    }
    final jumlah = double.tryParse(_jumlahCtrl.text.trim()) ?? 0;
    if (jumlah <= 0) {
      _snack('Jumlah stok keluar harus lebih dari 0.', isError: true);
      return;
    }

    final b = _currentBahan;
    final stokAda = (num.tryParse(b?['stok']?.toString() ?? '0')) ?? 0;
    if (jumlah > stokAda) {
      _snack('Jumlah keluar ($_formatNumber(jumlah)) melebihi stok tersedia (${_formatNumber(stokAda)}).', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await StockManagementService.catatStokKeluar(
        idBahanBaku: _selectedBahanId!,
        jumlah: jumlah,
        alasan: _alasan,
        satuan: b?['satuan'],
        catatan: _catatanCtrl.text.trim(),
      );

      _snack('Pengurangan stok berhasil dicatat!');
      _jumlahCtrl.clear();
      _catatanCtrl.clear();
      _loadBahan();
      widget.onSuccess();
    } catch (e) {
      _snack('Gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _danger : _navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _currentBahan;
    final stokAda = (num.tryParse(b?['stok']?.toString() ?? '0')) ?? 0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _softShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.remove_circle_outline_rounded, color: _danger, size: 28),
                  SizedBox(width: 10),
                  Text('Pencatatan Stok Keluar (Manual)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _navy)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Catat pengurangan stok karena bahan rusak, kedaluwarsa, tumpah/terbuang, atau penyesuaian opname.', style: TextStyle(fontSize: 12, color: _muted)),
              const Divider(height: 28),

              // PILIH BAHAN
              DropdownButtonFormField<int>(
                value: _selectedBahanId,
                decoration: const InputDecoration(labelText: 'Pilih Bahan Baku *'),
                items: _bahanList.map((item) {
                  return DropdownMenuItem<int>(
                    value: item['id_bahan_baku'] as int,
                    child: Text('${item['nama_bahan_baku']} (${_formatNumber((num.tryParse(item['stok']?.toString() ?? '0')) ?? 0)} ${item['satuan']})'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedBahanId = v),
              ),
              const SizedBox(height: 12),

              // INFO STOK TERSEDIA
              if (b != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stok Tersedia Saat Ini:', style: TextStyle(fontSize: 12, color: _navy, fontWeight: FontWeight.w600)),
                      Text('${_formatNumber(stokAda)} ${b['satuan']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _navy)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // JUMLAH KELUAR
              TextField(
                controller: _jumlahCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Jumlah Pengurangan *',
                  suffixText: b?['satuan'] ?? '',
                  hintText: 'Misal: 250',
                ),
              ),
              const SizedBox(height: 16),

              // ALASAN PENGURANGAN
              DropdownButtonFormField<String>(
                value: _alasan,
                decoration: const InputDecoration(labelText: 'Alasan Pengurangan *'),
                items: const [
                  DropdownMenuItem(value: 'rusak', child: Text('Bahan Baku Rusak')),
                  DropdownMenuItem(value: 'kedaluwarsa', child: Text('Bahan Baku Kedaluwarsa')),
                  DropdownMenuItem(value: 'terbuang', child: Text('Bahan Tumpah / Terbuang (Waste)')),
                  DropdownMenuItem(value: 'penyesuaian', child: Text('Penyesuaian Stok (Stock Opname)')),
                  DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _alasan = v);
                },
              ),
              const SizedBox(height: 16),

              // CATATAN
              TextField(
                controller: _catatanCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Keterangan Tambahan', hintText: 'Sebutkan rincian kondisi bahan'),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.remove_circle_rounded),
                  label: Text(_submitting ? 'Menyimpan...' : 'Simpan Pengurangan Stok', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 5. VIEW KELOLA RESEP PRODUK
// ============================================================

class _ResepProdukView extends StatefulWidget {
  const _ResepProdukView();

  @override
  State<_ResepProdukView> createState() => _ResepProdukViewState();
}

class _ResepProdukViewState extends State<_ResepProdukView> {
  List<Map<String, dynamic>> _resepList = [];
  List<Map<String, dynamic>> _bahanList = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final resProduk = await StockManagementService.getResepProduk(search: _search.isEmpty ? null : _search);
      final resBahan = await StockManagementService.getBahanBaku(status: 'aktif');
      if (mounted) {
        setState(() {
          _resepList = resProduk;
          _bahanList = resBahan;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _bukaDialogResep(Map<String, dynamic> produk) {
    final resepItems = ((produk['resep_produk'] as List?) ?? [])
        .map((r) => Map<String, dynamic>.from(r))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: _navy),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Resep: ${produk['nama_produk']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _navy)),
                        const Text('Bahan baku ini akan otomatis berkurang saat produk terjual di Kasir.', style: TextStyle(fontSize: 11, color: _muted)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (resepItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text('Belum ada komposisi bahan baku untuk produk ini.', style: TextStyle(color: _muted)),
                        )
                      else
                        ...resepItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final idBahan = item['id_bahan_baku'];
                          final bahanMatch = _bahanList.firstWhere(
                            (b) => b['id_bahan_baku'] == idBahan,
                            orElse: () => item['bahan_baku'] ?? {},
                          );
                          final namaBahan = bahanMatch['nama_bahan_baku'] ?? 'Bahan';
                          final satuan = item['satuan'] ?? bahanMatch['satuan'] ?? 'gram';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _background.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(namaBahan, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _navy)),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    initialValue: item['jumlah']?.toString() ?? '1',
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Jumlah',
                                      suffixText: satuan,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    onChanged: (val) {
                                      resepItems[idx]['jumlah'] = double.tryParse(val) ?? 0;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: _danger, size: 20),
                                  onPressed: () {
                                    setDlgState(() => resepItems.removeAt(idx));
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _navy,
                          side: const BorderSide(color: _navy),
                        ),
                        onPressed: () {
                          // Pilih bahan baru
                          _tambahBahanKeResep(resepItems, setDlgState);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('+ Tambah Bahan Baku ke Resep'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final payloadItems = resepItems.map((r) {
                        return {
                          'id_bahan_baku': r['id_bahan_baku'],
                          'jumlah': r['jumlah'] ?? 1,
                          'satuan': r['satuan'] ?? 'gram',
                        };
                      }).toList();

                      await StockManagementService.simpanResepProduk(
                        idProduk: produk['id_produk'],
                        items: payloadItems,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Resep produk berhasil disimpan!'), backgroundColor: _navy),
                        );
                        _fetch();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal menyimpan resep: $e'), backgroundColor: _danger),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan Resep'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _tambahBahanKeResep(List<Map<String, dynamic>> resepItems, StateSetter setDlgState) {
    int? selectedBahan;
    final jumlahCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx2) {
        return StatefulBuilder(
          builder: (context, setSubState) {
            return AlertDialog(
              title: const Text('Pilih Bahan Tambahan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _navy)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedBahan,
                    hint: const Text('Pilih Bahan Baku'),
                    items: _bahanList.map((b) {
                      return DropdownMenuItem<int>(
                        value: b['id_bahan_baku'] as int,
                        child: Text('${b['nama_bahan_baku']} (${b['satuan']})'),
                      );
                    }).toList(),
                    onChanged: (v) => setSubState(() => selectedBahan = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: jumlahCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Jumlah Pemakaian per Cup / Porsi'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white),
                  onPressed: () {
                    if (selectedBahan == null) return;
                    final bahanObj = _bahanList.firstWhere((b) => b['id_bahan_baku'] == selectedBahan);
                    setDlgState(() {
                      resepItems.add({
                        'id_bahan_baku': selectedBahan,
                        'jumlah': double.tryParse(jumlahCtrl.text.trim()) ?? 1,
                        'satuan': bahanObj['satuan'] ?? 'gram',
                        'bahan_baku': bahanObj,
                      });
                    });
                    Navigator.pop(ctx2);
                  },
                  child: const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama produk untuk mengatur resep...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  ),
                  onChanged: (v) {
                    _search = v;
                    _fetch();
                  },
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                onPressed: _fetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Segarkan'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _resepList.isEmpty
                    ? const Center(child: Text('Tidak ada produk ditemukan.', style: TextStyle(color: _muted)))
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _softShadow(),
                        ),
                        child: ListView.separated(
                          itemCount: _resepList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = _resepList[i];
                            final resep = (p['resep_produk'] as List?) ?? [];
                            final adaResep = resep.isNotEmpty;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: adaResep ? _success.withValues(alpha: 0.15) : _muted.withValues(alpha: 0.15),
                                child: Icon(Icons.coffee_maker_rounded, color: adaResep ? _success : _muted),
                              ),
                              title: Row(
                                children: [
                                  Text(p['nama_produk'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _navy)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: adaResep ? _success.withValues(alpha: 0.1) : _warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      adaResep ? '${resep.length} Komposisi' : 'Belum Ada Resep',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: adaResep ? _success : _warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                adaResep
                                    ? resep.map((r) => '${r['bahan_baku']?['nama_bahan_baku'] ?? 'Bahan'} (${_formatNumber((num.tryParse(r['jumlah']?.toString() ?? '0')) ?? 0)} ${r['satuan']})').join(', ')
                                    : 'Klik Atur Resep untuk menambahkan bahan baku yang dikurangi otomatis.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: _muted),
                              ),
                              trailing: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: adaResep ? _accentBlue : _navy,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _bukaDialogResep(p),
                                icon: const Icon(Icons.tune_rounded, size: 16),
                                label: Text(adaResep ? 'Ubah Resep' : 'Atur Resep', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 6. VIEW RIWAYAT STOK (MUTASI BUKU BESAR)
// ============================================================

class _RiwayatStokView extends StatefulWidget {
  const _RiwayatStokView();

  @override
  State<_RiwayatStokView> createState() => _RiwayatStokViewState();
}

class _RiwayatStokViewState extends State<_RiwayatStokView> {
  List<Map<String, dynamic>> _riwayat = [];
  bool _loading = true;
  String _filterJenis = 'semua';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await StockManagementService.getRiwayatStok(
        jenis: _filterJenis == 'semua' ? null : _filterJenis,
        search: _searchCtrl.text.trim(),
      );
      if (mounted) setState(() => _riwayat = res);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat pergerakan stok...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                  ),
                  onSubmitted: (_) => _fetch(),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterJenis,
                items: const [
                  DropdownMenuItem(value: 'semua', child: Text('Semua Jenis')),
                  DropdownMenuItem(value: 'masuk', child: Text('Stok Masuk')),
                  DropdownMenuItem(value: 'keluar', child: Text('Stok Keluar')),
                  DropdownMenuItem(value: 'penjualan', child: Text('Penjualan Kasir')),
                  DropdownMenuItem(value: 'penyesuaian', child: Text('Penyesuaian')),
                  DropdownMenuItem(value: 'batal_penjualan', child: Text('Batal Penjualan')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _filterJenis = v);
                    _fetch();
                  }
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                onPressed: _fetch,
                icon: const Icon(Icons.refresh),
                label: const Text('Segarkan'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _riwayat.isEmpty
                    ? const Center(child: Text('Belum ada riwayat stok tercatat.', style: TextStyle(color: _muted)))
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _softShadow(),
                        ),
                        child: ListView.separated(
                          itemCount: _riwayat.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final r = _riwayat[i];
                            final namaBahan = r['bahan_baku']?['nama_bahan_baku'] ?? 'Bahan';
                            final satuan = r['bahan_baku']?['satuan'] ?? '';
                            final jenis = r['jenis']?.toString() ?? '-';
                            final jumlah = (num.tryParse(r['jumlah']?.toString() ?? '0')) ?? 0;
                            final sebelum = (num.tryParse(r['stok_sebelum']?.toString() ?? '0')) ?? 0;
                            final setelah = (num.tryParse(r['stok_setelah']?.toString() ?? '0')) ?? 0;
                            final ket = r['keterangan'] ?? '-';
                            final waktu = r['created_at']?.toString() ?? '';
                            final user = r['pengguna']?['nama'] ?? 'Sistem';

                            return ListTile(
                              leading: _buildJenisBadge(jenis),
                              title: Row(
                                children: [
                                  Text(namaBahan, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _navy)),
                                  const SizedBox(width: 8),
                                  Text('(${_formatNumber(jumlah)} $satuan)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _colorByJenis(jenis))),
                                ],
                              ),
                              subtitle: Text(
                                '$ket  |  Oleh: $user  |  ${waktu.length >= 16 ? waktu.substring(0, 16).replaceAll('T', ' ') : waktu}',
                                style: const TextStyle(fontSize: 11, color: _muted),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  '${_formatNumber(sebelum)} âžª ${_formatNumber(setelah)} $satuan',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navy),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 7. VIEW LAPORAN STOK
// ============================================================

class _LaporanStokView extends StatefulWidget {
  const _LaporanStokView();

  @override
  State<_LaporanStokView> createState() => _LaporanStokViewState();
}

class _LaporanStokViewState extends State<_LaporanStokView> {
  Map<String, dynamic> _laporan = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await StockManagementService.getLaporanStok();
      if (mounted) setState(() => _laporan = res);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final ringkasan = (_laporan['ringkasan'] as Map<String, dynamic>?) ?? {};
    final rekap = (_laporan['rekap_bahan'] as List?) ?? [];

    final totalNilai = (num.tryParse(ringkasan['total_nilai_persediaan']?.toString() ?? '0')) ?? 0;
    final totalBiaya = (num.tryParse(ringkasan['total_biaya_pembelian']?.toString() ?? '0')) ?? 0;
    final totalBahan = ringkasan['total_bahan_baku'] ?? 0;
    final totalMenipis = ringkasan['total_bahan_menipis'] ?? 0;
    final totalHabis = ringkasan['total_bahan_habis'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SUMMARY
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _buildReportCard('Total Nilai Persediaan', _formatRupiah(totalNilai), Icons.account_balance_rounded, _navy),
              _buildReportCard('Total Biaya Pembelian', _formatRupiah(totalBiaya), Icons.shopping_bag_rounded, _accentBlue),
              _buildReportCard('Total Bahan Aktif', '$totalBahan jenis', Icons.inventory_rounded, _navyLight),
              _buildReportCard('Bahan Menipis/Habis', '$totalMenipis menipis / $totalHabis habis', Icons.warning_rounded, (totalMenipis + totalHabis > 0) ? _danger : _success),
            ],
          ),
          const SizedBox(height: 24),

          // TABEL REKAP PERSADAAN
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _softShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rekap Persediaan & Mutasi Bahan Baku', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _navy)),
                  ],
                ),
                const Divider(),
                if (rekap.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('Tidak ada data rekap persediaan.', style: TextStyle(color: _muted))),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(_background.withValues(alpha: 0.5)),
                      columns: const [
                        DataColumn(label: Text('Nama Bahan', style: TextStyle(fontWeight: FontWeight.w800, color: _navy))),
                        DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.w800, color: _navy))),
                        DataColumn(label: Text('Stok Tersedia', style: TextStyle(fontWeight: FontWeight.w800, color: _navy))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800, color: _navy))),
                        DataColumn(label: Text('Harga Beli', style: TextStyle(fontWeight: FontWeight.w800, color: _navy))),
                        DataColumn(label: Text('Nilai Aset', style: TextStyle(fontWeight: FontWeight.w800, color: _navy))),
                        DataColumn(label: Text('Total Masuk', style: TextStyle(fontWeight: FontWeight.w800, color: _navy))),
                        DataColumn(label: Text('Total Keluar', style: TextStyle(fontWeight: FontWeight.w800, color: _navy))),
                        DataColumn(label: Text('Pemakaian Kasir', style: TextStyle(fontWeight: FontWeight.w800, color: _navy))),
                      ],
                      rows: rekap.map((b) {
                        final stok = (num.tryParse(b['stok_tersedia']?.toString() ?? '0')) ?? 0;
                        final harga = (num.tryParse(b['harga_beli']?.toString() ?? '0')) ?? 0;
                        final nilai = (num.tryParse(b['nilai_persediaan']?.toString() ?? '0')) ?? 0;
                        final masuk = (num.tryParse(b['total_masuk']?.toString() ?? '0')) ?? 0;
                        final keluar = (num.tryParse(b['total_keluar']?.toString() ?? '0')) ?? 0;
                        final pemakaian = (num.tryParse(b['total_pemakaian']?.toString() ?? '0')) ?? 0;
                        final status = b['status_stok']?.toString() ?? 'aman';

                        return DataRow(
                          cells: [
                            DataCell(Text(b['nama_bahan_baku'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, color: _navy))),
                            DataCell(Text(b['kategori'] ?? '-')),
                            DataCell(Text('${_formatNumber(stok)} ${b['satuan']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                            DataCell(_buildStatusStokChip(status)),
                            DataCell(Text(_formatRupiah(harga))),
                            DataCell(Text(_formatRupiah(nilai), style: const TextStyle(fontWeight: FontWeight.w700, color: _accentBlue))),
                            DataCell(Text('+${_formatNumber(masuk)} ${b['satuan']}', style: const TextStyle(color: _success))),
                            DataCell(Text('-${_formatNumber(keluar)} ${b['satuan']}', style: const TextStyle(color: _danger))),
                            DataCell(Text('-${_formatNumber(pemakaian)} ${b['satuan']}', style: const TextStyle(color: _accentBlue))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: _softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _navy)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
        ],
      ),
    );
  }
}

// ============================================================
// HELPER BADGES & CHIPS
// ============================================================

Widget _buildStatusStokChip(String status) {
  Color c;
  String text;
  IconData icon;

  switch (status) {
    case 'habis':
      c = _danger;
      text = 'Habis';
      icon = Icons.cancel_rounded;
      break;
    case 'menipis':
      c = _warning;
      text = 'Menipis';
      icon = Icons.warning_amber_rounded;
      break;
    default:
      c = _success;
      text = 'Aman';
      icon = Icons.check_circle_rounded;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: c.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
      ],
    ),
  );
}

Widget _buildJenisBadge(String jenis) {
  Color c = _colorByJenis(jenis);
  IconData icon;
  String text;

  switch (jenis) {
    case 'masuk':
      icon = Icons.arrow_downward_rounded;
      text = 'Masuk';
      break;
    case 'keluar':
      icon = Icons.arrow_upward_rounded;
      text = 'Keluar';
      break;
    case 'penjualan':
      icon = Icons.point_of_sale_rounded;
      text = 'Jual';
      break;
    case 'batal_penjualan':
      icon = Icons.undo_rounded;
      text = 'Batal';
      break;
    default:
      icon = Icons.tune_rounded;
      text = 'Sesuaikan';
  }

  return Container(
    width: 60,
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: c.withValues(alpha: 0.3)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: c)),
      ],
    ),
  );
}

Color _colorByJenis(String jenis) {
  switch (jenis) {
    case 'masuk':
      return _success;
    case 'keluar':
      return _danger;
    case 'penjualan':
      return _accentBlue;
    case 'batal_penjualan':
      return Colors.purple;
    default:
      return _warning;
  }
}
