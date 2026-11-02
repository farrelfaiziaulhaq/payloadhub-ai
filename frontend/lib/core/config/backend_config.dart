import 'package:flutter/foundation.dart';

import '../../services/secure_storage_service.dart';

/// Runtime backend URL configuration.
///
/// The default is platform-aware (Android emulator reaches the host through
/// `10.0.2.2`; desktops and web use `localhost`). A user running the app on a
/// physical phone can override it from Settings without editing source code.
class BackendConfig {
  BackendConfig._();

  static String? _override;

  static String get platformDefault {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static String get baseUrl {
    final value = _override?.trim();
    return (value == null || value.isEmpty) ? platformDefault : value;
  }

  /// Removes trailing slashes and adds `http://` when the scheme is omitted.
  static String normalize(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';
    if (!value.contains('://')) value = 'http://$value';
    return value.replaceFirst(RegExp(r'/+$'), '');
  }

  /// Loads the persisted override at application startup.
  static Future<void> load() async {
    try {
      final stored = await SecureStorageService.instance.readBaseUrl();
      _override = (stored == null || stored.trim().isEmpty) ? null : stored.trim();
    } catch (_) {
      // A storage failure must not prevent the app from opening; fall back to
      // the platform default and let the user retry from Settings.
      _override = null;
    }
  }

  static Future<void> save(String raw) async {
    final value = normalize(raw);
    await SecureStorageService.instance.writeBaseUrl(value);
    _override = value.isEmpty ? null : value;
  }

  static Future<void> reload() => load();
}
