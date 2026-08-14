import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';
import '../../../core/services/database_provider.dart';
import '../dict_card_provider.dart';

class EtymologyCard extends ConsumerWidget {
  final Character character;
  final List<ComponentWithType> components;
  const EtymologyCard({super.key, required this.character, required this.components});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = character.etymologyStory;
    final state = ref.watch(etymologyStateProvider(character.id));

    if (story != null && story.isNotEmpty) return _StoryBox(story: story);
    if (state == EtymologyState.generating) return const _LoadingBox();
    return _NoStoryBox(character: character, components: components);
  }
}

class _StoryBox extends StatelessWidget {
  final String story;
  const _StoryBox({required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.hanviet.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hanviet.withAlpha(51)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.lightbulb_outline, color: AppTheme.hanviet, size: 14),
          SizedBox(width: 6),
          Text('Logic Chiết Tự',
              style: TextStyle(color: AppTheme.hanviet, fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        Text(story, style: TextStyle(color: AppTheme.hanviet.withAlpha(230), fontSize: 13, height: 1.5)),
      ]),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.hanviet.withAlpha(26),
      highlightColor: AppTheme.hanviet.withAlpha(64),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppTheme.hanviet.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Generating Chiết Tự story…',
              style: TextStyle(color: AppTheme.hanviet, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _NoStoryBox extends ConsumerStatefulWidget {
  final Character character;
  final List<ComponentWithType> components;
  const _NoStoryBox({required this.character, required this.components});

  @override
  ConsumerState<_NoStoryBox> createState() => _NoStoryBoxState();
}

class _NoStoryBoxState extends ConsumerState<_NoStoryBox> {
  bool _showPasteBanner = false;

  // H1 fix: use Uri.https() for proper percent-encoding
  Future<void> _launchGoogle(String symbol) async {
    final uri = Uri.https('www.google.com', '/search', {'q': '$symbol hán việt chiết tự'});
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // H2 fix: show paste banner AFTER launching the browser (user can see it when they return)
      if (mounted) setState(() => _showPasteBanner = true);
    }
  }

  void _showPasteSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.textMuted.withAlpha(102),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Paste story for ${widget.character.symbol}',
                style: const TextStyle(color: AppTheme.textPrimary,
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Copy from Google results and paste below',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl, maxLines: 4, autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                  hintText: 'Paste the Vietnamese etymology story here…'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.hanviet, foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final story = ctrl.text.trim();
                  if (story.isEmpty) return;
                  final db = ref.read(databaseProvider);
                  await db.characterDao.updateEtymologyStory(widget.character.id, story);
                  // M1 fix: set state immediately so card transitions without waiting for provider reload
                  ref.read(etymologyStateProvider(widget.character.id).notifier)
                      .set(EtymologyState.hasStory);
                  ref.invalidate(characterDetailProvider(widget.character.symbol));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) setState(() => _showPasteBanner = false);
                },
                child: const Text('Save Story',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c          = context.colors;
    final controller = ref.read(etymologyControllerProvider);

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.cardBg, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Logic Chiết Tự',
              style: TextStyle(color: c.textMuted, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text('No etymology story available yet.',
              style: TextStyle(color: c.textSub, fontSize: 13)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ActionButton(
              icon: Icons.auto_awesome, label: 'Generate with AI',
              color: AppTheme.semantic,
              onTap: () => controller.generate(
                characterId: widget.character.id, symbol: widget.character.symbol,
                pinyin: widget.character.pinyin, hanViet: widget.character.hanViet,
                englishDef: widget.character.englishDef, components: widget.components,
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: _ActionButton(
              icon: Icons.search, label: 'Look up on Google',
              color: AppTheme.phonetic,
              // H2 fix: only launch browser; paste banner appears after return
              onTap: () => _launchGoogle(widget.character.symbol),
            )),
          ]),
        ]),
      ),

      // H2 fix: persistent paste banner — appears after user returns from browser
      if (_showPasteBanner) ...[
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showPasteSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.phonetic.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.phonetic.withAlpha(77)),
            ),
            child: Row(children: [
              const Icon(Icons.content_paste, color: AppTheme.phonetic, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text('Tap to paste story for ${widget.character.symbol}',
                  style: const TextStyle(color: AppTheme.phonetic,
                      fontSize: 13, fontWeight: FontWeight.w600))),
              Icon(Icons.keyboard_arrow_up, color: AppTheme.phonetic.withAlpha(153), size: 18),
            ]),
          ),
        ),
      ],
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(31),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Flexible(child: Text(label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}
