/// Menghitung subtotal, pajak, diskon, dan total checkout tanpa bergantung UI.
class CashierCheckoutPricing {
  CashierCheckoutPricing._({
    required this.subtotal,
    required this.taxRate,
    required this.tax,
    required this.discount,
    required this.discountAmount,
    required this.total,
    required this.itemCount,
  });

  factory CashierCheckoutPricing.calculate({
    required List<Map<String, dynamic>> cart,
    required Map<String, dynamic>? existingOrder,
    required double defaultTaxRate,
    required double discount,
    required String discountType,
  }) {
    final savedSubtotal = (existingOrder?['subtotal'] as num?)?.toDouble();
    final subtotal =
        savedSubtotal ??
        cart.fold<double>(0, (sum, item) {
          final price = (item['price'] as num).toDouble();
          final quantity = item['quantity'] as int;
          return sum + price * quantity;
        });
    final taxRate =
        (existingOrder?['ppnRate'] as num?)?.toDouble() ?? defaultTaxRate;
    final tax =
        (existingOrder?['ppn'] as num?)?.toDouble() ?? subtotal * taxRate;
    final totalBeforeDiscount = subtotal + tax;
    final discountAmount = (discountType == '%'
            ? totalBeforeDiscount * discount / 100
            : discount)
        .clamp(0, totalBeforeDiscount)
        .toDouble();
    final itemCount = cart.fold<int>(
      0,
      (count, item) => count + (item['quantity'] as int),
    );

    return CashierCheckoutPricing._(
      subtotal: subtotal,
      taxRate: taxRate,
      tax: tax,
      discount: discount,
      discountAmount: discountAmount,
      total: totalBeforeDiscount - discountAmount,
      itemCount: itemCount,
    );
  }

  final double subtotal;
  final double taxRate;
  final double tax;
  final double discount;
  final double discountAmount;
  final double total;
  final int itemCount;
}
