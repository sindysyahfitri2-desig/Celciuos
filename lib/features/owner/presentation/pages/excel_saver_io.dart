import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart' show OpenFilex;
import 'package:path_provider/path_provider.dart';

/// Simpan dan buka file Excel di desktop/mobile melalui sistem file lokal.
class ExcelSaver {
  Future<void> saveExcel(String name, Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$name.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    // Membuka file melalui aplikasi spreadsheet default pada perangkat.
    await OpenFilex.open(file.path);
  }
}