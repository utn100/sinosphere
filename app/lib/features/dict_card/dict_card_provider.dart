import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../core/services/database_provider.dart';
import '../../core/services/ai_service.dart';

// Currently displayed character symbol
class ActiveSymbolNotifier extends Notifier<String> {
  @override
  String build() => '晨';
  void set(String s) => state = s;
}
final activeSymbolProvider = NotifierProvider<ActiveSymbolNotifier, String>(ActiveSymbolNotifier.new);

// Full character detail
final characterDetailProvider = FutureProvider.family<CharacterDetail?, String>((ref, symbol) async {
  final db = ref.read(databaseProvider);
  return db.characterDao.getCharacterDetail(symbol);
});

// Bookmark state
final bookmarkProvider = FutureProvider.family<bool, String>((ref, wordId) async {
  final db = ref.read(databaseProvider);
  return db.collectionDao.isBookmarked(wordId);
});

// Etymology state per character
enum EtymologyState { hasStory, generating, missing }

class EtymologyNotifier extends Notifier<EtymologyState> {
  @override
  EtymologyState build() => EtymologyState.missing;
  void set(EtymologyState s) => state = s;
}

// Per-character etymology state — keyed by characterId
final _etymologyStateMap = <String, EtymologyState>{};

class _EtymologyNotifier extends Notifier<EtymologyState> {
  final String characterId;
  _EtymologyNotifier(this.characterId);
  @override
  EtymologyState build() => _etymologyStateMap[characterId] ?? EtymologyState.missing;
  void set(EtymologyState s) {
    _etymologyStateMap[characterId] = s;
    state = s;
  }
}

final etymologyStateProvider =
    NotifierProvider.family<_EtymologyNotifier, EtymologyState, String>(
        (id) => _EtymologyNotifier(id));

// Generates and caches etymology story
class EtymologyController {
  final Ref ref;
  EtymologyController(this.ref);

  Future<void> generate({
    required String characterId,
    required String symbol,
    required String pinyin,
    required String hanViet,
    required String englishDef,
    required List<ComponentWithType> components,
  }) async {
    final db       = ref.read(databaseProvider);
    final ai       = ref.read(aiServiceProvider);
    final settings = await ref.read(llmSettingsProvider.future);
    if (!settings.isConfigured) return;

    _etymologyStateMap[characterId] = EtymologyState.generating;
    ref.read(etymologyStateProvider(characterId).notifier).set(EtymologyState.generating);

    final compMaps = components.map((c) => {
      'symbol':     c.component.symbol,
      'pinyin':     c.component.pinyin,
      'hanViet':    c.component.hanViet,
      'englishDef': c.component.englishDef,
      'type':       c.componentType ?? 'semantic',
    }).toList();

    final story = await ai.generateEtymologyStory(
      symbol: symbol, pinyin: pinyin, hanViet: hanViet,
      englishDef: englishDef, components: compMaps, settings: settings,
    );

    if (story != null && story.isNotEmpty) {
      await db.characterDao.updateEtymologyStory(characterId, story);
      // L3: set hasStory immediately so card transitions without waiting for provider reload
      ref.read(etymologyStateProvider(characterId).notifier).set(EtymologyState.hasStory);
      ref.invalidate(characterDetailProvider(symbol));
      return; // state already set above
    }

    ref.read(etymologyStateProvider(characterId).notifier).set(EtymologyState.missing);
  }
}

final etymologyControllerProvider =
    Provider<EtymologyController>((ref) => EtymologyController(ref));
