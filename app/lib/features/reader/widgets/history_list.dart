import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/services/database_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../reader_provider.dart';

class HistoryList extends ConsumerWidget {
  final VoidCallback onClose;
  const HistoryList({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c       = context.colors;
    final history = ref.watch(readerHistoryProvider);

    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
          child: Row(children: [
            Text('READING HISTORY',
                style: TextStyle(color: c.textMuted, fontSize: 10,
                    fontWeight: FontWeight.w800, letterSpacing: 1)),
            const Spacer(),
            GestureDetector(onTap: onClose,
                child: Icon(Icons.close, color: c.textMuted, size: 18)),
          ]),
        ),
        Divider(height: 0.5, thickness: 0.5, color: c.border),
        Expanded(
          child: history.when(
            loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.hanviet)),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) {
              if (items.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset('assets/logo.png', width: 120, height: 120),
                  const SizedBox(height: 12),
                  Text('No reading history yet.',
                      style: TextStyle(color: c.textMuted, fontSize: 13,
                          fontStyle: FontStyle.italic)),
                ]));
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 0.5, thickness: 0.5, color: c.border, indent: 16),
                itemBuilder: (_, i) => _HistoryRow(
                  item: items[i],
                  onTap: () {
                    ref.read(readerProvider.notifier).loadFromHistory(items[i]);
                    onClose();
                  },
                  onDelete: () async {
                    await ref.read(databaseProvider).readerDao.deleteHistory(items[i].id);
                    ref.invalidate(readerHistoryProvider);
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final ReadingHistoryData item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _HistoryRow({required this.item, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final c    = context.colors;
    final date = DateTime.fromMillisecondsSinceEpoch(item.createdAt);
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete entry?'),
            content: Text('Remove "${item.title}" from history?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ?? false;
      },
      background: Container(
        color: Colors.red.withAlpha(200),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.hanviet.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Icon(Icons.article_outlined,
                  color: AppTheme.hanviet, size: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title,
                  style: TextStyle(color: c.text, fontSize: 14,
                      fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(dateStr, style: TextStyle(color: c.textMuted, fontSize: 11)),
            ])),
            // Fix 5: explicit delete button with confirmation
            IconButton(
              icon: Icon(Icons.delete_outline, color: c.textMuted, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete entry?'),
                    content: Text('Remove "${item.title}" from history?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (ok == true) onDelete();
              },
            ),
          ]),
        ),
      ),
    );
  }
}
