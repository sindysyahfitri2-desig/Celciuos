import 'package:flutter/material.dart';
import 'kt_model.dart';

/// Isi tab kedua: "Modal & Keuntungan".
/// Hanya menampilkan ringkasan angka dari RekapShift.
class ModalKeuntunganPanel extends StatelessWidget {
  const ModalKeuntunganPanel({super.key, required this.rekap});

  final RekapShift rekap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KtWarna.navy,
        borderRadius: BorderRadius.circular(14),
        boxShadow: KtGaya.bayangan,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modal & Keuntungan',
            style: TextStyle(
              color: Color(0xffe8f0f8),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _baris('Modal awal laci', formatRupiah(rekap.modalAwal)),
          _baris('Penjualan tunai', formatRupiah(rekap.penjualanTunai)),
          _baris('Penjualan QR', formatRupiah(rekap.penjualanQr)),
          const Divider(color: Colors.white24),
          _baris('Total penjualan', formatRupiah(rekap.totalPenjualan), tebal: true),
          _baris('Kas seharusnya di laci', formatRupiah(rekap.kasSeharusnya), tebal: true),
        ],
      ),
    );
  }

  Widget _baris(String label, String nilai, {bool tebal = false}) {
    final gaya = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: tebal ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: gaya), Text(nilai, style: gaya)],
      ),
    );
  }
}