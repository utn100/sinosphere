import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/database_provider.dart';
import '../../core/services/lang_mode_provider.dart';

/// What the practice-reading screen should render.
enum PracticePhase {
  loading,       // still counting the learned-word pool
  notConfigured, // no LLM provider/key set
  emptyPool,     // configured, but no bookmarked/memorized words
  ready,         // can generate
  generating,    // request in flight
  success,       // story generated
  failed,        // generation failed (retries exhausted) — offer retry
}

class PracticeReadingState {
  final PracticePhase phase;
  final int wordCount;
  final String? story;
  final String? errorMessage;

  const PracticeReadingState({
    this.phase = PracticePhase.loading,
    this.wordCount = 0,
    this.story,
    this.errorMessage,
  });

  PracticeReadingState copyWith({
    PracticePhase? phase,
    int? wordCount,
    String? story,
    String? errorMessage,
    bool clearStory = false,
    bool clearError = false,
  }) => PracticeReadingState(
    phase: phase ?? this.phase,
    wordCount: wordCount ?? this.wordCount,
    story: clearStory ? null : (story ?? this.story),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

class PracticeReadingNotifier extends Notifier<PracticeReadingState> {
  AppDatabase get _db => ref.read(databaseProvider);

  static const _wordLimit = 20;

  @override
  PracticeReadingState build() {
    // Kick off the initial pool/config check; return loading synchronously.
    Future.microtask(refresh);
    return const PracticeReadingState();
  }

  bool get _isKorean => ref.read(langModeProvider) == LangMode.korean;

  Future<List<String>> _loadWords() =>
      _db.collectionDao.getLearnedWordForms(
          isKorean: _isKorean, limit: _wordLimit);

  /// Recomputes the resting phase (notConfigured / emptyPool / ready) from the
  /// current AI settings and learned-word pool. Does not generate.
  Future<void> refresh() async {
    final settings = await ref.read(llmSettingsProvider.future);
    final words = await _loadWords();
    if (!settings.isConfigured) {
      state = state.copyWith(
          phase: PracticePhase.notConfigured, wordCount: words.length,
          clearStory: true);
      return;
    }
    if (words.isEmpty) {
      state = state.copyWith(
          phase: PracticePhase.emptyPool, wordCount: 0, clearStory: true);
      return;
    }
    state = state.copyWith(
        phase: PracticePhase.ready, wordCount: words.length);
  }

  /// Generates a story from a fresh random sample of the learner's words.
  /// Each call re-samples, so there is no cache — every generation (and every
  /// Regenerate) reviews a different slice of the pool and costs one request.
  Future<void> generate() async {
    if (state.phase == PracticePhase.generating) return;
    final settings = await ref.read(llmSettingsProvider.future);
    if (!settings.isConfigured) {
      state = state.copyWith(phase: PracticePhase.notConfigured);
      return;
    }
    final words = await _loadWords();
    if (words.isEmpty) {
      state = state.copyWith(phase: PracticePhase.emptyPool, wordCount: 0);
      return;
    }

    final isKorean = _isKorean;
    state = state.copyWith(
        phase: PracticePhase.generating, wordCount: words.length,
        clearStory: true, clearError: true);
    final ai = ref.read(aiServiceProvider);
    try {
      // Diagnostic variant throws with the real HTTP status/body/timeout so a
      // release-build failure is visible in the UI.
      final story = await ai.generateReadingStoryDiagnostic(
          words: words, isKorean: isKorean, settings: settings);
      state = state.copyWith(phase: PracticePhase.success, story: story);
    } catch (e) {
      state = state.copyWith(
          phase: PracticePhase.failed, clearStory: true,
          errorMessage: e.toString());
    }
  }
}

final practiceReadingProvider =
    NotifierProvider<PracticeReadingNotifier, PracticeReadingState>(
        PracticeReadingNotifier.new);
