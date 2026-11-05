import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:kasir_celcious_coffe/data/payment_proof_store.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';

/// Builds and persists cashier orders and completed transactions.
class CashierTransactionService {
  CashierTransactionService._();

  static Map<String, String> createOrderCode({
    required List<Map<String, dynamic>> cart,
    required DateTime time,
  }) {
    final date =
        '${time.month.toString().padLeft(2, '0')}'
        '${time.day.toString().padLeft(2, '0')}';
    final prefix = 'CC-$date-';
    final existingIds = [
      ...TransactionStore.unfinishedOrders.value,
      ...TransactionStore.transactions.value,
    ].map((order) => order['id']?.toString() ?? '');
    var number = 1;
    for (final id in existingIds) {
      if (!id.startsWith(prefix)) continue;
      final previous = int.tryParse(id.substring(prefix.length));
      if (previous != null && previous >= number) number = previous + 1;
    }

    final orderId = '$prefix${number.toString().padLeft(3, '0')}';
    return {'id': orderId, 'display': orderId};
  }

  static Future<void> saveUnfinishedOrder({
    required Map<String, String> orderCode,
    required DateTime time,
    required String customerName,
    required String cashierName,
    required int itemCount,
    required double subtotal,
    required double taxRate,
    required double tax,
    required double discount,
    required double discountInput,
    required String discountType,
    required double total,
    required String orderType,
    required List<Map<String, dynamic>> cart,
    Uint8List? paymentProofBytes,
  }) async {
    final cartItems = cart.map((item) {
      return <String, dynamic>{
        'name': item['name'].toString(),
        'price': (item['price'] as num).toDouble(),
        'quantity': item['quantity'] as int,
        'category': item['category']?.toString() ?? '',
        'image': item['image']?.toString() ?? '',
        'catatan': item['catatan']?.toString() ?? '',
      };
    }).toList();

    await TransactionStore.addUnfinishedOrder({
      'id': orderCode['id'],
      'kode': orderCode['display'],
      'tanggal': time.toIso8601String(),
      'nama': customerName,
      'kasir': cashierName,
      'jumlah': itemCount,
      'subtotal': subtotal,
      'ppnRate': taxRate,
      'ppn': tax,
      'diskon': discount,
      'diskonInput': discountInput,
      'jenisDiskon': discountType,
      if (paymentProofBytes != null)
        'buktiPembayaranBase64': base64Encode(paymentProofBytes),
      'total': total,
      'tipe': orderType,
      'bayar': 'Pending',
      'selesai': false,
      'cart': cartItems,
    });
  }

  static Future<void> savePaidTransaction({
    required Map<String, String> orderCode,
    required DateTime time,
    required String customerName,
    required String cashierName,
    required int itemCount,
    required double subtotal,
    required double taxRate,
    required double tax,
    required double discount,
    required double discountInput,
    required String discountType,
    required double total,
    required String paymentMethod,
    required String orderType,
    required List<Map<String, dynamic>> cart,
    required Map<String, dynamic>? existingOrder,
    required String? paymentProofName,
    required Uint8List? paymentProofBytes,
  }) async {
    final cartItems = cart.map((item) {
      return <String, dynamic>{
        'name': item['name'].toString(),
        'price': (item['price'] as num).toDouble(),
        'quantity': item['quantity'] as int,
        'category': item['category']?.toString() ?? '',
        'catatan': item['catatan']?.toString() ?? '',
      };
    }).toList();
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final proofPath = paymentProofName == null || paymentProofBytes == null
        ? null
        : await PaymentProofStore.save(
            transactionId: orderCode['id']!,
            imageName: paymentProofName,
            bytes: paymentProofBytes,
          );
    final transaction = <String, dynamic>{
      'id': orderCode['id'],
      'kode': orderCode['display'],
      'tanggal': time.toIso8601String(),
      'jam': timeLabel,
      'kasir': cashierName.trim().isEmpty ? 'Kasir' : cashierName,
      'nama': customerName,
      'jumlah': itemCount.toString(),
      'pembayaran': paymentMethod,
      'subtotal': subtotal,
      'ppnRate': taxRate,
      'ppn': tax,
      'diskon': discount,
      'diskonInput': discountInput,
      'jenisDiskon': discountType,
      if (proofPath != null) 'buktiPembayaranPath': proofPath,
      if (kIsWeb && paymentProofBytes != null)
        'buktiPembayaranBase64': base64Encode(paymentProofBytes),
      'total': total,
    };

    try {
      if (existingOrder != null) {
        await TransactionStore.markUnfinishedOrderPaid(
          id: orderCode['id']!,
          paymentMethod: paymentMethod,
          transaction: transaction,
        );
      } else {
        await TransactionStore.addPaidOrder(
          order: {
            ...transaction,
            'jumlah': itemCount,
            'tipe': orderType,
            'bayar': 'Lunas',
            'selesai': false,
            'cart': cartItems,
          },
          transaction: {},
        );
      }
    } catch (_) {
      if (proofPath != null) await PaymentProofStore.delete(proofPath);
      rethrow;
    }
  }
}
