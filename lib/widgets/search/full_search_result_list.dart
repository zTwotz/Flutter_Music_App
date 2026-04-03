import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/collection_item.dart';
import '../../models/song.dart';
import '../../models/podcast.dart';
import '../../models/artist.dart';
import '../../models/album.dart';
import '../../providers/search_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/artist_detail_provider.dart';
import '../../core/app_ui_utils.dart';
import '../../core/player_utils.dart';
import '../../core/app_theme.dart';
import '../search_widgets.dart';
import 'search_state_widgets.dart';

class FullSearchResultList extends ConsumerWidget {
  final AsyncValue<SearchResults> results;
  final Function({
    required String keyword,
    required String contentType,
    String? contentId,
    required String title,
    String? subtitle,
    String? imageUrl,
  }) onSaveRecent;

  const FullSearchResultList({
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
              title: 'Không tìm thấy kết quả',
              subtitle: 'Hãy thử một từ khóa khác hoặc kiểm tra lại lỗi chính tả.',
              icon: LucideIcons.fileSearch,
            ),
          );
        }

        // Determine top result (could be exact match or first artist, then first song)
        final topResult = _getTopResult(data);

        return SliverList(
          delegate: SliverChildListDelegate([
            
            // ─── Top Result ──────────────────────────────────────────
            if (topResult != null)
               _buildTopResult(context, topResult, data, ref),

            // ─── Songs ───────────────────────────────────────────────
            if (data.songs.isNotEmpty) ...[
              _buildSectionHeader('Bài hát'),
              ...data.songs.take(4).map((s) {
                final index = data.songs.indexOf(s);
                final durationStr = s.durationSeconds != null ? _formatDuration(s.durationSeconds!) : null;
                return SearchResultTile(
                  title: s.title,
                  subtitle: durationStr != null ? '${s.artistName} • $durationStr' : (s.artistName ?? 'Âm nhạc'),
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
                    context.playOrNavigate(ref, s, data.songs, initialIndex: index);
                  },
                );
              }),
            ],

            // ─── Artists ─────────────────────────────────────────────
            if (data.artists.isNotEmpty) ...[
              _buildSectionHeader('Nghệ sĩ'),
              ...data.artists.take(4).map((a) => SearchResultTile(
                    title: a.name,
                    subtitle: 'Hồ sơ', // Can use a.followerCount if available
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
                  )),
            ],

            // ─── Albums ──────────────────────────────────────────────
            if (data.albums.isNotEmpty) ...[
              _buildSectionHeader('Albums'),
              ...data.albums.take(4).map((al) => SearchResultTile(
                    title: al.title,
                    subtitle: 'Album • ${al.releaseDate?.year ?? ""}',
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
                  )),
            ],

            // ─── Playlists ───────────────────────────────────────────
            if (data.playlists.isNotEmpty) ...[
              _buildSectionHeader('Danh sách phát'),
              ...data.playlists.take(4).map((p) => SearchResultTile(
                    title: p.name,
                    subtitle: 'Playlist • ${p.userId != null ? 'Người dùng' : 'Hệ thống'}',
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
                  )),
            ],

            // ─── Podcasts ────────────────────────────────────────────
            if (data.podcasts.isNotEmpty) ...[
              _buildSectionHeader('Podcasts'),
              ...data.podcasts.take(3).map((pd) {
                final index = data.podcasts.indexOf(pd);
                return SearchResultTile(
                  title: pd.title,
                  subtitle: 'Podcast • ${pd.channelName ?? ''}',
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
                    context.playOrNavigate(ref, _toSong(pd), queue, initialIndex: index);
                  },
                );
              }),
            ],

            // ─── Tags/Genres ─────────────────────────────────────────
            if (data.genres.isNotEmpty || data.moods.isNotEmpty || data.hashtags.isNotEmpty) ...[
              _buildSectionHeader('Thẻ liên quan'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...data.genres.map((g) => ProviderTagChip(
                      label: g['name'], 
                      onTap: () {
                        context.pushSafe('/category/${g['name']}', extra: {'title': g['name'], 'type': 'genre'});
                      }
                    )),
                    ...data.moods.map((m) => ProviderTagChip(
                      label: m['name'], 
                      onTap: () {
                        context.pushSafe('/category/${m['name']}', extra: {'title': m['name'], 'type': 'mood'});
                      }
                    )),
                    ...data.hashtags.map((h) => ProviderTagChip(
                      label: h['name'], 
                      onTap: () {
                        context.pushSafe('/category/${h['name']}', extra: {'title': h['name'], 'type': 'hashtag'});
                      }
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ]),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title, 
        style: const TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: Colors.white
        )
      ),
    );
  }
  
  Map<String, dynamic>? _getTopResult(SearchResults data) {
    // If we have an exact or close artist match, prioritize it
    if (data.artists.isNotEmpty) {
      return {'type': 'artist', 'data': data.artists.first};
    }
    
    // Fallback to other types
    if (data.songs.isNotEmpty) return {'type': 'song', 'data': data.songs.first};
    if (data.albums.isNotEmpty) return {'type': 'album', 'data': data.albums.first};
    if (data.playlists.isNotEmpty) return {'type': 'playlist', 'data': data.playlists.first};
    return null;
  }

  Widget _buildTopResult(BuildContext context, Map<String, dynamic> topResult, SearchResults results, WidgetRef ref) {
    final type = topResult['type'] as String;
    final item = topResult['data'];
    
    String title = '';
    String subtitle = '';
    String? imageUrl;
    String badge = 'Kết quả nổi bật';
    VoidCallback onTap = () {};

    if (type == 'artist') {
      title = item.name;
      subtitle = 'Nghệ sĩ';
      imageUrl = item.avatarUrl;
      onTap = () {
        onSaveRecent(keyword: title, contentType: 'artist', contentId: item.id.toString(), title: title, imageUrl: imageUrl);
        context.pushSafe('/artist/${item.id}', extra: item);
      };
    } else if (type == 'song') {
      title = item.title;
      subtitle = 'Bài hát • ${item.artistName}';
      imageUrl = item.coverUrl;
      onTap = () {
        onSaveRecent(keyword: title, contentType: 'song', contentId: item.id.toString(), title: title, imageUrl: imageUrl);
        context.playOrNavigate(ref, item, results.songs, initialIndex: 0);
      };
    } else if (type == 'album') {
      title = item.title;
      subtitle = 'Album';
      imageUrl = item.coverUrl;
      onTap = () {
        onSaveRecent(keyword: title, contentType: 'album', contentId: item.id.toString(), title: title, imageUrl: imageUrl);
        context.pushSafe('/album/${item.id}', extra: CollectionItem.fromAlbum(item));
      };
    } else if (type == 'playlist') {
      title = item.name;
      subtitle = 'Playlist';
      imageUrl = item.coverUrl;
      onTap = () {
        onSaveRecent(keyword: title, contentType: 'playlist', contentId: item.id.toString(), title: title, imageUrl: imageUrl);
        final user = ref.read(authStateProvider).value?.session?.user;
        context.pushSafe('/playlist/${item.id}', extra: CollectionItem.fromPlaylist(item, currentUserId: user?.id));
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(badge),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: type == 'artist' ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: type != 'artist' ? BorderRadius.circular(8) : null,
                          color: AppTheme.surfaceHighlight,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: Colors.white.withOpacity(0.05)),
                                errorWidget: (_,__,___)=>Icon(LucideIcons.music, color: Colors.white54, size: 40),
                              )
                            : Icon(LucideIcons.music, color: Colors.white54, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // ── EXTRA ARTIST CONTENT (Featured artist specific) ──
              if (type == 'artist') ...[
                const SizedBox(height: 16),
                _buildArtistSubContent(context, item, ref),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArtistSubContent(BuildContext context, Artist artist, WidgetRef ref) {
    final songsAsync = ref.watch(artistSongsProvider(artist.id));
    final albumsAsync = ref.watch(artistAlbumsProvider(artist.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Songs of Artist ──
        songsAsync.when(
          data: (songs) {
            if (songs.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Bài hát của ${artist.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: songs.length > 3 ? 3 : songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: song.coverUrl ?? '',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorWidget: (_,__,___) => Container(color: Colors.white.withOpacity(0.05), child: Icon(LucideIcons.music, size: 16)),
                        ),
                      ),
                      title: Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text(song.artistName ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () => context.playOrNavigate(ref, song, songs, initialIndex: index),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_,__) => const SizedBox.shrink(),
        ),

        // ── Albums of Artist ──
        albumsAsync.when(
          data: (albums) {
            if (albums.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Albums của ${artist.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: albums.length > 2 ? 2 : albums.length,
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: album.coverUrl ?? '',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorWidget: (_,__,___) => Container(color: Colors.white.withOpacity(0.05), child: Icon(LucideIcons.music, size: 16)),
                        ),
                      ),
                      title: Text(album.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text('${artist.name} • ${album.releaseDate?.year ?? ""}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () => context.pushSafe('/album/${album.id}', extra: CollectionItem.fromAlbum(album)),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(), // Don't show multiple indicators
          error: (_,__) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class ProviderTagChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ProviderTagChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
