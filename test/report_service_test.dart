import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/reports/application/report_service.dart';

void main() {
  test('report combines orders and excludes pending sales from cash total', () {
    final oldTransactions = TransactionStore.transactions.value;
    final oldUnfinishedOrders = TransactionStore.unfinishedOrders.value;
    final oldOpeningCash = TransactionStore.shiftOpeningCash.value;
    final oldCashier = TransactionStore.shiftCashier.value;
    final oldShift = TransactionStore.activeShift.value;
    final oldShifts = TransactionStore.shiftHistory.value;
    final oldDrawerEntries = TransactionStore.cashDrawerEntries.value;

    addTearDown(() {
      TransactionStore.transactions.value = oldTransactions;
      TransactionStore.unfinishedOrders.value = oldUnfinishedOrders;
      TransactionStore.shiftOpeningCash.value = oldOpeningCash;
      TransactionStore.shiftCashier.value = oldCashier;
      TransactionStore.activeShift.value = oldShift;
      TransactionStore.shiftHistory.value = oldShifts;
      TransactionStore.cashDrawerEntries.value = oldDrawerEntries;
    });

    TransactionStore.shiftOpeningCash.value = 500;
    TransactionStore.shiftCashier.value = 'Kasir Uji';
    TransactionStore.activeShift.value = {'id': 'shift-uji', 'status': 'open'};
    TransactionStore.shiftHistory.value = [];
    TransactionStore.transactions.value = [
      {
        'id': 'cash-1',
        'tanggal': '2026-11-01T10:00:00',
        'shiftId': 'shift-uji',
        'jumlah': 1,
        'pembayaran': 'Cash',
        'bayar': 'Lunas',
        'total': 1000,
      },
      {
        'id': 'pending-1',
        'tanggal': '2026-11-01T10:05:00',
        'pembayaran': 'Cash',
        'bayar': 'Pending',
        'total': 2000,
      },
    ];
    TransactionStore.unfinishedOrders.value = [
      {
        'id': 'qris-1',
        'tanggal': '2026-11-01T10:10:00',
        'pembayaran': 'QRIS',
        'bayar': 'Lunas',
        'total': 3000,
      },
    ];
    TransactionStore.cashDrawerEntries.value = [
      {
        'shiftId': 'shift-uji',
        'jenis': 'keluar',
        'amount': 100,
        'tanggal': '2026-11-01T10:15:00',
      },
    ];

    final report = ReportService.load(cashierFallback: 'Owner');

    expect(report.transactionRows, hasLength(3));
    expect(
      report.transactionRows.map((row) => row['id']),
      containsAll(['cash-1', 'qris-1']),
    );
    final pending = report.transactionRows.singleWhere(
      (row) => row['id'] == 'pending-1',
    );
    expect(pending['status'], 'Pending');
    expect(report.currentCash, 1400);
    expect(report.drawerRows, hasLength(2));
  });
}
