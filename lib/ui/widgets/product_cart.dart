import 'package:flutter/material.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
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

  final String name;
  final double price;
  final Object? image;
  final String category;
  final VoidCallback onAdd;
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onDelete;
  final bool showCartControls;

  static const _navy = Color(0xff082640);

  String _rupiah(double value) {
    final digits = value.toInt().toString();
    return 'Rp ${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: _navy,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, color: Colors.white, size: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 116.0;
        final compact = constraints.maxWidth < 220;
        final imageSize = (height - 18).clamp(54.0, compact ? 72.0 : 88.0);
        final hasQuantity = showCartControls && quantity > 0;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: _navy.withValues(alpha: 0.13),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: const Color(0xffd9d6e1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ProductImage(image: image, fit: BoxFit.cover),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 10, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xff081d2e),
                                fontWeight: FontWeight.w700,
                                fontSize: compact ? 12 : 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _rupiah(price),
                              style: TextStyle(
                                color: const Color(0xff244f6a),
                                fontWeight: FontWeight.w600,
                                fontSize: compact ? 10 : 12,
                              ),
                            ),
                          ],
                        ),
                        if (showCartControls)
                          if (hasQuantity)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _quantityButton(Icons.remove_rounded, onMinus),
                                SizedBox(width: compact ? 6 : 9),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: compact ? 6 : 9),
                                _quantityButton(Icons.add_rounded, onAdd),
                              ],
                            )
                          else
                            Align(
                              alignment: Alignment.centerRight,
                              child: _quantityButton(Icons.add_rounded, onAdd),
                            ),
                      ],
                    ),
                  ),
                ),
                if (hasQuantity)
                  Material(
                    color: const Color(0xffe45a5a),
                    child: InkWell(
                      onTap: onDelete,
                      child: SizedBox(
                        width: compact ? 34 : 42,
                        height: double.infinity,
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
