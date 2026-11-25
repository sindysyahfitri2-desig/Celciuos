import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/features/owner/application/kt_model.dart';
import 'package:kasir_celcious_coffe/ui/widgets/product_image.dart';

/// Panel besar navy "Riwayat Transaksi Kasir" berisi daftar transaksi.
class RiwayatTransaksiPanel extends StatelessWidget {
  const RiwayatTransaksiPanel({
    super.key,
    required this.daftar,
    required this.onHapus,
    this.onDetail,
  });

  final List<TransaksiKasir> daftar;
  final ValueChanged<TransaksiKasir> onHapus;
  final ValueChanged<TransaksiKasir>? onDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 320),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
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
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                const Text(
                  'Riwayat Transaksi Kasir',
                  style: TextStyle(
                    color: Color(0xffe8f0f8),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white54, width: 1.2),
                  ),
                  child: const Icon(
                    Icons.point_of_sale,
                    color: KtWarna.navy,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---------- Isi ----------
          if (daftar.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Text(
                  'Belum ada transaksi',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ),
            )
          else
            for (final t in daftar)
              TransaksiItemCard(
                data: t,
                onHapus: () => onHapus(t),
                onDetail: onDetail == null ? null : () => onDetail!(t),
              ),
        ],
      ),
    );
  }
}

// ==============================================================
// WIDGET: kartu satu transaksi (putih, responsif HP & desktop)
// ==============================================================
class TransaksiItemCard extends StatelessWidget {
  const TransaksiItemCard({
    super.key,
    required this.data,
    required this.onHapus,
    this.onDetail,
  });

  final TransaksiKasir data;
  final VoidCallback onHapus;
  final VoidCallback? onDetail;

  static const TextStyle _gayaDesktop = TextStyle(
    color: KtWarna.navy,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDetail,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 9 : 10,
                vertical: isCompact ? 8 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: KtGaya.bayanganRingan,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ---------- Foto produk pertama + badge +N ----------
                  _thumbnailProduk(isCompact),
                  SizedBox(width: isCompact ? 10 : 12),

                  // ---------- Detail transaksi ----------
                  Expanded(
                    child: isCompact ? _detailCompact() : _detailDesktop(),
                  ),
                  SizedBox(width: isCompact ? 8 : 10),

                  // ---------- Tombol batal/hapus (ringkas di HP) ----------
                  InkWell(
                    onTap: onHapus,
                    borderRadius: BorderRadius.circular(isCompact ? 9 : 12),
                    child: Container(
                      width: isCompact ? 32 : 42,
                      height: isCompact ? 32 : 26,
                      decoration: BoxDecoration(
                        gradient: KtGaya.gradasiMerah,
                        borderRadius: BorderRadius.circular(isCompact ? 9 : 13),
                        boxShadow: KtGaya.bayanganRingan,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: isCompact ? 17 : 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _thumbnailProduk(bool isCompact) {
    final w = isCompact ? 56.0 : 72.0;
    final h = isCompact ? 56.0 : 58.0;
    final hasPhoto = data.fotoAsset != null && data.fotoAsset!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 9 : 8),
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: const Color(0xffe6eff8),
              child: hasPhoto
                  ? ProductImage(image: data.fotoAsset, fit: BoxFit.cover)
                  : _fotoKosong(),
            ),
            if (data.extraItemCount > 0)
              Positioned(
                right: 3,
                bottom: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: KtWarna.navy.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.75),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '+${data.extraItemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Tata letak lega & nyaman dibaca khusus layar HP (tidak sumpek).
  Widget _detailCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.ringkasanItem,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: KtWarna.navy,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Flexible(
              child: Text(
                data.kasir,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: KtWarna.abuTeks,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text(
              '  •  ',
              style: TextStyle(color: KtWarna.abuTeks, fontSize: 10),
            ),
            Text(
              formatRupiah(data.totalHarga, spasi: false),
              style: const TextStyle(
                color: KtWarna.navy,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _badgeStatus(compact: true),
      ],
    );
  }

  /// Tata letak label sejajar untuk layar tablet/desktop.
  Widget _detailDesktop() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _baris(
          'Kasir',
          Text(
            data.kasir,
            style: _gayaDesktop,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _baris(
          'Pesanan',
          Text(
            data.ringkasanItem,
            style: _gayaDesktop,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _baris(
          'Total Harga',
          Text(
            formatRupiah(data.totalHarga, spasi: false),
            style: _gayaDesktop,
          ),
        ),
        _baris('Status', _badgeStatus(compact: false)),
      ],
    );
  }

  Widget _baris(String label, Widget isi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label, style: _gayaDesktop)),
          const Text(': ', style: _gayaDesktop),
          Flexible(child: isi),
        ],
      ),
    );
  }

  Widget _badgeStatus({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 2.5 : 2,
      ),
      decoration: BoxDecoration(
        gradient: data.lunas ? KtGaya.gradasiHijau : null,
        color: data.lunas ? null : KtWarna.oranye,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        data.labelStatus,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 9.2 : 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _fotoKosong() {
    return const Center(
      child: Icon(Icons.local_cafe_rounded, color: KtWarna.navy, size: 24),
    );
  }
}
