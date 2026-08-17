import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

enum LlmProvider { claude, gemini, openai, custom }

extension LlmProviderX on LlmProvider {
  String get displayName {
    switch (this) {
      case LlmProvider.claude:  return 'Claude Haiku';
      case LlmProvider.gemini:  return 'Gemini Flash';
      case LlmProvider.openai:  return 'GPT-4o mini';
      case LlmProvider.custom:  return 'Custom Endpoint';
    }
  }
  String get keyLabel {
    switch (this) {
      case LlmProvider.claude:  return 'Anthropic API Key';
      case LlmProvider.gemini:  return 'Google AI API Key';
      case LlmProvider.openai:  return 'OpenAI API Key';
      case LlmProvider.custom:  return 'API Key / Bearer Token';
    }
  }
  String get keyHint {
    switch (this) {
      case LlmProvider.claude:  return 'sk-ant-...';
      case LlmProvider.gemini:  return 'AIza...';
      case LlmProvider.openai:  return 'sk-...';
      case LlmProvider.custom:  return 'Your API key or bearer token';
    }
  }
}

class LlmSettings {
  final LlmProvider provider;
  final String apiKey;
  final String customBaseUrl;
  final String customModel;

  const LlmSettings({
    this.provider = LlmProvider.claude,
    this.apiKey = '',
    this.customBaseUrl = '',
    this.customModel = '',
  });

  bool get isConfigured {
    if (apiKey.isEmpty) return false;
    if (provider == LlmProvider.custom && customBaseUrl.isEmpty) return false;
    return true;
  }

  LlmSettings copyWith({
    LlmProvider? provider, String? apiKey,
    String? customBaseUrl, String? customModel,
  }) => LlmSettings(
    provider: provider ?? this.provider,
    apiKey: apiKey ?? this.apiKey,
    customBaseUrl: customBaseUrl ?? this.customBaseUrl,
    customModel: customModel ?? this.customModel,
  );
}

class WordExample {
  final String zh;
  final String py;
  final String en;
  const WordExample({required this.zh, required this.py, required this.en});
}

class WordDetails {
  final List<String> synonyms;
  final List<String> antonyms;
  final List<WordExample> examples;
  const WordDetails({
    required this.synonyms,
    required this.antonyms,
    required this.examples,
  });
}

const _systemPrompt = '''Bạn là chuyên gia ngôn ngữ học Hán-Việt và Chiết tự học.
Nhiệm vụ của bạn là viết một câu chuyện ký ức ngắn (2-3 câu) bằng tiếng Việt
giải thích logic kết hợp các thành phần của một chữ Hán.

Phong cách:
- Ngắn gọn, sinh động, dễ nhớ
- Nêu rõ tên Hán-Việt của từng thành phần trong ngoặc đơn
- Giải thích TẠI SAO các thành phần kết hợp tạo ra nghĩa đó
- Không dùng thuật ngữ học thuật khó hiểu

Chỉ trả về câu chuyện, không có gì khác.''';

class AiService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const _providerKey    = 'llm_provider';
  static const _apiKeyKey      = 'llm_api_key';
  static const _baseUrlKey     = 'llm_base_url';
  static const _customModelKey = 'llm_custom_model';

  Future<LlmSettings> loadSettings() async {
    final providerStr = await _storage.read(key: _providerKey);
    final apiKey      = await _storage.read(key: _apiKeyKey)      ?? '';
    final provider    = LlmProvider.values.firstWhere(
        (p) => p.name == providerStr, orElse: () => LlmProvider.claude);

    // Only load baseUrl/model for custom provider — clear for others
    final baseUrl     = provider == LlmProvider.custom
        ? (await _storage.read(key: _baseUrlKey) ?? '') : '';
    final customModel = provider == LlmProvider.custom
        ? (await _storage.read(key: _customModelKey) ?? '') : '';

    return LlmSettings(provider: provider, apiKey: apiKey,
        customBaseUrl: baseUrl, customModel: customModel);
  }

  Future<void> saveSettings(LlmSettings settings) async {
    await _storage.write(key: _providerKey, value: settings.provider.name);
    await _storage.write(key: _apiKeyKey,   value: settings.apiKey);
    if (settings.provider == LlmProvider.custom) {
      await _storage.write(key: _baseUrlKey,     value: settings.customBaseUrl);
      await _storage.write(key: _customModelKey, value: settings.customModel);
    } else {
      // Clear custom fields so they never bleed into other providers
      await _storage.delete(key: _baseUrlKey);
      await _storage.delete(key: _customModelKey);
    }
  }

  Future<String?> generateEtymologyStory({
    required String symbol, required String pinyin,
    required String hanViet, required String englishDef,
    required List<Map<String, String>> components,
    required LlmSettings settings,
  }) async {
    if (!settings.isConfigured) return null;

    final compLines = components.map((c) =>
        '  - ${c['symbol']} [${c['pinyin']}] ${c['hanViet']} = ${c['englishDef']} [${c['type']}]')
        .join('\n');

    final prompt = '''Chữ: $symbol
Pinyin: $pinyin
Hán-Việt: $hanViet
Nghĩa tiếng Anh: $englishDef
Thành phần:
$compLines

Viết câu chuyện Chiết tự ngắn (2-3 câu tiếng Việt):''';

    try {
      return await _dispatch(settings, prompt);
    } catch (_) {
      return null;
    }
  }

  Future<String?> testConnection(LlmSettings settings) =>
      generateEtymologyStory(
        symbol: '一', pinyin: 'yī', hanViet: 'NHẤT', englishDef: 'one',
        components: [], settings: settings);

  Future<String?> translateText(String chineseText, LlmSettings settings) async {
    if (!settings.isConfigured) return null;
    final prompt = 'Translate this Chinese text to natural English. '
        'Preserve the tone and style. Return only the translation:\n\n$chineseText';
    try {
      return await _dispatch(settings, prompt);
    } catch (_) {
      return null;
    }
  }

  Future<WordDetails?> generateWordDetails(
      String simplified, String pinyin, String englishDef,
      LlmSettings settings) async {
    if (!settings.isConfigured) return null;
    final prompt =
        'Chinese word: $simplified ($pinyin) — $englishDef\n\n'
        'Return ONLY a JSON object with keys:\n'
        '"synonyms": array of 2-3 simplified Chinese synonyms (characters only, empty if none)\n'
        '"antonyms": array of 1-2 simplified Chinese antonyms (characters only, empty if none)\n'
        '"examples": array of 1-3 objects, each with "zh" (8-25 char sentence), '
        '"py" (full pinyin with tone marks), "en" (natural English translation)\n\n'
        'Example: {"synonyms":["高兴","愉快"],"antonyms":["悲伤"],"examples":['
        '{"zh":"她看起来非常快乐。","py":"Tā kàn qǐlái fēicháng kuàilè.","en":"She looks very happy."}]}';
    try {
      final raw = await _dispatchRaw(settings, prompt);
      if (raw == null) return null;
      final clean = raw.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
      final map = jsonDecode(clean) as Map<String, dynamic>;
      final examplesList = (map['examples'] as List?)?.map((e) {
        final m = e as Map<String, dynamic>;
        return WordExample(
          zh: m['zh'] as String? ?? '',
          py: m['py'] as String? ?? '',
          en: m['en'] as String? ?? '',
        );
      }).toList() ?? [];
      return WordDetails(
        synonyms: (map['synonyms'] as List?)
            ?.map((e) => e.toString()).toList() ?? [],
        antonyms: (map['antonyms'] as List?)
            ?.map((e) => e.toString()).toList() ?? [],
        examples: examplesList,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _dispatch(LlmSettings settings, String prompt) =>
      _dispatchRaw(settings, prompt);

  Future<String?> _dispatchRaw(LlmSettings settings, String prompt) {
    switch (settings.provider) {
      case LlmProvider.claude:
        return _callClaude(settings.apiKey, prompt);
      case LlmProvider.gemini:
        return _callGemini(settings.apiKey, prompt);
      case LlmProvider.openai:
        return _callOpenAiCompat(settings.apiKey, 'https://api.openai.com',
            prompt, model: 'gpt-4o-mini');
      case LlmProvider.custom:
        if (settings.customBaseUrl.isEmpty) return Future.value(null);
        return _callOpenAiCompat(settings.apiKey, settings.customBaseUrl,
            prompt, model: settings.customModel.isNotEmpty
                ? settings.customModel : 'gpt-4o-mini');
    }
  }

  Future<String?> _callClaude(String apiKey, String prompt) async {
    final uri = Uri.parse('https://api.anthropic.com/v1/messages');
    final response = await http.post(uri,
      headers: {
        'Content-Type':      'application/json',
        'x-api-key':         apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-haiku-4-5', 'max_tokens': 512,
        'system': _systemPrompt,
        'messages': [{'role': 'user', 'content': prompt}],
      }),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return null;
    final data    = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List?;
    if (content == null || content.isEmpty) return null;
    return (content.first as Map)['text'] as String?;
  }

  Future<String?> _callGemini(String apiKey, String prompt) async {
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');
    final response = await http.post(uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {'parts': [{'text': _systemPrompt}]},
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {'maxOutputTokens': 512},
      }),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
  }

  Future<String?> _callOpenAiCompat(String apiKey, String baseUrl, String prompt,
      {String model = 'gpt-4o-mini'}) async {
    if (baseUrl.isEmpty) return null;
    final uri = Uri.parse('$baseUrl/v1/chat/completions');
    final response = await http.post(uri,
      headers: {
        'Content-Type':  'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model, 'max_tokens': 512,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user',   'content': prompt},
        ],
      }),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['choices']?[0]?['message']?['content'] as String?;
  }
}

final aiServiceProvider = Provider<AiService>((ref) => AiService());

final llmSettingsProvider =
    AsyncNotifierProvider<LlmSettingsNotifier, LlmSettings>(LlmSettingsNotifier.new);

class LlmSettingsNotifier extends AsyncNotifier<LlmSettings> {
  @override
  Future<LlmSettings> build() => ref.read(aiServiceProvider).loadSettings();

  Future<void> save(LlmSettings settings) async {
    await ref.read(aiServiceProvider).saveSettings(settings);
    state = AsyncData(settings);
  }
}
