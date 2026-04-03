import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/collection_item.dart';
import '../../models/song.dart';
import '../../models/podcast.dart';
import '../../providers/search_providers.dart';
import '../../core/player_utils.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../search_widgets.dart';
import '../../core/app_ui_utils.dart';
import 'search_state_widgets.dart';

class LiveSuggestionList extends ConsumerWidget {
  final AsyncValue<SearchResults> results;
  final Function({
    required String keyword,
    required String contentType,
    String? contentId,
    required String title,
    String? subtitle,
    String? imageUrl,
  }) onSaveRecent;

  const LiveSuggestionList({
    super.key,
    required this.results,
    required this.onSaveRecent,
  });

  Song _toSong(Podcast p) {
    return Song(
      id: p.id.hashCode,
      title: p.title,
      artistName: p.channelName ?? 'Podcast',
      coverUrl: p.coverUrl,
      audioUrl: p.audioUrl ?? '',
      durationSeconds: p.durationSeconds,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return results.when(
      data: (data) {
        if (data.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: SearchEmptyState(
              title: 'Không có gợi ý',
              subtitle: 'Tiếp tục gõ hoặc thử từ khóa khác.',
              icon: LucideIcons.search,
            ),
          );
        }

        // Combine all items into a unified suggestion list
        final List<Widget> suggestionTiles = [];

        // 1. Hashtags (exact match/quick navigation)
        for (var h in data.hashtags) {
          suggestionTiles.add(
            SearchResultTile(
              title: h['name'],
              subtitle: 'Hashtag',
              type: 'hashtag',
              onTap: () {
                onSaveRecent(
                  keyword: h['name'],
                  contentType: 'keyword', // save as keyword to trigger search
                  title: h['name'],
                  subtitle: 'Hashtag',
                );
              },
            ),
          );
        }

        // 2. Artists
        for (var a in data.artists) {
          suggestionTiles.add(
            SearchResultTile(
              title: a.name,
              subtitle: 'Nghệ sĩ',
              imageUrl: a.avatarUrl,
              type: 'artist',
              onTap: () {
                onSaveRecent(
                  keyword: a.name,
                  contentType: 'artist',
                  contentId: a.id.toString(),
                  title: a.name,
                  subtitle: 'Nghệ sĩ',
                  imageUrl: a.avatarUrl,
                );
                context.pushSafe('/artist/${a.id}', extra: a);
              },
            ),
          );
        }

        // 3. Songs
        for (int i = 0; i < data.songs.length; i++) {
          final s = data.songs[i];
          suggestionTiles.add(
            SearchResultTile(
              title: s.title,
              subtitle: s.artistName ?? 'Bài hát',
              imageUrl: s.coverUrl,
              type: 'song',
              onTap: () {
                onSaveRecent(
                  keyword: s.title,
                  contentType: 'song',
                  contentId: s.id.toString(),
                  title: s.title,
                  subtitle: s.artistName,
                  imageUrl: s.coverUrl,
                );
                context.playOrNavigate(ref, s, data.songs, initialIndex: i);
              },
            ),
          );
        }

        // 4. Albums
        for (var al in data.albums) {
          suggestionTiles.add(
            SearchResultTile(
              title: al.title,
              subtitle: 'Album',
              imageUrl: al.coverUrl,
              type: 'album',
              onTap: () {
                onSaveRecent(
                  keyword: al.title,
                  contentType: 'album',
                  contentId: al.id.toString(),
                  title: al.title,
                  subtitle: 'Album',
                  imageUrl: al.coverUrl,
                );
                context.pushSafe('/album/${al.id}', extra: CollectionItem.fromAlbum(al));
              },
            ),
          );
        }

        // 5. Playlists
        for (var p in data.playlists) {
          suggestionTiles.add(
            SearchResultTile(
              title: p.name,
              subtitle: 'Playlist',
              imageUrl: p.coverUrl,
              type: 'playlist',
              onTap: () {
                onSaveRecent(
                  keyword: p.name,
                  contentType: 'playlist',
                  contentId: p.id.toString(),
                  title: p.name,
                  subtitle: 'Playlist',
                  imageUrl: p.coverUrl,
                );
                final user = ref.read(authStateProvider).value?.session?.user;
                context.pushSafe('/playlist/${p.id}', extra: CollectionItem.fromPlaylist(p, currentUserId: user?.id));
              },
            ),
          );
        }

        // 6. Podcasts
        for (int i = 0; i < data.podcasts.length; i++) {
          final pd = data.podcasts[i];
          suggestionTiles.add(
            SearchResultTile(
              title: pd.title,
              subtitle: pd.channelName ?? 'Podcast',
              imageUrl: pd.coverUrl,
              type: 'podcast',
              onTap: () {
                onSaveRecent(
                  keyword: pd.title,
                  contentType: 'podcast',
                  contentId: pd.id.toString(),
                  title: pd.title,
                  subtitle: pd.channelName,
                  imageUrl: pd.coverUrl,
                );
                final queue = data.podcasts.map(_toSong).toList();
                context.playOrNavigate(ref, _toSong(pd), queue, initialIndex: i);
              },
            ),
          );
        }
        
        // 7. Genres & Moods
        for (var g in data.genres) {
          suggestionTiles.add(
            SearchResultTile(
              title: g['name'],
              subtitle: 'Danh mục',
              imageUrl: g['cover_url'],
              type: 'genre',
              onTap: () {
                context.pushSafe('/category/${g['name']}', extra: {'title': g['name'], 'type': 'genre'});
              },
            ),
          );
        }
        for (var m in data.moods) {
          suggestionTiles.add(
            SearchResultTile(
              title: m['name'],
              subtitle: 'Tâm trạng',
              imageUrl: m['cover_url'],
              type: 'mood',
              onTap: () {
                context.pushSafe('/category/${m['name']}', extra: {'title': m['name'], 'type': 'mood'});
              },
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => suggestionTiles[index],
            childCount: suggestionTiles.length,
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: SearchLoadingState(isList: true),
      ),
      error: (e, st) => SliverFillRemaining(
        child: SearchErrorState(
          errorMessage: e.toString(),
          onRetry: () => ref.invalidate(searchResultsProvider),
        ),
      ),
    );
  }
}
