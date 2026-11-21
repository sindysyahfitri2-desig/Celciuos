
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kasir_celcious_coffe/features/owner/application/staff_directory_controller.dart';

// ============================================================
// KONSTANTA DESAIN
// ============================================================

const _kPrimary = Color(0xff0E2F56);
const _kBackground = Color(0xffDCE8F3);
const _kCardRadius = 12.0;
const _kImgRadius = 9.0;

// ============================================================
// RESPONSIVE
// ============================================================

enum _ScreenSize { phone, tablet, desktop }

_ScreenSize _screenOf(double w) {
  if (w >= 1024) return _ScreenSize.desktop;
  if (w >= 600) return _ScreenSize.tablet;
  return _ScreenSize.phone;
}

// ============================================================
// HALAMAN KONTROL STAF
// ============================================================

class KontrolStafPage extends StatefulWidget {
  const KontrolStafPage({super.key});

  @override
  State<KontrolStafPage> createState() => _KontrolStafPageState();
}

class _KontrolStafPageState extends State<KontrolStafPage> {
  final StaffDirectoryController _directory =
      StaffDirectoryController();

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
              error
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor:
            error ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
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
    final dialogWidth = screenW < 400 ? screenW * 0.92 : 380.0;

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
              constraints: BoxConstraints(
                maxWidth: dialogWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24, 24, 24, 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Edit Profil Staf',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                        ),
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
                            onPressed: () =>
                                Navigator.pop(dCtx, false),
                            child: const Text('Batal'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                Navigator.pop(dCtx, true),
                            icon: const Icon(
                              Icons.save,
                              size: 18,
                            ),
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
      _snack(
        'Nama staf tidak boleh kosong.',
        error: true,
      );
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
      _snack(
        _directory.errorMessage!,
        error: true,
      );
    }
  }

  // ==========================================================
  // HAPUS / NONAKTIFKAN STAF
  // ==========================================================

  Future<void> _confirmDelete(int index) async {
    final staff = staffList[index];

    final yes = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
            ),
            SizedBox(width: 10),
            Flexible(child: Text('Hapus Staf')),
          ],
        ),
        content: Text(
          'Hapus akun ${staff.name}?\n\n'
          'Jika staf sudah punya riwayat transaksi atau shift, '
          'akun akan dinonaktifkan (bukan dihapus) dan bisa '
          'diaktifkan kembali.',
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
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    final success = await _directory.deactivate(index);

    if (!mounted) return;

    final m = success
        ? _directory.infoMessage
        : _directory.errorMessage;

    if (m != null) {
      _snack(m, error: !success);
    }
  }

  // ==========================================================
  // AKTIFKAN KEMBALI
  // ==========================================================

  Future<void> _activate(int index) async {
    final success = await _directory.activate(index);

    if (!mounted) return;

    final m = success
        ? _directory.infoMessage
        : _directory.errorMessage;

    if (m != null) {
      _snack(m, error: !success);
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final filtered = _directory.filteredStaff;

    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final screen = _screenOf(box.maxWidth);

            final hPad = screen == _ScreenSize.phone
                ? 16.0
                : screen == _ScreenSize.tablet
                    ? 24.0
                    : 12.0;

            final cols = screen == _ScreenSize.phone
                ? 2
                : screen == _ScreenSize.tablet
                    ? 3
                    : box.maxWidth > 1450
                        ? 5
                        : 4;

            return RefreshIndicator(
              onRefresh: _directory.fetchStaff,
              color: _kPrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: hPad,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      screen: screen,
                      onSearch: _directory.setSearchQuery,
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: _FilterBar(
                        showInactive: _directory.showInactive,
                        onChanged: _directory.setShowInactive,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (!_directory.showInactive) ...[
                      _AddStaffCard(
                        screen: screen,
                        onSave: (s, pin) async {
                          final ok = await _directory.addStaff(
                            s,
                            pin: pin,
                          );

                          if (!ok &&
                              mounted &&
                              _directory.errorMessage != null) {
                            _snack(
                              _directory.errorMessage!,
                              error: true,
                            );
                          }

                          return ok;
                        },
                      ),

                      const SizedBox(height: 20),
                    ],

                    _buildBody(
                      filtered,
                      cols,
                      screen == _ScreenSize.phone ? 0.78 : 0.85,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // BODY DAFTAR STAF
  // ==========================================================

  Widget _buildBody(
    List<Staff> list,
    int cols,
    double ratio,
  ) {
    if (_directory.isLoading && list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: CircularProgressIndicator(
            color: _kPrimary,
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                _directory.showInactive
                    ? 'Tidak ada staf nonaktif.'
                    : 'Belum ada staf.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: ratio,
      ),
      itemBuilder: (_, i) {
        final staff = list[i];
        final ri = staffList.indexOf(staff);

        return _StaffCard(
          staff: staff,
          inactive: _directory.showInactive,
          onEdit: () => _editStaff(ri),
          onDelete: () => _confirmDelete(ri),
          onActivate: () => _activate(ri),
        );
      },
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _Header extends StatelessWidget {
  final _ScreenSize screen;
  final ValueChanged<String> onSearch;

  const _Header({
    required this.screen,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = screen == _ScreenSize.phone;

    final search = SizedBox(
      width: isPhone ? double.infinity : 220,
      height: 34,
      child: TextField(
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: 'Cari',
          hintStyle: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 15,
            color: Colors.grey.shade400,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: _kPrimary,
              width: 1,
            ),
          ),
        ),
      ),
    );

    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kontrol Staf',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 10),
          search,
        ],
      );
    }

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Kontrol Staf',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: _kPrimary,
            ),
          ),
        ),
        search,
      ],
    );
  }
}

// ============================================================
// FILTER AKTIF / NONAKTIF
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
      spacing: 8,
      children: [
        _Chip(
          label: 'Aktif',
          icon: Icons.check_circle_outline,
          selected: !showInactive,
          onTap: () => onChanged(false),
        ),
        _Chip(
          label: 'Nonaktif',
          icon: Icons.cancel_outlined,
          selected: showInactive,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _kPrimary
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// KARTU STAF
// ============================================================

class _StaffCard extends StatelessWidget {
  final Staff staff;
  final bool inactive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onActivate;

  const _StaffCard({
    required this.staff,
    required this.inactive,
    required this.onEdit,
    required this.onDelete,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(_kImgRadius),
                  child: Container(
                    color: Colors.grey.shade300,
                    child: staff.photoUrl != null
                        ? Image.network(
                            staff.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatar(),
                          )
                        : _avatar(),
                  ),
                ),

                if (inactive)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Nonaktif',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          Text(
            staff.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: _kPrimary,
            ),
          ),

          if (staff.username != null &&
              staff.username!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '@${staff.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade500,
              ),
            ),
          ],

          const SizedBox(height: 5),

          if (inactive)
            SizedBox(
              height: 24,
              width: 65,
              child: FilledButton.icon(
                onPressed: onActivate,
                icon: const Icon(Icons.refresh, size: 12),
                label: const Text(
                  'Aktifkan',
                  style: TextStyle(fontSize: 9),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: EdgeInsets.zero,
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 24,
                  width: 65,
                  child: FilledButton(
                    onPressed: onEdit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                SizedBox(
                  width: 25,
                  height: 24,
                  child: IconButton(
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 15,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 45,
        color: Colors.grey.shade400,
      ),
    );
  }
}

// ============================================================
// KARTU TAMBAH STAF
// ============================================================

class _AddStaffCard extends StatefulWidget {
  final _ScreenSize screen;
  final Future<bool> Function(Staff, String pin) onSave;

  const _AddStaffCard({
    required this.screen,
    required this.onSave,
  });

  @override
  State<_AddStaffCard> createState() => _AddStaffCardState();
}

class _AddStaffCardState extends State<_AddStaffCard> {
  final _nameCtrl = TextEditingController();

  String? _photoPath;
  Uint8List? _photoBytes;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ==========================================================
  // PILIH FOTO
  // ==========================================================

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

  // ==========================================================
  // INPUT PIN
  // ==========================================================

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
                tooltip: hide
                    ? 'Tampilkan PIN'
                    : 'Sembunyikan PIN',
                onPressed: () {
                  setDS(() => hide = !hide);
                },
                icon: Icon(
                  hide
                      ? Icons.visibility
                      : Icons.visibility_off,
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
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
              ),
              child: const Text('Simpan PIN'),
            ),
          ],
        ),
      ),
    );

    pc.dispose();
    return pin;
  }

  // ==========================================================
  // SIMPAN STAF
  // ==========================================================

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
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ==========================================================
  // FOTO PICKER UI
  // ==========================================================

  Widget _photoPicker({double size = 44}) {
    return GestureDetector(
      onTap: _pick,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xffD8D1E9),
          borderRadius: BorderRadius.circular(9),
        ),
        child: _photoBytes == null
            ? const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.memory(
                  _photoBytes!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                ),
              ),
      ),
    );
  }

  // ==========================================================
  // INPUT NAMA
  // ==========================================================

  Widget _nameField() {
    return TextField(
      controller: _nameCtrl,
      style: const TextStyle(
        fontSize: 12,
        color: _kPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Nama Staf',
        hintStyle: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        isDense: true,
      ),
    );
  }

  // ==========================================================
  // TOMBOL SIMPAN
  // ==========================================================

  Widget _saveButton({bool expand = false}) {
    return SizedBox(
      width: expand ? double.infinity : 48,
      height: 30,
      child: FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: _kPrimary,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Simpan',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // ==========================================================
  // BUILD CARD TAMBAH STAF
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final isPhone = widget.screen == _ScreenSize.phone;

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isPhone
          ? _phoneLayout()
          : _wideLayout(),
    );
  }

  // ==========================================================
  // LAYOUT HP
  // ==========================================================

  Widget _phoneLayout() {
    return Column(
      children: [
        Row(
          children: [
            _photoPicker(size: 55),
            const SizedBox(width: 10),
            Expanded(child: _nameField()),
            const Icon(
              Icons.edit_outlined,
              size: 16,
              color: _kPrimary,
            ),
          ],
        ),

        const SizedBox(height: 10),

        _saveButton(expand: true),
      ],
    );
  }

  // ==========================================================
  // LAYOUT TABLET / DESKTOP
  // ==========================================================

  Widget _wideLayout() {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          _photoPicker(size: 44),

          const SizedBox(width: 9),

          Expanded(
            child: _nameField(),
          ),

          const Icon(
            Icons.edit_outlined,
            size: 15,
            color: _kPrimary,
          ),

          const SizedBox(width: 12),

          _saveButton(),
        ],
      ),
    );
  }
}
