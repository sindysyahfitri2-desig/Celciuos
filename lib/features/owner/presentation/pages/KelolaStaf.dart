import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kasir_celcious_coffe/features/owner/application/staff_directory_controller.dart';

// ============================================================
// KONSTANTA DESAIN
// ============================================================

const _kPrimary = Color(0xFF0B2540);
const _kBackground = Color(0xFFDCE9F4);
const _kPlaceholder = Color(0xFFD9D9D9);
const _kPicker = Color(0xFFD6D1EA);
const _kMuted = Color(0xFF6B8094);

const List<BoxShadow> _kCardShadow = [
  BoxShadow(
    color: Color(0x26082640),
    blurRadius: 10,
    offset: Offset(0, 4),
  ),
];

const List<BoxShadow> _kPillShadow = [
  BoxShadow(
    color: Color(0x2E082640),
    blurRadius: 6,
    offset: Offset(0, 2),
  ),
];

// ============================================================
// HALAMAN KONTROL STAF
// ============================================================

class KontrolStafPage extends StatefulWidget {
  const KontrolStafPage({super.key});

  @override
  State<KontrolStafPage> createState() => _KontrolStafPageState();
}

class _KontrolStafPageState extends State<KontrolStafPage> {
  final StaffDirectoryController _directory = StaffDirectoryController();

  List<Staff> get staffList => _directory.staff;

  @override
  void initState() {
    super.initState();
    _directory.addListener(_refresh);
    _directory.fetchStaff();
  }

  @override
  void dispose() {
    _directory
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: error ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  // ==========================================================
  // EDIT STAF
  // ==========================================================

  Future<void> _editStaff(int index) async {
    final staff = staffList[index];
    final nameCtrl = TextEditingController(text: staff.name);

    Uint8List? newPhoto;
    bool photoChanged = false;

    final screenW = MediaQuery.of(context).size.width;
    final dialogWidth = screenW < 420 ? screenW * 0.92 : 390.0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (_, setDState) {
          Future<void> pick() async {
            final img = await ImagePicker().pickImage(
              source: ImageSource.gallery,
              maxWidth: 800,
              imageQuality: 85,
            );

            if (img != null) {
              final b = await img.readAsBytes();
              setDState(() {
                newPhoto = b;
                photoChanged = true;
              });
            }
          }

          ImageProvider? provider;
          if (newPhoto != null) {
            provider = MemoryImage(newPhoto!);
          } else if (staff.photoUrl != null) {
            provider = NetworkImage(staff.photoUrl!);
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialogWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Edit Profil Staf',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: pick,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: provider,
                            child: provider == null
                                ? Icon(
                                    Icons.person,
                                    size: 44,
                                    color: Colors.grey.shade400,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: _kPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ketuk foto untuk mengganti',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Nama Staf',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dCtx, false),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(dCtx, true),
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Simpan'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (ok != true) {
      nameCtrl.dispose();
      return;
    }

    final nm = nameCtrl.text.trim();
    nameCtrl.dispose();

    if (nm.isEmpty) {
      _snack('Nama staf tidak boleh kosong.', error: true);
      return;
    }

    final ri = staffList.indexOf(staff);

    final success = await _directory.updateStaff(
      ri,
      newName: nm,
      photoBytes: photoChanged ? newPhoto : null,
    );

    if (success) {
      _snack('Profil staf berhasil diperbarui.');
    } else if (_directory.errorMessage != null) {
      _snack(_directory.errorMessage!, error: true);
    }
  }

  // ==========================================================
  // NONAKTIFKAN STAF
  // ==========================================================

  Future<void> _confirmDeactivate(int index) async {
    final staff = staffList[index];

    final yes = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Flexible(child: Text('Nonaktifkan Staf')),
          ],
        ),
        content: Text(
          'Nonaktifkan akun ${staff.name}?\n\n'
          'Staf nonaktif tidak bisa login kasir, namun riwayat transaksi '
          'tetap tersimpan dan dapat diaktifkan kembali kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    final success = await _directory.deactivate(index);
    if (!mounted) return;

    final m = success ? _directory.infoMessage : _directory.errorMessage;
    if (m != null) _snack(m, error: !success);
  }

  // ==========================================================
  // AKTIFKAN KEMBALI
  // ==========================================================

  Future<void> _activate(int index) async {
    final success = await _directory.activate(index);
    if (!mounted) return;

    final m = success ? _directory.infoMessage : _directory.errorMessage;
    if (m != null) _snack(m, error: !success);
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final filtered = _directory.filteredStaff;

    return SizedBox.expand(
      child: ColoredBox(
        color: _kBackground,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isPhone = width < 600;
              final isTablet = width >= 600 && width < 1024;
              final pad = isPhone ? 16.0 : (isTablet ? 24.0 : 30.0);

              return RefreshIndicator(
                onRefresh: _directory.fetchStaff,
                color: _kPrimary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    pad,
                    isPhone ? 16 : 24,
                    pad,
                    28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        isPhone: isPhone,
                        onSearch: _directory.setSearchQuery,
                      ),
                      SizedBox(height: isPhone ? 18 : 24),

                      // Kartu tambah staf di bagian atas (menyerupai desain referensi)
                      if (!_directory.showInactive) ...[
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isPhone ? double.infinity : 640,
                          ),
                          child: _AddStaffCard(
                            isPhone: isPhone,
                            onSave: (s, pin) async {
                              final ok = await _directory.addStaff(s, pin: pin);

                              if (!ok &&
                                  mounted &&
                                  _directory.errorMessage != null) {
                                _snack(_directory.errorMessage!, error: true);
                              } else if (ok && mounted) {
                                _snack('Staf baru berhasil ditambahkan.');
                              }
                              return ok;
                            },
                          ),
                        ),
                        SizedBox(height: isPhone ? 18 : 22),
                      ],

                      // Filter Aktif & Nonaktif di sebelah KIRI
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _FilterBar(
                          showInactive: _directory.showInactive,
                          onChanged: _directory.setShowInactive,
                        ),
                      ),
                      SizedBox(height: isPhone ? 16 : 20),

                      // Daftar kartu staf
                      _buildBody(
                        filtered,
                        availableWidth: width - (pad * 2),
                        isPhone: isPhone,
                        isTablet: isTablet,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BODY DAFTAR STAF
  // ==========================================================

  Widget _buildBody(
    List<Staff> list, {
    required double availableWidth,
    required bool isPhone,
    required bool isTablet,
  }) {
    if (_directory.isLoading && list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: CircularProgressIndicator(color: _kPrimary),
        ),
      );
    }

    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _kCardShadow,
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              _directory.showInactive
                  ? 'Tidak ada staf nonaktif.'
                  : 'Belum ada staf terdaftar.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kMuted,
              ),
            ),
          ],
        ),
      );
    }

    final spacing = isPhone ? 12.0 : 18.0;
    final double cardWidth;
    if (isPhone) {
      final cols = availableWidth < 330 ? 1 : 2;
      cardWidth = (availableWidth - spacing * (cols - 1)) / cols;
    } else if (isTablet) {
      cardWidth = 172.0;
    } else {
      cardWidth = 180.0;
    }
    final cardHeight = isPhone ? 210.0 : 226.0;

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final staff in list)
          SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: _StaffCard(
              staff: staff,
              inactive: _directory.showInactive,
              onEdit: () => _editStaff(staffList.indexOf(staff)),
              onDeactivate: () => _confirmDeactivate(staffList.indexOf(staff)),
              onActivate: () => _activate(staffList.indexOf(staff)),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// HEADER (JUDUL + SEARCH)
// ============================================================

class _Header extends StatelessWidget {
  final bool isPhone;
  final ValueChanged<String> onSearch;

  const _Header({
    required this.isPhone,
    required this.onSearch,
  });

  Widget _title() {
    return Text(
      'Kontrol Staf',
      style: TextStyle(
        fontSize: isPhone ? 24 : 28,
        fontWeight: FontWeight.w900,
        color: _kPrimary,
        letterSpacing: -0.2,
        shadows: const [
          Shadow(
            color: Color(0x33082640),
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _kCardShadow,
      ),
      child: TextField(
        onChanged: onSearch,
        style: const TextStyle(fontSize: 13, color: _kPrimary),
        decoration: InputDecoration(
          hintText: 'Cari',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFFA2B5C9),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFF7F95B0),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 38),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: _kPrimary, width: 1.2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(),
          const SizedBox(height: 12),
          _searchBox(),
        ],
      );
    }

    return Row(
      children: [
        _title(),
        const SizedBox(width: 20),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: _searchBox(),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TOMBOL PIL (Simpan / Edit / Aktifkan)
// ============================================================

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double minWidth;
  final double height;
  final double fontSize;
  final Color color;
  final bool loading;

  const _PillButton({
    required this.label,
    required this.onTap,
    required this.minWidth,
    required this.height,
    required this.fontSize,
    this.color = _kPrimary,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _kPillShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FILTER AKTIF / NONAKTIF (RATA KIRI)
// ============================================================

class _FilterBar extends StatelessWidget {
  final bool showInactive;
  final ValueChanged<bool> onChanged;

  const _FilterBar({
    required this.showInactive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 10,
      runSpacing: 8,
      children: [
        _StatusTabChip(
          label: 'Aktif',
          icon: Icons.check_circle_outline_rounded,
          selected: !showInactive,
          onTap: () => onChanged(false),
        ),
        _StatusTabChip(
          label: 'Nonaktif',
          icon: Icons.cancel_outlined,
          selected: showInactive,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _StatusTabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _StatusTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? _kPrimary : const Color(0xFFC5D5E4),
              width: 1.2,
            ),
            boxShadow: _kPillShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : _kMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _kPrimary,
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
// KARTU STAF (sesuai desain gambar referensi, aksi status di KIRI)
// ============================================================

class _StaffCard extends StatelessWidget {
  final Staff staff;
  final bool inactive;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onActivate;

  const _StaffCard({
    required this.staff,
    required this.inactive,
    required this.onEdit,
    required this.onDeactivate,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    color: _kPlaceholder,
                    child: staff.photoUrl != null
                        ? Image.network(
                            staff.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatar(),
                          )
                        : _avatar(),
                  ),
                ),

                // Status / tombol nonaktifkan diletakkan di KIRI ATAS (bukan di kanan)
                Positioned(
                  top: 7,
                  left: 7,
                  child: inactive
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _kPillShadow,
                          ),
                          child: Text(
                            'Nonaktif',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        )
                      : Tooltip(
                          message: 'Nonaktifkan staf',
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(10),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: onDeactivate,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_off_outlined,
                                      size: 13,
                                      color: Colors.redAccent,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            staff.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (inactive)
            _PillButton(
              label: 'Aktifkan',
              onTap: onActivate,
              minWidth: 94,
              height: 28,
              fontSize: 11.5,
              color: const Color(0xFF1F8A5B),
            )
          else
            _PillButton(
              label: 'Edit',
              onTap: onEdit,
              minWidth: 84,
              height: 28,
              fontSize: 12,
            ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 48,
        color: Colors.grey.shade500,
      ),
    );
  }
}

// ============================================================
// KARTU TAMBAH STAF (sesuai desain gambar referensi)
// ============================================================

class _AddStaffCard extends StatefulWidget {
  final bool isPhone;
  final Future<bool> Function(Staff, String pin) onSave;

  const _AddStaffCard({
    required this.isPhone,
    required this.onSave,
  });

  @override
  State<_AddStaffCard> createState() => _AddStaffCardState();
}

class _AddStaffCardState extends State<_AddStaffCard> {
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();

  String? _photoPath;
  Uint8List? _photoBytes;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (img != null) {
      final b = await img.readAsBytes();
      if (!mounted) return;

      setState(() {
        _photoPath = img.path;
        _photoBytes = b;
      });
    }
  }

  Future<String?> _askPin() async {
    final pc = TextEditingController();
    var hide = true;

    final pin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => StatefulBuilder(
        builder: (_, setDS) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Buat PIN Staf Baru',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _kPrimary,
            ),
          ),
          content: TextField(
            controller: pc,
            autofocus: true,
            keyboardType: TextInputType.number,
            obscureText: hide,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => setDS(() {}),
            decoration: InputDecoration(
              hintText: 'Masukkan PIN 6 digit',
              counterText: '',
              prefixIcon: const Icon(Icons.pin_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                tooltip: hide ? 'Tampilkan PIN' : 'Sembunyikan PIN',
                onPressed: () => setDS(() => hide = !hide),
                icon: Icon(
                  hide ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: pc.text.length == 6
                  ? () => Navigator.pop(dCtx, pc.text)
                  : null,
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: const Text('Simpan PIN'),
            ),
          ],
        ),
      ),
    );

    pc.dispose();
    return pin;
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama staf harus diisi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final pin = await _askPin();
    if (pin == null || !mounted) return;

    setState(() => _saving = true);

    try {
      final ok = await widget.onSave(
        Staff(
          name: name,
          photoPath: _photoPath,
          photoBytes: _photoBytes,
        ),
        pin,
      );

      if (!mounted || !ok) return;

      _nameCtrl.clear();
      setState(() {
        _photoPath = null;
        _photoBytes = null;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoSize = widget.isPhone ? 64.0 : 78.0;

    return Container(
      padding: EdgeInsets.all(widget.isPhone ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _kCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Kotak foto ungu muda + ikon plus putih
          Tooltip(
            message: 'Pilih foto staf',
            child: InkWell(
              onTap: _pick,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: photoSize,
                height: photoSize,
                decoration: BoxDecoration(
                  color: _kPicker,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photoBytes == null
                    ? Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: widget.isPhone ? 30 : 36,
                      )
                    : Image.memory(
                        _photoBytes!,
                        fit: BoxFit.cover,
                        width: photoSize,
                        height: photoSize,
                      ),
              ),
            ),
          ),

          SizedBox(width: widget.isPhone ? 12 : 16),

          // Nama staf + ikon edit di sebelahnya
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: widget.isPhone ? 90 : 120,
                        maxWidth: widget.isPhone ? 180 : 280,
                      ),
                      child: TextField(
                        controller: _nameCtrl,
                        focusNode: _nameFocus,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(
                          fontSize: widget.isPhone ? 14 : 16,
                          color: _kPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nama Staf',
                          hintStyle: TextStyle(
                            fontSize: widget.isPhone ? 14 : 16,
                            color: _kPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _nameFocus.requestFocus(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_square,
                      size: widget.isPhone ? 16 : 18,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Tombol Simpan berbentuk pil navy di kanan
          _PillButton(
            label: 'Simpan',
            onTap: _saving ? null : _save,
            minWidth: widget.isPhone ? 74 : 92,
            height: widget.isPhone ? 30 : 34,
            fontSize: widget.isPhone ? 11.5 : 13,
            loading: _saving,
          ),
        ],
      ),
    );
  }
}
