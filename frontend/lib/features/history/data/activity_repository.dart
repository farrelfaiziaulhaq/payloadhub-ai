import 'dart:convert';

import '../../../services/secure_storage_service.dart';
import '../domain/activity_entry.dart';

/// Storage contract for the activity history.
///
/// Kept as an interface so widget/unit tests can inject an in-memory fake and
/// so a future SQLite or cloud implementation can replace the encrypted
/// key-value store without touching the presentation layer.
abstract class ActivityRepository {
  Future<List<ActivityEntry>> load();

  Future<void> save(List<ActivityEntry> entries);
}

/// Persists history inside [SecureStorageService] (Android Keystore backed).
///
/// Payload snippets are security-sensitive material, so they are stored with
/// the same encrypted backend as the API keys instead of plain preferences.
class SecureActivityRepository implements ActivityRepository {
  SecureActivityRepository(this._storage);

  final SecureStorageService _storage;

  @override
  Future<List<ActivityEntry>> load() async {
    final raw = await _storage.readActivityLog();
    if (raw == null || raw.trim().isEmpty) return <ActivityEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <ActivityEntry>[];
      final entries = <ActivityEntry>[];
      for (final item in decoded) {
        final entry = ActivityEntry.tryFromJson(item);
        if (entry != null) entries.add(entry);
      }
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } on FormatException {
      // A corrupted blob must not block the app; start with an empty history.
      return <ActivityEntry>[];
    }
  }

  @override
  Future<void> save(List<ActivityEntry> entries) async {
    final payload = jsonEncode(
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );
    await _storage.writeActivityLog(payload);
  }
}
