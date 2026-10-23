import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/presentation/dashboard_providers.dart';
import '../data/activity_repository.dart';
import 'history_controller.dart';

/// Encrypted activity-history store used by the app.
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return SecureActivityRepository(ref.watch(secureStorageProvider));
});

/// Local history state (list, loading flag, last persistence error).
final historyProvider =
    StateNotifierProvider<HistoryController, HistoryState>((ref) {
  return HistoryController(ref.watch(activityRepositoryProvider));
});
