import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/pages/LaporanPage.dart';

// >>> IMPORT 2 dari 2 yang perlu disesuaikan dengan foldermu <<<
import '../LaporanPage.dart';
import 'kt_data_service.dart';
import 'kt_model.dart'; // berisi KtWarna, KtGaya, formatRupiah, dan model data
import 'modal_keuntungan.dart';
import 'Riwayat_transaksi.dart';

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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        child: Column(
          children: [
            _kotakCari(),
            const SizedBox(height: 14),

            // Kartu judul + baris chip/tombol (dua bagian terpisah seperti di desain)
            const HeaderRekap(),
            const SizedBox(height: 10),
            BarisChip(
              tanggalText: formatTanggalLengkap(rekap.tanggal),
              shiftText: rekap.labelShift,
              onUnduh: _bukaLaporan,
            ),
            const SizedBox(height: 14),

            ProfilKasirCard(
              nama: rekap.namaKasir,
              namaShift: rekap.namaShift,
              rentangJam: rekap.rentangJam,
              status: rekap.statusShift,
              fotoAsset: rekap.fotoKasirAsset,
            ),
            const SizedBox(height: 14),

            BarisKartuRingkasan(
              kartu: [
                KartuRingkasan(
                  judul: 'Modal Awal Laci',
                  nominal: formatRupiah(rekap.modalAwal, kapital: true),
                  icon: Icons.point_of_sale,
                  bawah: KartuRingkasan.pilHijau('Serah Terima : ${rekap.serahTerima}'),
                ),
                KartuRingkasan(
                  judul: 'Penjualan Tunai',
                  nominal: formatRupiah(rekap.penjualanTunai, kapital: true),
                  icon: Icons.savings_outlined,
                  bawah: KartuRingkasan.teksJumlah('${rekap.jumlahTransaksiTunai} Transaksi'),
                ),
                KartuRingkasan(
                  judul: 'Penjualan QR',
                  nominal: formatRupiah(rekap.penjualanQr, kapital: true),
                  icon: Icons.qr_code_2,
                  bawah: KartuRingkasan.teksJumlah('${rekap.jumlahTransaksiQr} Transaksi'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: TabTombol(
                tabDipilih: tabDipilih,
                onPilih: (i) => setState(() => tabDipilih = i),
              ),
            ),
            const SizedBox(height: 14),

            if (tabDipilih == 0)
              RiwayatTransaksiPanel(
                daftar: _transaksiTampil,
                onHapus: _konfirmasiHapus,
              )
            else
              ModalKeuntunganPanel(rekap: rekap),
          ],
        ),
      ),
    );
  }

  // Kotak "Cari" berbentuk pil (lonjong) dengan bayangan
  Widget _kotakCari() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: KtGaya.bayangan,
      ),
      child: TextField(
        onChanged: (v) => setState(() => kataCari = v),
        style: const TextStyle(fontSize: 12, color: KtWarna.navy),
        decoration: const InputDecoration(
          hintText: 'Cari',
          hintStyle: TextStyle(fontSize: 12, color: KtWarna.abuTeks),
          prefixIcon: Icon(Icons.search, size: 16, color: KtWarna.abuTeks),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 13),
        ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: KtGaya.bayangan,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: KtWarna.navy, width: 1.6),
              borderRadius: BorderRadius.circular(6),
              boxShadow: KtGaya.bayangan,
            ),
            child: const Icon(Icons.point_of_sale, color: KtWarna.navy, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekap Sift Kasir & Pengawasan  Kas Laci',
                  style: TextStyle(
                    color: KtWarna.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Audit Kas, Non-tunai',
                  style: TextStyle(color: KtWarna.abuTeks, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
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
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _chip(tanggalText, Icons.calendar_today, bulat: false),
          _chip(shiftText, Icons.access_time_filled, bulat: true),
          GestureDetector(
            onTap: onUnduh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: KtWarna.navy,
                borderRadius: BorderRadius.circular(4),
                boxShadow: KtGaya.bayangan,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, color: Colors.white, size: 12),
                  SizedBox(width: 6),
                  Text(
                    'Unduh Laporan Keuangan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Chip putih kecil dengan icon di dalam kotak/lingkaran navy
  Widget _chip(String teks, IconData icon, {required bool bulat}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: KtGaya.bayangan,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: KtWarna.navy,
              shape: bulat ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: bulat ? null : BorderRadius.circular(2),
            ),
            child: Icon(icon, size: 9, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            teks,
            style: const TextStyle(
              color: KtWarna.navy,
              fontSize: 8,
              fontWeight: FontWeight.w600,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: KtWarna.navy,
        borderRadius: BorderRadius.circular(8),
        boxShadow: KtGaya.bayangan,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ---------- Foto (dengan bingkai putih) ----------
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                width: 66,
                height: 56,
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
          const SizedBox(width: 12),

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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Kasir ($namaShift )',
                  style: const TextStyle(color: Colors.white, fontSize: 7),
                ),
                const SizedBox(height: 1),
                Text(
                  'Mulai dari Pukul $rentangJam',
                  style: const TextStyle(color: Colors.white, fontSize: 7),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // ---------- Badge hijau (kanan atas) ----------
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                gradient: KtGaya.gradasiHijau,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fotoKosong() {
    return Container(
      color: Colors.white24,
      child: const Icon(Icons.person, color: Colors.white70, size: 36),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: KtGaya.bayangan,
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    shadows: KtGaya.bayanganTeks,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: KtWarna.navy, width: 1.2),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: KtGaya.bayangan,
                ),
                child: Icon(icon, size: 13, color: KtWarna.navy),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              nominal,
              style: TextStyle(
                color: KtWarna.navy,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                shadows: KtGaya.bayanganAngka,
              ),
            ),
          ),
          const SizedBox(height: 10),
          bawah,
        ],
      ),
    );
  }

  /// Pil hijau melebar, dipakai di kartu "Modal Awal Laci".
  static Widget pilHijau(String teks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: KtGaya.gradasiHijau,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        teks,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 7,
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
        fontSize: 9,
        fontWeight: FontWeight.w600,
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
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              for (final k in kartu)
                Padding(padding: const EdgeInsets.only(bottom: 10), child: k),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < kartu.length; i++) ...[
                Expanded(child: kartu[i]),
                if (i != kartu.length - 1) const SizedBox(width: 12),
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
      runSpacing: 8,
      children: [
        _tombol('Riwayat Transaksi Kasir', 0),
        _tombol('Modal & Keuntungan', 1),
      ],
    );
  }

  Widget _tombol(String teks, int index) {
    final aktif = tabDipilih == index;
    return GestureDetector(
      onTap: () => onPilih(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: aktif ? KtWarna.navy : KtWarna.tabNonaktif,
          borderRadius: BorderRadius.circular(20),
          boxShadow: KtGaya.bayangan,
        ),
        child: Text(
          teks,
          style: TextStyle(
            color: aktif ? Colors.white : KtWarna.teksNonaktif,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            // tab non-aktif: teks seperti "timbul" (ada bayangan putih)
            shadows: aktif
                ? null
                : const [Shadow(color: Colors.white, offset: Offset(1, 1), blurRadius: 1)],
          ),
        ),
      ),
    );
  }
}