import 'package:flutter_test/flutter_test.dart';

import 'package:crud_mahasiswa/models/mahasiswa.dart';
import 'package:crud_mahasiswa/utils/validators.dart';

void main() {
  group('Mahasiswa', () {
    test('toMap dan fromMap mempertahankan seluruh field', () {
      const mahasiswa = Mahasiswa(
        id: 7,
        nim: '230101001',
        nama: 'Ahmad Fauzi',
        prodi: 'Teknik Informatika',
      );

      final map = mahasiswa.toMap();
      final result = Mahasiswa.fromMap(map);

      expect(result.id, 7);
      expect(result.nim, '230101001');
      expect(result.nama, 'Ahmad Fauzi');
      expect(result.prodi, 'Teknik Informatika');
    });

    test('id nullable diterima untuk data baru', () {
      final result = Mahasiswa.fromMap(<String, Object?>{
        'id': null,
        'nim': '230101002',
        'nama': 'Siti Aminah',
        'prodi': 'Sistem Informasi',
      });

      expect(result.id, isNull);
      expect(result.nim, '230101002');
    });
  });

  group('validasi', () {
    test('NIM wajib dan harus 8 sampai 15 digit', () {
      expect(validateNim(''), 'NIM wajib diisi');
      expect(validateNim('123'), 'NIM harus 8 sampai 15 digit angka');
      expect(validateNim('2301010AB'), 'NIM harus 8 sampai 15 digit angka');
      expect(validateNim('230101001'), isNull);
      expect(validateNim('230101001234567'), isNull);
    });

    test('nama dan program studi wajib diisi', () {
      expect(validateNama(''), 'Nama wajib diisi');
      expect(validateNama('Al'), 'Nama minimal 3 karakter');
      expect(validateNama('Ahmad Fauzi'), isNull);
      expect(validateProdi(''), 'Program studi wajib diisi');
      expect(validateProdi('TI'), isNull);
    });
  });
}
