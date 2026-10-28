import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class PaymentProofStore {
  PaymentProofStore._();

  static Future<String?> save({
    required String transactionId,
    required String imageName,
    required Uint8List bytes,
  }) async {
    if (kIsWeb) return null;
    if (bytes.isEmpty) {
      throw StateError('Foto bukti QRIS kosong.');
    }

    final supportDirectory = await getApplicationSupportDirectory();
    final proofDirectory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}payment_proofs',
    );
    await proofDirectory.create(recursive: true);

    final extension = imageName.contains('.')
        ? imageName.split('.').last.toLowerCase()
        : 'jpg';
    const supportedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
    final safeExtension = supportedExtensions.contains(extension)
        ? extension
        : 'jpg';
    final safeId = transactionId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final destination = File(
      '${proofDirectory.path}${Platform.pathSeparator}'
      'proof-$safeId-${DateTime.now().microsecondsSinceEpoch}.$safeExtension',
    );

    await destination.writeAsBytes(bytes, flush: true);
    if (!await destination.exists() || await destination.length() == 0) {
      throw FileSystemException(
        'Foto bukti QRIS tidak berhasil disimpan.',
        destination.path,
      );
    }
    return destination.path;
  }

  static Future<void> delete(String path) async {
    if (kIsWeb) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
