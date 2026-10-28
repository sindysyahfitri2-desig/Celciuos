import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/pages/LaporanPage.dart';

// >>> IMPORT 2 dari 2 yang perlu disesuaikan dengan foldermu <<<
import '../LaporanPage.dart';
import 'kt_data_service.dart';
import 'kt_model.dart'; // berisi KtWarna, KtGaya, formatRupiah, dan model data
import 'modal_keuntungan.dart';
import 'Riwayat_transaksi.dart';

// ==============================================================
// BAYANGAN LOKAL (lebih tebal & lembut dari KtGaya.bayangan)
// ==============================================================
// [angkat] = true dipakai saat kartu di-hover (efek terangkat).
List<BoxShadow> _bayanganBesar({bool angkat = false}) => [
      BoxShadow(
        color: KtWarna.navy.withValues(alpha: angkat ? 0.26 : 0.16),
        blurRadius: angkat ? 30 : 22,
        offset: Offset(0, angkat ? 14 : 9),
      ),
      BoxShadow(
        color: KtWarna.navy.withValues(alpha: 0.08),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

// Gradasi navy yang dipakai tombol, badge ikon, dan kartu profil.
const LinearGradient _gradasiNavy = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1B4B78), KtWarna.navy, Color(0xFF082640)],
);

/// HALAMAN UTAMA "Kelola Transaksi" (tanpa sidebar).
/// Letakkan widget ini di area konten, di sebelah sidebar kamu.
class KelolaTransaksiPage extends StatefulWidget {
  const KelolaTransaksiPage({
    super.key,
    this.namaKasir = 'Kasir',
    this.pakaiDataContoh = true, // true = data sama seperti desain, false = data asli
  });

  final String namaKasir;
  final bool pakaiDataContoh;

  @override
  State<KelolaTransaksiPage> createState() => _KelolaTransaksiPageState();
}

class _KelolaTransaksiPageState extends State<KelolaTransaksiPage> {
  late RekapShift rekap;
  int tabDipilih = 0; // 0 = Riwayat, 1 = Modal & Keuntungan
  String kataCari = '';

  final List<Listenable> _sumberData = KtDataService.sumberData;

  @override
  void initState() {
    super.initState();
    rekap = _ambilData();
    if (!widget.pakaiDataContoh) {
      for (final s in _sumberData) {
        s.addListener(_muatUlang);
      }
    }
  }

  @override
  void dispose() {
    if (!widget.pakaiDataContoh) {
      for (final s in _sumberData) {
        s.removeListener(_muatUlang);
      }
    }
    super.dispose();
  }

  RekapShift _ambilData() {
    return widget.pakaiDataContoh
        ? KtDataService.dataContoh()
        : KtDataService.dariStore(widget.namaKasir);
  }

  void _muatUlang() {
    if (!mounted) return;
    setState(() => rekap = _ambilData());
  }

  // Daftar transaksi setelah difilter kotak "Cari"
  List<TransaksiKasir> get _transaksiTampil {
    final q = kataCari.trim().toLowerCase();
    if (q.isEmpty) return rekap.transaksi;
    return rekap.transaksi.where((t) {
      return t.id.toLowerCase().contains(q) ||
          t.kasir.toLowerCase().contains(q) ||
          t.ringkasanItem.toLowerCase().contains(q);
    }).toList();
  }

  // Tombol "Unduh Laporan Keuangan" -> buka LaporanPage
  void _bukaLaporan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LaporanPage(namaKasir: rekap.namaKasir),
      ),
    );
  }

  // Tombol merah di kartu transaksi
  Future<void> _konfirmasiHapus(TransaksiKasir t) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus transaksi?'),
        content: Text('Transaksi ${t.id} akan dihapus dari daftar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ya != true || !mounted) return;

    // TODO: kalau pakai data asli, panggil fungsi hapus di TransactionStore di sini.
    // Untuk data contoh, cukup hapus dari daftar di layar.
    if (widget.pakaiDataContoh) {
      setState(() => rekap.transaksi.remove(t));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffe6eef7), KtWarna.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 24,
              compact ? 16 : 22,
              compact ? 14 : 24,
              28,
            ),
            // Di layar lebar, isi dibatasi supaya tidak terlalu melebar.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  children: [
                    _kotakCari(),
                    const SizedBox(height: 20),

                    // Kartu judul + baris chip/tombol
                    const HeaderRekap(),
                    const SizedBox(height: 14),
                    BarisChip(
                      tanggalText: formatTanggalLengkap(rekap.tanggal),
                      shiftText: rekap.labelShift,
                      onUnduh: _bukaLaporan,
                    ),
                    const SizedBox(height: 20),

                    ProfilKasirCard(
                      nama: rekap.namaKasir,
                      namaShift: rekap.namaShift,
                      rentangJam: rekap.rentangJam,
                      status: rekap.statusShift,
                      fotoAsset: rekap.fotoKasirAsset,
                    ),
                    const SizedBox(height: 20),

                    BarisKartuRingkasan(
                      kartu: [
                        KartuRingkasan(
                          judul: 'Modal Awal Laci',
                          nominal: formatRupiah(rekap.modalAwal, kapital: true),
                          icon: Icons.point_of_sale,
                          bawah: KartuRingkasan.pilHijau(
                              'Serah Terima : ${rekap.serahTerima}'),
                        ),
                        KartuRingkasan(
                          judul: 'Penjualan Tunai',
                          nominal:
                              formatRupiah(rekap.penjualanTunai, kapital: true),
                          icon: Icons.savings_outlined,
                          bawah: KartuRingkasan.teksJumlah(
                              '${rekap.jumlahTransaksiTunai} Transaksi'),
                        ),
                        KartuRingkasan(
                          judul: 'Penjualan QR',
                          nominal:
                              formatRupiah(rekap.penjualanQr, kapital: true),
                          icon: Icons.qr_code_2,
                          bawah: KartuRingkasan.teksJumlah(
                              '${rekap.jumlahTransaksiQr} Transaksi'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: TabTombol(
                        tabDipilih: tabDipilih,
                        onPilih: (i) => setState(() => tabDipilih = i),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Animasi halus saat pindah tab.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(tabDipilih),
                        child: tabDipilih == 0
                            ? RiwayatTransaksiPanel(
                                daftar: _transaksiTampil,
                                onHapus: _konfirmasiHapus,
                              )
                            : ModalKeuntunganPanel(rekap: rekap),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Kotak "Cari" berbentuk pil (lonjong) dengan bayangan tebal
  Widget _kotakCari() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: _bayanganBesar(),
      ),
      child: TextField(
        onChanged: (v) => setState(() => kataCari = v),
        style: const TextStyle(fontSize: 14, color: KtWarna.navy),
        decoration: const InputDecoration(
          hintText: 'Cari transaksi, kasir, atau menu',
          hintStyle: TextStyle(fontSize: 13, color: KtWarna.abuTeks),
          prefixIcon: Icon(Icons.search_rounded, size: 22, color: KtWarna.abuTeks),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ==============================================================
// Pembungkus: kartu terangkat sedikit saat di-hover (laptop/web)
// ==============================================================
class _Angkat extends StatefulWidget {
  const _Angkat({required this.builder});

  final Widget Function(bool hovered) builder;

  @override
  State<_Angkat> createState() => _AngkatState();
}

class _AngkatState extends State<_Angkat> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        child: widget.builder(_hovered),
      ),
    );
  }
}

// ==============================================================
// WIDGET: kartu judul "Rekap Sift Kasir & Pengawasan Kas Laci"
// ==============================================================
class HeaderRekap extends StatelessWidget {
  const HeaderRekap({super.key});

  @override
  Widget build(BuildContext context) {
    return _Angkat(
      builder: (hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _bayanganBesar(angkat: hovered),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Garis navy di tepi kiri sebagai aksen.
                Container(width: 6, color: KtWarna.navy),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            gradient: _gradasiNavy,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: KtWarna.navy.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.point_of_sale,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rekap Sift Kasir & Pengawasan Kas Laci',
                                style: TextStyle(
                                  color: KtWarna.navy,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Audit Kas, Non-tunai',
                                style: TextStyle(
                                  color: KtWarna.abuTeks,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// ==============================================================
// WIDGET: baris chip tanggal, chip shift, tombol Unduh
// ==============================================================
class BarisChip extends StatelessWidget {
  const BarisChip({
    super.key,
    required this.tanggalText,
    required this.shiftText,
    required this.onUnduh,
  });

  final String tanggalText; // "Senin, 26 Oktober 2026"
  final String shiftText; // "Sift Sore (15.00-20.00)"
  final VoidCallback onUnduh;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chip(tanggalText, Icons.calendar_today_rounded, bulat: false),
          _chip(shiftText, Icons.access_time_filled_rounded, bulat: true),
          _tombolUnduh(),
        ],
      ),
    );
  }

  Widget _tombolUnduh() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onUnduh,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: _gradasiNavy,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: KtWarna.navy.withValues(alpha: 0.38),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Unduh Laporan Keuangan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Chip putih berbentuk pil dengan icon di dalam kotak/lingkaran navy
  Widget _chip(String teks, IconData icon, {required bool bulat}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _bayanganBesar(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: KtWarna.navy,
              shape: bulat ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: bulat ? null : BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 9),
          Text(
            teks,
            style: const TextStyle(
              color: KtWarna.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================
// WIDGET: kartu navy profil kasir
// ==============================================================
class ProfilKasirCard extends StatelessWidget {
  const ProfilKasirCard({
    super.key,
    required this.nama,
    required this.namaShift,
    required this.rentangJam,
    required this.status,
    this.fotoAsset,
  });

  final String nama;
  final String namaShift; // "Sift Sore"
  final String rentangJam; // "15.00-20.00"
  final String status; // "Balance/Tepat"
  final String? fotoAsset;

  @override
  Widget build(BuildContext context) {
    return _Angkat(
      builder: (hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _gradasiNavy,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _bayanganBesar(angkat: hovered),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ---------- Foto (dengan bingkai putih) ----------
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: SizedBox(
                  width: 84,
                  height: 74,
                  child: fotoAsset == null
                      ? _fotoKosong()
                      : Image.asset(
                          fotoAsset!,
                          fit: BoxFit.cover,
                          // kalau file gambar belum ada, tampilkan icon (tidak error)
                          errorBuilder: (_, __, ___) => _fotoKosong(),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // ---------- Teks ----------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kasir ($namaShift)',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mulai dari Pukul $rentangJam',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ---------- Badge hijau (kanan atas) ----------
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  gradient: KtGaya.gradasiHijau,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotoKosong() {
    return Container(
      color: Colors.white24,
      child: const Icon(Icons.person, color: Colors.white70, size: 42),
    );
  }
}

// ==============================================================
// WIDGET: kartu ringkasan (Modal Awal / Tunai / QR) + barisnya
// ==============================================================
class KartuRingkasan extends StatelessWidget {
  const KartuRingkasan({
    super.key,
    required this.judul,
    required this.nominal,
    required this.icon,
    required this.bawah,
  });

  final String judul; // "Penjualan Tunai"
  final String nominal; // "RP. 1.000.000"
  final IconData icon; // icon di pojok kanan atas
  final Widget bawah; // bagian bawah (pil hijau / teks jumlah transaksi)

  @override
  Widget build(BuildContext context) {
    return _Angkat(
      builder: (hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _bayanganBesar(angkat: hovered),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    judul,
                    style: TextStyle(
                      color: KtWarna.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      shadows: KtGaya.bayanganTeks,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: KtWarna.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: KtWarna.navy),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                nominal,
                style: TextStyle(
                  color: KtWarna.navy,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  shadows: KtGaya.bayanganAngka,
                ),
              ),
            ),
            const SizedBox(height: 14),
            bawah,
          ],
        ),
      ),
    );
  }

  /// Pil hijau melebar, dipakai di kartu "Modal Awal Laci".
  static Widget pilHijau(String teks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: KtGaya.gradasiHijau,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        teks,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Teks hijau kecil, dipakai untuk "58 Transaksi".
  static Widget teksJumlah(String teks) {
    return Text(
      teks,
      style: const TextStyle(
        color: KtWarna.hijau,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Menyusun 3 kartu: berjajar (Row) kalau layar lebar, ditumpuk (Column) kalau sempit.
class BarisKartuRingkasan extends StatelessWidget {
  const BarisKartuRingkasan({super.key, required this.kartu});

  final List<KartuRingkasan> kartu;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              for (final k in kartu)
                Padding(padding: const EdgeInsets.only(bottom: 14), child: k),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < kartu.length; i++) ...[
                Expanded(child: kartu[i]),
                if (i != kartu.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ==============================================================
// WIDGET: dua tombol tab (pil)
// ==============================================================
class TabTombol extends StatelessWidget {
  const TabTombol({
    super.key,
    required this.tabDipilih,
    required this.onPilih,
  });

  final int tabDipilih; // 0 atau 1
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: [
        _tombol('Riwayat Transaksi Kasir', 0, Icons.receipt_long_rounded),
        _tombol('Modal & Keuntungan', 1, Icons.trending_up_rounded),
      ],
    );
  }

  Widget _tombol(String teks, int index, IconData icon) {
    final aktif = tabDipilih == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onPilih(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: aktif ? _gradasiNavy : null,
            color: aktif ? null : KtWarna.tabNonaktif,
            borderRadius: BorderRadius.circular(26),
            boxShadow: aktif
                ? [
                    BoxShadow(
                      color: KtWarna.navy.withValues(alpha: 0.38),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : _bayanganBesar(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: aktif ? Colors.white : KtWarna.teksNonaktif,
              ),
              const SizedBox(width: 8),
              Text(
                teks,
                style: TextStyle(
                  color: aktif ? Colors.white : KtWarna.teksNonaktif,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  // tab non-aktif: teks seperti "timbul" (ada bayangan putih)
                  shadows: aktif
                      ? null
                      : const [
                          Shadow(
                            color: Colors.white,
                            offset: Offset(1, 1),
                            blurRadius: 1,
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}