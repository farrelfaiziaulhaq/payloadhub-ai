// Integration-style widget test: drives the dashboard through the sidebar
// pages and taps functional buttons, using fakes so no plugin/network is hit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:payloadhub_ai/main.dart';
import 'package:payloadhub_ai/services/secure_storage_service.dart';
import 'package:payloadhub_ai/features/payload_chat/domain/entities/chat_message.dart';
import 'package:payloadhub_ai/features/payload_chat/domain/repositories/payload_repository.dart';
import 'package:payloadhub_ai/features/dashboard/presentation/dashboard_providers.dart';
import 'package:payloadhub_ai/features/dashboard/presentation/dashboard_screen.dart';

class FakeStorage implements SecureStorageService {
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
  // (periodic telemetry/log timers would make it hang).
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('dashboard pages switch and actions do not throw', (tester) async {
    // Desktop-sized viewport so wide panels lay out as on a real laptop/tablet
    // (must be set BEFORE the first pump to avoid a narrow first frame).
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(FakeStorage()),
          payloadRepositoryProvider.overrideWithValue(FakeRepository()),
        ],
        child: const PayloadHubApp(),
      ),
    );

    await _settleDrain(tester);

    expect(find.text('Dashboard'), findsWidgets);

    // Navigate through every sidebar page.
    for (final page in ['Exploit Library', 'Script Generator', 'Monitoring', 'Settings']) {
      await tester.tap(find.text(page).first);
      await _settleDrain(tester);
      expect(tester.takeException(), isNull);
    }

    // Back to Dashboard.
    await tester.tap(find.text('Dashboard').first);
    await _settleDrain(tester);

    // Script Generator: generate a one-liner (synchronous, offline path).
    await tester.tap(find.text('Script Generator').first);
    await _settleDrain(tester);
    await tester.ensureVisible(find.text('Generate One-Liner').first);
    await _settleDrain(tester);
    await tester.tap(find.text('Generate One-Liner').first, warnIfMissed: false);
    await _settleDrain(tester);
    expect(tester.takeException(), isNull);

    // Verify the controller function actually produced output (the code is
    // rendered inside a RichText/HighlightView, so inspect the state directly).
    final container = ProviderScope.containerOf(tester.element(find.byType(DashboardScreen)));
    final generated = container.read(scriptGenProvider).generated;
    expect(generated, isNotEmpty);
    expect(generated, contains('/dev/tcp'));

    // Unmount so the provider timers are disposed cleanly (no pending-timer fail).
    await tester.pumpWidget(const SizedBox());
    await _settleDrain(tester);
    expect(tester.takeException(), isNull);
  });
}
