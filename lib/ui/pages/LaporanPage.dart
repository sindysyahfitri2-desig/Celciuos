import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/features/reports/application/celcious_report_export.dart';
import 'package:kasir_celcious_coffe/features/reports/application/report_service.dart';
import '../../data/transaction_store.dart';

/// Halaman Riwayat Operasional Harian untuk Kasir (khusus hari ini, read-only,
/// tanpa grafik rekap omzet dan tanpa ekspor PDF/Excel — ekspor & rekap penuh
/// hanya tersedia pada akun Owner sesuai prinsip ISO 27001 Least Privilege).
class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key, this.namaKasir = 'Kasir'});

  final String namaKasir;

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final Color navy = const Color(0xff082640);
  final Color background = const Color(0xffdce9f4);
  final Color qrisColor = const Color(0xff00875a);
  final Color cashColor = const Color(0xff28628a);

  // 0 = Riwayat Transaksi, 1 = Riwayat Kas Laci
  int tabDipilih = 0;

  // Filter metode pembayaran ringan untuk memudahkan kasir cek pesanan hari ini
  String? pembayaranDipilih;

  List<Map<String, String>> dataTransaksi = [];
  List<Map<String, String>> dataKasLaci = [];
  bool _memuat = false;

  @override
  void initState() {
    super.initState();
    TransactionStore.transactions.addListener(_muatDariLokalDanServer);
    TransactionStore.cashDrawerEntries.addListener(_muatDariLokalDanServer);

    final initial =
        ReportService.lastFetchedSnapshot ??
        ReportService.load(cashierFallback: widget.namaKasir);
    dataTransaksi = _filterHariIni(initial.transactionRows);
    dataKasLaci = _filterHariIni(initial.drawerRows);
    _muat();
  }

  @override
  void dispose() {
    TransactionStore.transactions.removeListener(_muatDariLokalDanServer);
    TransactionStore.cashDrawerEntries.removeListener(_muatDariLokalDanServer);
    super.dispose();
  }

  void _muatDariLokalDanServer() {
    if (!mounted) return;
    final local = ReportService.load(cashierFallback: widget.namaKasir);
    setState(() {
      if (dataTransaksi.isEmpty) {
        dataTransaksi = _filterHariIni(local.transactionRows);
      }
      if (dataKasLaci.isEmpty) {
        dataKasLaci = _filterHariIni(local.drawerRows);
      }
    });
    _muat();
  }

  bool _adalahHariIni(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  List<Map<String, String>> _filterHariIni(List<Map<String, String>> rows) {
    return rows.where((item) => _adalahHariIni(item['tanggal'])).toList();
  }

  Future<void> _muat() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (mounted) setState(() => _memuat = true);
    try {
      final snapshot = await ReportService.fetch(
        dari: today,
        sampai: today,
        cashierFallback: widget.namaKasir,
      );
      if (!mounted) return;
      setState(() {
        dataTransaksi = _filterHariIni(snapshot.transactionRows);
        dataKasLaci = _filterHariIni(snapshot.drawerRows);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat riwayat hari ini: ${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  String _formatTanggal(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  List<Map<String, String>> get _transaksiTerfilter {
    if (pembayaranDipilih == null) return dataTransaksi;
    return dataTransaksi
        .where(
          (item) =>
              item['pembayaran']?.toLowerCase() ==
              pembayaranDipilih!.toLowerCase(),
        )
        .toList();
  }

  String get _tanggalHariIniText =>
      CelciousReportExport.formatTanggalIndonesia(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: LayoutBuilder(
        builder: (context, ukuran) {
          final lebar = ukuran.maxWidth;
          return Column(
            children: [
              _header(lebar),
              Expanded(
                child: Stack(
                  children: [
                    _isiRiwayat(lebar),
                    if (_memuat)
                      LinearProgressIndicator(
                        minHeight: 3,
                        color: navy,
                        backgroundColor: Colors.white70,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(double lebar) {
    final hp = lebar < 550;
    return Container(
      width: double.infinity,
      height: 50,
      color: navy,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Riwayat',
            style: TextStyle(
              color: Colors.white,
              fontSize: hp ? 18 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Muat ulang riwayat hari ini',
              onPressed: _memuat ? null : _muat,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _isiRiwayat(double lebar) {
    final hp = lebar < 600;
    final tablet = lebar >= 600 && lebar < 950;
    final padding = hp ? 10.0 : (tablet ? 18.0 : 22.0);

    return RefreshIndicator(
      onRefresh: _muat,
      color: navy,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(hp ? 14 : 16),
          ),
          child: Column(
            children: [
              _tabRiwayat(lebar),
              if (tabDipilih == 0)
                _kontenRiwayatTransaksi(lebar)
              else
                _kontenRiwayatKasLaci(lebar),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabRiwayat(double lebar) {
    final hp = lebar < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: hp ? 10 : 0, top: hp ? 8 : 0),
      color: background,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _tabButton(
              title: 'Riwayat Transaksi',
              aktif: tabDipilih == 0,
              onTap: () {
                setState(() {
                  tabDipilih = 0;
                  pembayaranDipilih = null;
                });
              },
            ),
            const SizedBox(width: 8),
            _tabButton(
              title: 'Riwayat Kas Laci',
              aktif: tabDipilih == 1,
              onTap: () {
                setState(() {
                  tabDipilih = 1;
                  pembayaranDipilih = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required bool aktif,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: aktif ? Colors.white : const Color(0xffa2a9b1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: navy,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _barInfoHariIni({
    required bool hp,
    required int totalBaris,
    required String satuan,
    bool tampilFilterMetode = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: hp ? 12 : 16,
        vertical: hp ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xfff1f6fb),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffd2e2f0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.today_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivitas Hari Ini • $_tanggalHariIniText',
                    style: TextStyle(
                      color: navy,
                      fontSize: hp ? 12.5 : 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalBaris $satuan tercatat hari ini',
                    style: const TextStyle(
                      color: Color(0xff5b7186),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (tampilFilterMetode)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chipMetode('Semua', null),
                _chipMetode('Cash', 'Cash'),
                _chipMetode('QRIS', 'QRIS'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _chipMetode(String label, String? value) {
    final aktif = pembayaranDipilih == value;
    return InkWell(
      onTap: () => setState(() => pembayaranDipilih = value),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: aktif ? navy : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: aktif ? navy : navy.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: aktif ? Colors.white : navy,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _catatanHakAksesOwner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff7fafd),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffdbe7f3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: navy.withValues(alpha: 0.72),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Halaman ini hanya menampilkan riwayat operasional hari ini. Rekap lengkap & unduh PDF/Excel hanya tersedia di akun Owner.',
              style: TextStyle(
                color: Color(0xff566c80),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kontenRiwayatTransaksi(double lebar) {
    final hp = lebar < 600;
    final tablet = lebar >= 600 && lebar < 950;
    final rows = _transaksiTerfilter;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        hp ? 10 : (tablet ? 16 : 18),
        hp ? 12 : 16,
        hp ? 10 : (tablet ? 16 : 18),
        hp ? 14 : 20,
      ),
      child: Column(
        children: [
          _barInfoHariIni(
            hp: hp,
            totalBaris: rows.length,
            satuan: 'transaksi selesai',
            tampilFilterMetode: true,
          ),
          const SizedBox(height: 16),
          _containerTabel(child: _tabelRiwayatTransaksi(lebar, rows)),
          const SizedBox(height: 14),
          _catatanHakAksesOwner(),
        ],
      ),
    );
  }

  Widget _kontenRiwayatKasLaci(double lebar) {
    final hp = lebar < 600;
    final tablet = lebar >= 600 && lebar < 950;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        hp ? 10 : (tablet ? 16 : 18),
        hp ? 12 : 16,
        hp ? 10 : (tablet ? 16 : 18),
        hp ? 14 : 20,
      ),
      child: Column(
        children: [
          _barInfoHariIni(
            hp: hp,
            totalBaris: dataKasLaci.length,
            satuan: 'catatan kas laci',
          ),
          const SizedBox(height: 16),
          _containerTabel(child: _tabelKasLaci(lebar, dataKasLaci)),
          const SizedBox(height: 14),
          _catatanHakAksesOwner(),
        ],
      ),
    );
  }

  Widget _containerTabel({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe1e8ef)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }

  Widget _tampilanDataKosong({required bool kasLaci}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 44),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                kasLaci
                    ? Icons.point_of_sale_outlined
                    : Icons.receipt_long_outlined,
                size: 36,
                color: navy.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              kasLaci
                  ? 'Belum ada catatan kas laci hari ini'
                  : 'Belum ada riwayat transaksi hari ini',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              kasLaci
                  ? 'Kas awal, penjualan cash, penambahan, atau pengeluaran laci hari ini akan otomatis muncul di sini.'
                  : 'Transaksi yang sudah dibayar / diselesaikan pada $_tanggalHariIniText akan muncul di sini.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff71808d), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabelRiwayatTransaksi(double lebar, List<Map<String, String>> rows) {
    final hp = lebar < 600;
    if (rows.isEmpty) {
      return _tampilanDataKosong(kasLaci: false);
    }

    if (hp) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: rows.map((data) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfff9fbfd),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffe5e9ed)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['id'] ?? '-',
                          style: TextStyle(
                            color: navy,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _badgePembayaran(data['pembayaran'] ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _infoRow('Jam', data['jam'] ?? '-'),
                  _infoRow('Nama Kasir', data['kasir'] ?? '-'),
                  _infoRow('Jumlah Item', data['jumlah'] ?? '0'),
                  _infoRow('Total Harga', 'Rp ${data['total'] ?? '0'}', bold: true),
                  if (_adaBuktiPembayaran(data))
                    Align(
                      alignment: Alignment.centerRight,
                      child: _tombolLihatBukti(data),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: lebar < 1000 ? 18 : 28,
              horizontalMargin: 14,
              headingRowHeight: 44,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 68,
              headingRowColor: WidgetStateProperty.all(navy),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: TextStyle(color: navy, fontSize: 12),
              columns: const [
                DataColumn(label: Text('ID Pemesanan')),
                DataColumn(label: Text('Jam')),
                DataColumn(label: Text('Nama Kasir')),
                DataColumn(label: Text('Pembayaran')),
                DataColumn(label: Text('Jumlah Pemesanan')),
                DataColumn(label: Text('Total Harga')),
                DataColumn(label: Text('Status')),
              ],
              rows: rows.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text(data['id'] ?? '-')),
                    DataCell(Text(data['jam'] ?? '-')),
                    DataCell(Text(data['kasir'] ?? '-')),
                    DataCell(_badgePembayaran(data['pembayaran'] ?? '-')),
                    DataCell(Text(data['jumlah'] ?? '0')),
                    DataCell(
                      Text(
                        'Rp ${data['total'] ?? '0'}',
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: qrisColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          data['status'] ?? 'Lunas',
                          style: TextStyle(
                            color: qrisColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _tabelKasLaci(double lebar, List<Map<String, String>> rows) {
    final hp = lebar < 600;
    if (rows.isEmpty) {
      return _tampilanDataKosong(kasLaci: true);
    }

    if (hp) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: rows.map((data) {
            final masuk = data['jenis'] == 'masuk';
            return InkWell(
              onTap: () => _detailKas(data),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xfff9fbfd),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: masuk
                        ? const Color(0xff00875a).withValues(alpha: 0.25)
                        : const Color(0xffd85c5c).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['kasir'] ?? '-',
                            style: TextStyle(
                              color: navy,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          data['jam'] ?? '--:--',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _infoRow('Tanggal', _formatTanggal(data['tanggal'])),
                    _infoRow('Nominal', data['nominal'] ?? '-', bold: true),
                    _infoRow('Keterangan', data['keterangan'] ?? '-'),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: lebar < 1000 ? 18 : 28,
              horizontalMargin: 14,
              headingRowHeight: 44,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 68,
              headingRowColor: WidgetStateProperty.all(navy),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: TextStyle(color: navy, fontSize: 12),
              columns: const [
                DataColumn(label: Text('Tanggal')),
                DataColumn(label: Text('Jam')),
                DataColumn(label: Text('Nama Kasir')),
                DataColumn(label: Text('Nominal')),
                DataColumn(label: Text('Keterangan')),
              ],
              rows: rows.map((data) {
                final masuk = data['jenis'] == 'masuk';
                return DataRow(
                  cells: [
                    DataCell(Text(_formatTanggal(data['tanggal']))),
                    DataCell(Text(data['jam'] ?? '--:--')),
                    DataCell(Text(data['kasir'] ?? '-')),
                    DataCell(
                      Text(
                        data['nominal'] ?? '-',
                        style: TextStyle(
                          color: masuk
                              ? const Color(0xff00875a)
                              : const Color(0xffd85c5c),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(Text(data['keterangan'] ?? '-')),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _badgePembayaran(String metode) {
    final isQris = metode.toLowerCase().contains('qris');
    final color = isQris ? qrisColor : cashColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        metode,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: navy,
                fontSize: 11,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _adaBuktiPembayaran(Map<String, String> data) {
    return data['buktiPembayaranPath']?.isNotEmpty == true ||
        data['buktiPembayaranBase64']?.isNotEmpty == true;
  }

  Widget _tombolLihatBukti(Map<String, String> data) {
    if (!_adaBuktiPembayaran(data)) return const Text('-');
    return TextButton(
      onPressed: () => _lihatBuktiPembayaran(data),
      child: const Text('Lihat Bukti'),
    );
  }

  void _lihatBuktiPembayaran(Map<String, String> data) {
    final path = data['buktiPembayaranPath'] ?? '';
    final base64Image = data['buktiPembayaranBase64'] ?? '';
    final image = path.isNotEmpty
        ? (kIsWeb
            ? const Center(
                child: Text(
                  'Foto lokal hanya tersedia di aplikasi perangkat.',
                ),
              )
            : Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Center(
                  child: Text('Berkas bukti foto tidak ditemukan.'),
                ),
              ))
        : base64Image.isNotEmpty
            ? Image.memory(base64Decode(base64Image), fit: BoxFit.contain)
            : const Center(child: Text('Bukti foto tidak ditemukan.'));

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bukti Pembayaran QRIS'),
        content: SizedBox(width: 440, height: 420, child: image),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _detailKas(Map<String, String> data) {
    final masuk = data['jenis'] == 'masuk';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Detail Catatan Kas Laci',
          style: TextStyle(color: navy, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Tanggal', _formatTanggal(data['tanggal'])),
            _infoRow('Jam', data['jam'] ?? '--:--'),
            _infoRow('Kasir', data['kasir'] ?? '-'),
            _infoRow('Jenis', masuk ? 'Kas Masuk' : 'Kas Keluar'),
            _infoRow('Nominal', data['nominal'] ?? '-', bold: true),
            _infoRow('Keterangan', data['keterangan'] ?? '-'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
