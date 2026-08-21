import 'dart:convert';
import 'dart:developer' as developer;
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
  static const _baseUrlKey     = 'llm_base_url';
  static const _customModelKey = 'llm_custom_model';

  // Per-provider API key so switching providers doesn't clobber a saved key.
  // Legacy single-key ('llm_api_key') is migrated into the active provider.
  static const _legacyApiKeyKey = 'llm_api_key';
  static String _apiKeyKeyFor(LlmProvider p) => 'llm_api_key_${p.name}';

  Future<LlmSettings> loadSettings() async {
    final providerStr = await _storage.read(key: _providerKey);
    final provider    = LlmProvider.values.firstWhere(
        (p) => p.name == providerStr, orElse: () => LlmProvider.claude);

    var apiKey = await _storage.read(key: _apiKeyKeyFor(provider)) ?? '';
    // One-time migration: fold the old shared key into the active provider.
    if (apiKey.isEmpty) {
      final legacy = await _storage.read(key: _legacyApiKeyKey);
      if (legacy != null && legacy.isNotEmpty) {
        apiKey = legacy;
        await _storage.write(key: _apiKeyKeyFor(provider), value: legacy);
        await _storage.delete(key: _legacyApiKeyKey);
      }
    }

    // Base URL / model belong to the custom provider. Always load them so
    // they persist when the user switches away and back to Custom.
    final baseUrl     = await _storage.read(key: _baseUrlKey) ?? '';
    final customModel = await _storage.read(key: _customModelKey) ?? '';

    return LlmSettings(provider: provider, apiKey: apiKey,
        customBaseUrl: baseUrl, customModel: customModel);
  }

  Future<void> saveSettings(LlmSettings settings) async {
    await _storage.write(key: _providerKey, value: settings.provider.name);
    await _storage.write(
        key: _apiKeyKeyFor(settings.provider), value: settings.apiKey);
    // Persist custom URL/model whenever provided. Only the custom provider
    // writes them, and they're harmless for other providers, so we keep them
    // rather than deleting — so switching away and back preserves them.
    if (settings.provider == LlmProvider.custom) {
      await _storage.write(key: _baseUrlKey,     value: settings.customBaseUrl);
      await _storage.write(key: _customModelKey, value: settings.customModel);
    }
  }

  /// Changes only the active provider selection, leaving every provider's
  /// stored key intact. Use when the user picks a different provider so we
  /// then reload THAT provider's own saved key.
  Future<void> setActiveProvider(LlmProvider provider) =>
      _storage.write(key: _providerKey, value: provider.name);

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

  Future<String?> testConnection(LlmSettings settings) async {
    // Diagnostic path: unlike production calls, this THROWS with the real
    // HTTP status + response body so the failure is visible in the Settings
    // test box on a release APK (where developer.log is invisible).
    if (!settings.isConfigured) {
      throw Exception('Not configured: enter an API key'
          '${settings.provider == LlmProvider.custom ? " and Base URL" : ""}.');
    }
    const prompt = 'Chữ: 一\nViết câu chuyện Chiết tự ngắn (2-3 câu tiếng Việt):';
    final (uri, headers, body) = _buildRequest(settings, prompt);
    http.Response? resp;
    // Retry transient statuses (busy/rate-limit) a few times so a one-off 503
    // doesn't read as a hard failure — same policy as production calls.
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        resp = await http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          throw Exception('Network error reaching $uri\n$e');
        }
        await Future.delayed(_retryDelays[attempt]);
        continue;
      }
      if (_retryableStatus.contains(resp.statusCode) &&
          attempt < _maxRetries - 1) {
        await Future.delayed(_retryDelays[attempt]);
        continue;
      }
      break;
    }
    if (resp!.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} from $uri\n${resp.body}');
    }
    final text = _extractText(settings.provider, resp.body);
    if (text == null) {
      throw Exception('HTTP 200 but no text in response:\n${resp.body}');
    }
    return text;
  }

  /// Builds the (uri, headers, body) for a provider — shared by the test path.
  (Uri, Map<String, String>, String) _buildRequest(
      LlmSettings settings, String prompt,
      {String? systemPrompt, int maxTokens = 512}) {
    final sys = systemPrompt ?? _systemPrompt;
    switch (settings.provider) {
      case LlmProvider.claude:
        return (
          Uri.parse('https://api.anthropic.com/v1/messages'),
          {
            'Content-Type':      'application/json',
            'x-api-key':         settings.apiKey,
            'anthropic-version': '2023-06-01',
          },
          jsonEncode({
            'model': 'claude-haiku-4-5', 'max_tokens': maxTokens,
            'system': sys,
            'messages': [{'role': 'user', 'content': prompt}],
          }),
        );
      case LlmProvider.gemini:
        return (
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/'
              'models/gemini-flash-latest:generateContent?key=${settings.apiKey}'),
          {'Content-Type': 'application/json'},
          jsonEncode({
            'system_instruction': {'parts': [{'text': sys}]},
            'contents': [{'parts': [{'text': prompt}]}],
            'generationConfig': {'maxOutputTokens': maxTokens},
          }),
        );
      case LlmProvider.openai:
        return _openAiCompatRequest(
            settings.apiKey, 'https://api.openai.com', 'gpt-4o-mini', prompt,
            systemPrompt: sys, maxTokens: maxTokens);
      case LlmProvider.custom:
        return _openAiCompatRequest(
            settings.apiKey, settings.customBaseUrl,
            settings.customModel.isNotEmpty ? settings.customModel : 'gpt-4o-mini',
            prompt, systemPrompt: sys, maxTokens: maxTokens);
    }
  }

  (Uri, Map<String, String>, String) _openAiCompatRequest(
      String apiKey, String baseUrl, String model, String prompt,
      {String? systemPrompt, int maxTokens = 512}) => (
    Uri.parse('$baseUrl/v1/chat/completions'),
    {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    jsonEncode({
      'model': model, 'max_tokens': maxTokens,
      'messages': [
        {'role': 'system', 'content': systemPrompt ?? _systemPrompt},
        {'role': 'user',   'content': prompt},
      ],
    }),
  );

  String? _extractText(LlmProvider provider, String responseBody) {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    switch (provider) {
      case LlmProvider.claude:
        final content = data['content'] as List?;
        if (content == null || content.isEmpty) return null;
        return (content.first as Map)['text'] as String?;
      case LlmProvider.gemini:
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      case LlmProvider.openai:
      case LlmProvider.custom:
        return data['choices']?[0]?['message']?['content'] as String?;
    }
  }

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

  /// Generates a short graded-reader passage built mostly from the learner's
  /// own [words] (their bookmarked + memorized vocabulary), in Chinese or
  /// Korean. THROWS with the real HTTP status/body/timeout on failure so the
  /// failure is visible on a release APK (where developer.log is invisible);
  /// mirrors [testConnection]'s retry loop. Returns only the story text.
  Future<String> generateReadingStoryDiagnostic({
    required List<String> words,
    required bool isKorean,
    required LlmSettings settings,
  }) async {
    if (!settings.isConfigured) {
      throw Exception('Not configured: enter an API key'
          '${settings.provider == LlmProvider.custom ? " and Base URL" : ""}.');
    }
    if (words.isEmpty) throw Exception('No learned words to build a story from.');

    final (uri, headers, body) = _buildRequest(
        settings, _storyPrompt(words, isKorean),
        systemPrompt: _storySystemPrompt(isKorean), maxTokens: 1024);
    http.Response? resp;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        resp = await http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 60));
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          throw Exception('Network error / timeout reaching $uri\n$e');
        }
        await Future.delayed(_retryDelays[attempt]);
        continue;
      }
      if (_retryableStatus.contains(resp.statusCode) &&
          attempt < _maxRetries - 1) {
        await Future.delayed(_retryDelays[attempt]);
        continue;
      }
      break;
    }
    if (resp!.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} from $uri\n${resp.body}');
    }
    final text = _extractText(settings.provider, resp.body);
    if (text == null || text.trim().isEmpty) {
      throw Exception('HTTP 200 but no story text in response:\n${resp.body}');
    }
    return text;
  }

  String _storySystemPrompt(bool isKorean) {
    final lang = isKorean ? 'Korean (Hangul)' : 'Simplified Chinese';
    return 'You are a language teacher writing very short, simple graded-reader '
        'passages for a beginner learning $lang. Your passages are built mostly '
        'from a given list of target words, connected with only the simplest '
        'possible glue vocabulary and grammar. Keep it concrete, coherent, and '
        'easy to read.';
  }

  String _storyPrompt(List<String> words, bool isKorean) {
    final lang = isKorean ? 'Korean (Hangul)' : 'Simplified Chinese';
    final wordList = words.map((w) => '- $w').join('\n');
    return 'Write a short $lang story (2–4 short paragraphs) for reading practice.\n'
        'Use as MANY of these target words as you naturally can, weaving them '
        'into a single coherent little story:\n\n$wordList\n\n'
        'Rules:\n'
        '- Write ONLY in $lang script (no pinyin/romaja, no English).\n'
        '- Keep sentences short and simple; use only easy connective words '
        'beyond the target words.\n'
        '- Return ONLY the story text, nothing else.';
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

  Future<String?> _dispatch(LlmSettings settings, String prompt,
          {String? systemPrompt, int maxTokens = 512,
           Duration timeout = const Duration(seconds: 30)}) =>
      _dispatchRaw(settings, prompt,
          systemPrompt: systemPrompt, maxTokens: maxTokens, timeout: timeout);

  /// Transient status codes worth retrying: rate-limit + server-side blips.
  static const _retryableStatus = {429, 500, 502, 503, 504};
  static const _maxRetries = 3; // total attempts
  static const _retryDelays = [
    Duration(milliseconds: 800),
    Duration(milliseconds: 2000),
  ];

  Future<String?> _dispatchRaw(LlmSettings settings, String prompt,
      {String? systemPrompt, int maxTokens = 512,
       Duration timeout = const Duration(seconds: 30)}) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await _callProvider(settings, prompt,
            systemPrompt: systemPrompt, maxTokens: maxTokens, timeout: timeout);
      } on _RetryableException catch (e) {
        final isLast = attempt == _maxRetries - 1;
        developer.log(
            'Transient LLM failure (${e.reason}), attempt '
            '${attempt + 1}/$_maxRetries${isLast ? " — giving up" : " — retrying"}',
            name: 'AiService.Retry');
        if (isLast) return null;
        await Future.delayed(_retryDelays[attempt]);
      } catch (e) {
        // Non-retryable (bad key, 404, parse error): fail fast.
        developer.log('Non-retryable LLM failure: $e', name: 'AiService.Retry');
        return null;
      }
    }
    return null;
  }

  Future<String?> _callProvider(LlmSettings settings, String prompt,
      {String? systemPrompt, int maxTokens = 512,
       Duration timeout = const Duration(seconds: 30)}) {
    switch (settings.provider) {
      case LlmProvider.claude:
        return _callClaude(settings.apiKey, prompt,
            systemPrompt: systemPrompt, maxTokens: maxTokens, timeout: timeout);
      case LlmProvider.gemini:
        return _callGemini(settings.apiKey, prompt,
            systemPrompt: systemPrompt, maxTokens: maxTokens, timeout: timeout);
      case LlmProvider.openai:
        return _callOpenAiCompat(settings.apiKey, 'https://api.openai.com',
            prompt, model: 'gpt-4o-mini',
            systemPrompt: systemPrompt, maxTokens: maxTokens, timeout: timeout);
      case LlmProvider.custom:
        if (settings.customBaseUrl.isEmpty) return Future.value(null);
        return _callOpenAiCompat(settings.apiKey, settings.customBaseUrl,
            prompt, model: settings.customModel.isNotEmpty
                ? settings.customModel : 'gpt-4o-mini',
            systemPrompt: systemPrompt, maxTokens: maxTokens, timeout: timeout);
    }
  }

  Future<String?> _callClaude(String apiKey, String prompt,
      {String? systemPrompt, int maxTokens = 512,
       Duration timeout = const Duration(seconds: 30)}) async {
    final uri = Uri.parse('https://api.anthropic.com/v1/messages');
    final http.Response response;
    try {
      response = await http.post(uri,
        headers: {
          'Content-Type':      'application/json',
          'x-api-key':         apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-haiku-4-5', 'max_tokens': maxTokens,
          'system': systemPrompt ?? _systemPrompt,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      ).timeout(timeout);
    } catch (e) {
      // Network errors / timeouts are transient — let the retry loop handle it.
      throw _RetryableException('network: $e');
    }
    developer.log('Claude API response: ${response.statusCode}', name: 'AiService.Claude');
    if (_retryableStatus.contains(response.statusCode)) {
      throw _RetryableException('HTTP ${response.statusCode}');
    }
    if (response.statusCode != 200) {
      developer.log('Claude error body: ${response.body}', name: 'AiService.Claude');
      return null;
    }
    final data    = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List?;
    if (content == null || content.isEmpty) return null;
    return (content.first as Map)['text'] as String?;
  }

  Future<String?> _callGemini(String apiKey, String prompt,
      {String? systemPrompt, int maxTokens = 512,
       Duration timeout = const Duration(seconds: 30)}) async {
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey');
    final http.Response response;
    try {
      developer.log('Gemini request to: $uri', name: 'AiService.Gemini');
      response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {'parts': [{'text': systemPrompt ?? _systemPrompt}]},
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'maxOutputTokens': maxTokens},
        }),
      ).timeout(timeout);
    } catch (e) {
      throw _RetryableException('network: $e');
    }
    developer.log('Gemini response: ${response.statusCode}', name: 'AiService.Gemini');
    if (_retryableStatus.contains(response.statusCode)) {
      throw _RetryableException('HTTP ${response.statusCode}');
    }
    if (response.statusCode != 200) {
      developer.log('Gemini error body: ${response.body}', name: 'AiService.Gemini');
      return null;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
  }

  Future<String?> _callOpenAiCompat(String apiKey, String baseUrl, String prompt,
      {String model = 'gpt-4o-mini', String? systemPrompt, int maxTokens = 512,
       Duration timeout = const Duration(seconds: 30)}) async {
    if (baseUrl.isEmpty) return null;
    final uri = Uri.parse('$baseUrl/v1/chat/completions');
    final http.Response response;
    try {
      developer.log('OpenAI-compat request to: $uri (model: $model)',
          name: 'AiService.OpenAiCompat');
      response = await http.post(uri,
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model, 'max_tokens': maxTokens,
          'messages': [
            {'role': 'system', 'content': systemPrompt ?? _systemPrompt},
            {'role': 'user',   'content': prompt},
          ],
        }),
      ).timeout(timeout);
    } catch (e) {
      throw _RetryableException('network: $e');
    }
    developer.log('OpenAI-compat response: ${response.statusCode}',
        name: 'AiService.OpenAiCompat');
    if (_retryableStatus.contains(response.statusCode)) {
      throw _RetryableException('HTTP ${response.statusCode}');
    }
    if (response.statusCode != 200) {
      developer.log('OpenAI-compat error body: ${response.body}',
          name: 'AiService.OpenAiCompat');
      return null;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['choices']?[0]?['message']?['content'] as String?;
  }
}

/// Thrown by provider calls on transient failures (rate-limit, 5xx, network
/// timeout) so [_dispatchRaw]'s retry loop can back off and try again.
class _RetryableException implements Exception {
  final String reason;
  _RetryableException(this.reason);
  @override
  String toString() => 'RetryableException: $reason';
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
