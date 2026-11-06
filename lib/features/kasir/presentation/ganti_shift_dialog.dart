import 'package:flutter/material.dart';
import 'package:kasir_celcious_coffe/data/api_service.dart';

/// Mengembalikan data pengguna (Map) kasir baru kalau sukses, null kalau batal.
Future<Map<String, dynamic>?> showGantiShiftDialog(
  BuildContext context, {
  required int? idKasirSaatIni,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _GantiShiftDialog(idKasirSaatIni: idKasirSaatIni),
  );
}

class _GantiShiftDialog extends StatefulWidget {
  const _GantiShiftDialog({required this.idKasirSaatIni});
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
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<String?> _askPin(String nama) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('PIN untuk $nama'),
        content: TextField(
          controller: c,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Masuk')),
        ],
      ),
    );
  }

  Future<void> _simpan() async {
    if (_dipilih == null || !_yakin || _submitting) return;
    final k = _kasir.firstWhere((e) => e['id_pengguna'] == _dipilih);

    final pin = await _askPin(k['nama'].toString());
    if (pin == null || pin.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final res = await ApiService.post('login-pin', {
        'id_pengguna': k['id_pengguna'],
        'pin': pin,
      });
      final user = Map<String, dynamic>.from(res['pengguna'] as Map);
      await ApiService.saveAuth(token: res['token'].toString(), user: user);
      if (!mounted) return;
      Navigator.pop(context, user);
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ganti Shift :',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              const Text('Pilih Nama Kasir :', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_kasir.isEmpty)
                const Text('Tidak ada kasir lain.')
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView(
                    shrinkWrap: true,
                    children: _kasir.map((k) {
                      final aktif = k['id_pengguna'] == _dipilih;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: aktif
                              ? const Color(0xffdce7f2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: aktif
                                ? const Color(0xff0E2F56)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          onTap: () =>
                              setState(() => _dipilih = k['id_pengguna'] as int),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: k['foto_url'] != null
                                ? NetworkImage(
                                    k['foto_url'],
                                    headers: const {
                                      'ngrok-skip-browser-warning': 'true'
                                    },
                                  )
                                : null,
                            child: k['foto_url'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(k['nama'].toString()),
                          trailing: aktif
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xff0E2F56))
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _yakin,
                    onChanged: (v) => setState(() => _yakin = v ?? false),
                  ),
                  const Expanded(
                    child: Text('Apakah Sudah Yakin?',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        (_dipilih != null && _yakin && !_submitting) ? _simpan : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0E2F56),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}