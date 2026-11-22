import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crud_mahasiswa/models/mahasiswa.dart';
import 'package:crud_mahasiswa/screens/mahasiswa_form_page.dart';
import 'package:crud_mahasiswa/theme/app_theme.dart';

void main() {
  testWidgets('form menolak data kosong dengan pesan yang jelas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const MahasiswaFormPage()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan data'));
    await tester.pumpAndSettle();

    expect(find.text('NIM wajib diisi'), findsOneWidget);
    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(find.text('Program studi wajib diisi'), findsOneWidget);
  });

  testWidgets('form edit menampilkan data awal', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const MahasiswaFormPage(
          initial: Mahasiswa(
            id: 1,
            nim: '230101001',
            nama: 'Ahmad Fauzi',
            prodi: 'Teknik Informatika',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ubah mahasiswa'), findsOneWidget);
    expect(find.text('230101001'), findsOneWidget);
    expect(find.text('Ahmad Fauzi'), findsOneWidget);
    expect(find.text('Teknik Informatika'), findsOneWidget);
    expect(find.text('Simpan perubahan'), findsOneWidget);
  });
}
