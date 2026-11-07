import 'package:flutter/material.dart';
import 'product_image.dart';

class ProductCard extends StatefulWidget {
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

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  static const _navy = Color(0xff082640);
  static const _merah = Color(0xffe45a5a);

  bool _hover = false;

  String _rupiah(double value) {
    final digits = value.toInt().toString();
    return 'Rp ${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}';
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
        final hasQuantity = widget.showCartControls && widget.quantity > 0;
        final tabWidth = compact ? 34.0 : 42.0;

        return MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: height,
            transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
            decoration: BoxDecoration(
              // Warna merah di belakang membentuk tab hapus di sisi kanan.
              color: hasQuantity ? _merah : Colors.white,
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: _hover ? 0.20 : 0.13),
                  blurRadius: _hover ? 16 : 12,
                  offset: Offset(0, _hover ? 6 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Row(
                children: [
                  // KARTU PUTIH
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17),
                      ),
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
                              child: ProductImage(
                                image: widget.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(2, 10, 10, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: const Color(0xff081d2e),
                                          fontWeight: FontWeight.w800,
                                          fontSize: compact ? 12 : 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _rupiah(widget.price),
                                        style: TextStyle(
                                          color: const Color(0xff244f6a),
                                          fontWeight: FontWeight.w600,
                                          fontSize: compact ? 10 : 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Kontrol jumlah rata kanan, seperti desain.
                                  if (widget.showCartControls)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: hasQuantity
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _QtyButton(
                                                  icon: Icons.remove_rounded,
                                                  onTap: widget.onMinus,
                                                ),
                                                SizedBox(width: compact ? 4 : 6),
                                                SizedBox(
                                                  width: compact ? 18 : 22,
                                                  child: Center(
                                                    child: AnimatedSwitcher(
                                                      duration: const Duration(
                                                        milliseconds: 160,
                                                      ),
                                                      transitionBuilder:
                                                          (child, animation) =>
                                                              ScaleTransition(
                                                                scale:
                                                                    animation,
                                                                child:
                                                                    FadeTransition(
                                                                      opacity:
                                                                          animation,
                                                                      child:
                                                                          child,
                                                                    ),
                                                              ),
                                                      child: Text(
                                                        '${widget.quantity}',
                                                        key: ValueKey(
                                                          widget.quantity,
                                                        ),
                                                        style: const TextStyle(
                                                          color: _navy,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: compact ? 4 : 6),
                                                _QtyButton(
                                                  icon: Icons.add_rounded,
                                                  onTap: widget.onAdd,
                                                ),
                                              ],
                                            )
                                          : _QtyButton(
                                              icon: Icons.add_rounded,
                                              onTap: widget.onAdd,
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

                  // TAB MERAH HAPUS (melebar halus saat jumlah > 0)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: hasQuantity ? tabWidth : 0,
                    child: ClipRect(
                      child: IgnorePointer(
                        ignoring: !hasQuantity,
                        child: Material(
                          color: _merah,
                          child: InkWell(
                            onTap: widget.onDelete,
                            child: const Center(
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
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
}

// Tombol + / - berwarna navy dengan efek tekan.
class _QtyButton extends StatefulWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_QtyButton> createState() => _QtyButtonState();
}

class _QtyButtonState extends State<_QtyButton> {
  bool _press = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _press = true),
        onTapUp: (_) => setState(() => _press = false),
        onTapCancel: () => setState(() => _press = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          scale: _press ? 0.86 : 1,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _ProductCardState._navy,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 15),
          ),
        ),
      ),
    );
  }
}