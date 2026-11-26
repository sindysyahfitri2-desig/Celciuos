import 'dart:async';
import 'package:flutter/material.dart';

import 'package:kasir_celcious_coffe/features/owner/application/owner_notification_service.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaProduk.dart'
    as owner_products;
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/KelolaStaf.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/Transaksi/Kelola_Transaksi.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/stok/manajemen_stok_page.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/widgets/Navigation.dart';
import 'package:kasir_celcious_coffe/features/owner/presentation/pages/PengaturanPage.dart';
import 'package:kasir_celcious_coffe/ui/widgets/app_branding_logo.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';
import 'package:kasir_celcious_coffe/data/dashboard_service.dart';
import 'package:kasir_celcious_coffe/data/owner_profile_store.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';
import 'KelolaLaporan.dart';

// ============================================================
// WARNA DAN HELPER
// ============================================================

const Color ownerNavy = Color(0xFF082640);
const Color ownerDarkNavy = Color(0xFF082640);
const Color ownerBackground = Color(0xFFDCE9F4);
const Color ownerBlue = Color(0xFF4098CE);
const Color _mutedText = Color(0xFF667B8D);

String _formatNumber(num value) {
  return value.round().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
}

List<BoxShadow> _softShadow({bool lifted = false}) => [
  BoxShadow(
    color: ownerNavy.withValues(alpha: lifted ? 0.18 : 0.10),
    blurRadius: lifted ? 22 : 14,
    offset: Offset(0, lifted ? 9 : 5),
  ),
];

// ============================================================
// DASHBOARD OWNER
// ============================================================

class DashboardOwner extends StatefulWidget {
  const DashboardOwner({super.key, this.namaOwner = 'Daniel', this.onLogout});

  final String namaOwner;
  final VoidCallback? onLogout;

  @override
  State<DashboardOwner> createState() => _DashboardOwnerState();
}

class _DashboardOwnerState extends State<DashboardOwner> {
  int selectedMenu = 0;
  bool _openProfileOnPengaturan = false;
  int _profileRequestId = 0;
  List<OwnerNotificationItem> _notifications = const [];
  final Set<String> _readNotificationIds = {};
  Timer? _notifTimer;
  bool _loadingNotif = false;
  final List<Widget?> _cachedPages = List<Widget?>.filled(7, null);
  int _cachedPengaturanReqId = -1;

  static const menuTitles = [
    'Dashboard',
    'Kelola Laporan',
    'Kelola Produk',
    'Manajemen Stok',
    'Transaksi',
    'Kelola Staf',
    'Pengaturan',
  ];

  @override
  void initState() {
    super.initState();
    OwnerProfileStore.initialize(fallbackName: widget.namaOwner);
    OwnerProfileStore.ownerName.addListener(_onOwnerProfileChanged);
    OwnerProfileStore.photoBytes.addListener(_onOwnerProfileChanged);
    OwnerProfileStore.photoUrl.addListener(_onOwnerProfileChanged);
    // Tunda muat notifikasi 1.5 detik agar Dashboard utama selesai lebih dulu
    // tanpa berebut antrean dengan server PHP lokal.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _muatNotifikasi();
    });
    _notifTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _muatNotifikasi();
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    OwnerProfileStore.ownerName.removeListener(_onOwnerProfileChanged);
    OwnerProfileStore.photoBytes.removeListener(_onOwnerProfileChanged);
    OwnerProfileStore.photoUrl.removeListener(_onOwnerProfileChanged);
    super.dispose();
  }

  int get _unreadNotifCount => _notifications
      .where((n) => !_readNotificationIds.contains(n.id))
      .length;

  Future<void> _muatNotifikasi() async {
    if (_loadingNotif) return;
    _loadingNotif = true;
    try {
      final items = await OwnerNotificationService.fetchAll();
      if (!mounted) return;
      setState(() {
        _notifications = items;
      });
    } finally {
      _loadingNotif = false;
    }
  }

  Future<void> _bukaPanelNotifikasi() async {
    if (!mounted) return;

    OwnerNotifType? filter;
    bool refreshing = false;
    bool modalOpen = true;
    StateSetter? activeModalSetter;

    Future<void> refreshInBackground() async {
      if (refreshing) return;
      refreshing = true;
      if (modalOpen) activeModalSetter?.call(() {});
      await _muatNotifikasi();
      refreshing = false;
      if (modalOpen) activeModalSetter?.call(() {});
    }

    // Buka panel INSTAN dengan data yang sudah tersedia, sambil refresh di latar belakang
    refreshInBackground();

    final isPhone = MediaQuery.sizeOf(context).width < 600;

    Widget buildPanelContent(BuildContext panelCtx, StateSetter setModalState) {
      activeModalSetter = setModalState;

      final filtered = filter == null
          ? _notifications
          : _notifications.where((n) => n.type == filter).toList();

      Widget chipFilter(String label, OwnerNotifType? value) {
        final active = filter == value;
        return InkWell(
          onTap: () => setModalState(() => filter = value),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: active ? ownerNavy : const Color(0xFFEAF2F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : ownerNavy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }

      IconData iconFor(OwnerNotifType type) => switch (type) {
        OwnerNotifType.stok => Icons.inventory_2_rounded,
        OwnerNotifType.shift => Icons.point_of_sale_rounded,
        OwnerNotifType.order => Icons.receipt_long_rounded,
      };

      Color colorFor(OwnerNotificationItem item) {
        if (item.type == OwnerNotifType.stok) {
          return item.title.startsWith('Stok Habis')
              ? const Color(0xFFDC2626)
              : const Color(0xFFD97706);
        }
        if (item.type == OwnerNotifType.shift) {
          return item.isUrgent
              ? const Color(0xFFD97706)
              : const Color(0xFF16558A);
        }
        return item.isUrgent
            ? const Color(0xFFD97706)
            : const Color(0xFF00875A);
      }

      final topRadius = isPhone ? 22.0 : 20.0;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isPhone
              ? BorderRadius.vertical(top: Radius.circular(topRadius))
              : BorderRadius.circular(topRadius),
          boxShadow: _softShadow(lifted: true),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(
                18,
                isPhone ? 10 : 16,
                12,
                14,
              ),
              decoration: BoxDecoration(
                color: ownerNavy,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(topRadius),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPhone) ...[
                    Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifikasi Owner',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Stok, Pengawasan Shift & Pesanan Meja',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: refreshing ? null : refreshInBackground,
                        icon: refreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                      ),
                      IconButton(
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.of(panelCtx).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    chipFilter('Semua (${_notifications.length})', null),
                    const SizedBox(width: 6),
                    chipFilter('Stok', OwnerNotifType.stok),
                    const SizedBox(width: 6),
                    chipFilter('Shift & Kas', OwnerNotifType.shift),
                    const SizedBox(width: 6),
                    chipFilter('Pesanan', OwnerNotifType.order),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Daftar Notifikasi
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            refreshing
                                ? Icons.sync_rounded
                                : Icons.notifications_off_outlined,
                            size: 42,
                            color: _mutedText,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            refreshing
                                ? 'Memuat notifikasi...'
                                : 'Semua aman — tidak ada notifikasi.',
                            style: const TextStyle(
                              color: ownerNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final unread =
                            !_readNotificationIds.contains(item.id);
                        final accent = colorFor(item);
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            setState(() {
                              _readNotificationIds.add(item.id);
                            });
                            Navigator.of(panelCtx).pop();
                            selectMenu(item.targetMenuIndex);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: unread
                                  ? const Color(0xFFF0F7FD)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: unread
                                    ? accent.withValues(alpha: 0.35)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    iconFor(item.type),
                                    color: accent,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: const TextStyle(
                                                color: ownerNavy,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            item.timeLabel,
                                            style: TextStyle(
                                              color: item.isUrgent
                                                  ? accent
                                                  : _mutedText,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.subtitle,
                                        style: const TextStyle(
                                          color: _mutedText,
                                          fontSize: 11.5,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Footer
            if (_notifications.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: isPhone
                      ? BorderRadius.zero
                      : const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Ketuk item untuk buka halaman terkait',
                        style: TextStyle(
                          color: _mutedText,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (final n in _notifications) {
                            _readNotificationIds.add(n.id);
                          }
                        });
                        setModalState(() {});
                      },
                      child: const Text(
                        'Tandai dibaca',
                        style: TextStyle(
                          color: ownerNavy,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    if (isPhone) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) {
          final maxH = MediaQuery.sizeOf(sheetCtx).height * 0.78;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: StatefulBuilder(
              builder: (context, setModalState) =>
                  buildPanelContent(sheetCtx, setModalState),
            ),
          );
        },
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 440,
                maxHeight: 560,
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) =>
                    buildPanelContent(dialogCtx, setModalState),
              ),
            ),
          );
        },
      );
    }

    modalOpen = false;
    activeModalSetter = null;

    // Tandai terbaca setelah panel ditutup agar badge tetap bersih
    if (mounted && _notifications.isNotEmpty) {
      setState(() {
        for (final n in _notifications) {
          _readNotificationIds.add(n.id);
        }
      });
    }
  }

  void _onOwnerProfileChanged() {
    if (mounted) setState(() {});
  }

  String get _currentOwnerName {
    final stored = OwnerProfileStore.ownerName.value.trim();
    return stored.isNotEmpty ? stored : widget.namaOwner;
  }

  void selectMenu(int index) {
    if (index < 0 || index >= menuTitles.length) return;
    setState(() {
      selectedMenu = index;
      if (index != 6) {
        _openProfileOnPengaturan = false;
      }
    });
  }

  void _openOwnerProfileSettings({bool closeDrawer = false}) {
    if (closeDrawer) {
      Navigator.of(context).pop();
    }
    setState(() {
      selectedMenu = 6;
      _openProfileOnPengaturan = true;
      _profileRequestId++;
    });
  }

  void _pilihMenuDariDrawer(int index) {
    Navigator.of(context).pop();
    selectMenu(index);
  }

  Widget _buildLaporan() {
    return _OwnerLaporanLivePage(namaOwner: _currentOwnerName);
  }

  Future<void> _konfirmasiLogout({bool closeDrawer = false}) async {
    if (widget.onLogout == null) return;
    if (closeDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC4C5B)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Konfirmasi Keluar',
                style: TextStyle(
                  color: ownerNavy,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Anda yakin ingin keluar dari Dashboard Owner?\n\n'
          'Anda perlu memasukkan PIN atau Face ID kembali untuk masuk lagi.',
          style: TextStyle(color: Color(0xFF3A5268), fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: _mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC4C5B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text(
              'Ya, Keluar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (yakin == true && mounted) {
      widget.onLogout?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        return Scaffold(
          backgroundColor: ownerBackground,
          drawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: ownerNavy,
                  child: SafeArea(
                    child: OwnerNavigation(
                      selectedIndex: selectedMenu,
                      ownerName: _currentOwnerName,
                      onDestinationSelected: _pilihMenuDariDrawer,
                      onDashboard: () => _pilihMenuDariDrawer(0),
                      onLaporan: () => _pilihMenuDariDrawer(1),
                      onProduk: () => _pilihMenuDariDrawer(2),
                      onStok: () => _pilihMenuDariDrawer(3),
                      onTransaksi: () => _pilihMenuDariDrawer(4),
                      onKelolaStaf: () => _pilihMenuDariDrawer(5),
                      onPengaturan: () => _pilihMenuDariDrawer(6),
                      onProfileTap: () =>
                          _openOwnerProfileSettings(closeDrawer: true),
                      onLogout: widget.onLogout == null
                          ? null
                          : () => _konfirmasiLogout(closeDrawer: true),
                    ),
                  ),
                ),
          body: SafeArea(
            child: Column(
              children: [
                _topBar(isDesktop: isDesktop),
                Expanded(
                  child: Row(
                    children: [
                      if (isDesktop)
                        OwnerNavigation(
                          selectedIndex: selectedMenu,
                          ownerName: _currentOwnerName,
                          onDestinationSelected: selectMenu,
                          onDashboard: () => selectMenu(0),
                          onLaporan: () => selectMenu(1),
                          onProduk: () => selectMenu(2),
                          onStok: () => selectMenu(3),
                          onTransaksi: () => selectMenu(4),
                          onKelolaStaf: () => selectMenu(5),
                          onPengaturan: () => selectMenu(6),
                          onProfileTap: () => _openOwnerProfileSettings(),
                          onLogout: widget.onLogout == null
                              ? null
                              : () => _konfirmasiLogout(),
                        ),
                      Expanded(child: _content()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageForIndex(int index) {
    return switch (index) {
      0 => _DashboardBody(namaOwner: _currentOwnerName),
      1 => _buildLaporan(),
      2 => const owner_products.ProdukPage(),
      3 => const ManajemenStokPage(),
      4 => KelolaTransaksiPage(
        pakaiDataContoh: false,
        initialTab: 0,
        onNavigasiLaporan: () => selectMenu(1),
      ),
      5 => const KontrolStafPage(),
      6 => PengaturanPage(
        initialOpenProfile: _openProfileOnPengaturan,
        profileRequestId: _profileRequestId,
      ),
      _ => _DashboardBody(namaOwner: _currentOwnerName),
    };
  }

  Widget _content() {
    // Pastikan halaman yang dipilih dibangun sekali (lazy) dan dipertahankan
    // di memori agar perpindahan antar menu Owner instan tanpa loading ulang.
    if (selectedMenu == 6 && _cachedPengaturanReqId != _profileRequestId) {
      _cachedPages[6] = _buildPageForIndex(6);
      _cachedPengaturanReqId = _profileRequestId;
    } else {
      _cachedPages[selectedMenu] ??= _buildPageForIndex(selectedMenu);
    }

    return IndexedStack(
      index: selectedMenu,
      children: List<Widget>.generate(
        menuTitles.length,
        (i) => _cachedPages[i] ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _topBar({required bool isDesktop}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ownerNavy,
        boxShadow: [
          BoxShadow(
            color: ownerNavy.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Buka menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
              ),
            ),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF3979AD),
              shape: BoxShape.circle,
            ),
            child: const ClipOval(child: AppBrandingLogo(fallbackIconSize: 18)),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Celcious Coffee',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Dashboard Owner',
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifikasi',
                visualDensity: VisualDensity.compact,
                onPressed: _bukaPanelNotifikasi,
                icon: Icon(
                  _unreadNotifCount > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ownerNavy, width: 1.2),
                      ),
                      child: Text(
                        _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Pengaturan Profil Owner',
            child: InkWell(
              onTap: () => _openOwnerProfileSettings(),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EEF6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: OwnerProfileStore.photoBytes.value != null
                    ? Image.memory(
                        OwnerProfileStore.photoBytes.value!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person,
                          color: ownerNavy,
                          size: 19,
                        ),
                      )
                    : (OwnerProfileStore.photoUrl.value != null &&
                            OwnerProfileStore.photoUrl.value!.isNotEmpty)
                        ? Image.network(
                            OwnerProfileStore.photoUrl.value!,
                            fit: BoxFit.cover,
                            headers: const {
                              'ngrok-skip-browser-warning': 'true',
                            },
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person,
                              color: ownerNavy,
                              size: 19,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            color: ownerNavy,
                            size: 19,
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// ============================================================
// DASHBOARD BODY
// ============================================================

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({required this.namaOwner});

  final String namaOwner;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody>
    with TickerProviderStateMixin {
  late final AnimationController _chartController;
  late final AnimationController _entryController;
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = false;
  Object? _error;

  late final Animation<double> _headerAnimation;
  late final List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _headerAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
    );

    _cardAnimations = List.generate(
      3,
      (index) => CurvedAnimation(
        parent: _entryController,
        curve: Interval(
          0.12 + (index * 0.13),
          0.72 + (index * 0.09),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // Tampilkan data cache seketika (0 ms) jika tersedia, lalu segarkan di latar belakang
    _dashboardData = DashboardService.cachedData;
    _entryController.forward();
    if (_dashboardData != null) {
      _chartController.forward();
    }
    _muat(silent: _dashboardData != null);
  }

  @override
  void dispose() {
    _chartController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _muat({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final result = await DashboardService().ambilDashboard();
      if (!mounted) return;
      setState(() {
        _dashboardData = result;
        _isLoading = false;
        _error = null;
      });
      if (_chartController.status != AnimationStatus.completed) {
        _chartController.forward();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_dashboardData == null) _error = e;
      });
    }
  }

  double _num(dynamic value) => double.tryParse('$value') ?? 0;

  Future<void> _refresh() async {
    await _muat(silent: true);
    if (!mounted) return;
    _chartController
      ..reset()
      ..forward();
  }

  Widget _animatedCard(int index, Widget child) {
    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, _) {
        final progress = _cardAnimations[index].value;
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _dashboardData == null) {
      return const Center(
        child: CircularProgressIndicator(color: ownerNavy),
      );
    }

    if (_error != null && _dashboardData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                'Terjadi kesalahan:\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: ownerNavy),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _muat(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _dashboardData ?? {};
        final ringkasan = (data['ringkasan'] as Map<String, dynamic>?) ?? {};
        final metode = (data['distribusi_metode'] as List?) ?? [];

        final omzet = _num(ringkasan['omzet_hari_ini']);
        final totalTrx = _num(ringkasan['total_transaksi']);

        final totalNonTunai = metode.fold<double>(
          0,
          (sum, item) => sum + _num(item['total_nominal']),
        );

        final kasLaci = _num(
          ringkasan['kas_laci'] ??
              ringkasan['total_tunai'] ??
              (omzet - totalNonTunai),
        );

        final rincianMetode = <String>[];
        if (kasLaci > 0) {
          rincianMetode.add('Tunai Rp. ${_formatNumber(kasLaci)}');
        }
        for (final item in metode) {
          final nama =
              (item['metode'] ?? item['metode_pembayaran'] ?? 'Non Tunai')
                  .toString();
          rincianMetode.add(
            '$nama Rp. ${_formatNumber(_num(item['total_nominal']))}',
          );
        }

        final detailMetode = rincianMetode.isEmpty
            ? 'Tunai Rp. ${_formatNumber(kasLaci)} • '
                  'Non Tunai Rp. ${_formatNumber(totalNonTunai)}'
            : rincianMetode.join(' • ');

        final summaries = [
          _SummaryData(
            title: 'Total Omset Penjualan',
            amount: omzet,
            icon: Icons.payments_outlined,
            accent: ownerNavy,
            detail: 'Target Harian (Rp. 4.000.000)',
            progress: (omzet / 4000000).clamp(0.0, 1.0),
          ),
          _SummaryData(
            title: 'Kas Laci & Non Tunai',
            amount: kasLaci + totalNonTunai > 0
                ? kasLaci + totalNonTunai
                : omzet,
            icon: Icons.account_balance_wallet_outlined,
            accent: const Color(0xFF1687A7),
            detail: detailMetode,
            progress: omzet > 0 ? (totalNonTunai / omzet).clamp(0.0, 1.0) : 0,
          ),
          _SummaryData(
            title: 'Total Transaksi',
            amount: totalTrx,
            suffix: 'Struk',
            icon: Icons.receipt_long_outlined,
            accent: const Color(0xFF159B76),
            detail: 'Transaksi hari ini',
            progress: 1,
          ),
        ];

        final grafik = ((data['grafik_per_jam'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isPhone = width < 600;
            final isTablet = width >= 600 && width < 1000;

            final horizontalPadding = isPhone
                ? 14.0
                : isTablet
                ? 20.0
                : 24.0;

            return Container(
              color: ownerBackground,
              child: RefreshIndicator(
                color: ownerNavy,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isPhone ? 18 : 22,
                    horizontalPadding,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _headerAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-0.07, 0),
                            end: Offset.zero,
                          ).animate(_headerAnimation),
                          child: Text(
                            'Halo Bos ${widget.namaOwner}',
                            style: TextStyle(
                              color: const Color(0xFF07506D),
                              fontSize: isPhone
                                  ? 23
                                  : isTablet
                                  ? 27
                                  : 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              height: 1.1,
                              shadows: const [
                                Shadow(
                                  color: Color(0x6689A7B8),
                                  offset: Offset(1, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isPhone ? 22 : 34),

                      // Kartu ringkasan adaptif:
                      // - HP (< 600px): 1 kartu utama penuh di atas + 2 kartu sejajar di bawah (teks besar & nyaman dibaca)
                      // - Tablet & Laptop (>= 600px): 3 kartu sejajar horizontal
                      if (isPhone) ...[
                        _animatedCard(
                          0,
                          _SummaryCard(
                            data: summaries[0],
                            compact: false,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _animatedCard(
                                1,
                                _SummaryCard(
                                  data: summaries[1],
                                  compact: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _animatedCard(
                                2,
                                _SummaryCard(
                                  data: summaries[2],
                                  compact: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < summaries.length; i++) ...[
                              if (i > 0)
                                SizedBox(
                                  width: isTablet ? 10 : 14,
                                ),
                              Expanded(
                                child: _animatedCard(
                                  i,
                                  _SummaryCard(
                                    data: summaries[i],
                                    compact: false,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                      SizedBox(height: isPhone ? 20 : 28),

                      FadeTransition(
                        opacity: _cardAnimations[2],
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(_cardAnimations[2]),
                          child: _SalesChartCard(
                            controller: _chartController,
                            data: grafik,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }
}

// ============================================================
// DATA SUMMARY
// ============================================================

class _SummaryData {
  const _SummaryData({
    required this.title,
    required this.amount,
    required this.icon,
    required this.accent,
    required this.detail,
    required this.progress,
    this.suffix,
  });

  final String title;
  final double amount;
  final String? suffix;
  final IconData icon;
  final Color accent;
  final String detail;
  final double progress;
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, this.compact = false});

  final _SummaryData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTiny = compact || width < 145;
        final scale = (width / 270).clamp(0.78, 1.15);
        final isNarrow = width < 230;
        final cardHeight = isTiny
            ? 136.0
            : (data.suffix == null ? (isNarrow ? 150.0 : 156.0) : 148.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: cardHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTiny ? 11 : 14),
            border: Border.all(
              color: const Color(0xFFC5DBEE),
              width: 1,
            ),
            boxShadow: _softShadow(),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: isTiny ? (width * 0.55) : 105 * scale,
                  height: isTiny ? 6 : 8,
                  decoration: BoxDecoration(
                    color: data.accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: isTiny
                    ? const EdgeInsets.fromLTRB(8, 11, 8, 8)
                    : EdgeInsets.fromLTRB(13 * scale, 15, 13 * scale, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            maxLines: isTiny ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ownerNavy,
                              fontSize: isTiny ? 10.5 : 11.5 * scale,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                        if (!isTiny) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3FB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(data.icon, size: 15, color: ownerNavy),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: isTiny ? 6 : 8),
                    if (data.suffix != null)
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatNumber(data.amount),
                                  style: TextStyle(
                                    color: ownerNavy,
                                    fontSize: isTiny ? 24 : 35 * scale,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 3,
                                    bottom: 3,
                                  ),
                                  child: Text(
                                    data.suffix!,
                                    style: TextStyle(
                                      color: ownerNavy,
                                      fontSize: isTiny ? 8.5 : 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Rp. ${_formatNumber(data.amount)}',
                          style: TextStyle(
                            color: ownerNavy,
                            fontSize: isTiny ? 17 : 27 * scale,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    if (data.suffix == null) ...[
                      const Spacer(),
                      if (data.title == 'Kas Laci & Non Tunai')
                        ...data.detail
                            .split(' • ')
                            .where((line) => line.isNotEmpty)
                            .take(isTiny ? 1 : 2)
                            .map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: data.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        line,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: ownerNavy,
                                          fontSize: isTiny ? 9.2 : 9.0 * scale,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                      else ...[
                        Text(
                          data.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ownerNavy,
                            fontSize: isTiny ? 7.5 : 8.5 * scale,
                          ),
                        ),
                        SizedBox(height: isTiny ? 4 : 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: data.progress,
                            minHeight: isTiny ? 3.5 : 4,
                            backgroundColor: const Color(0xFFE5EAF0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              data.accent,
                            ),
                          ),
                        ),
                      ],
                      if (data.title == 'Total Omset Penjualan' && !isTiny)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Sisa Rp. ${_formatNumber((4000000 - data.amount).clamp(0, 4000000))}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _mutedText,
                                    fontSize: 7.5 * scale,
                                  ),
                                ),
                              ),
                              Text(
                                '${(data.progress * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: ownerNavy,
                                  fontSize: 7.5 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// SALES CHART
// ============================================================

class _SalesChartCard extends StatefulWidget {
  const _SalesChartCard({required this.controller, required this.data});

  final AnimationController controller;
  final List<Map<String, dynamic>> data;

  @override
  State<_SalesChartCard> createState() => _SalesChartCardState();
}

class _SalesChartCardState extends State<_SalesChartCard> {
  int? activeIndex;

  double _num(dynamic value) => double.tryParse('$value') ?? 0;

  List<Map<String, dynamic>> get chartData {
    final first = widget.data.indexWhere((e) => _num(e['total']) > 0);
    if (first == -1) return const [];

    final last = widget.data.lastIndexWhere((e) => _num(e['total']) > 0);
    return widget.data.sublist(first, last + 1);
  }

  List<double> get totals => chartData.map((e) => _num(e['total'])).toList();

  List<String> get hours => chartData.map((e) {
    final value = '${e['jam']}';
    return value.length >= 2 ? value.substring(0, 2) : value;
  }).toList();

  double get maxTotal => totals.fold<double>(0, (a, b) => a > b ? a : b);

  int get peakIndex => maxTotal > 0 ? totals.indexOf(maxTotal) : -1;

  double get average {
    final active = totals.where((e) => e > 0).toList();
    if (active.isEmpty) return 0;
    return active.reduce((a, b) => a + b) / active.length;
  }

  @override
  Widget build(BuildContext context) {
    final n = totals.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 600;
        final chartHeight = isPhone ? 220.0 : 280.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isPhone ? 13 : 20,
            16,
            isPhone ? 13 : 20,
            14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _softShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 21,
                    decoration: BoxDecoration(
                      color: ownerBlue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'GRAFIK PENJUALAN CELCIOUS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF315A80),
                        fontSize: isPhone ? 12 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (n == 0 || maxTotal == 0)
                const SizedBox(
                  height: 160,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 38,
                          color: Color(0xFF9AAFC0),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada penjualan hari ini.',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: chartHeight,
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final barMaxHeight = chartHeight * 0.70;
                      final slot = box.maxWidth / n;
                      final tooltipWidth = (box.maxWidth * 0.48).clamp(
                        125.0,
                        205.0,
                      );
                      final tooltipLeft = peakIndex < 0
                          ? 0.0
                          : ((peakIndex + 0.5) * slot - tooltipWidth / 2).clamp(
                              0.0,
                              box.maxWidth - tooltipWidth,
                            );

                      return Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 24 + barMaxHeight * (average / maxTotal),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFF9BAFC0),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F4FA),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'Rata-rata: Rp. ${_formatNumber(average)}',
                                    style: const TextStyle(
                                      color: Color(0xFF1687C1),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned.fill(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(
                                n,
                                (index) => Expanded(
                                  child: _buildBar(index, chartHeight),
                                ),
                              ),
                            ),
                          ),
                          if (peakIndex >= 0)
                            Positioned(
                              top: 0,
                              left: tooltipLeft,
                              width: tooltipWidth,
                              child: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: ownerNavy,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Jam Sibuk Tertinggi (${hours[peakIndex]}:00)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${_formatNumber(maxTotal)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(int index, double chartHeight) {
    final isPeak = index == peakIndex;
    final isActive = activeIndex == index;
    final amount = totals[index];
    final ratio = maxTotal > 0 ? amount / maxTotal : 0.0;
    final barMaxHeight = chartHeight * 0.70;

    return MouseRegion(
      onEnter: (_) => setState(() => activeIndex = index),
      onExit: (_) => setState(() => activeIndex = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            activeIndex = activeIndex == index ? null : index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedBuilder(
                    animation: widget.controller,
                    builder: (context, child) {
                      final progress = Curves.easeOutCubic.transform(
                        widget.controller.value,
                      );

                      return Container(
                        height: barMaxHeight * ratio * progress,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isPeak
                                ? const [
                                    Color(0xFF35CBA0),
                                    Color(0xFF2B9FC0),
                                    Color(0xFF082640),
                                  ]
                                : const [Color(0xFF3D6997), Color(0xFF365D88)],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hours[index],
                maxLines: 1,
                style: TextStyle(
                  color: isActive || isPeak ? ownerNavy : Colors.black54,
                  fontSize: 8,
                  fontWeight: isActive || isPeak
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (isActive)
                Text(
                  _formatNumber(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ownerNavy,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WRAPPER LIVE KELOLA LAPORAN OWNER (TERHUBUNG KE BACKEND API)
// ============================================================

enum _PeriodeLaporanOwner { hariIni, bulanIni, semua }

class _OwnerLaporanLivePage extends StatefulWidget {
  const _OwnerLaporanLivePage({required this.namaOwner});

  final String namaOwner;

  @override
  State<_OwnerLaporanLivePage> createState() => _OwnerLaporanLivePageState();
}

class _OwnerLaporanLivePageState extends State<_OwnerLaporanLivePage> {
  static Map<String, dynamic>? _cachedTokoRes;
  static Map<String, dynamic>? _cachedShiftRes;

  _PeriodeLaporanOwner _periode = _PeriodeLaporanOwner.hariIni;
  bool _loading = true;
  LaporanPreviewData? _previewData;
  String _judulLaporan = 'LAPORAN TRANSAKSI CELCIOUS COFFEE';
  String _tanggalLaporan = '';

  static const _bulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  String _formatTglRow(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }

  Future<void> _muatData({_PeriodeLaporanOwner? overridePeriode}) async {
    final target = overridePeriode ?? _periode;
    if (mounted) {
      setState(() {
        _periode = target;
        _loading = true;
      });
    }

    final now = DateTime.now();
    late DateTime dari;
    final sampai = now;
    late String judul;
    late String labelPeriode;

    switch (target) {
      case _PeriodeLaporanOwner.hariIni:
        dari = DateTime(now.year, now.month, now.day);
        judul = 'LAPORAN TRANSAKSI CELCIOUS COFFEE';
        labelPeriode = '${now.day} ${_bulan[now.month - 1]} ${now.year}';
      case _PeriodeLaporanOwner.bulanIni:
        dari = DateTime(now.year, now.month, 1);
        judul = 'LAPORAN TRANSAKSI BULANAN CELCIOUS COFFEE';
        labelPeriode = '${_bulan[now.month - 1]} ${now.year}';
      case _PeriodeLaporanOwner.semua:
        dari = DateTime(2024, 1, 1);
        judul = 'LAPORAN TRANSAKSI KESELURUHAN CELCIOUS COFFEE';
        labelPeriode = 'Semua Periode s.d. ${now.day} ${_bulan[now.month - 1]} ${now.year}';
    }

    try {
      final query = <String, String>{
        'dari_tanggal': _isoDate(dari),
        'sampai_tanggal': _isoDate(sampai),
      };

      final res = await Future.wait([
        ApiService.get(
          'laporan',
          query: {...query, 'status_bayar': 'lunas'},
        ).catchError((_) => <String, dynamic>{}),
        ApiService.get(
          'laporan/kas-laci',
          query: query,
        ).catchError((_) => <String, dynamic>{}),
        _cachedTokoRes != null
            ? Future.value(_cachedTokoRes!)
            : ApiService.get('pengaturan-toko')
                .then((v) => _cachedTokoRes = v)
                .catchError((_) => <String, dynamic>{}),
        _cachedShiftRes != null && overridePeriode != null
            ? Future.value(_cachedShiftRes!)
            : ApiService.get('shift/aktif')
                .then((v) => _cachedShiftRes = v)
                .catchError((_) => <String, dynamic>{}),
      ]);

      final lapData = res[0]['data'] is Map
          ? Map<String, dynamic>.from(res[0]['data'] as Map)
          : <String, dynamic>{};
      final ringkasan = lapData['ringkasan'] is Map
          ? Map<String, dynamic>.from(lapData['ringkasan'] as Map)
          : <String, dynamic>{};
      final trxRaw = (lapData['transaksi'] as List? ?? const []).whereType<Map>();

      final rows = trxRaw.map((t) {
        final kode = t['kode']?.toString() ?? 'TRX-${t['id_transaksi']}';
        final pelanggan = t['nama_pelanggan']?.toString().trim() ?? '';
        final kasir = (t['pengguna'] is Map ? t['pengguna']['nama']?.toString() : null) ?? 'Kasir';
        final metode = (t['metode_pembayaran'] is Map
                ? t['metode_pembayaran']['nama_metode']?.toString()
                : null) ??
            (t['midtrans_order_id'] != null ? 'QRIS' : 'Cash');
        final ket = pelanggan.isNotEmpty ? '$kode - $pelanggan ($kasir)' : '$kode - $kasir';

        final rawWaktu = (t['dibayar_pada'] ?? t['tanggal'])?.toString() ?? '';
        final dtLocal = DateTime.tryParse(rawWaktu)?.toLocal();
        final jamText = dtLocal != null
            ? '${dtLocal.hour.toString().padLeft(2, '0')}:${dtLocal.minute.toString().padLeft(2, '0')}'
            : '-';

        final details = (t['detail_transaksi'] as List? ?? const []).whereType<Map>();
        final qtySum = details.fold<int>(
          0,
          (sum, d) => sum + (int.tryParse('${d['jumlah'] ?? 0}') ?? 0),
        );
        final pesananItems = details
            .map((d) {
              final nama = ((d['produk'] is Map ? d['produk']['nama_produk'] : null) ??
                      d['nama_produk'] ??
                      'Menu')
                  .toString()
                  .trim();
              final q = int.tryParse('${d['jumlah'] ?? 1}') ?? 1;
              return q > 1 ? '$nama ($q)' : nama;
            })
            .where((s) => s.isNotEmpty)
            .toList();

        return LaporanPreviewRow(
          tanggal: rawWaktu.isNotEmpty ? rawWaktu : _formatTglRow(rawWaktu),
          idPemesanan: kode,
          jam: jamText,
          namaKasir: kasir,
          pesanan: pesananItems.isEmpty ? '-' : pesananItems.join(', '),
          jumlahPemesanan: qtySum > 0 ? qtySum : 1,
          keterangan: ket,
          metode: metode,
          nominal: _toDouble(t['total']),
        );
      }).toList();

      // Beban operasional & data lengkap Laporan Kas Laci pada periode yang sama
      final kasData = res[1]['data'] is Map
          ? Map<String, dynamic>.from(res[1]['data'] as Map)
          : <String, dynamic>{};
      final kasRingkasan = kasData['ringkasan'] is Map
          ? Map<String, dynamic>.from(kasData['ringkasan'] as Map)
          : <String, dynamic>{};
      final openingCash = _toDouble(kasRingkasan['kas_awal']);
      final currentCash = _toDouble(kasRingkasan['kas_saat_ini']);
      final kasBaris = (kasData['baris'] as List? ?? const []).whereType<Map>();
      final drawerRows = kasBaris.map((b) {
        final rawWaktu = b['waktu']?.toString() ?? '';
        final dtLocal = DateTime.tryParse(rawWaktu)?.toLocal();
        final jamText = dtLocal != null
            ? '${dtLocal.hour.toString().padLeft(2, '0')}:${dtLocal.minute.toString().padLeft(2, '0')}'
            : '--:--';
        final jenis = (b['jenis']?.toString() ?? 'masuk').toLowerCase();
        final jumlah = _toDouble(b['jumlah']);
        final formatted = jumlah.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
        return <String, String>{
          'kasir': b['kasir']?.toString() ?? 'Kasir',
          'tanggal': rawWaktu,
          'jam': jamText,
          'nominal': '${jenis == 'keluar' ? '-' : '+'}$formatted',
          'keterangan': b['keterangan']?.toString() ?? '',
          'jenis': jenis,
          'shiftId': b['id_shift']?.toString() ?? '',
        };
      }).toList();

      final bebanItems = kasBaris
          .where((b) => b['jenis']?.toString().toLowerCase() == 'keluar')
          .map((b) {
            final ket = (b['keterangan']?.toString() ?? '').trim();
            return LaporanNominalItem(
              label: ket.isEmpty ? 'Pengeluaran Kas Laci' : ket,
              nominal: _toDouble(b['jumlah']),
            );
          })
          .toList();

      // Pengaturan toko (alamat & PPN)
      final tokoData = res[2]['data'] is Map
          ? Map<String, dynamic>.from(res[2]['data'] as Map)
          : <String, dynamic>{};
      final alamatRaw = tokoData['alamat']?.toString().trim() ?? '';
      final alamatToko = alamatRaw.isNotEmpty
          ? alamatRaw
          : 'Jl. Arah Kampung Satu, Mekar Sawit, Kec. Sawit Seberang, Kab. Langkat, Sumatera Utara';
      final ppnPersen = _toDouble(tokoData['ppn_persen']);

      // Nama kasir aktif atau dari transaksi terbaru
      final shiftWrap = res[3]['data'];
      String namaKasir = 'Kasir';
      String? namaKasirSiang;
      String? namaKasirMalam;
      if (shiftWrap is Map && shiftWrap['shift'] is Map) {
        final shift = shiftWrap['shift'] as Map;
        final kasir2 = shift['kasir2'];
        final kasir1 = shift['kasir1'];
        if (kasir1 is Map && (kasir1['nama']?.toString().trim().isNotEmpty ?? false)) {
          namaKasirSiang = kasir1['nama'].toString().trim();
        }
        if (kasir2 is Map && (kasir2['nama']?.toString().trim().isNotEmpty ?? false)) {
          namaKasirMalam = kasir2['nama'].toString().trim();
          namaKasir = namaKasirMalam;
        } else if (namaKasirSiang != null) {
          namaKasir = namaKasirSiang;
        }
      } else if (trxRaw.isNotEmpty) {
        final firstPengguna = trxRaw.first['pengguna'];
        if (firstPengguna is Map && firstPengguna['nama'] != null) {
          namaKasir = firstPengguna['nama'].toString();
        }
      } else if (TransactionStore.shiftCashier.value.trim().isNotEmpty) {
        namaKasir = TransactionStore.shiftCashier.value.trim();
      }

      // Rincian pendapatan berdasarkan semua metode pembayaran aktif dari backend
      // agar total pendapatan 100% sinkron dengan Dashboard, Transaksi, & Sheet 2 Excel.
      final totalOmzet = _toDouble(ringkasan['total_pendapatan']);
      final totalTunai = _toDouble(ringkasan['total_cash']);
      final totalQris = _toDouble(ringkasan['total_qris']);
      final totalPpn = _toDouble(ringkasan['total_ppn']);
      final totalTrx =
          int.tryParse('${ringkasan['total_transaksi'] ?? rows.length}') ??
          rows.length;

      final rincianMetodeRaw =
          (ringkasan['rincian_metode'] as List? ?? const []).whereType<Map>();
      final pendapatanItems = <LaporanNominalItem>[];
      for (final m in rincianMetodeRaw) {
        final namaM = (m['nama_metode']?.toString() ?? 'Lainnya').trim();
        final nomM = _toDouble(m['total_nominal']);
        final cntM = int.tryParse('${m['total_transaksi'] ?? 0}') ?? 0;
        if (nomM > 0) {
          final isCash =
              namaM.toLowerCase().contains('cash') ||
              namaM.toLowerCase().contains('tunai');
          final label = isCash
              ? 'Penjualan Tunai / Cash ($cntM transaksi)'
              : 'Penjualan Non-Tunai / $namaM ($cntM transaksi)';
          pendapatanItems.add(LaporanNominalItem(label: label, nominal: nomM));
        }
      }

      // Jika hari ini kosong saat pertama dibuka, otomatis coba Bulan Ini 1x agar Owner langsung lihat data
      if (overridePeriode == null &&
          target == _PeriodeLaporanOwner.hariIni &&
          rows.isEmpty &&
          totalOmzet == 0) {
        await _muatData(overridePeriode: _PeriodeLaporanOwner.bulanIni);
        return;
      }

      if (!mounted) return;
      setState(() {
        _judulLaporan = judul;
        _tanggalLaporan = labelPeriode;
        _previewData = LaporanPreviewData(
          totalOmzet: totalOmzet,
          totalTunai: totalTunai,
          totalNonTunai: totalQris,
          totalTransaksi: totalTrx,
          rows: rows,
          drawerRows: drawerRows,
          openingCash: openingCash,
          currentCash: currentCash,
          pendapatanItems: pendapatanItems,
          bebanItems: bebanItems,
          pajakPersen: ppnPersen > 0 ? ppnPersen : 11,
          pajakNominal: totalPpn,
          namaKasir: namaKasir,
          namaKasirSiang: namaKasirSiang,
          namaKasirMalam: namaKasirMalam,
          namaOwner: widget.namaOwner,
          alamatToko: alamatToko,
        );
        _loading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat laporan owner dari backend: $e');
      if (!mounted) return;
      setState(() {
        _judulLaporan = judul;
        _tanggalLaporan = labelPeriode;
        _loading = false;
      });
    }
  }

  Future<void> _catatRiwayatCetak() async {
    try {
      await ApiService.post('laporan', {
        'jenis_laporan': _judulLaporan,
        'periode': _tanggalLaporan,
      });
    } catch (_) {
      // Abaikan jika gagal catat riwayat audit cetak
    }
  }

  Widget _chipPeriode(String label, _PeriodeLaporanOwner value) {
    final active = _periode == value;
    return InkWell(
      onTap: _loading ? null : () => _muatData(overridePeriode: value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? ownerNavy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? ownerNavy : ownerNavy.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : ownerNavy,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bar Filter Periode Laporan (Terhubung real-time ke Database)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          color: ownerBackground,
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chipPeriode('Hari Ini', _PeriodeLaporanOwner.hariIni),
                      const SizedBox(width: 8),
                      _chipPeriode('Bulan Ini', _PeriodeLaporanOwner.bulanIni),
                      const SizedBox(width: 8),
                      _chipPeriode('Semua Periode', _PeriodeLaporanOwner.semua),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Muat ulang data laporan',
                onPressed: _loading ? null : () => _muatData(overridePeriode: _periode),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ownerNavy,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: ownerNavy),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading && _previewData == null
              ? const Center(
                  child: CircularProgressIndicator(color: ownerNavy),
                )
              : KelolaLaporanContent(
                  judulLaporan: _judulLaporan,
                  tanggalLaporan: _tanggalLaporan,
                  previewData: _previewData,
                  onDownload: _catatRiwayatCetak,
                ),
        ),
      ],
    );
  }
}
