import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/mahasiswa.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

class MahasiswaFormPage extends StatefulWidget {
  const MahasiswaFormPage({super.key, this.initial});

  final Mahasiswa? initial;

  @override
  State<MahasiswaFormPage> createState() => _MahasiswaFormPageState();
}

class _MahasiswaFormPageState extends State<MahasiswaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper.instance;

  late final TextEditingController _nimController;
  late final TextEditingController _namaController;
  late final TextEditingController _prodiController;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nimController = TextEditingController(text: initial?.nim ?? '');
    _namaController = TextEditingController(text: initial?.nama ?? '');
    _prodiController = TextEditingController(text: initial?.prodi ?? '');
  }

  @override
  void dispose() {
    _nimController.dispose();
    _namaController.dispose();
    _prodiController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final data = Mahasiswa(
      id: widget.initial?.id,
      nim: _nimController.text.trim(),
      nama: _namaController.text.trim(),
      prodi: _prodiController.text.trim(),
    );

    try {
      if (_isEdit) {
        await _db.updateMahasiswa(data);
      } else {
        await _db.insertMahasiswa(data);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DatabaseException catch (error) {
      final duplicate = error.toString().contains('UNIQUE');
      _showMessage(
        duplicate
            ? 'NIM sudah terdaftar. Gunakan NIM lain.'
            : 'Data gagal disimpan. Periksa kembali isian Anda.',
      );
    } catch (error) {
      _showMessage('Data gagal disimpan: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Ubah mahasiswa' : 'Tambah mahasiswa';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEdit
                      ? 'Perbarui data mahasiswa tanpa mengubah NIM lama.'
                      : 'Lengkapi data mahasiswa untuk disimpan di perangkat.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                _FormField(
                  child: TextFormField(
                    controller: _nimController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    maxLength: 15,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: validateNim,
                    decoration: const InputDecoration(
                      labelText: 'NIM',
                      hintText: 'Contoh: 230101001',
                      counterText: '',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _FormField(
                  child: TextFormField(
                    controller: _namaController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    validator: validateNama,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                      hintText: 'Contoh: Ahmad Fauzi',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _FormField(
                  child: TextFormField(
                    controller: _prodiController,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    validator: validateProdi,
                    onFieldSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: 'Program studi',
                      hintText: 'Contoh: Teknik Informatika',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.softGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.storage_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Data disimpan di SQLite perangkat. Tidak ada data '
                          'yang dikirim ke server.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _saving
                        ? 'Menyimpan...'
                        : _isEdit
                        ? 'Simpan perubahan'
                        : 'Simpan data',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
