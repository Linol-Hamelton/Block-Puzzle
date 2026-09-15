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
    this.onSaveFailure,
  });

  final PlayerProgressRepository localRepository;
  final AppLogger logger;

  /// Called when a cloud save fails, so the failure can reach the crash
  /// reporter without this repository depending on it.
  final void Function(Object error, StackTrace stackTrace)? onSaveFailure;

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
                // The cloud copy carries empty entitlement lists by
                // construction - toCloudJson strips them - so adopting it
                // wholesale would erase what the player owns. Progress comes
                // from the cloud, entitlements stay local until
                // entitlements/{uid} is read back.
                final PlayerProgressState merged =
                    cloudState.withEntitlementsFrom(localState);
                logger.info('Cloud state is newer; merging over local state.');
                await localRepository.save(merged);
                return merged;
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
      if (user == null) {
        return;
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        <String, dynamic>{
          // Entitlements are stripped here: they belong to entitlements/{uid},
          // written by verifyPurchase, and the rules reject them in this
          // document. See PlayerProgressState.toCloudJson.
          'progress': state.toCloudJson(),
          'lastSyncUtc': DateTime.now().toUtc().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error, stackTrace) {
      // A rejected write is not a network blip and must not be filed as one.
      // The previous version caught everything and said nothing, so when the
      // security rules denied every save the app looked perfectly healthy and
      // a player would have discovered the loss only after losing the device.
      if (error.code == 'permission-denied') {
        logger.error(
          'Cloud save DENIED by security rules: ${error.message}. '
          'The client/rules contract is broken - progress is local only.',
        );
      } else {
        logger.warn('Cloud save failed (${error.code}); will retry next save.');
      }
      _reportSaveFailure(error, stackTrace);
    } catch (error, stackTrace) {
      logger.warn('Cloud save failed: $error; will retry next save.');
      _reportSaveFailure(error, stackTrace);
    }
  }

  void _reportSaveFailure(Object error, StackTrace stackTrace) {
    // Kept as a seam rather than a direct CrashReporter dependency so this
    // repository stays constructible in tests without a DI container.
    onSaveFailure?.call(error, stackTrace);
  }
}
