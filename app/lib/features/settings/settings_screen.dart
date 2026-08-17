import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/ai_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyCtrl   = TextEditingController();
  final _urlCtrl   = TextEditingController();
  final _modelCtrl = TextEditingController();
  bool _keyObscured  = true;
  bool _testing      = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(aiServiceProvider).loadSettings();
    _keyCtrl.text   = settings.apiKey;
    _urlCtrl.text   = settings.customBaseUrl;
    _modelCtrl.text = settings.customModel;
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _urlCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c        = context.colors;
    final settings = ref.watch(llmSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: c.text, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text('Settings',
            style: TextStyle(color: c.text, fontSize: 20,
                fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // ── LLM Provider ──────────────────────────────────────────
            _SectionHeader(label: 'AI PROVIDER', c: c),
            const SizedBox(height: 8),
            settings.when(
              loading: () => const CircularProgressIndicator(strokeWidth: 2),
              error: (_, _) => const SizedBox.shrink(),
              data: (s) => Column(
                children: [
                  _ProviderPicker(
                    current: s.provider,
                    onChanged: (provider) {
                      // Clear custom fields when switching away from Custom
                      if (provider != LlmProvider.custom) {
                        _urlCtrl.clear();
                        _modelCtrl.clear();
                      }
                      ref.read(llmSettingsProvider.notifier).save(
                        s.copyWith(
                          provider: provider,
                          customBaseUrl: provider != LlmProvider.custom ? '' : s.customBaseUrl,
                          customModel:   provider != LlmProvider.custom ? '' : s.customModel,
                        ));
                    },
                  ),
                  const SizedBox(height: 12),
                  // Custom base URL + model (only for custom provider)
                  if (s.provider == LlmProvider.custom) ...[
                    _LabeledField(
                      label: 'Base URL',
                      hint: 'https://your-openai-compatible-proxy.com',
                      controller: _urlCtrl,
                      onChanged: (v) => ref
                          .read(llmSettingsProvider.notifier)
                          .save(s.copyWith(customBaseUrl: v)),
                    ),
                    const SizedBox(height: 8),
                    _LabeledField(
                      label: 'Model Name',
                      hint: 'claude-haiku-4-5 / llama3 / mistral / …',
                      controller: _modelCtrl,
                      onChanged: (v) => ref
                          .read(llmSettingsProvider.notifier)
                          .save(s.copyWith(customModel: v)),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // API Key
                  _LabeledField(
                    label: s.provider.keyLabel,
                    hint: s.provider.keyHint,
                    controller: _keyCtrl,
                    obscure: _keyObscured,
                    suffixIcon: IconButton(
                      icon: Icon(
                          _keyObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: c.textMuted, size: 18),
                      onPressed: () =>
                          setState(() => _keyObscured = !_keyObscured),
                    ),
                    onChanged: (v) => ref
                        .read(llmSettingsProvider.notifier)
                        .save(s.copyWith(apiKey: v)),
                  ),
                  const SizedBox(height: 8),
                  // Test connection button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.semantic),
                        foregroundColor: AppTheme.semantic,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _testing
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.semantic))
                          : const Icon(Icons.wifi_tethering, size: 18),
                      label: Text(_testing
                          ? 'Testing…'
                          : 'Test Connection'),
                      onPressed: _testing ? null : () => _testConnection(s),
                    ),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.semantic.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_testResult!,
                          style: const TextStyle(
                              color: AppTheme.semantic, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Appearance ──────────────────────────────────────────
            _SectionHeader(label: 'APPEARANCE', c: c),
            const SizedBox(height: 8),
            _SettingsRow(
              c: c,
              label: 'Dark Mode',
              subtitle: 'Default theme',
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                activeThumbColor: AppTheme.hanviet,
                activeTrackColor: AppTheme.hanviet.withAlpha(77),
                onChanged: (v) => ref
                    .read(themeModeProvider.notifier)
                    .set(v ? ThemeMode.dark : ThemeMode.light),
              ),
            ),

            const SizedBox(height: 28),

            // ── About ────────────────────────────────────────────────
            _SectionHeader(label: 'ABOUT', c: c),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border, width: 0.5),
              ),
              child: Column(
                children: [
                  _InfoRow(c: c, label: 'Version', value: '1.0.0'),
                  Divider(height: 16, thickness: 0.5, color: c.border),
                  _InfoRow(c: c, label: 'DB', value: '82 MB'),
                  Divider(height: 16, thickness: 0.5, color: c.border),
                  _InfoRow(c: c, label: 'Words', value: '119,449'),
                  Divider(height: 16, thickness: 0.5, color: c.border),
                  _InfoRow(c: c, label: 'Data sources',
                      value: 'CC-CEDICT · Unihan · Thiều Chửu · MakeMeHanzi'),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection(LlmSettings s) async {
    setState(() { _testing = true; _testResult = null; });
    final ai     = ref.read(aiServiceProvider);
    final result = await ai.testConnection(s);
    setState(() {
      _testing   = false;
      _testResult = result != null
          ? '✓ Connected — sample story for 一:\n$result'
          : '✗ Connection failed. Check your API key and try again.';
    });
  }
}

class _ProviderPicker extends StatelessWidget {
  final LlmProvider current;
  final void Function(LlmProvider) onChanged;
  const _ProviderPicker({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: RadioGroup<LlmProvider>(
        groupValue: current,
        onChanged: (p) { if (p != null) onChanged(p); },
        child: Column(
        children: LlmProvider.values.map((p) {
          final isLast = p == LlmProvider.values.last;
          return Column(
            children: [
              InkWell(
                onTap: () => onChanged(p),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Radio<LlmProvider>(
                        value: p,
                        fillColor: WidgetStateProperty.resolveWith((s) =>
                            s.contains(WidgetState.selected)
                                ? AppTheme.hanviet
                                : AppTheme.textMuted),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Text(p.displayName,
                          style: TextStyle(
                              color: c.text, fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(height: 0.5, thickness: 0.5, color: c.border),
            ],
          );
        }).toList(),
      ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffixIcon;
  final void Function(String) onChanged;

  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.suffixIcon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: c.textMuted, fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          style: TextStyle(color: c.text, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint, suffixIcon: suffixIcon),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final dynamic c;
  final String label;
  final String subtitle;
  final Widget trailing;
  const _SettingsRow({required this.c, required this.label,
      required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.cardBg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: c.text, fontSize: 14,
                    fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: c.textMuted, fontSize: 11)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final dynamic c;
  final String label;
  final String value;
  const _InfoRow({required this.c, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: c.textMuted, fontSize: 13)),
        Flexible(
          child: Text(value,
              style: TextStyle(color: c.text, fontSize: 12,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final dynamic c;
  const _SectionHeader({required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            color: c.textMuted, fontSize: 10,
            fontWeight: FontWeight.w800, letterSpacing: 1));
  }
}
