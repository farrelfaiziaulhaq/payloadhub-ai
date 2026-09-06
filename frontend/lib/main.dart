import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'services/auto_key_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Auto-seed bundled API keys (api-*) into encrypted storage so the user
  // never has to enter them manually.
  await AutoKeyLoader.seed();
  runApp(const ProviderScope(child: PayloadHubApp()));
}

class PayloadHubApp extends StatelessWidget {
  const PayloadHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayloadHub-AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const DashboardScreen(),
    );
  }
}
