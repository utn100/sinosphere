import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../reader/reader_provider.dart';
import '../settings/settings_screen.dart';
import '../shell/app_shell.dart' show tabIndexProvider;
import 'practice_reading_provider.dart';

class PracticeReadingScreen extends ConsumerStatefulWidget {
  const PracticeReadingScreen({super.key});

  @override
  ConsumerState<PracticeReadingScreen> createState() =>
      _PracticeReadingScreenState();
}

class _PracticeReadingScreenState extends ConsumerState<PracticeReadingScreen> {
  @override
  void initState() {
    super.initState();
    // Re-evaluate config + word pool each time the screen opens, so newly
    // collected words (or a just-configured provider) are reflected. Skips
    // clobbering an in-flight/successful generation.
    Future.microtask(() {
      final phase = ref.read(practiceReadingProvider).phase;
      if (phase != PracticePhase.generating && phase != PracticePhase.success) {
        ref.read(practiceReadingProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c     = context.colors;
    final state = ref.watch(practiceReadingProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: c.text, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Practice Reading',
            style: TextStyle(color: c.text, fontSize: 20,
                fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A short story woven from the words you\'ve bookmarked and '
                  'memorized — read it to practice in context.',
                  style: TextStyle(color: c.textSub, fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),
              _buildBody(context, state, c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context,
      PracticeReadingState state, SinosphereColors c) {
    switch (state.phase) {
      case PracticePhase.loading:
        return const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );

      case PracticePhase.notConfigured:
        return _InfoCard(
          color: AppTheme.phonetic,
          icon: Icons.info_outline,
          text: 'Configure AI in Settings to generate practice stories →',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
        );

      case PracticePhase.emptyPool:
        return _InfoCard(
          color: AppTheme.hanviet,
          icon: Icons.bookmark_add_outlined,
          text: 'Bookmark or mark some words as memorized first, then come '
              'back to generate a story from them.',
        );

      case PracticePhase.ready:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${state.wordCount} words ready',
              style: TextStyle(color: c.textMuted, fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _GenerateButton(
            label: 'Generate story',
            icon: Icons.auto_stories,
            onPressed: () => ref.read(practiceReadingProvider.notifier).generate(),
          ),
        ]);

      case PracticePhase.generating:
        return Column(children: const [
          SizedBox(height: 20),
          Center(child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(height: 12),
          Text('Writing your story…',
              style: TextStyle(color: AppTheme.textSecond, fontSize: 12)),
        ]);

      case PracticePhase.failed:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _InfoCard(
            color: AppTheme.coral,
            icon: Icons.error_outline,
            text: 'Story generation failed. Check your connection or API key.',
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.coral.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(state.errorMessage!,
                  style: TextStyle(color: c.textSub, fontSize: 11, height: 1.4)),
            ),
          ],
          const SizedBox(height: 12),
          _GenerateButton(
            label: 'Retry',
            icon: Icons.refresh,
            color: AppTheme.coral,
            onPressed: () => ref.read(practiceReadingProvider.notifier).generate(),
          ),
        ]);

      case PracticePhase.success:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Text(state.story ?? '',
                style: TextStyle(color: c.text, fontSize: 17, height: 1.9)),
          ),
          const SizedBox(height: 16),
          _GenerateButton(
            label: 'Read it (annotate & open Reader)',
            icon: Icons.menu_book,
            onPressed: () => _openInReader(context, state.story ?? ''),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Regenerate'),
              onPressed: () =>
                  ref.read(practiceReadingProvider.notifier).generate(),
            ),
          ),
        ]);
    }
  }

  void _openInReader(BuildContext context, String story) {
    if (story.trim().isEmpty) return;
    ref.read(readerProvider.notifier).annotate(story, title: 'Practice story');
    ref.read(tabIndexProvider.notifier).set(2); // Reader tab
    Navigator.of(context).pop(); // back to the shell, now showing the Reader
  }
}

class _InfoCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const _InfoCard({
    required this.color, required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(text,
              style: TextStyle(color: color, fontSize: 13,
                  fontWeight: FontWeight.w600, height: 1.4))),
        ]),
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _GenerateButton({
    required this.label, required this.icon, required this.onPressed,
    this.color = AppTheme.semantic});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        onPressed: onPressed,
      ),
    );
  }
}
