
import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/features/owner/application/kt_model.dart';

class ModalKeuntunganPanel extends StatefulWidget {
  const ModalKeuntunganPanel({
    super.key,
    required this.rekap,
  });

  final RekapShift rekap;

  @override
  State<ModalKeuntunganPanel> createState() =>
      _ModalKeuntunganPanelState();
}

class _ModalKeuntunganPanelState extends State<ModalKeuntunganPanel> {
  int jamDipilih = 21;

  // Jam 00 ditampilkan sebagai 24.00 seperti desain.
  static const List<int> daftarJam = [
    16, 17, 18, 19, 20, 21, 22, 23, 0,
  ];

  String _labelJam(int jam) {
    final angka = jam == 0 ? 24 : jam;
    return '${angka.toString().padLeft(2, '0')}.00';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rekap;

    final hpp = r.totalHpp;
    final labaBersih =
        hpp == null ? null : r.totalPenjualan - hpp;

    final compact = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =====================================================
        // TIGA KARTU RINGKASAN
        // =====================================================

        if (compact)
          Column(
            children: [
              _kartuRingkasan(
                judul: 'Modal',
                nominal: formatRupiah(
                  r.modalAwal,
                  kapital: true,
                ),
                icon: Icons.account_balance_wallet_outlined,
                warna: const Color(0xff174a70),
                catatan: 'Modal awal laci',
              ),
              const SizedBox(height: 12),
              _kartuRingkasan(
                judul: 'Omset Kotor',
                nominal: formatRupiah(
                  r.totalPenjualan,
                  kapital: true,
                ),
                icon: Icons.savings_outlined,
                warna: const Color(0xff188c79),
                catatan:
                    '${r.jumlahTransaksiTunai + r.jumlahTransaksiQr} Transaksi',
              ),
              const SizedBox(height: 12),
              _kartuRingkasan(
                judul: 'Laba Bersih',
                nominal: labaBersih == null
                    ? 'Belum tersedia'
                    : formatRupiah(
                        labaBersih,
                        kapital: true,
                      ),
                icon: Icons.trending_up_rounded,
                warna: const Color(0xff209c43),
                catatan: hpp == null
                    ? 'Data HPP belum tersedia'
                    : 'Omset dikurangi HPP',
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _kartuRingkasan(
                  judul: 'Modal',
                  nominal: formatRupiah(
                    r.modalAwal,
                    kapital: true,
                  ),
                  icon: Icons.account_balance_wallet_outlined,
                  warna: const Color(0xff174a70),
                  catatan: 'Modal awal laci',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _kartuRingkasan(
                  judul: 'Omset Kotor',
                  nominal: formatRupiah(
                    r.totalPenjualan,
                    kapital: true,
                  ),
                  icon: Icons.savings_outlined,
                  warna: const Color(0xff188c79),
                  catatan:
                      '${r.jumlahTransaksiTunai + r.jumlahTransaksiQr} Transaksi',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _kartuRingkasan(
                  judul: 'Laba Bersih',
                  nominal: labaBersih == null
                      ? 'Belum tersedia'
                      : formatRupiah(
                          labaBersih,
                          kapital: true,
                        ),
                  icon: Icons.trending_up_rounded,
                  warna: const Color(0xff209c43),
                  catatan: hpp == null
                      ? 'Data HPP belum tersedia'
                      : 'Omset dikurangi HPP',
                ),
              ),
            ],
          ),

        const SizedBox(height: 22),

        // =====================================================
        // GRAFIK PENJUALAN
        // =====================================================

        Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 13 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: const Color(0xffc7d5e1),
              width: 1,
            ),
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
              // Judul grafik
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  const Text(
                    'GRAFIK PENJUALAN CELCIOUS',
                    style: TextStyle(
                      color: KtWarna.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffe7f0f8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Total: ${formatRupiah(r.totalPenjualan)}',
                      style: const TextStyle(
                        color: KtWarna.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              if (r.penjualanPerJam.isEmpty)
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xfff1f5f9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 42,
                        color: KtWarna.abuTeks,
                      ),
                      SizedBox(height: 9),
                      Text(
                        'Data waktu transaksi belum tersedia',
                        style: TextStyle(
                          color: KtWarna.abuTeks,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Grafik akan muncul setelah transaksi memiliki waktu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: KtWarna.abuTeks,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tooltip
                    if (r.penjualanPerJam.containsKey(jamDipilih))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: KtWarna.navy,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: KtGaya.bayanganRingan,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  size: 7,
                                  color: Color(0xffff6464),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Penjualan Pukul ${_labelJam(jamDipilih)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah(
                                r.penjualanPerJam[jamDipilih] ?? 0,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Grafik
                    SizedBox(
                      height: 215,
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              final lebar = constraints.maxWidth;
                              final posisi = details.localPosition.dx;

                              final index = (posisi /
                                      (lebar / daftarJam.length))
                                  .floor()
                                  .clamp(0, daftarJam.length - 1);

                              setState(() {
                                jamDipilih = daftarJam[index];
                              });
                            },
                            child: CustomPaint(
                              size: Size(
                                constraints.maxWidth,
                                215,
                              ),
                              painter: _GrafikPenjualanPainter(
                                data: r.penjualanPerJam,
                                jamDipilih: jamDipilih,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // Keterangan grafik
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _keterangan(
                    warna: const Color(0xff3286b8),
                    teks: 'Penjualan per jam',
                  ),
                  _keterangan(
                    warna: const Color(0xff65a9db),
                    teks: 'Rata-rata penjualan',
                    garis: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // KARTU RINGKASAN
  // ===========================================================

  Widget _kartuRingkasan({
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
        border: Border.all(
          color: const Color(0xffc7d5e1),
        ),
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
                child: Text(
                  judul,
                  style: const TextStyle(
                    color: KtWarna.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: warna.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: warna,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nominal,
              style: TextStyle(
                color: warna,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                shadows: KtGaya.bayanganAngka,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            catatan,
            style: TextStyle(
              color: warna,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _keterangan({
    required Color warna,
    required String teks,
    bool garis = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (garis)
          Container(
            width: 19,
            height: 2,
            color: warna,
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: warna,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 6),
        Text(
          teks,
          style: const TextStyle(
            color: KtWarna.abuTeks,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// =============================================================
// CUSTOM PAINTER GRAFIK PENJUALAN
// =============================================================

class _GrafikPenjualanPainter extends CustomPainter {
  final Map<int, double> data;
  final int jamDipilih;

  _GrafikPenjualanPainter({
    required this.data,
    required this.jamDipilih,
  });

  static const List<int> jam = [
    16, 17, 18, 19, 20, 21, 22, 23, 0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const kiri = 5.0;
    const kanan = 5.0;
    const atas = 12.0;
    const bawah = 27.0;

    final areaLebar = size.width - kiri - kanan;
    final areaTinggi = size.height - atas - bawah;

    final nilai = jam.map((j) => data[j] ?? 0).toList();

    final maksimum = nilai.fold<double>(
      0,
      (sebelumnya, sekarang) =>
          sebelumnya > sekarang ? sebelumnya : sekarang,
    );

    final batas = maksimum <= 0 ? 1.0 : maksimum * 1.2;

    final rata =
        nilai.reduce((a, b) => a + b) / nilai.length;

    // ---------------------------------------------------------
    // GARIS GRID
    // ---------------------------------------------------------

    final paintGrid = Paint()
      ..color = const Color(0xffdce5ed)
      ..strokeWidth = 0.8;

    for (int i = 0; i < 4; i++) {
      final y = atas + (areaTinggi / 3) * i;

      canvas.drawLine(
        Offset(kiri, y),
        Offset(size.width - kanan, y),
        paintGrid,
      );
    }

    // ---------------------------------------------------------
    // GARIS RATA-RATA
    // ---------------------------------------------------------

    final yRata =
        atas + areaTinggi - ((rata / batas) * areaTinggi);

    final paintRata = Paint()
      ..color = const Color(0xff65a9db)
      ..strokeWidth = 1.2;

    double posisiX = kiri;

    while (posisiX < size.width - kanan) {
      canvas.drawLine(
        Offset(posisiX, yRata),
        Offset(
          (posisiX + 5).clamp(kiri, size.width - kanan),
          yRata,
        ),
        paintRata,
      );

      posisiX += 10;
    }

    // ---------------------------------------------------------
    // BATANG GRAFIK
    // ---------------------------------------------------------

    final lebarKolom = areaLebar / jam.length;
    final lebarBatang = lebarKolom * 0.43;

    for (int i = 0; i < jam.length; i++) {
      final nilaiJam = nilai[i];

      final tinggi = (nilaiJam / batas) * areaTinggi;

      final xTengah = kiri + lebarKolom * (i + 0.5);

      final top = atas + areaTinggi - tinggi;

      final rect = Rect.fromLTWH(
        xTengah - lebarBatang / 2,
        top,
        lebarBatang,
        tinggi,
      );

      final dipilih = jam[i] == jamDipilih;

      if (nilaiJam > 0) {
        final paintBatang = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dipilih
                ? const [
                    Color(0xff31cba0),
                    Color(0xff1673ad),
                  ]
                : const [
                    Color(0xff467db0),
                    Color(0xff31577f),
                  ],
          ).createShader(rect);

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect,
            const Radius.circular(5),
          ),
          paintBatang,
        );
      }

      // -------------------------------------------------------
      // LABEL JAM
      // -------------------------------------------------------

      final labelJam = jam[i] == 0 ? '24.00' : '${jam[i]}.00';

      final text = TextPainter(
        text: TextSpan(
          text: labelJam,
          style: TextStyle(
            color: dipilih
                ? KtWarna.navy
                : KtWarna.abuTeks,
            fontSize: 8,
            fontWeight: dipilih
                ? FontWeight.w900
                : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      text.paint(
        canvas,
        Offset(
          xTengah - text.width / 2,
          size.height - 15,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _GrafikPenjualanPainter oldDelegate,
  ) {
    return oldDelegate.data != data ||
        oldDelegate.jamDipilih != jamDipilih;
  }
}
