import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/features/owner/application/stock_management_service.dart';

// ============================================================
// PALET WARNA & TEMA VIBRANT (NAVY, BIRU MUDA & AKSEN BERWARNA)
// ============================================================

const Color _navy = Color(0xFF082640);
const Color _navyMid = Color(0xFF123F6B);
const Color _skyBlue = Color(0xFF2B84CA);
const Color _lightBlue = Color(0xFFA8CBE9);
const Color _softBlue = Color(0xFFEAF3FB);
const Color _background = Color(0xFFDCE9F4);
const Color _muted = Color(0xFF5D748B);
const Color _border = Color(0xFFC8DCEE);

const Color _emerald = Color(0xFF0F9D75);
const Color _teal = Color(0xFF0E8FA3);
const Color _amber = Color(0xFFEA8C00);
const Color _coral = Color(0xFFDC4C5B);
const Color _indigo = Color(0xFF585CE5);
const Color _purple = Color(0xFF8B5CF6);

const LinearGradient _navyGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_navy, _navyMid, Color(0xFF1D609B)],
);

const LinearGradient _emeraldGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0B8A67), _emerald, Color(0xFF20B589)],
);

const LinearGradient _coralGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFC43B4B), _coral, Color(0xFFEC6B76)],
);

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

List<BoxShadow> _softShadow({Color color = _navy, double alpha = 0.10}) => [
  BoxShadow(
    color: color.withValues(alpha: alpha),
    blurRadius: 14,
    offset: const Offset(0, 6),
  ),
];

InputDecoration _styledInput({
  required String label,
  String? hint,
  IconData? icon,
  String? prefixText,
  String? suffixText,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    suffixText: suffixText,
    labelStyle: const TextStyle(
      color: _navy,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: const TextStyle(color: Color(0xFF8CA4BA), fontSize: 12.5),
    prefixIcon: icon == null ? null : Icon(icon, color: _skyBlue, size: 20),
    filled: true,
    fillColor: const Color(0xFFF3F8FD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _skyBlue, width: 1.6),
    ),
  );
}

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
    {'title': 'Ringkasan', 'icon': Icons.dashboard_rounded},
    {'title': 'Bahan Baku', 'icon': Icons.inventory_2_rounded},
    {'title': 'Stok Masuk', 'icon': Icons.add_box_rounded},
    {'title': 'Stok Keluar', 'icon': Icons.indeterminate_check_box_rounded},
    {'title': 'Resep Produk', 'icon': Icons.menu_book_rounded},
    {'title': 'Riwayat Stok', 'icon': Icons.history_rounded},
    {'title': 'Laporan', 'icon': Icons.analytics_rounded},
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
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isPhone),
            _buildTabBar(isPhone),
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

  Widget _buildHeader(bool isPhone) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isPhone ? 16 : 24,
        isPhone ? 14 : 18,
        isPhone ? 16 : 24,
        isPhone ? 14 : 18,
      ),
      decoration: BoxDecoration(
        gradient: _navyGradient,
        boxShadow: _softShadow(alpha: 0.22),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -12,
            top: -18,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lightBlue.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            right: 54,
            bottom: -24,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _skyBlue.withValues(alpha: 0.18),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isPhone ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_lightBlue, _skyBlue],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.warehouse_rounded,
                  color: Colors.white,
                  size: isPhone ? 24 : 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _lightBlue.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _lightBlue.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Text(
                        'INVENTORI CELCIOUS COFFEE',
                        style: TextStyle(
                          color: Color(0xFFDCE9F4),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Manajemen Stok & Bahan Baku',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isPhone ? 17 : 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (!isPhone) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'Pantau persediaan, resep otomatis, mutasi masuk/keluar, dan laporan stok secara real-time',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC2DBF2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isPhone) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 10 : 18,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border, width: 1.2)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(24),
        indicator: BoxDecoration(
          gradient: _navyGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _softShadow(color: _navy, alpha: 0.22),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _navy,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        tabs: _tabs.map((tab) {
          return Tab(
            height: 38,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab['icon'] as IconData, size: 17),
                  const SizedBox(width: 7),
                  Text(tab['title'] as String),
                ],
              ),
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
      return const Center(child: CircularProgressIndicator(color: _navy));
    }
    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _softShadow(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: _coral, size: 48),
              const SizedBox(height: 10),
              Text(
                'Gagal memuat ringkasan stok:\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _fetch,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final totalBahan = _data['total_jenis_bahan'] ?? 0;
    final stokAman = _data['stok_aman'] ?? 0;
    final stokMenipis = _data['stok_menipis'] ?? 0;
    final stokHabis = _data['stok_habis'] ?? 0;
    final nilaiPersediaan =
        (num.tryParse(_data['nilai_persediaan']?.toString() ?? '0')) ?? 0;
    final mutasiHariIni = _data['mutasi_hari_ini'] ?? 0;
    final peringatan = (_data['peringatan'] as List?) ?? [];
    final mutasiTerakhir = (_data['mutasi_terakhir'] as List?) ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isPhone = width < 600;
        final pad = isPhone ? 14.0 : 22.0;
        final availW = width - pad * 2;
        final kpiCols = width < 520 ? 2 : (width < 980 ? 3 : 6);
        const gap = 12.0;
        final kpiWidth = (availW - gap * (kpiCols - 1)) / kpiCols;

        return RefreshIndicator(
          color: _navy,
          onRefresh: _fetch,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI CARDS BERWARNA
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    _buildKpiCard(
                      width: kpiWidth,
                      label: 'Total Bahan Baku',
                      value: '$totalBahan jenis',
                      icon: Icons.category_rounded,
                      primary: _navy,
                      lightBg: const Color(0xFFE5EFF8),
                    ),
                    _buildKpiCard(
                      width: kpiWidth,
                      label: 'Nilai Persediaan',
                      value: _formatRupiah(nilaiPersediaan),
                      icon: Icons.account_balance_wallet_rounded,
                      primary: _skyBlue,
                      lightBg: const Color(0xFFE3F2FD),
                    ),
                    _buildKpiCard(
                      width: kpiWidth,
                      label: 'Stok Aman',
                      value: '$stokAman',
                      icon: Icons.check_circle_rounded,
                      primary: _emerald,
                      lightBg: const Color(0xFFE2F7F0),
                      onTap: () => widget.onPindahTab(1),
                    ),
                    _buildKpiCard(
                      width: kpiWidth,
                      label: 'Stok Menipis',
                      value: '$stokMenipis',
                      icon: Icons.warning_amber_rounded,
                      primary: _amber,
                      lightBg: const Color(0xFFFFF5E0),
                      onTap: () => widget.onPindahTab(1),
                    ),
                    _buildKpiCard(
                      width: kpiWidth,
                      label: 'Stok Habis',
                      value: '$stokHabis',
                      icon: Icons.cancel_rounded,
                      primary: _coral,
                      lightBg: const Color(0xFFFDEAEB),
                      onTap: () => widget.onPindahTab(1),
                    ),
                    _buildKpiCard(
                      width: kpiWidth,
                      label: 'Mutasi Hari Ini',
                      value: '$mutasiHariIni',
                      icon: Icons.swap_horiz_rounded,
                      primary: _indigo,
                      lightBg: const Color(0xFFECECFD),
                      onTap: () => widget.onPindahTab(5),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // QUICK ACTIONS GRADIENT
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionBanner(
                        title: 'Catat Stok Masuk',
                        subtitle: 'Restock / pembelian bahan',
                        icon: Icons.add_shopping_cart_rounded,
                        gradient: _emeraldGradient,
                        onTap: () => widget.onPindahTab(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionBanner(
                        title: 'Catat Stok Keluar',
                        subtitle: 'Rusak, waste, atau opname',
                        icon: Icons.remove_circle_outline_rounded,
                        gradient: _coralGradient,
                        onTap: () => widget.onPindahTab(3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // PERINGATAN STOK MENIPIS / HABIS
                if (peringatan.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _amber.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: _softShadow(color: _amber, alpha: 0.12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFF3D6), Color(0xFFFFE5B4)],
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _amber,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Peringatan Stok Menipis & Habis (${peringatan.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: _navy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: peringatan.map((item) {
                              final status = item['status']?.toString();
                              final isHabis = status == 'habis';
                              final color = isHabis ? _coral : _amber;
                              final stok =
                                  (num.tryParse(item['stok']?.toString() ?? '0')) ??
                                      0;
                              final min = (num.tryParse(
                                    item['stok_minimum']?.toString() ?? '0',
                                  )) ??
                                  0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isHabis
                                          ? Icons.cancel_rounded
                                          : Icons.info_rounded,
                                      color: color,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${item['nama_bahan_baku']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: _navy,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                          Text(
                                            'Tersisa ${_formatNumber(stok)} ${item['satuan']}  •  Minimum ${_formatNumber(min)} ${item['satuan']}',
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isHabis ? 'HABIS' : 'MENIPIS',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _navy,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => widget.onPindahTab(2),
                                      child: const Text(
                                        'Restock',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // AKTIVITAS STOK TERKINI
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                    boxShadow: _softShadow(),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: _softBlue,
                          border: Border(bottom: BorderSide(color: _border)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: _skyBlue,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Aktivitas Stok Terkini',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: _navy,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () => widget.onPindahTab(5),
                              icon: const Text(
                                'Semua Riwayat',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              label: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: _skyBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mutasiTerakhir.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Text(
                              'Belum ada aktivitas mutasi stok.',
                              style: TextStyle(color: _muted),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: mutasiTerakhir.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: _softBlue),
                          itemBuilder: (_, idx) {
                            final m = mutasiTerakhir[idx];
                            final jenis = m['jenis']?.toString() ?? '-';
                            final jumlah =
                                (num.tryParse(m['jumlah']?.toString() ?? '0')) ??
                                    0;
                            final namaBahan =
                                m['bahan_baku']?['nama_bahan_baku'] ?? 'Bahan';
                            final satuan = m['bahan_baku']?['satuan'] ?? '';
                            final ket = m['keterangan'] ?? '-';
                            final waktu = m['created_at']?.toString() ?? '';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: _buildJenisBadge(jenis),
                              title: Text(
                                '$namaBahan • ${_formatNumber(jumlah)} $satuan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: _navy,
                                ),
                              ),
                              subtitle: Text(
                                ket,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: _muted,
                                ),
                              ),
                              trailing: Text(
                                waktu.length >= 16
                                    ? waktu.substring(0, 16).replaceAll('T', ' ')
                                    : waktu,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: _muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required Color primary,
    required Color lightBg,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withValues(alpha: 0.22)),
              boxShadow: _softShadow(color: primary, alpha: 0.10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  width: double.infinity,
                  color: primary,
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: lightBg,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(icon, color: primary, size: 20),
                          ),
                          if (onTap != null)
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: primary.withValues(alpha: 0.65),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _navy,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: _muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionBanner extends StatelessWidget {
  const _QuickActionBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _softShadow(alpha: 0.20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
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
        backgroundColor: isError ? _coral : _navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final namaCtrl = TextEditingController(
      text: item?['nama_bahan_baku'] ?? '',
    );
    final kategoriCtrl = TextEditingController(
      text: item?['kategori'] ?? 'Bahan Utama',
    );
    final satuanCtrl = TextEditingController(text: item?['satuan'] ?? 'gram');
    final stokCtrl = TextEditingController(
      text: item?['stok']?.toString() ?? '0',
    );
    final minCtrl = TextEditingController(
      text: item?['stok_minimum']?.toString() ?? '0',
    );
    final hargaCtrl = TextEditingController(
      text: item?['harga_beli']?.toString() ?? '0',
    );
    String status = item?['status'] ?? 'aktif';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: const BoxDecoration(gradient: _navyGradient),
                      child: Row(
                        children: [
                          Icon(
                            isEdit
                                ? Icons.edit_note_rounded
                                : Icons.add_box_rounded,
                            color: _lightBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isEdit
                                  ? 'Edit Bahan Baku'
                                  : 'Tambah Bahan Baku Baru',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: namaCtrl,
                              decoration: _styledInput(
                                label: 'Nama Bahan Baku *',
                                hint: 'Contoh: Susu Full Cream, Biji Kopi',
                                icon: Icons.local_cafe_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: kategoriCtrl,
                                    decoration: _styledInput(
                                      label: 'Kategori',
                                      hint: 'Kopi, Dairy, Sirup',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: ['gram', 'kg', 'ml', 'liter', 'pcs']
                                            .contains(
                                              satuanCtrl.text.toLowerCase(),
                                            )
                                        ? satuanCtrl.text.toLowerCase()
                                        : 'gram',
                                    decoration: _styledInput(
                                      label: 'Satuan Dasar *',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'gram',
                                        child: Text('gram (gr)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'kg',
                                        child: Text('Kilogram (kg)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'ml',
                                        child: Text('Mililiter (ml)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'liter',
                                        child: Text('Liter (l)'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'pcs',
                                        child: Text('Pcs / Buah'),
                                      ),
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
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: _styledInput(
                                        label: 'Stok Awal',
                                      ),
                                    ),
                                  ),
                                if (!isEdit) const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: minCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: _styledInput(
                                      label: 'Stok Minimum *',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: hargaCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _styledInput(
                                label: 'Harga Beli per Satuan',
                                prefixText: 'Rp ',
                                icon: Icons.payments_outlined,
                              ),
                            ),
                            if (isEdit) ...[
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: status,
                                decoration: _styledInput(label: 'Status'),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'aktif',
                                    child: Text('Aktif'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'nonaktif',
                                    child: Text('Nonaktif'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) setDlgState(() => status = v);
                                },
                              ),
                            ],
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _navy,
                                      side: const BorderSide(color: _border),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Batal'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _navy,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final nama = namaCtrl.text.trim();
                                      final satuan = satuanCtrl.text.trim();
                                      if (nama.isEmpty || satuan.isEmpty) {
                                        _snack(
                                          'Nama dan satuan bahan baku wajib diisi!',
                                          isError: true,
                                        );
                                        return;
                                      }
                                      Navigator.pop(ctx);
                                      try {
                                        if (isEdit) {
                                          await StockManagementService
                                              .updateBahanBaku(
                                            id: item['id_bahan_baku'],
                                            nama: nama,
                                            satuan: satuan,
                                            kategori: kategoriCtrl.text.trim(),
                                            stokMinimum: double.tryParse(
                                                  minCtrl.text.trim(),
                                                ) ??
                                                0,
                                            hargaBeli: double.tryParse(
                                                  hargaCtrl.text.trim(),
                                                ) ??
                                                0,
                                            status: status,
                                          );
                                          _snack(
                                            'Bahan baku berhasil diperbarui.',
                                          );
                                        } else {
                                          await StockManagementService
                                              .tambahBahanBaku(
                                            nama: nama,
                                            satuan: satuan,
                                            kategori: kategoriCtrl.text.trim(),
                                            stok: double.tryParse(
                                                  stokCtrl.text.trim(),
                                                ) ??
                                                0,
                                            stokMinimum: double.tryParse(
                                                  minCtrl.text.trim(),
                                                ) ??
                                                0,
                                            hargaBeli: double.tryParse(
                                                  hargaCtrl.text.trim(),
                                                ) ??
                                                0,
                                          );
                                          _snack(
                                            'Bahan baku baru berhasil ditambahkan.',
                                          );
                                        }
                                        _fetch();
                                      } catch (e) {
                                        _snack(
                                          'Gagal menyimpan: $e',
                                          isError: true,
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.save_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Simpan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _coral),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hapus / Nonaktifkan',
                  style: TextStyle(fontWeight: FontWeight.w800, color: _navy),
                ),
              ),
            ],
          ),
          content: Text(
            'Yakin ingin menghapus atau menonaktifkan "${item['nama_bahan_baku']}"?\n\n'
            'Jika bahan sudah punya riwayat mutasi, sistem akan menonaktifkannya secara otomatis.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final res = await StockManagementService.deleteBahanBaku(
                    item['id_bahan_baku'],
                  );
                  _snack(res['message']?.toString() ?? 'Berhasil memproses.');
                  _fetch();
                } catch (e) {
                  _snack('Gagal: $e', isError: true);
                }
              },
              child: const Text('Lanjutkan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.sizeOf(context).width < 650;

    return Padding(
      padding: EdgeInsets.all(isPhone ? 14 : 20),
      child: Column(
        children: [
          // BAR FILTER RESPONSIF
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
              boxShadow: _softShadow(),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: isPhone ? double.infinity : 260,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: _styledInput(
                      label: 'Cari bahan baku',
                      hint: 'Nama atau kategori...',
                      icon: Icons.search_rounded,
                    ),
                    onSubmitted: (_) => _fetch(),
                  ),
                ),
                _filterDropdown(
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                    DropdownMenuItem(
                      value: 'nonaktif',
                      child: Text('Nonaktif'),
                    ),
                    DropdownMenuItem(
                      value: 'semua',
                      child: Text('Semua Status'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _filterStatus = v);
                      _fetch();
                    }
                  },
                ),
                _filterDropdown(
                  value: _filterStok,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Semua Stok')),
                    DropdownMenuItem(value: 'aman', child: Text('Stok Aman')),
                    DropdownMenuItem(
                      value: 'menipis',
                      child: Text('Stok Menipis'),
                    ),
                    DropdownMenuItem(value: 'habis', child: Text('Stok Habis')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _filterStok = v);
                      _fetch();
                    }
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _showFormDialog(),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text(
                    'Tambah Bahan',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // DAFTAR BAHAN BAKU
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _navy))
                : _list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inbox_rounded,
                              size: 56,
                              color: _muted,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tidak ada bahan baku ditemukan.',
                              style: TextStyle(
                                color: _muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _navy,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _fetch,
                              child: const Text('Muat Ulang'),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                          boxShadow: _softShadow(),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          itemCount: _list.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: _softBlue),
                          itemBuilder: (context, i) {
                            final b = _list[i];
                            final stok =
                                (num.tryParse(b['stok']?.toString() ?? '0')) ??
                                    0;
                            final min = (num.tryParse(
                                  b['stok_minimum']?.toString() ?? '0',
                                )) ??
                                0;
                            final harga = (num.tryParse(
                                  b['harga_beli']?.toString() ?? '0',
                                )) ??
                                0;
                            final statusStok =
                                b['status_stok']?.toString() ?? 'aman';
                            final isNonaktif = b['status'] == 'nonaktif';

                            final statusColor = statusStok == 'habis'
                                ? _coral
                                : statusStok == 'menipis'
                                    ? _amber
                                    : _emerald;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isNonaktif
                                      ? _muted.withValues(alpha: 0.16)
                                      : statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  Icons.local_cafe_rounded,
                                  color: isNonaktif ? _muted : statusColor,
                                ),
                              ),
                              title: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    b['nama_bahan_baku'] ?? '-',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: isNonaktif ? _muted : _navy,
                                      decoration: isNonaktif
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _softBlue,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _lightBlue),
                                    ),
                                    child: Text(
                                      b['kategori'] ?? 'Bahan Utama',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: _navy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (isNonaktif)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _muted,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'NONAKTIF',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Min: ${_formatNumber(min)} ${b['satuan']}  •  Harga: ${_formatRupiah(harga)}/${b['satuan']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _muted,
                                  ),
                                ),
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
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w900,
                                          color: _navy,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      _buildStatusStokChip(statusStok),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      color: _skyBlue,
                                      size: 20,
                                    ),
                                    tooltip: 'Edit Bahan',
                                    onPressed: () => _showFormDialog(item: b),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: _coral,
                                      size: 20,
                                    ),
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
    final item = _bahanList.firstWhere(
      (b) => b['id_bahan_baku'] == id,
      orElse: () => {},
    );
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
        backgroundColor: isError ? _coral : _emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _emerald.withValues(alpha: 0.30)),
              boxShadow: _softShadow(color: _emerald, alpha: 0.14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(gradient: _emeraldGradient),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0x33FFFFFF),
                        child: Icon(
                          Icons.add_business_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pencatatan Stok Masuk',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Restock atau pembelian bahan baku akan menambah stok otomatis',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFE0FFF5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedBahanId,
                        isExpanded: true,
                        decoration: _styledInput(
                          label: 'Pilih Bahan Baku *',
                          icon: Icons.coffee_rounded,
                        ),
                        items: _bahanList.map((b) {
                          final stokVal =
                              (num.tryParse(b['stok']?.toString() ?? '0')) ?? 0;
                          return DropdownMenuItem<int>(
                            value: b['id_bahan_baku'] as int,
                            child: Text(
                              '${b['nama_bahan_baku']} (Stok: ${_formatNumber(stokVal)} ${b['satuan']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _onBahanChanged,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _jumlahCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _styledInput(
                                label: 'Jumlah Masuk *',
                                hint: 'Misal: 10, 5, 2000',
                                icon: Icons.add_chart_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _satuanCtrl,
                              decoration: _styledInput(
                                label: 'Satuan',
                                hint: 'gram, ml, pcs',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _hargaBeliCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _styledInput(
                                label: 'Total Biaya (Rp)',
                                prefixText: 'Rp ',
                                icon: Icons.payments_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _supplierCtrl,
                              decoration: _styledInput(
                                label: 'Nama Supplier',
                                hint: 'Toko Sumber Jaya',
                                icon: Icons.storefront_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _catatanCtrl,
                        maxLines: 2,
                        decoration: _styledInput(
                          label: 'Catatan / Nomor Faktur',
                          hint: 'Opsional',
                          icon: Icons.notes_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: _softBlue,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _lightBlue),
                        ),
                        child: CheckboxListTile(
                          value: _catatKeKas,
                          activeColor: _navy,
                          title: const Text(
                            'Catat ke pengeluaran Kas Laci Shift Aktif',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _navy,
                            ),
                          ),
                          subtitle: const Text(
                            'Bila shift kasir sedang buka, pengeluaran kas tercatat otomatis.',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                          onChanged: (v) =>
                              setState(() => _catatKeKas = v ?? false),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _emerald,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_rounded),
                          label: Text(
                            _submitting
                                ? 'Menyimpan...'
                                : 'Simpan Stok Masuk',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    return _bahanList.firstWhere(
      (b) => b['id_bahan_baku'] == _selectedBahanId,
      orElse: () => {},
    );
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
      _snack(
        'Jumlah keluar (${_formatNumber(jumlah)}) melebihi stok tersedia (${_formatNumber(stokAda)}).',
        isError: true,
      );
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
        backgroundColor: isError ? _coral : _navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _currentBahan;
    final stokAda = (num.tryParse(b?['stok']?.toString() ?? '0')) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _coral.withValues(alpha: 0.30)),
              boxShadow: _softShadow(color: _coral, alpha: 0.14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(gradient: _coralGradient),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0x33FFFFFF),
                        child: Icon(
                          Icons.remove_circle_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pencatatan Stok Keluar (Manual)',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Catat bahan rusak, kedaluwarsa, tumpah, atau stock opname',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFFE5E8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedBahanId,
                        isExpanded: true,
                        decoration: _styledInput(
                          label: 'Pilih Bahan Baku *',
                          icon: Icons.inventory_2_outlined,
                        ),
                        items: _bahanList.map((item) {
                          final stokVal =
                              (num.tryParse(item['stok']?.toString() ?? '0')) ??
                                  0;
                          return DropdownMenuItem<int>(
                            value: item['id_bahan_baku'] as int,
                            child: Text(
                              '${item['nama_bahan_baku']} (${_formatNumber(stokVal)} ${item['satuan']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedBahanId = v),
                      ),
                      const SizedBox(height: 12),
                      if (b != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: _softBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _lightBlue),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.inventory_rounded,
                                    size: 18,
                                    color: _skyBlue,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Stok Tersedia Saat Ini',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: _navy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_formatNumber(stokAda)} ${b['satuan'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: _navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _jumlahCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _styledInput(
                          label: 'Jumlah Pengurangan *',
                          hint: 'Misal: 250',
                          suffixText: b?['satuan'] ?? '',
                          icon: Icons.trending_down_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _alasan,
                        decoration: _styledInput(
                          label: 'Alasan Pengurangan *',
                          icon: Icons.report_problem_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'rusak',
                            child: Text('Bahan Baku Rusak'),
                          ),
                          DropdownMenuItem(
                            value: 'kedaluwarsa',
                            child: Text('Bahan Baku Kedaluwarsa'),
                          ),
                          DropdownMenuItem(
                            value: 'terbuang',
                            child: Text('Bahan Tumpah / Terbuang (Waste)'),
                          ),
                          DropdownMenuItem(
                            value: 'penyesuaian',
                            child: Text('Penyesuaian Stok (Stock Opname)'),
                          ),
                          DropdownMenuItem(
                            value: 'lainnya',
                            child: Text('Lainnya'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _alasan = v);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _catatanCtrl,
                        maxLines: 2,
                        decoration: _styledInput(
                          label: 'Keterangan Tambahan',
                          hint: 'Sebutkan rincian kondisi bahan',
                          icon: Icons.notes_rounded,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _coral,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.remove_circle_rounded),
                          label: Text(
                            _submitting
                                ? 'Menyimpan...'
                                : 'Simpan Pengurangan Stok',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      final resProduk = await StockManagementService.getResepProduk(
        search: _search.isEmpty ? null : _search,
      );
      final resBahan = await StockManagementService.getBahanBaku(
        status: 'aktif',
      );
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
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(gradient: _navyGradient),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            color: _lightBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resep: ${produk['nama_produk']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const Text(
                                  'Stok bahan berkurang otomatis saat menu terjual di Kasir',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFC7E0F7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (resepItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text(
                                  'Belum ada komposisi bahan baku untuk produk ini.',
                                  style: TextStyle(color: _muted),
                                ),
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
                                final namaBahan =
                                    bahanMatch['nama_bahan_baku'] ?? 'Bahan';
                                final satuan = item['satuan'] ??
                                    bahanMatch['satuan'] ??
                                    'gram';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _softBlue,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _lightBlue),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          namaBahan,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            color: _navy,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 100,
                                        child: TextFormField(
                                          initialValue:
                                              item['jumlah']?.toString() ?? '1',
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText: 'Qty',
                                            suffixText: satuan,
                                            filled: true,
                                            fillColor: Colors.white,
                                            isDense: true,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            resepItems[idx]['jumlah'] =
                                                double.tryParse(val) ?? 0;
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: _coral,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setDlgState(
                                            () => resepItems.removeAt(idx),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _navy,
                                side: const BorderSide(color: _skyBlue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () =>
                                  _tambahBahanKeResep(resepItems, setDlgState),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text(
                                'Tambah Bahan Baku ke Resep',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Batal'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _navy,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
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

                                        await StockManagementService
                                            .simpanResepProduk(
                                          idProduk: produk['id_produk'],
                                          items: payloadItems,
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Resep produk berhasil disimpan!',
                                              ),
                                              backgroundColor: _emerald,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          _fetch();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Gagal menyimpan resep: $e',
                                              ),
                                              backgroundColor: _coral,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.save_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Simpan Resep',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _tambahBahanKeResep(
    List<Map<String, dynamic>> resepItems,
    StateSetter setDlgState,
  ) {
    int? selectedBahan;
    final jumlahCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx2) {
        return StatefulBuilder(
          builder: (context, setSubState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Pilih Bahan Tambahan',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _navy,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedBahan,
                    isExpanded: true,
                    decoration: _styledInput(label: 'Pilih Bahan Baku'),
                    items: _bahanList.map((b) {
                      return DropdownMenuItem<int>(
                        value: b['id_bahan_baku'] as int,
                        child: Text(
                          '${b['nama_bahan_baku']} (${b['satuan']})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setSubState(() => selectedBahan = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: jumlahCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _styledInput(
                      label: 'Jumlah Pemakaian / Porsi',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx2),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (selectedBahan == null) return;
                    final bahanObj = _bahanList.firstWhere(
                      (b) => b['id_bahan_baku'] == selectedBahan,
                    );
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
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: EdgeInsets.all(isPhone ? 14 : 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
              boxShadow: _softShadow(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: _styledInput(
                      label: 'Cari produk',
                      hint: 'Cari nama menu untuk atur resep...',
                      icon: Icons.search_rounded,
                    ),
                    onChanged: (v) {
                      _search = v;
                      _fetch();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isPhone ? 12 : 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _fetch,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(isPhone ? '' : 'Segarkan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _navy))
                : _resepList.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada produk ditemukan.',
                          style: TextStyle(color: _muted),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                          boxShadow: _softShadow(),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          itemCount: _resepList.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: _softBlue),
                          itemBuilder: (context, i) {
                            final p = _resepList[i];
                            final resep = (p['resep_produk'] as List?) ?? [];
                            final adaResep = resep.isNotEmpty;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: adaResep
                                      ? _emerald.withValues(alpha: 0.14)
                                      : _amber.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  Icons.coffee_maker_rounded,
                                  color: adaResep ? _emerald : _amber,
                                ),
                              ),
                              title: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    p['nama_produk'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: _navy,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: adaResep
                                          ? _emerald.withValues(alpha: 0.12)
                                          : _amber.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      adaResep
                                          ? '${resep.length} Komposisi'
                                          : 'Belum Ada Resep',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: adaResep ? _emerald : _amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  adaResep
                                      ? resep
                                          .map(
                                            (r) =>
                                                '${r['bahan_baku']?['nama_bahan_baku'] ?? 'Bahan'} (${_formatNumber((num.tryParse(r['jumlah']?.toString() ?? '0')) ?? 0)} ${r['satuan']})',
                                          )
                                          .join(', ')
                                      : 'Klik Atur Resep untuk menambahkan bahan baku.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: _muted,
                                  ),
                                ),
                              ),
                              trailing: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: adaResep ? _skyBlue : _navy,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => _bukaDialogResep(p),
                                icon: const Icon(Icons.tune_rounded, size: 16),
                                label: Text(
                                  adaResep ? 'Ubah' : 'Atur',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
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
    final isPhone = MediaQuery.sizeOf(context).width < 650;

    return Padding(
      padding: EdgeInsets.all(isPhone ? 14 : 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
              boxShadow: _softShadow(),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: isPhone ? double.infinity : 280,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: _styledInput(
                      label: 'Cari riwayat mutasi',
                      hint: 'Nama bahan atau keterangan...',
                      icon: Icons.search_rounded,
                    ),
                    onSubmitted: (_) => _fetch(),
                  ),
                ),
                _filterDropdown(
                  value: _filterJenis,
                  items: const [
                    DropdownMenuItem(value: 'semua', child: Text('Semua Jenis')),
                    DropdownMenuItem(value: 'masuk', child: Text('Stok Masuk')),
                    DropdownMenuItem(
                      value: 'keluar',
                      child: Text('Stok Keluar'),
                    ),
                    DropdownMenuItem(
                      value: 'penjualan',
                      child: Text('Penjualan Kasir'),
                    ),
                    DropdownMenuItem(
                      value: 'penyesuaian',
                      child: Text('Penyesuaian'),
                    ),
                    DropdownMenuItem(
                      value: 'batal_penjualan',
                      child: Text('Batal Penjualan'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _filterJenis = v);
                      _fetch();
                    }
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _fetch,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Segarkan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _navy))
                : _riwayat.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada riwayat stok tercatat.',
                          style: TextStyle(color: _muted),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                          boxShadow: _softShadow(),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          itemCount: _riwayat.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: _softBlue),
                          itemBuilder: (context, i) {
                            final r = _riwayat[i];
                            final namaBahan =
                                r['bahan_baku']?['nama_bahan_baku'] ?? 'Bahan';
                            final satuan = r['bahan_baku']?['satuan'] ?? '';
                            final jenis = r['jenis']?.toString() ?? '-';
                            final jumlah =
                                (num.tryParse(r['jumlah']?.toString() ?? '0')) ??
                                    0;
                            final sebelum = (num.tryParse(
                                  r['stok_sebelum']?.toString() ?? '0',
                                )) ??
                                0;
                            final setelah = (num.tryParse(
                                  r['stok_setelah']?.toString() ?? '0',
                                )) ??
                                0;
                            final ket = r['keterangan'] ?? '-';
                            final waktu = r['created_at']?.toString() ?? '';
                            final user = r['pengguna']?['nama'] ?? 'Sistem';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: _buildJenisBadge(jenis),
                              title: Wrap(
                                spacing: 8,
                                children: [
                                  Text(
                                    namaBahan,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: _navy,
                                    ),
                                  ),
                                  Text(
                                    '(${_formatNumber(jumlah)} $satuan)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: _colorByJenis(jenis),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  '$ket  •  Oleh: $user  •  ${waktu.length >= 16 ? waktu.substring(0, 16).replaceAll('T', ' ') : waktu}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: _muted,
                                  ),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _softBlue,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _lightBlue),
                                ),
                                child: Text(
                                  '${_formatNumber(sebelum)} → ${_formatNumber(setelah)} $satuan',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _navy,
                                  ),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _navy));
    }

    final ringkasan = (_laporan['ringkasan'] as Map<String, dynamic>?) ?? {};
    final rekap = (_laporan['rekap_bahan'] as List?) ?? [];

    final totalNilai =
        (num.tryParse(ringkasan['total_nilai_persediaan']?.toString() ?? '0')) ??
            0;
    final totalBiaya =
        (num.tryParse(ringkasan['total_biaya_pembelian']?.toString() ?? '0')) ??
            0;
    final totalBahan = ringkasan['total_bahan_baku'] ?? 0;
    final totalMenipis = ringkasan['total_bahan_menipis'] ?? 0;
    final totalHabis = ringkasan['total_bahan_habis'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isPhone = width < 600;
        final pad = isPhone ? 14.0 : 20.0;
        final availW = width - pad * 2;
        final cols = width < 640 ? 2 : 4;
        const gap = 12.0;
        final cardW = (availW - gap * (cols - 1)) / cols;

        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KARTU RINGKASAN LAPORAN BERWARNA
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _buildReportCard(
                    width: cardW,
                    label: 'Total Nilai Persediaan',
                    value: _formatRupiah(totalNilai),
                    icon: Icons.account_balance_rounded,
                    color: _navy,
                    lightBg: const Color(0xFFE5EFF8),
                  ),
                  _buildReportCard(
                    width: cardW,
                    label: 'Total Biaya Pembelian',
                    value: _formatRupiah(totalBiaya),
                    icon: Icons.shopping_bag_rounded,
                    color: _skyBlue,
                    lightBg: const Color(0xFFE3F2FD),
                  ),
                  _buildReportCard(
                    width: cardW,
                    label: 'Total Bahan Aktif',
                    value: '$totalBahan jenis',
                    icon: Icons.inventory_rounded,
                    color: _teal,
                    lightBg: const Color(0xFFE1F6F8),
                  ),
                  _buildReportCard(
                    width: cardW,
                    label: 'Menipis / Habis',
                    value: '$totalMenipis / $totalHabis',
                    icon: Icons.warning_rounded,
                    color: (totalMenipis + totalHabis > 0) ? _coral : _emerald,
                    lightBg: (totalMenipis + totalHabis > 0)
                        ? const Color(0xFFFDEAEB)
                        : const Color(0xFFE2F7F0),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // TABEL REKAP PERSEDIAAN
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                  boxShadow: _softShadow(),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(gradient: _navyGradient),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.table_chart_rounded,
                                color: _lightBlue,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Rekap Persediaan & Mutasi Bahan Baku',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: 'Muat Ulang',
                            onPressed: _fetch,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rekap.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text(
                            'Tidak ada data rekap persediaan.',
                            style: TextStyle(color: _muted),
                          ),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(_softBlue),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Nama Bahan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Kategori',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Stok Tersedia',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Harga Beli',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Nilai Aset',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Total Masuk',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Total Keluar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Pemakaian Kasir',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                            ),
                          ],
                          rows: List.generate(rekap.length, (idx) {
                            final b = rekap[idx];
                            final stok = (num.tryParse(
                                  b['stok_tersedia']?.toString() ?? '0',
                                )) ??
                                0;
                            final harga = (num.tryParse(
                                  b['harga_beli']?.toString() ?? '0',
                                )) ??
                                0;
                            final nilai = (num.tryParse(
                                  b['nilai_persediaan']?.toString() ?? '0',
                                )) ??
                                0;
                            final masuk = (num.tryParse(
                                  b['total_masuk']?.toString() ?? '0',
                                )) ??
                                0;
                            final keluar = (num.tryParse(
                                  b['total_keluar']?.toString() ?? '0',
                                )) ??
                                0;
                            final pemakaian = (num.tryParse(
                                  b['total_pemakaian']?.toString() ?? '0',
                                )) ??
                                0;
                            final status =
                                b['status_stok']?.toString() ?? 'aman';

                            return DataRow(
                              color: WidgetStateProperty.all(
                                idx.isEven
                                    ? Colors.white
                                    : const Color(0xFFF6FAFE),
                              ),
                              cells: [
                                DataCell(
                                  Text(
                                    b['nama_bahan_baku'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _navy,
                                    ),
                                  ),
                                ),
                                DataCell(Text(b['kategori'] ?? '-')),
                                DataCell(
                                  Text(
                                    '${_formatNumber(stok)} ${b['satuan']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _navy,
                                    ),
                                  ),
                                ),
                                DataCell(_buildStatusStokChip(status)),
                                DataCell(Text(_formatRupiah(harga))),
                                DataCell(
                                  Text(
                                    _formatRupiah(nilai),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _skyBlue,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '+${_formatNumber(masuk)} ${b['satuan']}',
                                    style: const TextStyle(
                                      color: _emerald,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '-${_formatNumber(keluar)} ${b['satuan']}',
                                    style: const TextStyle(
                                      color: _coral,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '-${_formatNumber(pemakaian)} ${b['satuan']}',
                                    style: const TextStyle(
                                      color: _indigo,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportCard({
    required double width,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color lightBg,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        boxShadow: _softShadow(color: color, alpha: 0.10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 5, color: color),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: _navy,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPER DROPDOWN, BADGES & CHIPS
// ============================================================

Widget _filterDropdown({
  required String value,
  required List<DropdownMenuItem<String>> items,
  required ValueChanged<String?> onChanged,
}) {
  return Container(
    height: 46,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: _softBlue,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _lightBlue),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _navy),
        style: const TextStyle(
          color: _navy,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}

Widget _buildStatusStokChip(String status) {
  Color c;
  String text;
  IconData icon;

  switch (status) {
    case 'habis':
      c = _coral;
      text = 'Habis';
      icon = Icons.cancel_rounded;
      break;
    case 'menipis':
      c = _amber;
      text = 'Menipis';
      icon = Icons.warning_amber_rounded;
      break;
    default:
      c = _emerald;
      text = 'Aman';
      icon = Icons.check_circle_rounded;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c),
        ),
      ],
    ),
  );
}

Widget _buildJenisBadge(String jenis) {
  final c = _colorByJenis(jenis);
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
      text = 'Opname';
  }

  return Container(
    width: 58,
    padding: const EdgeInsets.symmetric(vertical: 5),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: c.withValues(alpha: 0.32)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: c),
        const SizedBox(height: 1),
        Text(
          text,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: c),
        ),
      ],
    ),
  );
}

Color _colorByJenis(String jenis) {
  switch (jenis) {
    case 'masuk':
      return _emerald;
    case 'keluar':
      return _coral;
    case 'penjualan':
      return _skyBlue;
    case 'batal_penjualan':
      return _purple;
    default:
      return _amber;
  }
}
