import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../collections/collections_screen.dart'
    show bookmarkedItemsProvider, bookmarkedSymbolsProvider;

final _bookmarkStateProvider = FutureProvider.family<bool, String>(
  (ref, wordId) =>
      ref.read(databaseProvider).collectionDao.isBookmarked(wordId),
);

class BookmarkButton extends ConsumerWidget {
  final String wordId;
  final bool compact; // icon-only when true (for use in hero cards)

  const BookmarkButton({
    super.key,
    required this.wordId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarked  = ref.watch(_bookmarkStateProvider(wordId));
    final isBookmarked = bookmarked.maybeWhen(data: (v) => v, orElse: () => false);

    return GestureDetector(
      onTap: () async {
        await ref.read(databaseProvider).collectionDao.toggleBookmark(wordId);
        ref.invalidate(_bookmarkStateProvider(wordId));
        ref.invalidate(bookmarkedItemsProvider);
        ref.invalidate(bookmarkedSymbolsProvider);
      },
      child: compact
          ? _CompactButton(isBookmarked: isBookmarked)
          : _FullButton(isBookmarked: isBookmarked),
    );
  }
}

class _CompactButton extends StatelessWidget {
  final bool isBookmarked;
  const _CompactButton({required this.isBookmarked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isBookmarked
            ? AppTheme.hanviet.withAlpha(30)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBookmarked
              ? AppTheme.hanviet.withAlpha(128)
              : AppTheme.hanviet.withAlpha(64),
          width: 1,
        ),
      ),
      child: Icon(
        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        color: AppTheme.hanviet,
        size: 18,
      ),
    );
  }
}

class _FullButton extends StatelessWidget {
  final bool isBookmarked;
  const _FullButton({required this.isBookmarked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isBookmarked
            ? AppTheme.hanviet.withAlpha(30)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBookmarked
              ? AppTheme.hanviet.withAlpha(128)
              : AppTheme.hanviet.withAlpha(64),
          width: 1,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: AppTheme.hanviet,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          isBookmarked ? 'Bookmarked' : 'Bookmark',
          style: const TextStyle(
            color: AppTheme.hanviet,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }
}
