import 'package:flutter/material.dart';
import 'data/app_branding_store.dart';
import 'data/produk_data.dart';
import 'data/transaction_store.dart';
import 'pages/Login.dart';

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
      home: FutureBuilder<void>(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              backgroundColor: Color(0xff082640),
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color(0xff082640),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aplikasi gagal memuat data.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _retryInitialization,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return const LoginPage();
        },
      ),
    );
  }
}
