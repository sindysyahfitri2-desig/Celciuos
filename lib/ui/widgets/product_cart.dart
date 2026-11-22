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
  static const _navy = Color(0xFF0B2846);
  static const _titleColor = Color(0xFF0E2235);
  static const _priceColor = Color(0xFF335E84);
  static const _imagePlaceholder = Color(0xFFD5D1E8);
  static const _merah = Color(0xFFD65656);

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
            : 102.0;
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 300.0;

        final compact = width < 260 || height < 96;
        final pad = compact ? 7.0 : 9.0;
        final imageSize = (height - pad * 2).clamp(58.0, 86.0);

        final hasQuantity =
            widget.showCartControls && widget.quantity > 0;

        final tabWidth = compact ? 38.0 : 44.0;
        final buttonSize = compact ? 24.0 : 27.0;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              0,
              _hover ? -2 : 0,
              0,
            ),
            decoration: BoxDecoration(
              color: hasQuantity ? _merah : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(
                    alpha: _hover ? 0.16 : 0.09,
                  ),
                  blurRadius: _hover ? 14 : 9,
                  offset: Offset(0, _hover ? 5 : 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(pad),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Foto produk di sebelah kiri (kotak membulat)
                          Container(
                            width: imageSize,
                            height: imageSize,
                            decoration: BoxDecoration(
                              color: _imagePlaceholder,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ProductImage(
                              image: widget.image,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: compact ? 10 : 12),

                          // Nama menu & harga sejajar dengan foto + tombol qty di kanan bawah
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.name,
                                        maxLines: height < 106 ? 1 : 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _titleColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: compact ? 12.5 : 14,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _rupiah(widget.price),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _priceColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: compact ? 11 : 12.5,
                                          height: 1.15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.showCartControls)
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: hasQuantity
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _QtyButton(
                                                icon: Icons.remove_rounded,
                                                onTap: widget.onMinus,
                                                size: buttonSize,
                                              ),
                                              SizedBox(
                                                width: compact ? 22 : 28,
                                                child: Center(
                                                  child: AnimatedSwitcher(
                                                    duration: const Duration(
                                                      milliseconds: 150,
                                                    ),
                                                    transitionBuilder:
                                                        (child, animation) {
                                                      return ScaleTransition(
                                                        scale: animation,
                                                        child: FadeTransition(
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
                                                            compact ? 13 : 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
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
                        ],
                      ),
                    ),
                  ),

                  // Strip merah tombol hapus di sisi kanan (tampil saat item dipilih)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
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
                                size: compact ? 18 : 20,
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

class _QtyButton extends StatefulWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.size = 28,
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: widget.size * 0.58,
            ),
          ),
        ),
      ),
    );
  }
}
