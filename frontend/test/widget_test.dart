// Integration-style widget tests: drive the dashboard through the sidebar /
// bottom navigation and functional buttons, using fakes so no plugin or
// network call is hit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:payloadhub_ai/main.dart';
import 'package:payloadhub_ai/services/secure_storage_service.dart';
import 'package:payloadhub_ai/features/payload_chat/domain/entities/chat_message.dart';
import 'package:payloadhub_ai/features/payload_chat/domain/repositories/payload_repository.dart';
import 'package:payloadhub_ai/features/dashboard/presentation/dashboard_providers.dart';
import 'package:payloadhub_ai/features/dashboard/presentation/dashboard_screen.dart';
import 'package:payloadhub_ai/features/history/presentation/history_providers.dart';

class FakeStorage implements SecureStorageService {
  String? _activity;

  @override
  Future<void> writeActivityLog(String value) async => _activity = value;
  @override
  Future<String?> readActivityLog() async => _activity;
  @override
  Future<void> deleteActivityLog() async => _activity = null;

  @override
  Future<void> writeApiKey(String value) async {}
  @override
  Future<String?> readApiKey() async => null;
  @override
  Future<void> deleteApiKey() async {}
  @override
  Future<void> writeDefaultLhost(String value) async {}
  @override
  Future<String?> readDefaultLhost() async => null;
  @override
  Future<void> writeDefaultLport(int value) async {}
  @override
  Future<int?> readDefaultLport() async => null;
  @override
  Future<void> writeBaseUrl(String value) async {}
  @override
  Future<String?> readBaseUrl() async => null;
  @override
  Future<void> writeChatProvider(String value) async {}
  @override
  Future<String?> readChatProvider() async => null;
  @override
  Future<void> writeChatApiKey(String value) async {}
  @override
  Future<String?> readChatApiKey() async => null;
  @override
  Future<void> writeOpenAiKey(String value) async {}
  @override
  Future<String?> readOpenAiKey() async => null;
  @override
  Future<void> writeDeepSeekKey(String value) async {}
  @override
  Future<String?> readDeepSeekKey() async => null;
  @override
  Future<void> writeGeminiKey(String value) async {}
  @override
  Future<String?> readGeminiKey() async => null;
  @override
  Future<void> writeShodanKey(String value) async {}
  @override
  Future<String?> readShodanKey() async => null;
  @override
  Future<void> writeVirusTotalKey(String value) async {}
  @override
  Future<String?> readVirusTotalKey() async => null;
  @override
  Future<void> writeLlmEngine(String value) async {}
  @override
  Future<String?> readLlmEngine() async => null;
  @override
  Future<void> writeUiGlow(bool value) async {}
  @override
  Future<bool> readUiGlow() async => false;
  @override
  Future<void> writeTerminalFont(bool value) async {}
  @override
  Future<bool> readTerminalFont() async => false;
  @override
  Future<void> writeSound(bool value) async {}
  @override
  Future<bool> readSound() async => false;
  @override
  Future<void> clearAll() async {}
}

class FakeRepository implements PayloadRepository {
  @override
  Future<ChatMessage> execute(PayloadRequest request) async {
    return const ChatMessage(
      role: MessageRole.assistant,
      content: 'ok',
      codeBlocks: [ChatCodeBlock(language: 'python', code: 'print("pwn")')],
    );
  }
}

Future<void> _settleDrain(WidgetTester tester) async {
  // Drive a few frames + let async provider reads finish, without pumpAndSettle
  // (periodic telemetry timers would make it hang).
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Widget _app() {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(FakeStorage()),
      payloadRepositoryProvider.overrideWithValue(FakeRepository()),
    ],
    child: const PayloadHubApp(),
  );
}

void main() {
  testWidgets('desktop dashboard pages, validation and history work',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await _settleDrain(tester);

    expect(find.text('Dashboard'), findsWidgets);

    for (final page in [
      'Exploit Library',
      'Script Generator',
      'Monitoring',
      'Settings'
    ]) {
      await tester.tap(find.text(page).first);
      await _settleDrain(tester);
      expect(tester.takeException(), isNull);
    }

    // Settings: the three switches must build without the ListTile assertion.
    expect(tester.takeException(), isNull);

    // Back to Dashboard then Script Generator.
    await tester.tap(find.text('Dashboard').first);
    await _settleDrain(tester);
    await tester.tap(find.text('Script Generator').first);
    await _settleDrain(tester);

    // Empty fields must be rejected (client-side validation).
    await tester.ensureVisible(find.text('Generate One-Liner').first);
    await _settleDrain(tester);
    await tester.tap(find.text('Generate One-Liner').first,
        warnIfMissed: false);
    await _settleDrain(tester);
    expect(find.text('IP address is required'), findsOneWidget);
    expect(find.text('Port is required'), findsOneWidget);

    // Fill valid values and generate.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '10.10.14.8');
    await tester.enterText(fields.at(1), '9001');
    await tester.pump();
    await tester.tap(find.text('Generate One-Liner').first,
        warnIfMissed: false);
    await _settleDrain(tester);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(DashboardScreen)));
    final generated = container.read(scriptGenProvider).generated;
    expect(generated, isNotEmpty);
    expect(generated, contains('/dev/tcp'));

    // The generation is persisted into the local history.
    final history = container.read(historyProvider);
    expect(history.entries, isNotEmpty);
    expect(history.entries.first.title, contains('Reverse Shell'));

    await tester.pumpWidget(const SizedBox());
    await _settleDrain(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile shell uses bottom navigation and stacked dashboard',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await _settleDrain(tester);
    expect(tester.takeException(), isNull);

    // Bottom navigation is present, sidebar is not.
    expect(find.byType(NavigationBar), findsOneWidget);
    // Mobile header keeps the product identity; the desktop sidebar is hidden.
    expect(find.text('PayloadHub-AI'), findsOneWidget);
    expect(find.text('Mobile Security Studio'), findsOneWidget);
    expect(find.text('Alat Cepat'), findsOneWidget);

    await tester.tap(find.text('Generator').last);
    await _settleDrain(tester);
    expect(find.text('One-Liner Generator'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Generate a payload on the phone viewport.
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '192.168.1.20');
    await tester.enterText(fields.at(1), '4444');
    await tester.pump();
    await tester.ensureVisible(find.text('Generate One-Liner').first);
    await tester.tap(find.text('Generate One-Liner').first,
        warnIfMissed: false);
    await _settleDrain(tester);
    expect(tester.takeException(), isNull);

    // Open the history route from the top bar and verify the entry is listed.
    await tester.tap(find.byIcon(Icons.history).first);
    await _settleDrain(tester);
    expect(find.text('Riwayat Aktivitas'), findsOneWidget);
    expect(find.text('Reverse Shell · bash'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await _settleDrain(tester);

    await tester.pumpWidget(const SizedBox());
    await _settleDrain(tester);
  });
}
