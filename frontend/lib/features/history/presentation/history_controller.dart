import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_repository.dart';
import '../domain/activity_entry.dart';

/// Immutable snapshot rendered by the history page and the dashboard panel.
class HistoryState {
  const HistoryState({
    this.entries = const <ActivityEntry>[],
    this.loading = true,
    this.error,
  });

  final List<ActivityEntry> entries;
  final bool loading;
  final String? error;

  HistoryState copyWith({
    List<ActivityEntry>? entries,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return HistoryState(
      entries: entries ?? this.entries,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Loads, appends and prunes the local activity history.
///
/// Writes are serialized through a single future so rapid taps cannot
/// interleave two `save` calls and lose an entry.
class HistoryController extends StateNotifier<HistoryState> {
  HistoryController(this._repository) : super(const HistoryState()) {
    _load();
  }

  final ActivityRepository _repository;

  /// Hard cap so the encrypted blob stays small and the UI stays readable.
  static const int maxEntries = 40;

  Future<void> _writeQueue = Future<void>.value();

  Future<void> _load() async {
    try {
      final entries = await _repository.load();
      final sorted = <ActivityEntry>[...entries]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      state = HistoryState(entries: sorted, loading: false);
    } catch (error) {
      if (!mounted) return;
      state = HistoryState(loading: false, error: error.toString());
    }
  }

  Future<void> reload() async {
    state = state.copyWith(loading: true, clearError: true);
    await _load();
  }

  /// Adds a new entry at the top, trims to [maxEntries] and persists.
  Future<void> add(ActivityEntry entry) async {
    final updated = <ActivityEntry>[entry, ...state.entries];
    if (updated.length > maxEntries) {
      updated.removeRange(maxEntries, updated.length);
    }
    state = state.copyWith(entries: updated, loading: false, clearError: true);
    await _persist(updated);
  }

  Future<void> remove(String id) async {
    final updated =
        state.entries.where((entry) => entry.id != id).toList(growable: false);
    state = state.copyWith(entries: updated);
    await _persist(updated);
  }

  Future<void> clear() async {
    state = state.copyWith(entries: const <ActivityEntry>[]);
    await _persist(const <ActivityEntry>[]);
  }

  Future<void> _persist(List<ActivityEntry> entries) {
    _writeQueue = _writeQueue.then((_) async {
      try {
        await _repository.save(entries);
      } catch (error) {
        if (!mounted) return;
        state = state.copyWith(error: 'Gagal menyimpan riwayat: $error');
      }
    });
    return _writeQueue;
  }
}
