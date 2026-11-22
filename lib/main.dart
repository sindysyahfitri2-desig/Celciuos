import 'package:flutter/material.dart';
import 'data/app_branding_store.dart';
import 'data/owner_profile_store.dart';
import 'data/payment_methods_store.dart';
import 'data/produk_data.dart';
import 'data/receipt_settings_store.dart';
import 'data/sticker_settings_store.dart';
import 'data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/auth/presentation/pilih_peran_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    await TransactionStore.initialize();
    await ProdukData.initialize();
    await AppBrandingStore.initialize();
    await OwnerProfileStore.initialize();
    await PaymentMethodsStore.initialize();
    await ReceiptSettingsStore.initialize();
    await StickerSettingsStore.initialize();
  }

  void _retryInitialization() {
    setState(() {
      _initialization = _initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(fontFamily: 'Roboto');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Celcious Coffee',
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
        primaryTextTheme: theme.primaryTextTheme.apply(
          fontFamily: 'Roboto',
        ),
      ),
      home: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Gagal memuat data aplikasi.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _retryInitialization,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const PilihPeranPage();
        },
      ),
    );
  }
}
