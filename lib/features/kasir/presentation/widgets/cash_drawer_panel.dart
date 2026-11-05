import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kasir_celcious_coffe/data/transaction_store.dart';

enum _CashDrawerType { addition, deduction, refund }

class CashDrawerPanel extends StatefulWidget {
  const CashDrawerPanel({super.key});

  @override
  State<CashDrawerPanel> createState() => _CashDrawerPanelState();
}

class _CashDrawerPanelState extends State<CashDrawerPanel> {
  static const Color _navy = Color(0xff082640);
  static const Color _textColor = Color(0xff102b40);

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  _CashDrawerType? _selectedType;

  int _step = 0;
  bool _amountConfirmed = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _descriptionLabel {
    return _selectedType == _CashDrawerType.refund
        ? 'ID Pesanan'
        : 'Keterangan';
  }

  String get _descriptionHint {
    return _selectedType == _CashDrawerType.refund
        ? 'ID Pesanan'
        : 'Keterangan...';
  }

  String get _nextLabel => _step == 2 ? 'Simpan' : 'Selanjutnya';

  void _continue() {
    if (_isSaving) return;

    setState(() {
      _errorMessage = null;

      if (_step == 0) {
        if (_selectedType == null) {
          _errorMessage = 'Pilih jenis kas terlebih dahulu.';
          return;
        }

        _step = 1;
        return;
      }

      if (_step == 1) {
        if (_descriptionController.text.trim().isEmpty) {
          _errorMessage = '$_descriptionLabel wajib diisi.';
          return;
        }

        _step = 2;
        return;
      }
    });

    if (_step == 2 && _errorMessage == null) {
      _save();
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || !amount.isFinite || amount <= 0) {
      setState(() {
        _errorMessage = 'Nominal harus diisi dengan benar.';
      });
      return;
    }

    if (!_amountConfirmed) {
      setState(() {
        _errorMessage = 'Konfirmasi nominal sebelum menyimpan.';
      });
      return;
    }

    final selectedType = _selectedType;

    if (selectedType == null) {
      setState(() {
        _errorMessage = 'Pilih jenis kas terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final type = selectedType == _CashDrawerType.addition ? 'masuk' : 'keluar';

    final description = selectedType == _CashDrawerType.refund
        ? 'Refund ${_descriptionController.text.trim()}'
        : _descriptionController.text.trim();

    try {
      await TransactionStore.addCashDrawerEntry(
        type: type,
        amount: amount,
        description: description,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kas laci berhasil disimpan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _step = 0;
        _selectedType = null;
        _descriptionController.clear();
        _amountController.clear();
        _amountConfirmed = false;
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = 'Gagal menyimpan kas laci: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffeeeeee), width: 0.7),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_step < 2) ...[
                const Text(
                  'Pilih :',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                for (final type in _CashDrawerType.values) ...[
                  _buildTypeOption(type),

                  if (_selectedType == type && _step == 1)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 7,
                        top: 2,
                        bottom: 5,
                      ),
                      child: _buildDescriptionField(),
                    ),
                ],
              ] else ...[
                const Text(
                  'Masukkan Nominal :',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _fieldDecoration('Nominal'),
                  style: const TextStyle(color: _textColor, fontSize: 13),
                ),

                const SizedBox(height: 5),

                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _amountConfirmed = !_amountConfirmed;
                        _errorMessage = null;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 28,
                          child: Checkbox(
                            value: _amountConfirmed,
                            activeColor: _navy,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) {
                              setState(() {
                                _amountConfirmed = value ?? false;
                                _errorMessage = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Flexible(
                          child: Text(
                            'Apakah Nominal Sudah Benar?',
                            style: TextStyle(color: Colors.red, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 5),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              ],

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _step--;
                                _errorMessage = null;
                              });
                            },
                      child: const Text(
                        'Kembali',
                        style: TextStyle(color: _navy, fontSize: 12),
                      ),
                    ),

                  const SizedBox(width: 4),

                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _navy.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _nextLabel,
                              style: const TextStyle(fontSize: 12),
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
  }

  Widget _buildTypeOption(_CashDrawerType type) {
    final label = switch (type) {
      _CashDrawerType.addition => 'Penambahan',
      _CashDrawerType.deduction => 'Pengurangan',
      _CashDrawerType.refund => 'Refund',
    };

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _errorMessage = null;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            SizedBox(
              width: 23,
              height: 24,
              child: Radio<_CashDrawerType>(
                value: type,
                groupValue: _selectedType,
                activeColor: _navy,
                visualDensity: VisualDensity.compact,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    _errorMessage = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(
                color: _textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _descriptionController,
            style: const TextStyle(color: _textColor, fontSize: 12),
            decoration: _fieldDecoration(_descriptionHint),
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          '*Wajib Isi',
          style: TextStyle(color: Colors.red, fontSize: 8),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 10),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _navy),
      ),
    );
  }
}
