import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/mahasiswa_list_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const CrudMahasiswaApp());
}

class CrudMahasiswaApp extends StatelessWidget {
  const CrudMahasiswaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRUD Mahasiswa',
      theme: buildAppTheme(),
      home: const MahasiswaListPage(),
    );
  }
}
