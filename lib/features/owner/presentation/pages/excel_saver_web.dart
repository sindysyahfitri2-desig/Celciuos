import 'dart:html' as html;
import 'dart:typed_data';

/// Unduh file Excel di Flutter Web melalui anchor elemen browser.
class ExcelSaver {
  Future<void> saveExcel(String name, Uint8List bytes) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "$name.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}