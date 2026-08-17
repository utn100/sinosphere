import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LangMode { chinese, korean }

const _kLangModeKey = 'sinosphere_lang_mode';

class LangModeNotifier extends Notifier<LangMode> {
  // Public static cache — pre-seeded in main.dart before first frame
  static LangMode cached = LangMode.chinese;

  @override
  LangMode build() => cached;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kLangModeKey);
    if (stored == 'korean') { cached = LangMode.korean; state = LangMode.korean; }
  }

  Future<void> set(LangMode mode) async {
    cached = mode;
    state  = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangModeKey, mode.name);
  }

  void toggle() => set(state == LangMode.chinese ? LangMode.korean : LangMode.chinese);
}

final langModeProvider =
    NotifierProvider<LangModeNotifier, LangMode>(LangModeNotifier.new);
