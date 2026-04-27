import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/progression/player_progress_repository.dart';
import '../../domain/progression/player_progress_state.dart';

/// Wraps a local [PlayerProgressRepository] with Firebase Cloud Save capabilities.
/// Uses Anonymous Authentication and Cloud Firestore.
class CloudPlayerProgressRepository implements PlayerProgressRepository {
  CloudPlayerProgressRepository({
    required this.localRepository,
    required this.logger,
  });

  final PlayerProgressRepository localRepository;
  final AppLogger logger;

  @override
  Future<PlayerProgressState?> load() async {
    // 1. Always load local first to be fast and offline-capable
    final PlayerProgressState? localState = await localRepository.load();

    // 2. Authenticate anonymously in the background
    try {
      final UserCredential cred = await FirebaseAuth.instance.signInAnonymously();
      final User? user = cred.user;

      if (user != null) {
        // 3. Try to fetch from cloud
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          if (data != null && data['progress'] != null) {
            try {
              final Map<String, Object?> progressMap =
                  (data['progress'] as Map).cast<String, Object?>();
              final PlayerProgressState cloudState =
                  PlayerProgressState.fromJson(progressMap);

              // Conflict resolution: pick the one with higher bestScore
              // If bestScore is same, pick the one with newer lastSeenUtc
              if (localState == null) {
                await localRepository.save(cloudState);
                return cloudState;
              }

              if (cloudState.bestScore > localState.bestScore ||
                  (cloudState.bestScore == localState.bestScore &&
                      cloudState.lastSeenUtc.isAfter(localState.lastSeenUtc))) {
                logger.info('Cloud state is newer. Overwriting local state.');
                await localRepository.save(cloudState);
                return cloudState;
              }
            } catch (parseError) {
              logger.warn('Failed to parse cloud progress: $parseError');
            }
          }
        }
      }
    } catch (e) {
      logger.warn('Cloud sync load failed (user might be offline): $e');
    }

    return localState;
  }

  @override
  Future<void> save(PlayerProgressState state) async {
    // 1. Always save local synchronously to ensure no data loss
    await localRepository.save(state);

    // 2. Fire and forget to cloud
    _saveToCloud(state).ignore();
  }

  Future<void> _saveToCloud(PlayerProgressState state) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(
          <String, dynamic>{
            'progress': state.toJson(),
            'lastSyncUtc': DateTime.now().toUtc().toIso8601String(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      // Ignore network errors, it will sync next time
    }
  }
}
