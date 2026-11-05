import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/kasir/presentation/widgets/cash_drawer_panel.dart';

class CashDrawerPage extends StatelessWidget {
  const CashDrawerPage({super.key});

  static const _navy = Color(0xff082640);

  String _rupiah(double amount) {
    final digits = amount.round().toString();
    return 'Rp ${digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        TransactionStore.activeShift,
        TransactionStore.cashDrawerEntries,
        TransactionStore.transactions,
        TransactionStore.unfinishedOrders,
      ]),
      builder: (context, _) {
        final shift = TransactionStore.activeShift.value;
        final isShiftOpen = shift?['status'] == 'open';
        final balance = isShiftOpen
            ? (TransactionStore.activeShiftSummary()['expectedCash'] as num)
                  .toDouble()
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kas Laci',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isShiftOpen
                        ? 'Kelola pemasukan, pengeluaran, dan refund shift aktif.'
                        : 'Buka shift terlebih dahulu untuk mencatat transaksi kas.',
                    style: const TextStyle(color: Color(0xff607181)),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff103456), Color(0xff214f73)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _navy.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo kas yang diharapkan',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _rupiah(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isShiftOpen) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Shift ${shift?['cashier'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(child: CashDrawerPanel()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
