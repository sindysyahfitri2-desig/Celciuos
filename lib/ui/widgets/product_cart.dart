
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
    return 'Rp ${digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 151.0;

        final compact = constraints.maxWidth < 250 || height < 105;

        final imageSize = compact
            ? (height - 16).clamp(48.0, 72.0)
            : (height - 18).clamp(70.0, 132.0);

        final hasQuantity =
            widget.showCartControls && widget.quantity > 0;

        final tabWidth = compact ? 34.0 : 41.0;
        final buttonSize = compact ? 26.0 : 36.0;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              0,
              _hover ? -2 : 0,
              0,
            ),
            decoration: BoxDecoration(
              color: hasQuantity ? _merah : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(
                    alpha: _hover ? 0.18 : 0.10,
                  ),
                  blurRadius: _hover ? 16 : 11,
                  offset: Offset(0, _hover ? 6 : 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  // BAGIAN PUTIH CARD
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          // GAMBAR PRODUK
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              width: imageSize,
                              height: imageSize,
                              decoration: BoxDecoration(
                                color: const Color(0xffd9d6e8),
                                borderRadius: BorderRadius.circular(19),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ProductImage(
                                image: widget.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          // INFORMASI PRODUK
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                compact ? 2 : 8,
                                10,
                                compact ? 7 : 10,
                                10,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                          color: const Color(0xff10202d),
                                          fontWeight: FontWeight.w800,
                                          fontSize: compact ? 11 : 15,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _rupiah(widget.price),
                                        style: TextStyle(
                                          color: const Color(0xff24577e),
                                          fontWeight: FontWeight.w600,
                                          fontSize: compact ? 9 : 13,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // TOMBOL JUMLAH
                                  if (widget.showCartControls)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: hasQuantity
                                          ? Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                _QtyButton(
                                                  icon: Icons.remove_rounded,
                                                  onTap: widget.onMinus,
                                                  size: buttonSize,
                                                ),
                                                SizedBox(
                                                  width: compact ? 4 : 9,
                                                ),
                                                SizedBox(
                                                  width: compact ? 18 : 28,
                                                  child: Center(
                                                    child: AnimatedSwitcher(
                                                      duration:
                                                          const Duration(
                                                        milliseconds: 160,
                                                      ),
                                                      transitionBuilder:
                                                          (child, animation) {
                                                        return ScaleTransition(
                                                          scale: animation,
                                                          child:
                                                              FadeTransition(
                                                            opacity: animation,
                                                            child: child,
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        '${widget.quantity}',
                                                        key: ValueKey(
                                                          widget.quantity,
                                                        ),
                                                        style: TextStyle(
                                                          color: _navy,
                                                          fontSize:
                                                              compact ? 12 : 20,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: compact ? 4 : 9,
                                                ),
                                                _QtyButton(
                                                  icon: Icons.add_rounded,
                                                  onTap: widget.onAdd,
                                                  size: buttonSize,
                                                ),
                                              ],
                                            )
                                          : _QtyButton(
                                              icon: Icons.add_rounded,
                                              onTap: widget.onAdd,
                                              size: buttonSize,
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

                  // TAB MERAH HAPUS
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
                            child: Center(
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                                size: compact ? 18 : 22,
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

// TOMBOL PLUS DAN MINUS
class _QtyButton extends StatefulWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

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
          scale: _press ? 0.88 : 1,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _ProductCardState._navy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: widget.size < 30 ? 15 : 21,
            ),
          ),
        ),
      ),
    );
  }
}
