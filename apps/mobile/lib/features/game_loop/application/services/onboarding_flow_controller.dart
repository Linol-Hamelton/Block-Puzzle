import '../../../../core/config/remote_config_reader.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../data/analytics/analytics_tracker.dart';
import '../../../../domain/progression/player_progress_repository.dart';
import '../../../../domain/progression/player_progress_state.dart';

/// Manages the FTUE/onboarding flow as a 3-step tutorial sequence.
///
/// Extracted from [GameLoopController] to isolate onboarding state
/// and transitions from core gameplay.
class OnboardingFlowController {
  static const String stepWelcome = 'welcome_drag_piece';
  static const String stepClearLine = 'goal_clear_line';
  static const String stepComboChain = 'goal_combo_chain';
  static const String tutorialFlow = 'onboarding_v1';
  static const String statusShown = 'shown';
  static const String statusCompleted = 'completed';
  static const String statusSkipped = 'skipped';

  OnboardingFlowController({
    required this.playerProgressRepository,
    required this.analyticsTracker,
    required this.logger,
    DateTime Function()? nowUtcProvider,
  }) : _nowUtc = nowUtcProvider ?? (() => DateTime.now().toUtc());

  final PlayerProgressRepository playerProgressRepository;
  final AnalyticsTracker analyticsTracker;
  final AppLogger logger;
  final DateTime Function() _nowUtc;

  bool _enabled = true;
  bool _completed = false;
  int _moveCount = 0;
  int _maxGuidedMoves = 8;

  bool get isEnabled => _enabled;
  bool get isCompleted => _completed;

  /// Configure from remote config values.
  void configure(RemoteConfigReader config) {
    _enabled = config.readBool('onboarding.enabled', fallback: true);
    _maxGuidedMoves = config.readInt(
      'onboarding.max_guided_moves',
      fallback: 8,
    ).clamp(2, 40);
  }

  /// Restore completion status from loaded player progress.
  void restoreFromProgress(PlayerProgressState state) {
    _completed = state.onboardingStatus.completed;
  }

  /// Whether onboarding should show for this game.
  bool shouldShowForGame(int gamesPlayed) {
    return _enabled && !_completed && gamesPlayed == 1;
  }

  /// Get the initial onboarding step ID.
  String get initialStepId => stepWelcome;
  String get initialTitle => 'Welcome to Classic Mode';
  String get initialDescription =>
      'Drag any piece from the rack onto the board to start your run.';

  /// Reset move count for a new game.
  void resetMoveCount() {
    _moveCount = 0;
  }

  /// Process a move to advance the onboarding flow.
  /// Returns an [OnboardingUpdate] describing what changed, or null if
  /// onboarding is inactive.
  Future<OnboardingUpdate?> handleAfterMove({
    required String? currentStepId,
    required bool isOnboardingVisible,
    required int clearedLines,
    required int comboStreak,
    required PlayerProgressState progressState,
  }) async {
    if (_completed || !isOnboardingVisible) {
      return null;
    }

    _moveCount += 1;
    if (currentStepId == null) {
      return null;
    }

    if (currentStepId == stepWelcome) {
      await _trackTutorialStep(stepId: stepWelcome, status: statusCompleted);
      return const OnboardingUpdate(
        type: OnboardingUpdateType.advanceStep,
        stepId: stepClearLine,
        title: 'Clear Your First Line',
        description:
            'Fill a full row or column. Line clears give score boosts and open space.',
      );
    }

    if (currentStepId == stepClearLine) {
      if (clearedLines > 0) {
        await _trackTutorialStep(
            stepId: stepClearLine, status: statusCompleted);
        return const OnboardingUpdate(
          type: OnboardingUpdateType.advanceStep,
          stepId: stepComboChain,
          title: 'Chain a Combo',
          description:
              'Try to clear lines in consecutive moves to build combo multipliers.',
        );
      }
      if (_moveCount >= _maxGuidedMoves) {
        await _markComplete(
          stepId: stepClearLine,
          status: statusSkipped,
          dropoffReason: 'max_guided_moves_reached',
          progressState: progressState,
        );
        return const OnboardingUpdate(type: OnboardingUpdateType.complete);
      }
    }

    if (currentStepId == stepComboChain) {
      if (comboStreak > 1) {
        await _trackTutorialStep(
            stepId: stepComboChain, status: statusCompleted);
        await _markComplete(
          stepId: tutorialFlow,
          status: statusCompleted,
          progressState: progressState,
        );
        return const OnboardingUpdate(type: OnboardingUpdateType.complete);
      }
      if (_moveCount >= _maxGuidedMoves) {
        await _markComplete(
          stepId: stepComboChain,
          status: statusSkipped,
          dropoffReason: 'max_guided_moves_reached',
          progressState: progressState,
        );
        return const OnboardingUpdate(type: OnboardingUpdateType.complete);
      }
    }

    return null;
  }

  /// Dismiss onboarding manually.
  Future<void> dismiss({
    required String? currentStepId,
    required PlayerProgressState progressState,
    String reason = 'manual_dismiss',
  }) async {
    if (_completed) {
      return;
    }
    await _markComplete(
      stepId: currentStepId ?? tutorialFlow,
      status: statusSkipped,
      dropoffReason: reason,
      progressState: progressState,
    );
  }

  /// Mark onboarding as complete on game-over.
  Future<void> completeOnGameOver({
    required String? currentStepId,
    required PlayerProgressState progressState,
  }) async {
    if (_completed) {
      return;
    }
    await _markComplete(
      stepId: currentStepId ?? tutorialFlow,
      status: statusSkipped,
      dropoffReason: 'game_over',
      progressState: progressState,
    );
  }

  /// Track showing a tutorial step.
  Future<void> trackStepShown(String stepId) async {
    await _trackTutorialStep(stepId: stepId, status: statusShown);
  }

  /// Persist activation of a new step into the progress state.
  Future<PlayerProgressState> activateStep({
    required String stepId,
    required PlayerProgressState progressState,
  }) async {
    final PlayerProgressState updated = progressState.copyWith(
      onboardingStatus: progressState.onboardingStatus.copyWith(
        lastStepId: stepId,
        lastStatus: statusShown,
      ),
      lastSeenUtc: _nowUtc(),
    );
    await playerProgressRepository.save(updated);
    return updated;
  }

  // ── Private ──

  Future<void> _markComplete({
    required String stepId,
    required String status,
    required PlayerProgressState progressState,
    String? dropoffReason,
  }) async {
    _completed = true;
    _moveCount = 0;
    final PlayerProgressState updated = progressState.copyWith(
      onboardingStatus: progressState.onboardingStatus.copyWith(
        completed: true,
        lastStepId: stepId,
        lastStatus: status,
      ),
      lastSeenUtc: _nowUtc(),
    );
    await playerProgressRepository.save(updated);
    await _trackTutorialStep(
      stepId: stepId,
      status: status,
      dropoffReason: dropoffReason,
    );
  }

  Future<void> _trackTutorialStep({
    required String stepId,
    required String status,
    String? dropoffReason,
  }) async {
    await analyticsTracker.track(
      'tutorial_step',
      params: <String, Object?>{
        'step_id': stepId,
        'status': status,
        if (dropoffReason != null) 'dropoff_reason': dropoffReason,
      },
    );
  }
}

/// Describes what the onboarding flow wants the controller to do.
class OnboardingUpdate {
  const OnboardingUpdate({
    required this.type,
    this.stepId,
    this.title,
    this.description,
  });

  final OnboardingUpdateType type;
  final String? stepId;
  final String? title;
  final String? description;
}

enum OnboardingUpdateType {
  advanceStep,
  complete,
}
