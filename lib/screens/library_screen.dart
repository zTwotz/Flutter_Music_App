import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_theme.dart';
import '../models/playlist.dart';
import '../models/artist.dart';
import '../models/podcast_channel.dart';
import '../providers/auth_provider.dart';
import '../providers/library_providers.dart';
import '../models/collection_item.dart';
import '../widgets/user_avatar.dart';
import '../widgets/state_widgets.dart';
import '../core/app_ui_utils.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value?.session?.user;
    final filter = ref.watch(libraryFilterProvider);

    return Material(
      color: AppTheme.background,
      child: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            leading: const UserAvatar(),
            title: const Text(
              'Thư viện',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.search, size: 22),
                tooltip: 'Tìm trong thư viện',
                onPressed: () => context.go('/search'),
              ),
              IconButton(
                icon: const Icon(LucideIcons.plus, size: 22),
                tooltip: 'Thêm playlist',
                onPressed: () {
                  if (user == null) {
                    _requireLogin();
                  } else {
                    context.push('/create-playlist');
                  }
                },
              ),
            ],
          ),

          // ── Filter Chips ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: LibraryFilter.values.map((f) {
                    final label = switch (f) {
                      LibraryFilter.all => 'Tất cả',
                      LibraryFilter.playlists => 'Danh sách phát',
                      LibraryFilter.artists => 'Nghệ sĩ',
                      LibraryFilter.podcasts => 'Podcasts',
                    };
                    final selected = filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) =>
                            ref.read(libraryFilterProvider.notifier).setFilter(f),
                        selectedColor: Colors.white,
                        backgroundColor: AppTheme.surfaceHighlight,
                        labelStyle: TextStyle(
                          color: selected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.transparent),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          if (user == null)
            _buildGuestContent()
          else
            _buildAuthenticatedContent(user.id, filter),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ── Guest Content ─────────────────────────────────────────────────────────

  Widget _buildGuestContent() {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Always show "Bài hát đã thích" even when logged out
        _buildLikedSongsTile(null),
        const SizedBox(height: 40),
        _buildGuestEmptyState(),
      ]),
    );
  }

  Widget _buildGuestEmptyState() {
    return AppEmptyState(
      icon: LucideIcons.library,
      title: 'Thư viện của bạn',
      message: 'Đăng nhập để cá nhân hoá thư viện và xem playlist, nghệ sĩ, podcast đã lưu.',
      actionLabel: 'Đăng nhập',
      onAction: () => context.push('/login'),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  // ── Authenticated Content ─────────────────────────────────────────────────

  Widget _buildAuthenticatedContent(String userId, LibraryFilter filter) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Always-visible "Bài hát đã thích"
        if (filter == LibraryFilter.all || filter == LibraryFilter.playlists)
          _buildLikedSongsTile(userId),

        // User Playlists
        if (filter == LibraryFilter.all || filter == LibraryFilter.playlists)
          _buildUserPlaylistsSection(userId),

        // Saved Playlists
        if (filter == LibraryFilter.all || filter == LibraryFilter.playlists)
          _buildSavedPlaylistsSection(userId),

        // Followed Artists
        if (filter == LibraryFilter.all || filter == LibraryFilter.artists)
          _buildFollowedArtistsSection(userId),

        // Subscribed Podcast Channels
        if (filter == LibraryFilter.all || filter == LibraryFilter.podcasts)
          _buildSubscribedChannelsSection(userId),
      ]),
    );
  }

  // ── Liked Songs Tile ─────────────────────────────────────────────────────

  Widget _buildLikedSongsTile(String? userId) {
    final countAsync = userId != null ? ref.watch(likedSongsCountProvider) : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B35CF), Color(0xFFE91E8C)],
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(LucideIcons.heart, color: Colors.white, size: 24),
      ),
      title: const Text(
        'Bài hát đã thích',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: countAsync != null
          ? countAsync.when(
              data: (count) => Text(
                '$count bài hát',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              loading: () => const Text('...', style: TextStyle(color: AppTheme.textSecondary)),
              error: (_, __) => const SizedBox(),
            )
          : const Text('Đăng nhập để xem', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      trailing: const Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary, size: 18),
      onTap: () {
        if (userId == null) {
          _requireLogin();
        } else {
          context.push('/liked-songs');
        }
      },
    );
  }

  // ── Sections ─────────────────────────────────────────────────────────────

  Widget _buildUserPlaylistsSection(String userId) {
    final playlistsAsync = ref.watch(userPlaylistsProvider);
    return playlistsAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) return const SizedBox();
        return _buildSection(
          title: 'Playlist của bạn',
          children: playlists.asMap().entries.map((e) => _buildPlaylistTile(e.value).animate().fadeIn(delay: (e.key * 20).ms)).toList(),
        );
      },
      loading: () => _buildSectionSkeleton('Playlist của bạn'),
      error: (e, _) => AppErrorState(onRetry: () => ref.invalidate(userPlaylistsProvider)),
    );
  }

  Widget _buildSavedPlaylistsSection(String userId) {
    final savedAsync = ref.watch(savedPlaylistsProvider);
    return savedAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) return const SizedBox();
        return _buildSection(
          title: 'Playlist đã lưu',
          children: playlists.map((p) => _buildPlaylistTile(p)).toList(),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildFollowedArtistsSection(String userId) {
    final artistsAsync = ref.watch(followedArtistsLibraryProvider);
    return artistsAsync.when(
      data: (artists) {
        if (artists.isEmpty) return const SizedBox();
        return _buildSection(
          title: 'Nghệ sĩ đang theo dõi',
          children: artists.asMap().entries.map((e) => _buildArtistTile(e.value).animate().fadeIn(delay: (e.key * 20).ms)).toList(),
        );
      },
      loading: () => _buildSectionSkeleton('Nghệ sĩ đang theo dõi'),
      error: (e, _) => AppErrorState(onRetry: () => ref.invalidate(followedArtistsLibraryProvider)),
    );
  }

  Widget _buildSubscribedChannelsSection(String userId) {
    final channelsAsync = ref.watch(subscribedChannelsLibraryProvider);
    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) return const SizedBox();
        return _buildSection(
          title: 'Podcast đang theo dõi',
          children: channels.map((c) => _buildChannelTile(c)).toList(),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  // ── Reusable Row Items ────────────────────────────────────────────────────

  Widget _buildPlaylistTile(Playlist playlist) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _buildCover(playlist.coverUrl, LucideIcons.listMusic, const Color(0xFF1E3264)),
      title: Text(
        playlist.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (playlist.isSystem)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Spotify', style: TextStyle(fontSize: 10, color: Colors.white70)),
            ),
          Text(
            'Playlist',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
      trailing: const Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary, size: 18),
      onTap: () {
        final u = ref.read(authStateProvider).value?.session?.user;
        context.push('/playlist/${playlist.id}', extra: CollectionItem.fromPlaylist(playlist, currentUserId: u?.id));
      },
    );
  }

  Widget _buildArtistTile(Artist artist) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppTheme.surfaceHighlight,
        backgroundImage: artist.avatarUrl != null
            ? CachedNetworkImageProvider(artist.avatarUrl!)
            : null,
        child: artist.avatarUrl == null
            ? Text(
                artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        artist.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (artist.isVerified) ...[
            const Icon(LucideIcons.checkCircle, size: 12, color: Color(0xFF1DB954)),
            const SizedBox(width: 4),
          ],
          const Text('Nghệ sĩ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
      trailing: const Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary, size: 18),
      onTap: () => context.push('/artist/${artist.id}', extra: artist),
    );
  }

  Widget _buildChannelTile(PodcastChannel channel) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppTheme.surfaceHighlight,
        backgroundImage: channel.avatarUrl != null
            ? CachedNetworkImageProvider(channel.avatarUrl!)
            : null,
        child: channel.avatarUrl == null
            ? Text(
                channel.name.isNotEmpty ? channel.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        channel.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: const Text('Kênh Podcast', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      trailing: const Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary, size: 18),
      onTap: () => context.push('/podcast-channel/${channel.id}'),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSectionSkeleton(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.l, AppSpacing.m, AppSpacing.xs),
          child: Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary, letterSpacing: 0.5)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: AppLoadingIndicator(size: 24),
        ),
      ],
    );
  }

  Widget _buildCover(String? imageUrl, IconData fallbackIcon, Color fallbackColor) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: fallbackColor,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Icon(fallbackIcon, color: Colors.white60, size: 24),
            )
          : Icon(fallbackIcon, color: Colors.white60, size: 24),
    );
  }

  void _requireLogin() {
    context.showInfo('Đăng nhập để sử dụng chức năng này');
  }
}
