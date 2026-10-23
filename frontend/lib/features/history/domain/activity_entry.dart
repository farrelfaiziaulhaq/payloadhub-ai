/// Domain model for one locally stored activity record.
///
/// Activity history is intentionally small (an id, a kind, a title, a detail
/// and a timestamp) so it can be persisted as a compact JSON array inside the
/// encrypted storage that the app already uses for API keys.
enum ActivityKind { payload, exploit, scan, threat, chat }

extension ActivityKindLabel on ActivityKind {
  /// Human-readable label used by the history list and the detail sheet.
  String get label {
    switch (this) {
      case ActivityKind.payload:
        return 'Payload';
      case ActivityKind.exploit:
        return 'Exploit';
      case ActivityKind.scan:
        return 'Scan';
      case ActivityKind.threat:
        return 'Threat Intel';
      case ActivityKind.chat:
        return 'AI Chat';
    }
  }

  /// Stable identifier stored in JSON (do not rename without a migration).
  String get storageKey => name;

  static ActivityKind fromStorage(String? raw) {
    for (final kind in ActivityKind.values) {
      if (kind.name == raw) return kind;
    }
    return ActivityKind.payload;
  }
}

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.createdAt,
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final String detail;
  final DateTime createdAt;

  /// Factory that derives a sortable id from the creation timestamp.
  factory ActivityEntry.create({
    required ActivityKind kind,
    required String title,
    required String detail,
    DateTime? createdAt,
  }) {
    final timestamp = createdAt ?? DateTime.now();
    return ActivityEntry(
      id: '${timestamp.microsecondsSinceEpoch}-${kind.name}',
      kind: kind,
      title: title,
      detail: detail,
      createdAt: timestamp,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.storageKey,
        'title': title,
        'detail': detail,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Defensive parser: malformed records are skipped by the repository instead
  /// of crashing the whole history page.
  static ActivityEntry? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    final title = json['title'];
    final detail = json['detail'];
    final createdAtRaw = json['createdAt'];
    if (id is! String || title is! String || detail is! String) {
      return null;
    }
    final createdAt =
        createdAtRaw is String ? DateTime.tryParse(createdAtRaw) : null;
    if (createdAt == null) return null;
    return ActivityEntry(
      id: id,
      kind: ActivityKindLabel.fromStorage(json['kind'] as String?),
      title: title,
      detail: detail,
      createdAt: createdAt,
    );
  }
}
