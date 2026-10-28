import 'package:flutter/material.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final Object? image;
  final String category;
  final VoidCallback onAdd;
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onDelete;
  final bool showCartControls;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    required this.onAdd,
    required this.quantity,
    required this.onMinus,
    required this.onDelete,
    this.showCartControls = true,
  });

  // ==========================================================
  // FORMAT RUPIAH
  // ==========================================================

  String rupiah(double value) {
    final number = value.toInt().toString();

    String result = '';
    int count = 0;

    for (int i = number.length - 1; i >= 0; i--) {
      result = number[i] + result;
      count++;

      if (count == 3 && i != 0) {
        result = '.$result';
        count = 0;
      }
    }

    return 'Rp $result';
  }

  // ==========================================================
  // TOMBOL
  // ==========================================================

  Widget tombol({
    required IconData icon,
    required VoidCallback onTap,
    double ukuran = 32,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: ukuran,
        height: ukuran,
        decoration: BoxDecoration(
          color: const Color(0xff082640),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: Colors.white,
          size: ukuran <= 28 ? 15 : 17,
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, ukuranCard) {
        final double lebarCard = ukuranCard.maxWidth;

        // ======================================================
        // DETEKSI HP
        // ======================================================

        final bool ukuranHP =
            lebarCard.isFinite && lebarCard < 200;

        // ======================================================
        // TINGGI CARD
        // ======================================================

        final double tinggiCard =
            ukuranCard.maxHeight.isFinite
                ? ukuranCard.maxHeight
                : ukuranHP
                    ? 10
                    : 10;

        // ======================================================
        // PADDING CARD
        // ======================================================

        final double padding = ukuranHP ? 5 : 9;

        // ======================================================
        // UKURAN FOTO
        // ======================================================

        // FOTO HP DIBESARKAN
        final double ukuranFoto = ukuranHP ? 450 : 100;

        // ======================================================
        // UKURAN TOMBOL
        // ======================================================

        final double ukuranTombol = ukuranHP ? 14 : 30;

        // ======================================================
        // UKURAN FONT
        // ======================================================

        final double ukuranNama = ukuranHP ? 18 : 16;

        final double ukuranKategori = ukuranHP ? 10 : 13;

        final double ukuranHarga = ukuranHP ? 12 : 14;

        return Container(
          width: 280,
          height: 260,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // ==================================================
              // FOTO PRODUK
              // ==================================================

              SizedBox(
                width: ukuranFoto,
                height: ukuranFoto,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffd9d6e1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ProductImage(
                      image: image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              SizedBox(
                width: ukuranHP ? 19 : 19,
              ),

              // ==================================================
              // BAGIAN KANAN
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ==================================================
                    // NAMA
                    // ==================================================

                    Text(
                      name,
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xff081d2e),
                        fontWeight: FontWeight.bold,
                        fontSize: ukuranNama,
                      ),
                    ),

                    const SizedBox(height: 3),

       
                    // ==================================================
                    // HARGA
                    // ==================================================
                    Text(
                      rupiah(price),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xff244f6a),
                        fontWeight: FontWeight.bold,
                        fontSize: ukuranHarga,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // TOMBOL
                    // ==================================================

                    if (showCartControls && quantity == 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: tombol(
                          icon: Icons.add,
                          onTap: onAdd,
                          ukuran: ukuranTombol,
                        ),
                      ),

                    // ==================================================
                    // DELETE - MINUS - JUMLAH - PLUS
                    // ==================================================

                    if (showCartControls && quantity > 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            // DELETE
                            InkWell(
                              onTap: onDelete,
                              borderRadius:
                                  BorderRadius.circular(8),
                              child: SizedBox(
                                width: ukuranTombol,
                                height: ukuranTombol,
                                child: Center(
                                  child: Icon(
                                    Icons.delete_outline,
                                    color:
                                        const Color(0xff082640),
                                    size: ukuranHP ? 20 : 23,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(
                              width: ukuranHP ? 3 : 5,
                            ),

                            // MINUS
                            tombol(
                              icon: Icons.remove,
                              onTap: onMinus,
                              ukuran: ukuranTombol,
                            ),

                            SizedBox(
                              width: ukuranHP ? 4 : 5,
                            ),

                            // JUMLAH
                            SizedBox(
                              width: ukuranHP ? 16 : 18,
                              child: Text(
                                '$quantity',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      const Color(0xff082640),
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize:
                                      ukuranHP ? 13 : 15,
                                ),
                              ),
                            ),

                            SizedBox(
                              width: ukuranHP ? 4 : 7,
                            ),

                            // PLUS
                            tombol(
                              icon: Icons.add,
                              onTap: onAdd,
                              ukuran: ukuranTombol,
                            ),
                          ],
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
}