import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/features/owner/application/kt_model.dart';

String _singkat(double v) {
  if (v >= 1000000) {
    return 'Rp ${(v / 1000000).toStringAsFixed(v >= 10000000 ? 0 : 1)}jt';
  }
  if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
  return 'Rp ${v.toStringAsFixed(0)}';
}

String _labelJam(int jam) => '${(jam == 0 ? 24 : jam).toString().padLeft(2, '0')}.00';

class ModalKeuntunganPanel extends StatefulWidget {
  const ModalKeuntunganPanel({super.key, required this.rekap});

  final RekapShift rekap;

  @override
  State<ModalKeuntunganPanel> createState() => _ModalKeuntunganPanelState();
}

class _ModalKeuntunganPanelState extends State<ModalKeuntunganPanel> {
  int? _jamDipilih;

  @override
  void didUpdateWidget(covariant ModalKeuntunganPanel old) {
    super.didUpdateWidget(old);
    if (old.rekap.penjualanPerJam != widget.rekap.penjualanPerJam) {
      _jamDipilih = null; // pilih ulang jam teramai saat data berubah
    }
  }

  // Urutan jam: 00-05 dianggap setelah tengah malam (24-29).
  int _urut(int j) => j < 6 ? j + 24 : j;

  List<int> _daftarJam(Map<int, double> data) {
    if (data.isEmpty) return const [];
    final urut = data.keys.map(_urut).toList()..sort();
    final awal = urut.first;
    var akhir = urut.last;
    if (akhir - awal < 5) akhir = awal + 5; // minimal 6 kolom
    return [for (var u = awal; u <= akhir; u++) u % 24];
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rekap;
    final compact = MediaQuery.of(context).size.width < 600;

    final hpp = r.totalHpp;
    final labaBersih = hpp == null ? null : r.totalPenjualan - hpp;
    final jumlahTrx = r.jumlahTransaksiTunai + r.jumlahTransaksiQr;

    final jamList = _daftarJam(r.penjualanPerJam);
    double nilai(int j) => r.penjualanPerJam[j] ?? 0;

    int? jamTeramai;
    for (final j in jamList) {
      if (nilai(j) > 0 && (jamTeramai == null || nilai(j) > nilai(jamTeramai))) {
        jamTeramai = j;
      }
    }
    final jamAktif = (_jamDipilih != null && jamList.contains(_jamDipilih))
        ? _jamDipilih!
        : jamTeramai;

    final rataPerJam = jamList.isEmpty
        ? 0.0
        : jamList.map(nilai).reduce((a, b) => a + b) / jamList.length;
    final rataPerTrx = jumlahTrx == 0 ? 0.0 : r.totalPenjualan / jumlahTrx;

    final kartu = [
      _kartu(
        judul: 'Modal Awal',
        nominal: formatRupiah(r.modalAwal, kapital: true),
        icon: Icons.account_balance_wallet_outlined,
        warna: const Color(0xff174a70),
        catatan: 'Uang yang ada di laci saat shift dibuka',
      ),
      _kartu(
        judul: 'Penjualan (Omset)',
        nominal: formatRupiah(r.totalPenjualan, kapital: true),
        icon: Icons.savings_outlined,
        warna: const Color(0xff188c79),
        catatan: '$jumlahTrx transaksi (tunai ${r.jumlahTransaksiTunai}, QRIS ${r.jumlahTransaksiQr})',
      ),
      _kartu(
        judul: 'Laba Bersih',
        nominal: labaBersih == null ? 'Belum tersedia' : formatRupiah(labaBersih, kapital: true),
        icon: Icons.trending_up_rounded,
        warna: labaBersih == null
            ? KtWarna.abuTeks
            : (labaBersih >= 0 ? const Color(0xff209c43) : const Color(0xffc0392b)),
        catatan: labaBersih == null
            ? 'Menunggu data harga modal (HPP) produk'
            : 'Penjualan dikurangi HPP',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        compact
            ? Column(children: [
                for (final k in kartu) ...[k, const SizedBox(height: 12)],
              ])
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < kartu.length; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(child: kartu[i]),
                    ],
                  ],
                ),
              ),

        if (hpp == null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xfffff6e0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffefd58a)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xff8a6d00)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Laba bersih belum bisa dihitung karena harga modal (HPP) tiap produk '
                    'belum diisi. Setelah diisi, laba otomatis muncul di sini.',
                    style: TextStyle(fontSize: 11, color: Color(0xff6b5400)),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 22),

        Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 13 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xffc7d5e1)),
            boxShadow: [
              BoxShadow(
                color: KtWarna.navy.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(2, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Penjualan per Jam',
                style: TextStyle(
                  color: KtWarna.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Ketuk batang untuk melihat penjualan di jam itu.',
                style: TextStyle(color: KtWarna.abuTeks, fontSize: 11),
              ),
              const SizedBox(height: 14),

              if (jamList.isEmpty) _kosong(),
              if (jamList.isNotEmpty) ...[
                // Ringkasan cepat
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Jam teramai',
                        jamTeramai == null ? '-' : _labelJam(jamTeramai)),
                    _chip('Rata-rata per jam', formatRupiah(rataPerTrxSafe(rataPerJam))),
                    _chip('Rata-rata per transaksi', formatRupiah(rataPerTrx)),
                  ],
                ),
                const SizedBox(height: 12),

                if (jamAktif != null) _tooltip(jamAktif, nilai(jamAktif), r.totalPenjualan),

                const SizedBox(height: 12),

                SizedBox(
                  height: 230,
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, c) {
  final lebar = c.maxWidth.isFinite
      ? c.maxWidth
      : MediaQuery.of(context).size.width - 32;
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (d) {
      if (jamList.isEmpty) return;
      const kiri = _GrafikPainter.kiri;
      final lebarKolom = (lebar - kiri - 5) / jamList.length;
      if (lebarKolom <= 0) return;
      final i = ((d.localPosition.dx - kiri) / lebarKolom)
          .floor()
          .clamp(0, jamList.length - 1);
      setState(() => _jamDipilih = jamList[i]);
    },
    child: CustomPaint(
      size: Size(lebar, 230),
      painter: _GrafikPainter(
        jam: jamList,
        data: r.penjualanPerJam,
        jamDipilih: jamAktif,
      ),
    ),
  );
},
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _keterangan(const Color(0xff3286b8), 'Penjualan per jam'),
                    _keterangan(const Color(0xff65a9db), 'Rata-rata per jam', garis: true),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  double rataPerTrxSafe(double v) => v.isNaN || v.isInfinite ? 0 : v;

  Widget _kosong() => Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xfff1f5f9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 42, color: KtWarna.abuTeks),
            SizedBox(height: 8),
            Text('Belum ada penjualan pada shift ini',
                style: TextStyle(
                    color: KtWarna.abuTeks, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      );

  Widget _chip(String label, String nilai) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xffe7f0f8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: KtWarna.abuTeks, fontSize: 9)),
            const SizedBox(height: 2),
            Text(nilai,
                style: const TextStyle(
                    color: KtWarna.navy, fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      );

  Widget _tooltip(int jam, double nilai, double total) {
    final persen = total <= 0 ? 0 : (nilai / total * 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: KtWarna.navy,
        borderRadius: BorderRadius.circular(9),
        boxShadow: KtGaya.bayanganRingan,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pukul ${_labelJam(jam)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
              const SizedBox(height: 3),
              Text(formatRupiah(nilai),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(width: 14),
          Text('${persen.toStringAsFixed(0)}% dari total',
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _kartu({
    required String judul,
    required String nominal,
    required IconData icon,
    required Color warna,
    required String catatan,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffc7d5e1)),
        boxShadow: [
          BoxShadow(
            color: KtWarna.navy.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(judul,
                    style: const TextStyle(
                        color: KtWarna.navy, fontSize: 13, fontWeight: FontWeight.w900)),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: warna.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 19, color: warna),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(nominal,
                style: TextStyle(
                  color: warna,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  shadows: KtGaya.bayanganAngka,
                )),
          ),
          const SizedBox(height: 8),
          Text(catatan,
              style: TextStyle(color: warna, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _keterangan(Color warna, String teks, {bool garis = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          garis
              ? Container(width: 19, height: 2, color: warna)
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
                ),
          const SizedBox(width: 6),
          Text(teks, style: const TextStyle(color: KtWarna.abuTeks, fontSize: 10)),
        ],
      );
}

class _GrafikPainter extends CustomPainter {
  _GrafikPainter({required this.jam, required this.data, required this.jamDipilih});

  final List<int> jam;
  final Map<int, double> data;
  final int? jamDipilih;

  static const double kiri = 46;
  static const double kanan = 5;
  static const double atas = 12;
  static const double bawah = 27;

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite || !size.height.isFinite || size.width < 70) return;
    final areaLebar = size.width - kiri - kanan;
    final areaTinggi = size.height - atas - bawah;
    final nilai = jam.map((j) => data[j] ?? 0).toList();
    if (nilai.isEmpty) return;

    final maks = nilai.fold<double>(0, (a, b) => a > b ? a : b);
    final batas = maks <= 0 ? 1.0 : maks * 1.2;
    final rata = nilai.reduce((a, b) => a + b) / nilai.length;

    // Grid + label sumbu Y
    final grid = Paint()
      ..color = const Color(0xffdce5ed)
      ..strokeWidth = 0.8;
    for (var i = 0; i < 4; i++) {
      final y = atas + (areaTinggi / 3) * i;
      canvas.drawLine(Offset(kiri, y), Offset(size.width - kanan, y), grid);
      final tp = TextPainter(
        text: TextSpan(
          text: _singkat(batas * (1 - i / 3)),
          style: const TextStyle(color: KtWarna.abuTeks, fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(kiri - tp.width - 4, y - tp.height / 2));
    }

    // Garis rata-rata
    final yRata = atas + areaTinggi - (rata / batas) * areaTinggi;
    final paintRata = Paint()
      ..color = const Color(0xff65a9db)
      ..strokeWidth = 1.2;
    for (var x = kiri; x < size.width - kanan; x += 10) {
      canvas.drawLine(Offset(x, yRata),
          Offset((x + 5).clamp(kiri, size.width - kanan), yRata), paintRata);
    }

    // Batang
    final lebarKolom = areaLebar / jam.length;
    final lebarBatang = lebarKolom * 0.5;

    for (var i = 0; i < jam.length; i++) {
      final tinggi = (nilai[i] / batas) * areaTinggi;
      final xTengah = kiri + lebarKolom * (i + 0.5);
      final dipilih = jam[i] == jamDipilih;

      if (dipilih) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(xTengah - lebarKolom / 2 + 1, atas,
                lebarKolom - 2, areaTinggi),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xffe7f0f8),
        );
      }

      if (nilai[i] > 0) {
        final rect = Rect.fromLTWH(xTengah - lebarBatang / 2,
            atas + areaTinggi - tinggi, lebarBatang, tinggi);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dipilih
                  ? const [Color(0xff31cba0), Color(0xff1673ad)]
                  : const [Color(0xff467db0), Color(0xff31577f)],
            ).createShader(rect),
        );
      }

      final label = TextPainter(
        text: TextSpan(
          text: _labelJam(jam[i]),
          style: TextStyle(
            color: dipilih ? KtWarna.navy : KtWarna.abuTeks,
            fontSize: 8,
            fontWeight: dipilih ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(xTengah - label.width / 2, size.height - 15));
    }
  }

  @override
  bool shouldRepaint(covariant _GrafikPainter old) =>
      old.data != data || old.jamDipilih != jamDipilih || old.jam != jam;
}