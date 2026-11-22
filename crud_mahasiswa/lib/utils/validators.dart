final RegExp _nimPattern = RegExp(r'^[0-9]{8,15}$');

String? validateNim(String? value) {
  final nim = value?.trim() ?? '';
  if (nim.isEmpty) return 'NIM wajib diisi';
  if (!_nimPattern.hasMatch(nim)) {
    return 'NIM harus 8 sampai 15 digit angka';
  }
  return null;
}

String? validateNama(String? value) {
  final nama = value?.trim() ?? '';
  if (nama.isEmpty) return 'Nama wajib diisi';
  if (nama.length < 3) return 'Nama minimal 3 karakter';
  return null;
}

String? validateProdi(String? value) {
  final prodi = value?.trim() ?? '';
  if (prodi.isEmpty) return 'Program studi wajib diisi';
  if (prodi.length < 2) return 'Nama program studi terlalu pendek';
  return null;
}
