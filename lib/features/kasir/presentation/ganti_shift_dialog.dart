
import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';

const Color _navy = Color(0xFF082640);
const Color _pageBg = Color(0xFFDCE9F4);
const Color _muted = Color(0xFF71869A);

// Mengembalikan data pengguna kasir baru kalau sukses, null kalau batal.
Future<Map<String, dynamic>?> showGantiShiftDialog(
  BuildContext context, {
  required int? idKasirSaatIni,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _GantiShiftDialog(
      idKasirSaatIni: idKasirSaatIni,
    ),
  );
}

class _GantiShiftDialog extends StatefulWidget {
  const _GantiShiftDialog({
    required this.idKasirSaatIni,
  });

  final int? idKasirSaatIni;

  @override
  State<_GantiShiftDialog> createState() => _GantiShiftDialogState();
}

class _GantiShiftDialogState extends State<_GantiShiftDialog> {
  List<Map<String, dynamic>> _kasir = [];

  bool _loading = true;
  bool _submitting = false;
  int? _dipilih;
  bool _yakin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('kasir-profil');

      final list = (res['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((k) => k['id_pengguna'] != widget.idKasirSaatIni)
          .toList();

      if (!mounted) return;

      setState(() {
        _kasir = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _snack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: _navy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<String?> _askPin(String nama) {
    final c = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Verifikasi PIN',
          style: TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan PIN akun kasir $nama.',
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: c,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Masukkan PIN',
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF5F7F9),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFE1E6EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: _navy,
                    width: 1.3,
                  ),
                ),
              ),
              onSubmitted: (v) {
                Navigator.pop(ctx, v.trim());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: _muted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, c.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            child: const Text('Masuk'),
          ),
        ],
      ),
    ).whenComplete(() => c.dispose());
  }

  Future<void> _simpan() async {
    if (_dipilih == null || !_yakin || _submitting) return;

    final k = _kasir.firstWhere(
      (e) => e['id_pengguna'] == _dipilih,
    );

    final pin = await _askPin(k['nama'].toString());

    if (pin == null || pin.isEmpty) return;
    if (!mounted) return;

    setState(() => _submitting = true);

    try {
      final res = await ApiService.post('login-pin', {
        'id_pengguna': k['id_pengguna'],
        'pin': pin,
      });

      final user = Map<String, dynamic>.from(
        res['pengguna'] as Map,
      );

      await ApiService.saveAuth(
        token: res['token'].toString(),
        user: user,
      );

      if (!mounted) return;

      Navigator.pop(context, user);
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildKasirCard(Map<String, dynamic> k) {
    final aktif = k['id_pengguna'] == _dipilih;
    final foto = k['foto_url']?.toString();

    return InkWell(
      onTap: _submitting
          ? null
          : () {
              setState(() {
                _dipilih = k['id_pengguna'] as int;
              });
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: aktif ? _pageBg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: aktif ? _navy : const Color(0xFFE5E7EB),
            width: aktif ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: _pageBg,
              backgroundImage: foto != null && foto.isNotEmpty
                  ? NetworkImage(
                      foto,
                      headers: const {
                        'ngrok-skip-browser-warning': 'true',
                      },
                    )
                  : null,
              child: foto == null || foto.isEmpty
                  ? const Icon(
                      Icons.person,
                      color: _navy,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                k['nama'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (aktif)
              const Icon(
                Icons.check,
                color: _navy,
                size: 19,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 390,
          maxHeight: 550,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 17,
              ),
              color: _navy,
              child: const Text(
                'Ganti Shift Kasir',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // KONTEN
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Nama Kasir',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(25),
                          child: CircularProgressIndicator(
                            color: _navy,
                          ),
                        ),
                      )
                    else if (_kasir.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Tidak ada kasir lain.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._kasir.map(_buildKasirCard),

                    const SizedBox(height: 10),

                    // KONFIRMASI
                    CheckboxListTile(
                      value: _yakin,
                      onChanged: _submitting
                          ? null
                          : (v) {
                              setState(() {
                                _yakin = v ?? false;
                              });
                            },
                      activeColor: _navy,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Saya yakin ingin mengganti shift kasir.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // TOMBOL
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navy,
                        side: const BorderSide(color: _navy),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _dipilih != null &&
                              _yakin &&
                              !_submitting
                          ? _simpan
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        disabledBackgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
