import 'package:flutter/foundation.dart';

/// Owns cart mutations and calculations for the cashier presentation.
class CashierCartController extends ChangeNotifier {
  final List<Map<String, dynamic>> items = [];

  int get itemCount => items.fold<int>(
    0,
    (count, item) => count + (item['quantity'] as int? ?? 0),
  );

  double get total => items.fold<double>(0, (sum, item) {
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final quantity = item['quantity'] as int? ?? 0;
    return sum + price * quantity;
  });

  void addProduct(Map<String, dynamic> product) {
    final index = items.indexWhere((item) => item['name'] == product['name']);
    if (index >= 0) {
      final currentQuantity = items[index]['quantity'] as int? ?? 0;
      items[index]['quantity'] = currentQuantity + 1;
    } else {
      items.add({
        'name': product['name'],
        'price': product['price'],
        'category': product['category'],
        'image': product['image'],
        'quantity': 1,
      });
    }
    notifyListeners();
  }

  void setNote(int index, String note) {
    if (index < 0 || index >= items.length) return;
    items[index]['catatan'] = note;
    notifyListeners();
  }

  void changeQuantity(int index, int delta) {
    if (index < 0 || index >= items.length) return;
    final quantity = (items[index]['quantity'] as int? ?? 0) + delta;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index]['quantity'] = quantity;
    }
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    if (items.isEmpty) return;
    items.clear();
    notifyListeners();
  }
}
