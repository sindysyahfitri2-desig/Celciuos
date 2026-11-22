class CashierOrderService {
  CashierOrderService._();

  /// Adds newly persisted orders without duplicating orders already on screen.
  static List<Map<String, dynamic>> mergeSavedOrders(
    List<Map<String, dynamic>> current,
    List<Map<String, dynamic>> saved,
  ) {
    final existingIds = current.map((item) => item['id']?.toString()).toSet();
    final existingTrxIds = current
        .where((item) => item['idTransaksi'] != null)
        .map((item) => item['idTransaksi'].toString())
        .toSet();
    return saved.where((order) {
      final id = order['id']?.toString();
      final trxId = order['idTransaksi']?.toString();
      if (id != null && existingIds.contains(id)) return false;
      if (trxId != null && existingTrxIds.contains(trxId)) return false;
      return true;
    }).map((
      order,
    ) {
      final quantity = _toInt(order['jumlah']);
      final totalRaw = order['total'];
      final total = totalRaw is num
          ? totalRaw.toDouble()
          : (double.tryParse(totalRaw?.toString() ?? '') ?? 0.0);
      return <String, dynamic>{
        ...order,
        'kode': order['kode']?.toString() ?? order['id'].toString(),
        'jumlah': '$quantity item',
        'harga': 'Rp.${_formatNumber(total.toInt())}',
        'selesai': order['selesai'] == true,
      };
    }).toList();
  }

  static List<Map<String, dynamic>> filterOrders({
    required List<Map<String, dynamic>> orders,
    required String searchQuery,
    required String activeFilter,
  }) {
    final search = searchQuery.toLowerCase();
    return orders.where((item) {
      final name = item['nama']?.toString().toLowerCase() ?? '';
      final code = item['kode']?.toString().replaceAll('\n', '').toLowerCase();
      if (!name.contains(search) && !(code ?? '').contains(search))
        return false;

      switch (activeFilter) {
        case 'Order Meja':
          return item['isSelfOrder'] == true;
        case 'Belum Bayar':
          return item['bayar'] == 'Pending';
        case 'Take Away':
        case 'Dine In':
          return item['tipe'] == activeFilter;
        default:
          return true;
      }
    }).toList();
  }

  static List<Map<String, dynamic>> cartForCheckout(
    Map<String, dynamic>? order,
  ) {
    final savedCart = order?['cart'];
    if (savedCart is! List) return [];
    return savedCart
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String formatRupiah(double value) =>
      'Rp ${_formatNumber(value.toInt())}';

  static String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }
    static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    final digits = RegExp(r'\d+').firstMatch(value?.toString() ?? '');
    return int.tryParse(digits?.group(0) ?? '') ?? 0;
  }
}
