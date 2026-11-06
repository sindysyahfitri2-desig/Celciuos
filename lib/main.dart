import 'package:flutter/material.dart';
import 'data/app_branding_store.dart';
import 'data/produk_data.dart';
import 'data/receipt_settings_store.dart';
import 'data/transaction_store.dart';
import 'features/auth/presentation/login_page.dart';
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
    await ReceiptSettingsStore.initialize();
  }

  void _retryInitialization() {
    setState(() {
      _initialization = _initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Celcious Coffee',
      home: const PilihPeranPage(),
    );
  }
}
