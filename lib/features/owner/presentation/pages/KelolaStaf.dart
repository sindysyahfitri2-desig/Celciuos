import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import 'package:kasir_celcious_coffe/features/owner/application/staff_directory_controller.dart';

// ============================================================
// KONSTANTA DESAIN
// ============================================================

const _kPrimary = Color(0xff0E2F56);
const _kBackground = Color(0xffD8E4F0);
const _kPlaceholder = Color(0xffD9D9D9);
const _kPicker = Color(0xffD8D1E9);

/// Shadow khas desain: jatuh ke kanan-bawah, abu-abu lembut.
const List<BoxShadow> _kShadow = [
  BoxShadow(
    color: Color(0x40000000),
    blurRadius: 4,
    offset: Offset(2, 3),
  ),
];

const List<BoxShadow> _kShadowSmall = [
  BoxShadow(
    color: Color(0x59000000),
    blurRadius: 3,
    offset: Offset(1, 2),
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
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
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

    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _directory.fetchStaff,
          color: _kPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(onSearch: _directory.setSearchQuery),
                const SizedBox(height: 18),
                if (!_directory.showInactive) ...[
                  _AddStaffCard(
                    onSave: (s, pin) async {
                      final ok = await _directory.addStaff(s, pin: pin);

                      if (!ok && mounted && _directory.errorMessage != null) {
                        _snack(_directory.errorMessage!, error: true);
                      }
                      return ok;
                    },
                  ),
                  const SizedBox(height: 22),
                ],
                _buildBody(filtered),
                const SizedBox(height: 16),
                // Filter dipindah ke bawah agar tampilan atas sama
                // persis dengan desain.
                _FilterBar(
                  showInactive: _directory.showInactive,
                  onChanged: _directory.setShowInactive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BODY DAFTAR STAF
  // ==========================================================

  Widget _buildBody(List<Staff> list) {
    if (_directory.isLoading && list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: CircularProgressIndicator(color: _kPrimary),
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
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    // Kartu berukuran tetap ~ 105 x 140 seperti desain, rata kiri.
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final staff in list)
          SizedBox(
            width: 105,
            height: 140,
            child: _StaffCard(
              staff: staff,
              inactive: _directory.showInactive,
              onEdit: () => _editStaff(staffList.indexOf(staff)),
              onDelete: () => _confirmDelete(staffList.indexOf(staff)),
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
  final ValueChanged<String> onSearch;

  const _Header({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Kontrol Staf',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _kPrimary,
            shadows: [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 3,
                offset: Offset(1.5, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _kShadow,
                ),
                child: TextField(
                  onChanged: onSearch,
                  style: const TextStyle(fontSize: 11, color: _kPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari',
                    hintStyle: const TextStyle(
                      fontSize: 10,
                      color: Color(0xffA9BBD1),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 13,
                      color: Color(0xff7F95B0),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TOMBOL PIL (dipakai Simpan / Edit / Aktifkan)
// ============================================================

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final double fontSize;
  final Color color;
  final bool loading;

  const _PillButton({
    required this.label,
    required this.onTap,
    required this.width,
    required this.height,
    required this.fontSize,
    this.color = _kPrimary,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _kShadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _kShadowSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Colors.grey.shade700,
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
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kShadow,
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
                if (inactive)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Nonaktif',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
                if (!inactive)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: _kShadowSmall,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            staff.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 9,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (inactive)
            _PillButton(
              label: 'Aktifkan',
              onTap: onActivate,
              width: 52,
              height: 16,
              fontSize: 8,
              color: Colors.green.shade600,
            )
          else
            _PillButton(
              label: 'Edit',
              onTap: onEdit,
              width: 40,
              height: 16,
              fontSize: 8,
            ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }
}

// ============================================================
// KARTU TAMBAH STAF
// ============================================================

class _AddStaffCard extends StatefulWidget {
  final Future<bool> Function(Staff, String pin) onSave;

  const _AddStaffCard({required this.onSave});

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
      if (mounted) setState(() => _saving = false);
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kotak foto (ungu muda + ikon plus putih)
          GestureDetector(
            onTap: _pick,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _kPicker,
                borderRadius: BorderRadius.circular(9),
              ),
              child: _photoBytes == null
                  ? const Icon(Icons.add, color: Colors.white, size: 26)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.memory(
                        _photoBytes!,
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Nama staf + ikon edit tepat di sebelahnya
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 95),
                      child: TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Nama Staf',
                          hintStyle: TextStyle(
                            fontSize: 11,
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
                  const SizedBox(width: 14),
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.edit_square,
                      size: 12,
                      color: _kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Tombol Simpan di pojok kanan atas
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _PillButton(
              label: 'Simpan',
              onTap: _saving ? null : _save,
              width: 44,
              height: 16,
              fontSize: 8,
              loading: _saving,
            ),
          ),
        ],
      ),
    );
  }
}