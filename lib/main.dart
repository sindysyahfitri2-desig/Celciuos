import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/app_branding_store.dart';
import 'data/kitchen_receipt_settings_store.dart';
import 'data/owner_profile_store.dart';
import 'data/payment_methods_store.dart';
import 'data/produk_data.dart';
import 'data/receipt_settings_store.dart';
import 'data/sticker_settings_store.dart';
import 'data/transaction_store.dart';
import 'package:kasir_celcious_coffe/features/auth/presentation/pilih_peran_page.dart';

const Color _kAndroidStatusBarColor = Color(0xFF082640);
const Color _kAndroidNavBarColor = Color(0xFFFFFFFF);
const Color _kAndroidNavBarBorderColor = Color(0xFFD5DEE7);

const SystemUiOverlayStyle _kSystemOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarDividerColor: _kAndroidNavBarBorderColor,
  systemNavigationBarContrastEnforced: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Perbesar cache gambar RAM agar foto produk & staf tidak diunduh berulang kali
  PaintingBinding.instance.imageCache.maximumSize = 250;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 120 << 20;
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(_kSystemOverlayStyle);
  }
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
    await Future.wait([
      TransactionStore.initialize(),
      ProdukData.initialize(),
      AppBrandingStore.initialize(),
      OwnerProfileStore.initialize(),
      PaymentMethodsStore.initialize(),
      ReceiptSettingsStore.initialize(),
      StickerSettingsStore.initialize(),
      KitchenReceiptSettingsStore.initialize(),
    ]);
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
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: _kSystemOverlayStyle,
        ),
        textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
        primaryTextTheme: theme.primaryTextTheme.apply(
          fontFamily: 'Roboto',
        ),
      ),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        if (kIsWeb) return child;

        final mq = MediaQuery.of(context);
        final topInset = mq.padding.top;
        final bottomInset = mq.padding.bottom;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _kSystemOverlayStyle,
          child: ColoredBox(
            color: _kAndroidStatusBarColor,
            child: Column(
              children: [
                if (topInset > 0)
                  Container(
                    height: topInset,
                    width: double.infinity,
                    color: _kAndroidStatusBarColor,
                  ),
                Expanded(
                  child: MediaQuery(
                    data: mq.removePadding(
                      removeTop: topInset > 0,
                      removeBottom: bottomInset > 0,
                    ),
                    child: child,
                  ),
                ),
                if (bottomInset > 0)
                  Container(
                    height: bottomInset,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: _kAndroidNavBarColor,
                      border: Border(
                        top: BorderSide(
                          color: _kAndroidNavBarBorderColor,
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
