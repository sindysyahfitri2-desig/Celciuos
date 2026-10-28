import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/transaction_store.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_saver/file_saver.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({
    super.key,
    this.namaKasir = 'Kasir',
    this.onShiftClosed,
  });

  final String namaKasir;
  final VoidCallback? onShiftClosed;

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  // ============================================================
  // WARNA
  // ============================================================

  final Color navy = const Color(0xff082640);
  final Color background = const Color(0xffdce9f4);

  final Color qrisColor = const Color(0xff00875a);
  final Color cashColor = const Color(0xff28628a);

  // ============================================================
  // TAB
  // ============================================================

  int tabDipilih = 0;

  // 0 = Laporan Keuangan
  // 1 = Laporan Kas Laci

  // ============================================================
  // FILTER
  // ============================================================

  String tanggal = "Semua";
  String bulan = "September";
  String tahun = "2026";
  bool filterDiterapkan = false;
  String shiftDipilih = 'Semua Shift';

  final Map<String, int> nomorBulan = const {
    'Januari': 1,
    'Februari': 2,
    'Maret': 3,
    'April': 4,
    'Mei': 5,
    'Juni': 6,
    'Juli': 7,
    'Agustus': 8,
    'September': 9,
    'Oktober': 10,
    'November': 11,
    'Desember': 12,
  };

  // ============================================================
  // PEMBAYARAN YANG DIPILIH DI CHART
  // ============================================================

  String? pembayaranDipilih;

  // ============================================================
  // DATA LAPORAN KEUANGAN
  // ============================================================

  List<Map<String, String>> dataLaporan = [];

  // ============================================================
  // DATA KAS LACI
  //
  // NANTI BAGIAN INI BISA DIAMBIL DARI TRANSAKSI KASIR
  // ============================================================

  List<Map<String, String>> dataKasLaci = [];

  // ============================================================
  // KAS AWAL DAN KAS SAAT INI
  // ============================================================

  double kasAwal = TransactionStore.shiftOpeningCash.value;
  double kasSaatIni = TransactionStore.shiftOpeningCash.value;

  @override
  void initState() {
    super.initState();
    _muatTransaksi();
    TransactionStore.transactions.addListener(_muatTransaksi);
    TransactionStore.unfinishedOrders.addListener(_muatTransaksi);
    TransactionStore.shiftOpeningCash.addListener(_muatTransaksi);
    TransactionStore.shiftHistory.addListener(_muatTransaksi);
    TransactionStore.activeShift.addListener(_muatTransaksi);
    TransactionStore.cashDrawerEntries.addListener(_muatTransaksi);
  }

  @override
  void dispose() {
    TransactionStore.transactions.removeListener(_muatTransaksi);
    TransactionStore.unfinishedOrders.removeListener(_muatTransaksi);
    TransactionStore.shiftOpeningCash.removeListener(_muatTransaksi);
    TransactionStore.shiftHistory.removeListener(_muatTransaksi);
    TransactionStore.activeShift.removeListener(_muatTransaksi);
    TransactionStore.cashDrawerEntries.removeListener(_muatTransaksi);
    super.dispose();
  }

  void _muatTransaksi() {
    final unfinishedById = <String, Map<String, dynamic>>{};
    for (final order in TransactionStore.unfinishedOrders.value) {
      final id = order['id']?.toString();
      if (id != null && id.isNotEmpty) unfinishedById[id] = order;
    }
    final transaksiById = <String, Map<String, dynamic>>{};
    final transaksiTanpaId = <Map<String, dynamic>>[];
    for (final item in TransactionStore.transactions.value) {
      final id = item['id']?.toString();
      final unfinished = id == null ? null : unfinishedById[id];
      if (unfinished != null) {
        if (!_isPaid(unfinished)) continue;
        transaksiById[id!] = {...item, ...unfinished};
        continue;
      }
      if (id == null || id.isEmpty) {
        transaksiTanpaId.add(item);
      } else {
        transaksiById.putIfAbsent(id, () => item);
      }
    }
    for (final entry in unfinishedById.entries) {
      if (_isPaid(entry.value)) {
        transaksiById.putIfAbsent(entry.key, () => entry.value);
      }
    }
    final transaksi = [...transaksiById.values, ...transaksiTanpaId];
    final awalShift = TransactionStore.shiftOpeningCash.value;
    final kasirShift = TransactionStore.shiftCashier.value.trim().isEmpty
        ? widget.namaKasir
        : TransactionStore.shiftCashier.value;
    final cashTransactions = transaksi
        .where(
          (item) =>
              item['pembayaran']?.toString().toLowerCase() == 'cash' &&
              _isPaid(item),
        )
        .toList();
    final activeShiftId = TransactionStore.activeShift.value?['id']?.toString();
    final activeCashSales = cashTransactions
        .where((item) => item['shiftId']?.toString() == activeShiftId)
        .fold<double>(
          0,
          (total, item) => total + ((item['total'] as num?)?.toDouble() ?? 0),
        );
    final activeCashAdjustments = TransactionStore.cashDrawerEntries.value
        .where((item) => item['shiftId']?.toString() == activeShiftId)
        .fold<double>(0, (total, item) {
          final amount = (item['amount'] as num?)?.toDouble() ?? 0;
          return total +
              (item['jenis']?.toString() == 'keluar' ? -amount : amount);
        });
    final formatNominal = (double value) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]}.',
      );
    };

    setState(() {
      kasAwal = awalShift;
      dataKasLaci = [
        ...TransactionStore.shiftHistory.value.map((shift) {
          final openedAt = shift['openedAt']?.toString() ?? '';
          final openingCash = (shift['openingCash'] as num?)?.toDouble() ?? 0;
          return {
            'kasir': shift['cashier']?.toString() ?? kasirShift,
            'tanggal': openedAt,
            'jam': _jamDariTanggal(openedAt),
            'nominal': '+${formatNominal(openingCash)}',
            'keterangan': 'Kas awal shift',
            'jenis': 'masuk',
            'shiftId': shift['id']?.toString() ?? '',
          };
        }),
        ...cashTransactions.map((item) {
          final waktu = DateTime.tryParse(item['tanggal']?.toString() ?? '');
          final total = (item['total'] as num?)?.toDouble() ?? 0;
          return {
            'tanggal': item['tanggal']?.toString() ?? '',
            'kasir': item['kasir']?.toString().trim().isNotEmpty == true
                ? item['kasir'].toString()
                : kasirShift,
            'jam':
                item['jam']?.toString() ??
                (waktu == null
                    ? '--:--'
                    : '${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}'),
            'nominal': '+${formatNominal(total)}',
            'keterangan': 'Penjualan Cash',
            'jenis': 'masuk',
            'shiftId': item['shiftId']?.toString() ?? '',
          };
        }),
        ...TransactionStore.cashDrawerEntries.value.map((item) {
          final amount = (item['amount'] as num?)?.toDouble() ?? 0;
          final type = item['jenis']?.toString() ?? 'masuk';
          final formatted = formatNominal(amount);
          return {
            'tanggal': item['tanggal']?.toString() ?? '',
            'kasir': item['kasir']?.toString() ?? kasirShift,
            'jam': _jamDariTanggal(item['tanggal']?.toString() ?? ''),
            'nominal': '${type == 'keluar' ? '-' : '+'}$formatted',
            'keterangan': item['keterangan']?.toString() ?? '',
            'jenis': type,
            'shiftId': item['shiftId']?.toString() ?? '',
          };
        }),
      ];
      kasSaatIni = TransactionStore.activeShift.value == null
          ? 0
          : awalShift + activeCashSales + activeCashAdjustments;
      dataLaporan = transaksi.map((item) {
        final waktu = DateTime.tryParse(item['tanggal']?.toString() ?? '');
        final total = (item['total'] as num?)?.toDouble() ?? 0;
        final angka = total.toInt().toString();
        final totalFormat = angka.replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
        return {
          'id': item['id']?.toString() ?? '-',
          'tanggal': item['tanggal']?.toString() ?? '',
          'jam':
              item['jam']?.toString() ??
              (waktu == null
                  ? '-'
                  : '${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}'),
          'shiftId': item['shiftId']?.toString() ?? '',
          'kasir': item['kasir']?.toString().trim().isNotEmpty == true
              ? item['kasir'].toString()
              : widget.namaKasir,
          'jumlah': item['jumlah']?.toString() ?? '0',
          'pembayaran': item['pembayaran']?.toString() ?? '-',
          'total': totalFormat,
          'status': _statusTransaksi(item),
          'buktiPembayaranPath': item['buktiPembayaranPath']?.toString() ?? '',
          'buktiPembayaranBase64':
              item['buktiPembayaranBase64']?.toString() ?? '',
        };
      }).toList();
    });
  }

  bool _isPaid(Map<String, dynamic> item) {
    final status = item['bayar']?.toString().toLowerCase();
    if (status == 'pending' || status == 'belum bayar') return false;
    if (status == 'lunas') return true;
    final payment = item['pembayaran']?.toString().toLowerCase();
    return payment == 'cash' || payment == 'tunai' || payment == 'qris';
  }

  String _statusTransaksi(Map<String, dynamic> item) {
    if (_isPaid(item)) return 'Lunas';
    final value = item['bayar']?.toString().trim();
    return value == null || value.isEmpty ? 'Belum Bayar' : value;
  }

  String _jamDariTanggal(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return '--:--';
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTanggal(String? value) {
    final date = _tanggalDariData(value);
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime? _tanggalDariData(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool _cocokTanggal(String? raw) {
    final waktu = _tanggalDariData(raw);
    final bulanAngka = nomorBulan[bulan];
    if (waktu == null || bulanAngka == null) return false;
    if (waktu.year != int.tryParse(tahun) || waktu.month != bulanAngka) {
      return false;
    }
    if (tanggal != 'Semua' && waktu.day != int.tryParse(tanggal)) {
      return false;
    }
    return true;
  }

  List<Map<String, String>> get dataLaporanTerfilter {
    return dataLaporan.where((item) {
      if (filterDiterapkan && !_cocokTanggal(item['tanggal'])) return false;
      if (shiftDipilih != 'Semua Shift' && item['shiftId'] != shiftDipilih) {
        return false;
      }
      if (pembayaranDipilih != null &&
          item['pembayaran']?.toLowerCase() !=
              pembayaranDipilih!.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, String>> get dataKasLaciTerfilter {
    return dataKasLaci.where((item) {
      if (filterDiterapkan && !_cocokTanggal(item['tanggal'])) return false;
      if (shiftDipilih != 'Semua Shift' && item['shiftId'] != shiftDipilih) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, String>> get penjualanLunasTerfilter =>
      dataLaporanTerfilter.where((item) => item['status'] == 'Lunas').toList();

  double _totalMetode(String metode) {
    return penjualanLunasTerfilter
        .where(
          (item) => item['pembayaran']?.toLowerCase() == metode.toLowerCase(),
        )
        .fold<double>(
          0,
          (total, item) =>
              total +
              (double.tryParse(item['total']?.replaceAll('.', '') ?? '') ?? 0),
        );
  }

  Widget _filterShift() {
    final shifts = TransactionStore.shiftHistory.value;
    final availableIds = shifts
        .map((item) => item['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    if (shiftDipilih != 'Semua Shift' && !availableIds.contains(shiftDipilih)) {
      shiftDipilih = 'Semua Shift';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: DropdownButtonFormField<String>(
        initialValue: shiftDipilih,
        decoration: const InputDecoration(
          labelText: 'Filter Shift',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: [
          const DropdownMenuItem(
            value: 'Semua Shift',
            child: Text('Semua Shift'),
          ),
          for (final shift in shifts)
            if ((shift['id']?.toString() ?? '').isNotEmpty)
              DropdownMenuItem(
                value: shift['id'].toString(),
                child: Text(
                  shift['cashier']?.toString().trim().isNotEmpty == true
                      ? shift['cashier'].toString()
                      : 'Kasir',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        ],
        onChanged: (value) {
          setState(() => shiftDipilih = value ?? 'Semua Shift');
        },
      ),
    );
  }

  void _terapkanFilter() {
    setState(() => filterDiterapkan = true);
  }

  Widget _tampilanDataKosong({required bool kasLaci}) {
    final rentang = tanggal == 'Semua'
        ? 'bulan $bulan $tahun'
        : 'tanggal $tanggal $bulan $tahun';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 46),
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
                size: 38,
                color: navy.withOpacity(0.68),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tidak ada transaksi',
              style: TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada data pada $rentang.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff71808d), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: LayoutBuilder(
        builder: (context, ukuran) {
          double lebar = ukuran.maxWidth;

          return Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              _header(lebar),

              // ==================================================
              // ISI
              // ==================================================
              Expanded(child: _isiLaporan(lebar)),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header(double lebar) {
    bool hp = lebar < 600;

    return Container(
      width: double.infinity,
      height: hp ? 55 : 64,
      color: navy,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ======================================================
          // JUDUL
          // ======================================================
          Text(
            "Laporan Keuangan",
            style: TextStyle(
              color: Colors.white,
              fontSize: hp ? 18 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ISI LAPORAN
  // ============================================================

  Widget _isiLaporan(double lebar) {
    bool hp = lebar < 600;
    bool tablet = lebar >= 600 && lebar < 950;

    double padding;

    if (hp) {
      padding = 10;
    } else if (tablet) {
      padding = 18;
    } else {
      padding = 22;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(hp ? 14 : 0),
        ),
        child: Column(
          children: [
            // ====================================================
            // TAB
            // ====================================================
            _tabLaporan(lebar),

            // ====================================================
            // ISI TAB
            // ====================================================
            if (tabDipilih == 0)
              _laporanKeuangan(lebar)
            else
              _laporanKasLaci(lebar),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAB LAPORAN
  // ============================================================

  Widget _tabLaporan(double lebar) {
    bool hp = lebar < 600;

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
              title: "Laporan Keuangan",
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
              title: "Laporan Kas Laci",
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

  // ============================================================
  // BUTTON TAB
  // ============================================================

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

  // ============================================================
  // LAPORAN KEUANGAN
  // ============================================================

  Widget _laporanKeuangan(double lebar) {
    bool hp = lebar < 600;
    bool tablet = lebar >= 600 && lebar < 950;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        hp
            ? 10
            : tablet
            ? 16
            : 18,
        hp
            ? 10
            : tablet
            ? 12
            : 14,
        hp
            ? 10
            : tablet
            ? 16
            : 18,
        hp
            ? 14
            : tablet
            ? 18
            : 20,
      ),
      child: Column(
        children: [
          _filterShift(),
          // ======================================================
          // FILTER + CHART
          // ======================================================
          if (hp)
            Column(
              children: [
                _filterHP(),

                const SizedBox(height: 14),

                _chartPembayaran(kecil: true),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _filterDesktop()),

                const SizedBox(width: 14),

                _chartPembayaran(kecil: false),
              ],
            ),

          const SizedBox(height: 20),

          // ======================================================
          // TABEL
          // ======================================================
          _containerTabel(child: _tabelLaporan(lebar)),

          const SizedBox(height: 18),

          // ======================================================
          // EXPORT
          // ======================================================
          if (hp)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [_tombolKosongkanLaporan(), _tombolExport(hp)],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _tombolKosongkanLaporan(),
                const SizedBox(width: 8),
                _tombolExport(hp),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LAPORAN KAS LACI
  // ============================================================

  Widget _laporanKasLaci(double lebar) {
    bool hp = lebar < 600;
    bool tablet = lebar >= 600 && lebar < 950;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        hp
            ? 10
            : tablet
            ? 16
            : 18,
        hp
            ? 10
            : tablet
            ? 12
            : 14,
        hp
            ? 10
            : tablet
            ? 16
            : 18,
        hp
            ? 14
            : tablet
            ? 18
            : 20,
      ),
      child: Column(
        children: [
          _filterShift(),
          // ======================================================
          // FILTER
          // ======================================================
          _filterDesktopKasLaci(lebar),

          const SizedBox(height: 12),

          if (hp)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [_tombolInputKas(), _tombolTutupShift()],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _tombolInputKas(),
                const SizedBox(width: 8),
                _tombolTutupShift(),
              ],
            ),

          const SizedBox(height: 18),

          // ======================================================
          // KAS AWAL + KAS SAAT INI
          // ======================================================
          if (hp)
            Column(
              children: [
                _boxKas("Kas Awal", kasAwal),

                const SizedBox(height: 12),

                _boxKas("Kas Saat ini", kasSaatIni),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _boxKas("Kas Awal", kasAwal)),

                const SizedBox(width: 22),

                Expanded(child: _boxKas("Kas Saat ini", kasSaatIni)),
              ],
            ),

          const SizedBox(height: 25),

          // ======================================================
          // TABEL KAS LACI
          // ======================================================
          _containerTabel(child: _tabelKasLaci(lebar)),

          const SizedBox(height: 18),

          // ======================================================
          // EXPORT
          // ======================================================
          Align(alignment: Alignment.centerRight, child: _tombolExport(hp)),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER LAPORAN DESKTOP
  // ============================================================

  Widget _filterDesktop() {
    return Row(
      children: [
        Expanded(
          child: _dropdown("Tanggal", tanggal, [
            'Semua',
            ...List.generate(31, (index) => '${index + 1}'),
          ]),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _dropdown("Bulan", bulan, [
            "Januari",
            "Februari",
            "Maret",
            "April",
            "Mei",
            "Juni",
            "Juli",
            "Agustus",
            "September",
            "Oktober",
            "November",
            "Desember",
          ]),
        ),

        const SizedBox(width: 10),

        Expanded(child: _dropdown("Tahun", tahun, ["2025", "2026", "2027"])),

        const SizedBox(width: 10),

        SizedBox(
          height: 47,
          child: ElevatedButton.icon(
            onPressed: _terapkanFilter,
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 18),
            label: const Text(
              "Filter",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER KAS LACI
  // ============================================================

  Widget _filterDesktopKasLaci(double lebar) {
    bool hp = lebar < 600;

    if (hp) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dropdown("Tanggal", tanggal, [
                  'Semua',
                  ...List.generate(31, (index) => '${index + 1}'),
                ]),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _dropdown("Bulan", bulan, [
                  "Januari",
                  "Februari",
                  "Maret",
                  "April",
                  "Mei",
                  "Juni",
                  "Juli",
                  "Agustus",
                  "September",
                  "Oktober",
                  "November",
                  "Desember",
                ]),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _dropdown("Tahun", tahun, ["2025", "2026", "2027"]),
              ),

              const SizedBox(width: 8),

              _buttonFilter(),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _dropdown("Tanggal", tanggal, [
            'Semua',
            ...List.generate(31, (index) => '${index + 1}'),
          ]),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _dropdown("Bulan", bulan, [
            "Januari",
            "Februari",
            "Maret",
            "April",
            "Mei",
            "Juni",
            "Juli",
            "Agustus",
            "September",
            "Oktober",
            "November",
            "Desember",
          ]),
        ),

        const SizedBox(width: 10),

        Expanded(child: _dropdown("Tahun", tahun, ["2025", "2026", "2027"])),

        const SizedBox(width: 10),

        _buttonFilter(),
      ],
    );
  }

  // ============================================================
  // BUTTON FILTER
  // ============================================================

  Widget _buttonFilter() {
    return SizedBox(
      height: 47,
      child: ElevatedButton.icon(
        onPressed: _terapkanFilter,
        icon: const Icon(Icons.filter_list, color: Colors.white, size: 18),
        label: const Text(
          "Filter",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER HP
  // ============================================================

  Widget _filterHP() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _dropdown("Tanggal", tanggal, [
                'Semua',
                ...List.generate(31, (index) => '${index + 1}'),
              ]),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: _dropdown("Bulan", bulan, [
                "Januari",
                "Februari",
                "Maret",
                "April",
                "Mei",
                "Juni",
                "Juli",
                "Agustus",
                "September",
                "Oktober",
                "November",
                "Desember",
              ]),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _dropdown("Tahun", tahun, ["2025", "2026", "2027"]),
            ),

            const SizedBox(width: 8),

            _buttonFilter(),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdown(String judul, String nilai, List<String> pilihan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          judul,
          style: TextStyle(
            color: navy,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Container(
          height: 47,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: const Color(0xfffafafa),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffe3e7ea)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: nilai,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
                size: 20,
              ),
              items: pilihan.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  if (judul == "Tanggal") {
                    tanggal = value;
                  }

                  if (judul == "Bulan") {
                    bulan = value;
                  }

                  if (judul == "Tahun") {
                    tahun = value;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHART PEMBAYARAN
  // ============================================================

  Widget _chartPembayaran({required bool kecil}) {
    final cashTotal = _totalMetode('Cash') + _totalMetode('Tunai');
    final qrisTotal = _totalMetode('QRIS');
    final totalPaid = cashTotal + qrisTotal;
    final qrisShare = totalPaid == 0 ? .5 : qrisTotal / totalPaid;
    final cashPercent = totalPaid == 0
        ? 0
        : (cashTotal / totalPaid * 100).round();
    final qrisPercent = totalPaid == 0 ? 0 : 100 - cashPercent;

    return Container(
      width: kecil ? double.infinity : 285,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfffbfcfd),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffedf0f2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ======================================================
          // DONUT
          // ======================================================
          SizedBox(
            width: kecil ? 72 : 82,
            height: kecil ? 72 : 82,
            child: CustomPaint(
              painter: DonutChartPainter(
                qrisColor: qrisColor,
                cashColor: cashColor,
                selected: pembayaranDipilih,
                qrisShare: qrisShare,
              ),
              child: Center(
                child: Text(
                  '${totalPaid == 0 ? 0 : 100}%',
                  style: TextStyle(
                    color: navy,
                    fontSize: kecil ? 10 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 13),

          // ======================================================
          // DATA CHART
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Metode Pembayaran",
                  style: TextStyle(
                    color: navy,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                _legendInteraktif(
                  "QRIS",
                  "$qrisPercent% • ${_formatRupiah(qrisTotal)}",
                  qrisColor,
                ),

                const SizedBox(height: 3),

                _legendInteraktif(
                  "Cash",
                  "$cashPercent% • ${_formatRupiah(cashTotal)}",
                  cashColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEGEND INTERAKTIF
  // ============================================================

  Widget _legendInteraktif(String nama, String persen, Color warna) {
    bool dipilih = pembayaranDipilih == nama;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (pembayaranDipilih == nama) {
            pembayaranDipilih = null;
          } else {
            pembayaranDipilih = nama;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: dipilih ? warna.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Text(
                nama,
                style: TextStyle(
                  color: navy,
                  fontSize: 11,
                  fontWeight: dipilih ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),

            Text(
              persen,
              style: TextStyle(
                color: navy,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTAINER TABEL
  // ============================================================

  Widget _containerTabel({required Widget child}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffeeeeee)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }

  // ============================================================
  // TABEL LAPORAN KEUANGAN
  // ============================================================

  Widget _tabelLaporan(double lebar) {
    bool hp = lebar < 600;
    final rows = dataLaporanTerfilter;
    if (filterDiterapkan && rows.isEmpty) {
      return _tampilanDataKosong(kasLaci: false);
    }

    if (hp) {
      return Column(
        children: rows.map((data) {
          return InkWell(
            onTap: () {
              setState(() {
                pembayaranDipilih = data["pembayaran"];
              });
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfff9fbfd),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: pembayaranDipilih == data["pembayaran"]
                      ? navy
                      : const Color(0xffe5e9ed),
                  width: pembayaranDipilih == data["pembayaran"] ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data["id"]!,
                          style: TextStyle(
                            color: navy,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  _infoRow("Jam", data["jam"]!),
                  _infoRow("Nama Kasir", data["kasir"]!),
                  _infoRow("Pembayaran", data["pembayaran"]!),
                  _infoRow("Jumlah Pesanan", data["jumlah"]!),
                  _infoRow("Total Harga", "Rp ${data["total"]!}", bold: true),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _tombolLihatBukti(data),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
              dataRowMaxHeight: 70,
              headingRowColor: MaterialStateProperty.all(navy),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: TextStyle(color: navy, fontSize: 12),
              columns: const [
                DataColumn(label: Text("ID Pemesanan")),
                DataColumn(label: Text("Jam")),
                DataColumn(label: Text("Nama Kasir")),
                DataColumn(label: Text("Pembayaran")),
                DataColumn(label: Text("Jumlah Pemesanan")),
                DataColumn(label: Text("Total Harga")),
                DataColumn(label: Text("Bukti Pembayaran")),
              ],
              rows: rows.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text(data["id"]!)),
                    DataCell(Text(data["jam"]!)),
                    DataCell(Text(data["kasir"]!)),
                    DataCell(_badgePembayaran(data["pembayaran"]!)),
                    DataCell(Text(data["jumlah"]!)),
                    DataCell(
                      Text(
                        "Rp ${data["total"]!}",
                        style: TextStyle(
                          color: navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(_tombolLihatBukti(data)),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
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
                  errorBuilder: (_, __, ___) => const Center(
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

  // ============================================================
  // TABEL KAS LACI
  // ============================================================

  Widget _tabelKasLaci(double lebar) {
    bool hp = lebar < 600;
    final rows = dataKasLaciTerfilter;
    if (filterDiterapkan && rows.isEmpty) {
      return _tampilanDataKosong(kasLaci: true);
    }

    if (hp) {
      return Column(
        children: rows.map((data) {
          bool masuk = data["jenis"] == "masuk";

          return InkWell(
            onTap: () {
              _detailKas(data);
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xfff9fbfd),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: masuk
                      ? const Color(0xff00875a).withOpacity(0.25)
                      : const Color(0xffd85c5c).withOpacity(0.25),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data["kasir"]!,
                          style: TextStyle(
                            color: navy,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        data["jam"]!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  _infoRow("Tanggal", _formatTanggal(data["tanggal"])),
                  _infoRow("Nominal", data["nominal"]!, bold: true),
                  _infoRow("Keterangan", data["keterangan"]!),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: lebar < 1000 ? 28 : 42,
              horizontalMargin: 15,
              headingRowHeight: 44,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 60,
              headingRowColor: MaterialStateProperty.all(navy),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: TextStyle(color: navy, fontSize: 12),
              columns: const [
                DataColumn(label: Text("Nama Kasir")),
                DataColumn(label: Text("Tanggal")),
                DataColumn(label: Text("Jam")),
                DataColumn(label: Text("Pemasukan/Pengeluaran")),
                DataColumn(label: Text("Keterangan")),
              ],
              rows: rows.map((data) {
                bool masuk = data["jenis"] == "masuk";

                return DataRow(
                  cells: [
                    DataCell(
                      Text(data["kasir"]!),
                      onTap: () => _detailKas(data),
                    ),
                    DataCell(Text(_formatTanggal(data["tanggal"]))),
                    DataCell(Text(data["jam"]!)),
                    DataCell(
                      Text(
                        data["nominal"]!,
                        style: TextStyle(
                          color: masuk
                              ? const Color(0xff00875a)
                              : const Color(0xffd85c5c),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(Text(data["keterangan"]!)),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _detailKas(Map<String, String> data) {
    bool masuk = data["jenis"] == "masuk";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            masuk ? "Detail Pemasukan" : "Detail Pengeluaran",
            style: TextStyle(color: navy, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Kasir : ${data["kasir"]}"),
              const SizedBox(height: 7),
              Text("Jam : ${data["jam"]}"),
              const SizedBox(height: 7),
              Text("Nominal : ${data["nominal"]}"),
              const SizedBox(height: 7),
              Text("Keterangan : ${data["keterangan"]}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tutup", style: TextStyle(color: navy)),
            ),
          ],
        );
      },
    );
  }

  Widget _tombolInputKas() {
    return ElevatedButton.icon(
      onPressed: _modalInputKas,
      icon: const Icon(Icons.add, color: Colors.white, size: 18),
      label: const Text(
        "Input Kas",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }

  Widget _tombolTutupShift() {
    return ElevatedButton.icon(
      onPressed: _modalTutupShift,
      icon: const Icon(
        Icons.lock_clock_outlined,
        color: Colors.white,
        size: 18,
      ),
      label: const Text(
        'Tutup Shift',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xffa84848),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }

  Widget _tombolKosongkanLaporan() {
    return OutlinedButton.icon(
      onPressed: _konfirmasiKosongkanLaporan,
      icon: const Icon(Icons.delete_outline, size: 17),
      label: const Text('Kosongkan Laporan'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xffa84848),
        side: const BorderSide(color: Color(0xffa84848)),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      ),
    );
  }

  Future<void> _konfirmasiKosongkanLaporan() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kosongkan Laporan?'),
        content: const Text(
          'Semua transaksi pada Laporan Keuangan akan dihapus permanen dari perangkat. '
          'Pesanan belum selesai dan kas awal shift tidak ikut dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffa84848),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus Transaksi'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;

    try {
      await TransactionStore.clearTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data laporan berhasil dikosongkan.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengosongkan laporan: $error')),
      );
    }
  }

  void _modalTutupShift() {
    final activeShift = TransactionStore.activeShift.value;
    if (activeShift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada shift aktif untuk ditutup.')),
      );
      return;
    }
    final summary = TransactionStore.activeShiftSummary();
    final kasir = activeShift['cashier']?.toString() ?? widget.namaKasir;
    final now = DateTime.now();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: navy.withOpacity(.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xffffeeee),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.lock_clock_rounded,
                      color: Color(0xffa84848),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ringkasan Tutup Shift',
                    style: TextStyle(
                      color: navy,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  •  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Color(0xff73818d)),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xfff1f6fa),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        _barisRingkasanShift('Nama kasir', kasir),
                        _barisRingkasanShift(
                          'Jumlah transaksi',
                          '${summary['transactionCount']}',
                        ),
                        _barisRingkasanShift(
                          'Pembayaran Cash',
                          _formatRupiah(
                            (summary['cashSales'] as num).toDouble(),
                          ),
                        ),
                        _barisRingkasanShift(
                          'Pembayaran QRIS',
                          _formatRupiah(
                            (summary['qrisSales'] as num).toDouble(),
                          ),
                        ),
                        const Divider(height: 20),
                        _barisRingkasanShift(
                          'Kas awal',
                          _formatRupiah(
                            (summary['openingCash'] as num).toDouble(),
                          ),
                        ),
                        _barisRingkasanShift(
                          'Kas akhir yang diharapkan',
                          _formatRupiah(
                            (summary['expectedCash'] as num).toDouble(),
                          ),
                          bold: true,
                        ),
                        const Divider(height: 20),
                        _barisRingkasanShift(
                          'Total penjualan',
                          _formatRupiah(
                            (summary['totalSales'] as num).toDouble(),
                          ),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await TransactionStore.closeActiveShift();
                              if (!mounted) return;
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Shift berhasil ditutup dan disimpan ke riwayat.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Color(0xff16865c),
                                ),
                              );
                              widget.onShiftClosed?.call();
                            } catch (error) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal menyimpan shift: $error',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.save_rounded, size: 17),
                          label: const Text('Tutup & Simpan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _barisRingkasanShift(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xff596a78))),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: navy,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                fontSize: bold ? 16 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _modalInputKas() {
    String jenis = "masuk";
    final nominalController = TextEditingController();
    final keteranganController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                "Input Kas Laci",
                style: TextStyle(color: navy, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: jenis,
                      decoration: const InputDecoration(
                        labelText: "Jenis",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "masuk",
                          child: Text("Pemasukan"),
                        ),
                        DropdownMenuItem(
                          value: "keluar",
                          child: Text("Pengeluaran"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            jenis = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nominalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Nominal",
                        hintText: "Contoh: 25000",
                        prefixText: "Rp ",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keteranganController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Keterangan",
                        hintText: "Contoh: Penjualan / beli sedotan",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("Batal", style: TextStyle(color: navy)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nominalText = nominalController.text.trim();
                    final nominal = double.tryParse(nominalText);

                    if (nominal == null || !nominal.isFinite || nominal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Nominal harus diisi dengan angka yang benar",
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await TransactionStore.addCashDrawerEntry(
                        type: jenis,
                        amount: nominal,
                        description: keteranganController.text,
                      );
                      if (!mounted || !dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            jenis == "masuk"
                                ? "Pemasukan berhasil ditambahkan"
                                : "Pengeluaran berhasil ditambahkan",
                          ),
                        ),
                      );
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menyimpan kas laci: $error'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BOX KAS AWAL / KAS SAAT INI
  // ============================================================

  Widget _boxKas(String judul, double nominal) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            height: double.infinity,
            width: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              judul,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: Center(
              child: Text(
                _formatRupiah(nominal),
                style: TextStyle(
                  color: navy,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGE PEMBAYARAN
  // ============================================================

  Widget _badgePembayaran(String pembayaran) {
    bool qris = pembayaran == "QRIS";

    Color warna = qris ? qrisColor : cashColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: warna.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        pembayaran,
        style: TextStyle(
          color: warna,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String _formatRupiah(double value) {
    final number = value.toInt().toString();

    String result = "";
    int count = 0;

    for (int i = number.length - 1; i >= 0; i--) {
      result = number[i] + result;
      count++;

      if (count == 3 && i != 0) {
        result = ".$result";
        count = 0;
      }
    }

    return "Rp $result";
  }

  // ============================================================
  // TOMBOL EXPORT
  // ============================================================

  Widget _tombolExport(bool hp) {
    return ElevatedButton.icon(
      onPressed: _modalExport,
      icon: const Icon(Icons.download, color: Colors.white, size: 19),
      label: Text(
        hp ? 'Export' : 'Export to Excel',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        elevation: 2,
      ),
    );
  }

  void _modalExport() {
    final kasLaci = tabDipilih == 1;
    final namaFile = kasLaci
        ? 'Laporan_Kas_Laci_${tanggal}_${bulan}_$tahun'
        : 'Laporan_Keuangan_${tanggal}_${bulan}_$tahun';
    var sedangDownload = false;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(kasLaci ? 'Ekspor Kas Laci' : 'Ekspor Keuangan'),
          content: Text(
            'Simpan ${kasLaci ? dataKasLaciTerfilter.length : dataLaporanTerfilter.length} baris laporan sebagai $namaFile.xlsx?',
          ),
          actions: [
            TextButton(
              onPressed: sedangDownload
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: sedangDownload
                  ? null
                  : () async {
                      setDialogState(() => sedangDownload = true);
                      final berhasil = await _downloadExcel(kasLaci, namaFile);
                      if (!dialogContext.mounted) return;
                      if (berhasil) {
                        Navigator.pop(dialogContext);
                      } else {
                        setDialogState(() => sedangDownload = false);
                      }
                    },
              icon: sedangDownload
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(sedangDownload ? 'Menyimpan...' : 'Simpan Excel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _downloadExcel(bool kasLaci, String namaFile) async {
    try {
      final workbook = Excel.createExcel();
      final sheet = workbook[kasLaci ? 'Kas Laci' : 'Laporan Keuangan'];
      sheet.appendRow(
        kasLaci
            ? [
                TextCellValue('Tanggal'),
                TextCellValue('Jam'),
                TextCellValue('Kasir'),
                TextCellValue('Nominal'),
                TextCellValue('Jenis'),
                TextCellValue('Keterangan'),
              ]
            : [
                TextCellValue('ID Pemesanan'),
                TextCellValue('Jam'),
                TextCellValue('Nama Kasir'),
                TextCellValue('Pembayaran'),
                TextCellValue('Jumlah Pemesanan'),
                TextCellValue('Total (Rp)'),
                TextCellValue('Bukti Pembayaran'),
              ],
      );
      for (final row in kasLaci ? dataKasLaciTerfilter : dataLaporanTerfilter) {
        sheet.appendRow(
          kasLaci
              ? [
                  TextCellValue(_formatTanggal(row['tanggal'])),
                  TextCellValue(row['jam'] ?? ''),
                  TextCellValue(row['kasir'] ?? ''),
                  TextCellValue(row['nominal'] ?? ''),
                  TextCellValue(row['jenis'] ?? ''),
                  TextCellValue(row['keterangan'] ?? ''),
                ]
              : [
                  TextCellValue(row['id'] ?? ''),
                  TextCellValue(row['jam'] ?? ''),
                  TextCellValue(row['kasir'] ?? ''),
                  TextCellValue(row['pembayaran'] ?? ''),
                  TextCellValue(row['jumlah'] ?? ''),
                  TextCellValue(row['total'] ?? ''),
                  TextCellValue(
                    _adaBuktiPembayaran(row) ? 'Tersedia' : 'Tidak ada',
                  ),
                ],
        );
      }
      final bytes = workbook.encode();
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Berkas Excel kosong dan tidak dapat disimpan.');
      }
      final lokasi = await FileSaver.instance.saveFile(
        name: namaFile,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Excel berhasil disimpan: $lokasi')),
      );
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan Excel: $error')),
        );
      }
      return false;
    }
  }
}
// ==================================================================
// DONUT CHART
// ==================================================================

class DonutChartPainter extends CustomPainter {
  final Color qrisColor;
  final Color cashColor;
  final String? selected;
  final double qrisShare;

  DonutChartPainter({
    required this.qrisColor,
    required this.cashColor,
    required this.selected,
    required this.qrisShare,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double stroke = 12;

    double radius = (size.width / 2) - stroke;

    Offset center = Offset(size.width / 2, size.height / 2);

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = stroke;

    // ==========================================================
    // QRIS
    // ==========================================================

    paint.color = qrisColor;

    if (selected == "QRIS") {
      paint.strokeWidth = 15;
    } else {
      paint.strokeWidth = stroke;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * qrisShare.clamp(0, 1).toDouble(),
      false,
      paint,
    );

    // ==========================================================
    // CASH
    // ==========================================================

    paint.color = cashColor;

    if (selected == "Cash") {
      paint.strokeWidth = 15;
    } else {
      paint.strokeWidth = stroke;
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + math.pi * 2 * qrisShare.clamp(0, 1).toDouble(),
      math.pi * 2 * (1 - qrisShare.clamp(0, 1).toDouble()),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.selected != selected ||
        oldDelegate.qrisShare != qrisShare;
  }
}
