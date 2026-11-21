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
      return Image.asset(
        image as String,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
