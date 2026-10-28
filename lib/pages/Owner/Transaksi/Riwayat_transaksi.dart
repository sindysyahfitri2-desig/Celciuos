import 'package:flutter/material.dart';
import 'kt_model.dart';

/// Panel besar navy "Riwayat Transaksi Kasir" berisi daftar transaksi.
class RiwayatTransaksiPanel extends StatelessWidget {
  const RiwayatTransaksiPanel({
    super.key,
    required this.daftar,
    required this.onHapus,
  });

  final List<TransaksiKasir> daftar;
  final ValueChanged<TransaksiKasir> onHapus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
      decoration: BoxDecoration(
        color: KtWarna.navy,
        borderRadius: BorderRadius.circular(14),
        boxShadow: KtGaya.bayangan,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Judul panel ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Text(
                  'Riwayat Transaksi Kasir',
                  style: TextStyle(
                    color: Color(0xffe8f0f8),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white54, width: 1.5),
                  ),
                  child: const Icon(Icons.point_of_sale, color: KtWarna.navy, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ---------- Isi ----------
          if (daftar.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'Belum ada transaksi',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            )
          else
            for (final t in daftar)
              TransaksiItemCard(data: t, onHapus: () => onHapus(t)),
        ],
      ),
    );
  }
}

// ==============================================================
// WIDGET: kartu satu transaksi (putih)
// ==============================================================
class TransaksiItemCard extends StatelessWidget {
  const TransaksiItemCard({
    super.key,
    required this.data,
    required this.onHapus,
  });

  final TransaksiKasir data;
  final VoidCallback onHapus; // dipanggil saat tombol merah ditekan

  static const TextStyle _gaya = TextStyle(
    color: KtWarna.navy,
    fontSize: 7,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: KtGaya.bayangan,
      ),
      child: Row(
        children: [
          // ---------- Foto menu ----------
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              width: 74,
              height: 52,
              child: data.fotoAsset == null
                  ? _fotoKosong()
                  : Image.asset(
                      data.fotoAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fotoKosong(),
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // ---------- Detail ----------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _baris('Kasir', Text(data.kasir, style: _gaya, maxLines: 1, overflow: TextOverflow.ellipsis)),
                _baris('Total Pesanan', Text(data.ringkasanItem, style: _gaya, maxLines: 1, overflow: TextOverflow.ellipsis)),
                _baris('Total Harga', Text(formatRupiah(data.totalHarga, spasi: false), style: _gaya)),
                _baris('Status Pembayaran', _badgeStatus()),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // ---------- Tombol merah ----------
          GestureDetector(
            onTap: onHapus,
            child: Container(
              width: 46,
              height: 20,
              decoration: BoxDecoration(
                gradient: KtGaya.gradasiMerah,
                borderRadius: BorderRadius.circular(10),
                boxShadow: KtGaya.bayangan,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Satu baris "Label : isi" (label lebarnya tetap supaya titik dua rata)
  Widget _baris(String label, Widget isi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(width: 62, child: Text(label, style: _gaya)),
          const Text(': ', style: _gaya),
          Flexible(child: isi),
        ],
      ),
    );
  }

  Widget _badgeStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        gradient: data.lunas ? KtGaya.gradasiHijau : null,
        color: data.lunas ? null : KtWarna.oranye,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        data.labelStatus,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _fotoKosong() {
    return Container(
      color: const Color(0xffe6eff8),
      child: const Icon(Icons.local_cafe, color: KtWarna.navy, size: 26),
    );
  }
}