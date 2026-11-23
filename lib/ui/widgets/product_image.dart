import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final Object? image;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (image is Uint8List) {
      return Image.memory(
        image as Uint8List,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    if (image is String && (image as String).isNotEmpty) {
      final src = (image as String).trim();
      if (src.startsWith('http://') || src.startsWith('https://')) {
        return Image.network(
          src,
          key: ValueKey(src),
          fit: fit,
          headers: const {'ngrok-skip-browser-warning': 'true'},
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF082640),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        );
      }

      return Image.asset(
        src,
        key: ValueKey(src),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(
        Icons.local_cafe_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
