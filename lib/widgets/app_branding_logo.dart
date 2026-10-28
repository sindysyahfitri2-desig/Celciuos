import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/app_branding_store.dart';

class AppBrandingLogo extends StatelessWidget {
  const AppBrandingLogo({
    super.key,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.coffee_rounded,
    this.fallbackIconSize = 24,
    this.height = 40,
    this.showText = false,
  });

  final BoxFit fit;
  final IconData fallbackIcon;
  final double fallbackIconSize;
  final double height;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ValueListenableBuilder<Uint8List?>(
        valueListenable: AppBrandingStore.logoBytes,
        builder: (context, logoBytes, child) {
          if (logoBytes != null) {
            return Image.memory(
              logoBytes,
              fit: fit,
              errorBuilder: (context, error, stackTrace) => _fallback(),
            );
          }

          return ValueListenableBuilder<String?>(
            valueListenable: AppBrandingStore.logoPath,
            builder: (context, logoPath, child) {
              if (logoPath == null || kIsWeb) return _fallback();

              return Image.file(
                File(logoPath),
                key: ValueKey(logoPath),
                fit: fit,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Icon(
        fallbackIcon,
        color: Colors.white,
        size: fallbackIconSize,
      ),
    );
  }
}