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

  Widget _placeholder() {
    return const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (image is Uint8List) {
      return Image.memory(
        image as Uint8List,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    if (image is String) {
      final path = (image as String).trim();

      if (path.isEmpty) return _placeholder();

      if (path.startsWith('http://') ||
          path.startsWith('https://')) {
        return Image.network(
          path,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            );
          },
        );
      }

      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }
}
