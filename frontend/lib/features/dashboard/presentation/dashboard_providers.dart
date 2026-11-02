import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/backend_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../services/free_chatbot_service.dart';
import '../../../services/secure_storage_service.dart';
import '../../payload_chat/data/payload_repository_impl.dart';
import '../../payload_chat/domain/repositories/payload_repository.dart';
import '../data/threat_intel_service.dart';
import 'controllers/free_chat_controller.dart';
import 'controllers/script_generator_controller.dart';
import 'controllers/studio_controller.dart';
import 'controllers/telemetry_controller.dart';
import '../domain/models/dashboard_models.dart';

/// Platform-aware default backend base URL, optionally overridden in Settings.
String get defaultBaseUrl => BackendConfig.baseUrl;

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService.instance,
);

// IMPORTANT: keep this chain synchronous. Making it depend on an async provider
// (e.g. a `FutureProvider`) causes the notifier providers below to recompute and
// DISPOSE their StateNotifiers when the future resolves, which produces
// "Bad state: Tried to use XController after dispose was called" when a button
// already captured the stale notifier. The base URL can still be overridden by
// editing `defaultBaseUrl` or by restarting after a change in Settings.
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(baseUrl: defaultBaseUrl);
});

final payloadRepositoryProvider = Provider<PayloadRepository>((ref) {
  return PayloadRepositoryImpl(ref.watch(dioClientProvider));
});

final threatIntelServiceProvider = Provider<ThreatIntelService>((ref) {
  return ThreatIntelService(
    ref.watch(dioClientProvider),
    ref.watch(secureStorageProvider),
  );
});

final telemetryProvider =
    StateNotifierProvider<TelemetryController, TelemetryData>((ref) {
  return TelemetryController();
});

final studioProvider =
    StateNotifierProvider<StudioController, StudioState>((ref) {
  return StudioController(
    ref.watch(payloadRepositoryProvider),
    ref.watch(secureStorageProvider),
  );
});

final scriptGenProvider =
    StateNotifierProvider<ScriptGenController, ScriptGenState>((ref) {
  return ScriptGenController(
    ref.watch(payloadRepositoryProvider),
    ref.watch(secureStorageProvider),
  );
});

final freeChatbotServiceProvider = Provider<FreeChatbotService>((ref) {
  return FreeChatbotService(ref.watch(secureStorageProvider));
});

final freeChatControllerProvider =
    StateNotifierProvider<FreeChatController, FreeChatState>((ref) {
  return FreeChatController(ref.watch(freeChatbotServiceProvider));
});
