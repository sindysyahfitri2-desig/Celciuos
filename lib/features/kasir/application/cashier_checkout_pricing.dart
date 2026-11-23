/// Menghitung subtotal, pajak (PPN), biaya layanan, diskon, dan total checkout
/// agar 100% identik dengan perhitungan backend Laravel (TransaksiController).
class CashierCheckoutPricing {
  CashierCheckoutPricing._({
    required this.subtotal,
    required this.taxRate,
    required this.tax,
    required this.serviceFeeRate,
    required this.serviceFee,
    required this.discount,
    required this.discountAmount,
    required this.total,
    required this.itemCount,
  });

  factory CashierCheckoutPricing.calculate({
    required List<Map<String, dynamic>> cart,
    required Map<String, dynamic>? existingOrder,
    required double defaultTaxRate,
    double defaultServiceFeeRate = 0,
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
        (existingOrder?['ppn'] as num?)?.toDouble() ??
        (subtotal * taxRate).roundToDouble();

    final serviceFeeRate =
        (existingOrder?['serviceFeeRate'] as num?)?.toDouble() ??
        defaultServiceFeeRate;

    final serviceFee =
        (existingOrder?['biaya_layanan'] as num?)?.toDouble() ??
        (subtotal * serviceFeeRate).roundToDouble();

    final totalBeforeDiscount = subtotal + tax + serviceFee;

    // Ikuti perhitungan backend TransaksiController:
    // '%' = persen dari total sebelum diskon, 'Rp' = nominal rupiah.
    final isPercentage = discountType == '%';

    final discountAmount = (isPercentage
            ? (totalBeforeDiscount * discount.clamp(0, 100) / 100).roundToDouble()
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
      serviceFeeRate: serviceFeeRate,
      serviceFee: serviceFee,
      discount: discount,
      discountAmount: discountAmount,
      total: totalBeforeDiscount - discountAmount,
      itemCount: itemCount,
    );
  }

  final double subtotal;
  final double taxRate;
  final double tax;
  final double serviceFeeRate;
  final double serviceFee;
  final double discount;
  final double discountAmount;
  final double total;
  final int itemCount;
}
