import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/app_theme.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/collection_item.dart';
import '../providers/player_provider.dart';
import '../providers/home_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_drawer.dart';
import '../widgets/user_avatar.dart';
import '../widgets/song_list_item.dart';
import '../widgets/playlist_card.dart';
import '../widgets/artist_avatar_row.dart';
import '../widgets/podcast_card.dart';
import '../widgets/followed_channels_row.dart';
import '../widgets/home_section_header.dart';
import '../widgets/state_widgets.dart';
import '../providers/podcast_providers.dart';
import '../core/app_ui_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ── Greeting helper ──────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  // ── Greeting helper ──────────────────────────────────────────────────────────
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  // ── Helper: play a single song ───────────────────────────────────────────────
  Future<void> _playSong(Song song, List<Song> queue, int index) async {
    ref.read(currentSongProvider.notifier).setSong(song);
    await ref.read(audioHandlerProvider).playPlaylist(queue, initialIndex: index);
    if (mounted) context.pushSafe('/player');
  }

  // ── Navigate to detail screens ───────────────────────────────────────────────
  void _openPlaylist(Playlist playlist) {
    final u = ref.read(authStateProvider).value?.session?.user;
    context.pushSafe('/playlist/${playlist.id}', extra: CollectionItem.fromPlaylist(playlist, currentUserId: u?.id));
  }

  void _openArtist(Artist artist) =>
      context.pushSafe('/artist/${artist.id}', extra: artist);

  // ─────────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(homeFilterProvider);

    return Scaffold(
      drawer: const UserDrawer(),
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trendingSongsProvider);
          ref.invalidate(artistsProvider);
          ref.invalidate(systemPlaylistsProvider);
          ref.invalidate(allPodcastsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Header: Avatar + Filter Bar ─────────────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: AppTheme.background,
              elevation: 0,
              centerTitle: false,
              titleSpacing: 0,
              leading: const UserAvatar(),
              title: _buildFilterBar(filter),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.bell, size: 22),
                  onPressed: () => context.showInfo('Thông báo sẽ sớm ra mắt'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ─── Content ─────────────────────────────────────────────────────
            ..._buildBodySlivers(filter),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  FILTER BAR
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildFilterBar(HomeFilter filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 8, right: 16),
      child: Row(
        children: [
          // "Tất cả"
          _buildTopChip(
            'Tất cả',
            isSelected: filter == HomeFilter.all,
            isOutlined: filter != HomeFilter.all,
            onTap: () => ref.read(homeFilterProvider.notifier).setFilter(HomeFilter.all),
          ),
          const SizedBox(width: 8),

          // "Âm nhạc" — becomes joined chip when active
          if (filter == HomeFilter.music || filter == HomeFilter.musicFollowing) ...[
            _buildJoinedChip(
              leftLabel: 'Âm nhạc',
              rightLabel: 'Đang theo dõi',
              leftActiveColor: const Color(0xFF90CEFA),
              rightActiveColor: const Color(0xFF90CEFA),
              isLeftActive: filter == HomeFilter.music,
              onLeftTap: () => ref.read(homeFilterProvider.notifier).setFilter(HomeFilter.music),
              onRightTap: () => ref.read(homeFilterProvider.notifier).setFilter(HomeFilter.musicFollowing),
            ),
          ] else ...[
            _buildTopChip(
              'Âm nhạc',
              isSelected: false,
              isOutlined: filter != HomeFilter.all,
              onTap: () => ref.read(homeFilterProvider.notifier).setFilter(HomeFilter.music),
            ),
          ],
          const SizedBox(width: 8),

          // "Podcasts" — becomes joined chip when active
          if (filter == HomeFilter.podcasts || filter == HomeFilter.podcastsFollowing) ...[
            _buildJoinedChip(
              leftLabel: 'Podcasts',
              rightLabel: 'Đang theo dõi',
              leftActiveColor: const Color(0xFF1ED760),
              rightActiveColor: const Color(0xFF1ED760),
              isLeftActive: filter == HomeFilter.podcasts,
              onLeftTap: () => ref.read(homeFilterProvider.notifier).setFilter(HomeFilter.podcasts),
              onRightTap: () => ref.read(homeFilterProvider.notifier).setFilter(HomeFilter.podcastsFollowing),
            ),
          ] else ...[
            _buildTopChip(
              'Podcasts',
              isSelected: false,
              isOutlined: filter != HomeFilter.all,
              onTap: () => ref.read(homeFilterProvider.notifier).setFilter(HomeFilter.podcasts),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  UI Helper Methods for Chips
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTopChip(
    String label, {
    required bool isSelected,
    required bool isOutlined,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : (isOutlined ? Colors.transparent : AppTheme.surfaceHighlight),
          borderRadius: BorderRadius.circular(20),
          border: isOutlined ? Border.all(color: Colors.white.withOpacity(0.12), width: 1) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildJoinedChip({
    required String leftLabel,
    required String rightLabel,
    required Color leftActiveColor,
    required Color rightActiveColor,
    required bool isLeftActive,
    required VoidCallback onLeftTap,
    required VoidCallback onRightTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onLeftTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isLeftActive ? leftActiveColor : AppTheme.primary.withOpacity(0.12),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(
                  leftLabel,
                  style: TextStyle(
                    fontSize: 13, 
                    fontWeight: FontWeight.w600, 
                    color: isLeftActive ? Colors.black : AppTheme.primary,
                  ),
                ),
                if (isLeftActive) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.close, size: 14, color: Colors.black54),
                ],
              ],
            ),
          ),
        ),
        Container(width: 1, color: Colors.black12, height: 28),
        GestureDetector(
          onTap: onRightTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: !isLeftActive ? rightActiveColor : AppTheme.surfaceHighlight,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
            ),
            child: Text(
              rightLabel,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w600, 
                color: !isLeftActive ? Colors.black : AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  BODY sliver router
  // ─────────────────────────────────────────────────────────────────────────────
  List<Widget> _buildBodySlivers(HomeFilter filter) {
    return switch (filter) {
      HomeFilter.all              => _buildAllSlivers(),
      HomeFilter.music            => _buildMusicSlivers(),
      HomeFilter.musicFollowing   => _buildMusicFollowingSlivers(),
      HomeFilter.podcasts         => _buildPodcastsSlivers(),
      HomeFilter.podcastsFollowing => _buildPodcastsFollowingSlivers(),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  "TẤT CẢ" view (Slivers)
  // ─────────────────────────────────────────────────────────────────────────────
  List<Widget> _buildAllSlivers() {
    return [
      // Greeting
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, AppSpacing.xs),
          child: Text(
            _greeting(),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
      ),

      // System Playlists section
      ..._buildPlaylistSection(),

      // Artists row
      ..._buildArtistSection(),

      // Songs section
      ..._buildSongSection(),

      // Podcasts section
      ..._buildPodcastSection(),

      const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  "ÂM NHẠC" view (Slivers)
  // ─────────────────────────────────────────────────────────────────────────────
  List<Widget> _buildMusicSlivers() {
    return [
      ..._buildPlaylistSection(),
      ..._buildArtistSection(),
      ..._buildSongSection(),
      const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  "ÂM NHẠC - ĐANG THEO DÕI" view (Slivers)
  // ─────────────────────────────────────────────────────────────────────────────
  List<Widget> _buildMusicFollowingSlivers() {
    final user = ref.watch(authStateProvider).value?.session?.user;
    if (user == null) return [SliverToBoxAdapter(child: _buildLoginPrompt('theo dõi nghệ sĩ'))];

    final followedAsync = ref.watch(followedArtistsProvider);

    return [
      SliverToBoxAdapter(child: HomeSectionHeader(title: 'Nghệ sĩ đang theo dõi')),
      SliverToBoxAdapter(
        child: followedAsync.when(
          loading: () => const SizedBox(height: 104, child: AppLoadingIndicator()),
          error: (e, _) => AppErrorState(onRetry: () => ref.invalidate(followedArtistsProvider)),
          data: (artists) {
            if (artists.isEmpty) {
              return AppEmptyState(
                icon: LucideIcons.userPlus,
                title: 'Chưa theo dõi ai',
                message: 'Hãy khám phá các nghệ sĩ và nhấn theo dõi để cập nhật nhạc mới.',
                actionLabel: 'Khám phá ngay',
                onAction: () => ref.read(homeFilterProvider.notifier).setFilter(HomeFilter.all),
              );
            }
            return ArtistAvatarRow(artists: artists, onTap: _openArtist).animate().fadeIn();
          },
        ),
      ),
      ..._buildSongSection(title: 'Nhạc của nghệ sĩ bạn theo dõi'),
      const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  "PODCASTS" view (Slivers)
  // ─────────────────────────────────────────────────────────────────────────────
  List<Widget> _buildPodcastsSlivers() {
    return [
      ..._buildPodcastSection(title: 'Khám phá Podcast'),
      const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  "PODCASTS - ĐANG THEO DÕI" view (Slivers)
  // ─────────────────────────────────────────────────────────────────────────────
  List<Widget> _buildPodcastsFollowingSlivers() {
    final user = ref.watch(authStateProvider).value?.session?.user;
    if (user == null) return [SliverToBoxAdapter(child: _buildLoginPrompt('theo dõi podcast'))];

    final channelsAsync = ref.watch(subscribedChannelsProvider);
    final followedPodcastsAsync = ref.watch(followedPodcastsProvider);

    return [
      SliverToBoxAdapter(child: HomeSectionHeader(title: 'Kênh podcast đang theo dõi')),
      SliverToBoxAdapter(
        child: channelsAsync.when(
          loading: () => const SizedBox(height: 104, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => _buildError('Không tải được kênh'),
          data: (channels) {
            if (channels.isEmpty) return _buildEmpty('Bạn chưa theo dõi kênh nào');
            return FollowedPodcastChannelsRow(channels: channels);
          },
        ),
      ),
      SliverToBoxAdapter(child: HomeSectionHeader(title: 'Tập mới từ các kênh bạn theo dõi')),
      followedPodcastsAsync.when(
        loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
        error: (e, _) => SliverToBoxAdapter(child: _buildError('Lỗi tải bài học mới')),
        data: (podcasts) {
          if (podcasts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => PodcastCard(
                  podcast: podcasts[index],
                  onTap: () => context.pushSafe('/podcast/${podcasts[index].id}', extra: podcasts[index]),
                ),
                childCount: podcasts.length,
              ),
            ),
          );
        },
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  REUSABLE SECTION BUILDERS
  // ─────────────────────────────────────────────────────────────────────────────

  List<Widget> _buildPlaylistSection() {
    final playlistsAsync = ref.watch(systemPlaylistsProvider);
    return [
      SliverToBoxAdapter(child: HomeSectionHeader(title: 'Dành cho bạn')),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 192,
          child: playlistsAsync.when(
            loading: () => const AppLoadingIndicator(),
            error: (e, _) => AppErrorState(onRetry: () => ref.invalidate(systemPlaylistsProvider)),
            data: (playlists) {
              if (playlists.isEmpty) {
                return const AppEmptyState(
                  icon: LucideIcons.music,
                  title: 'Trống',
                  message: 'Không tìm thấy danh sách phát nào.',
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                itemCount: playlists.length,
                itemBuilder: (context, i) {
                  final p = playlists[i];
                  return PlaylistCard(
                    title: p.name,
                    subtitle: p.description,
                    imageUrl: p.coverUrl,
                    onTap: () => _openPlaylist(p),
                  ).animate().fadeIn(delay: (i * 50).ms).scale(begin: const Offset(0.9, 0.9));
                },
              );
            },
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildArtistSection() {
    final artistsAsync = ref.watch(artistsProvider);
    return [
      SliverToBoxAdapter(child: HomeSectionHeader(title: 'Nghệ sĩ nổi bật')),
      SliverToBoxAdapter(
        child: artistsAsync.when(
          loading: () => const SizedBox(height: 104, child: AppLoadingIndicator()),
          error: (e, _) => AppErrorState(onRetry: () => ref.invalidate(artistsProvider)),
          data: (artists) {
            if (artists.isEmpty) return const SizedBox.shrink();
            return ArtistAvatarRow(artists: artists, onTap: _openArtist).animate().fadeIn();
          },
        ),
      ),
    ];
  }

  List<Widget> _buildSongSection({String title = 'Top thịnh hành'}) {
    final songsAsync = ref.watch(trendingSongsProvider);
    final expanded = ref.watch(songsExpandedProvider);
    const defaultCount = 10;

    return [
      SliverToBoxAdapter(
        child: songsAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (songs) => HomeSectionHeader(
            title: title,
            actionLabel: songs.length > defaultCount
                ? (expanded ? 'Thu gọn' : 'Hiển thị thêm')
                : null,
            onActionTap: () => ref.read(songsExpandedProvider.notifier).toggle(),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: songsAsync.when(
          loading: () => Column(
            children: List.generate(5, (_) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
              child: AppSkeleton(width: double.infinity, height: 60),
            )),
          ),
          error: (e, _) => AppErrorState(onRetry: () => ref.invalidate(trendingSongsProvider)),
          data: (songs) {
            if (songs.isEmpty) return const AppEmptyState(icon: LucideIcons.music, title: 'Không có bài hát', message: 'Hiện chưa có bài hát thịnh hành.');
            final shown = expanded ? songs : songs.take(defaultCount).toList();
            return Column(
              children: [
                ...shown.asMap().entries.map((e) => SongListItem(
                  song: e.value,
                  onTap: () => _playSong(e.value, songs, e.key),
                ).animate().fadeIn(delay: (e.key * 30).ms)),
                if (songs.length > defaultCount)
                  _buildExpandCollapseButton(
                    expanded: expanded,
                    onTap: () => ref.read(songsExpandedProvider.notifier).toggle(),
                  ),
              ],
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildPodcastSection({String title = 'Podcasts nổi bật'}) {
    final podcastsAsync = ref.watch(allPodcastsProvider);
    final expanded = ref.watch(podcastsExpandedProvider);
    const defaultCount = 3;

    return [
      SliverToBoxAdapter(
        child: podcastsAsync.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (podcasts) => HomeSectionHeader(
            title: title,
            actionLabel: podcasts.length > defaultCount
                ? (expanded ? 'Thu gọn' : 'Hiển thị thêm')
                : null,
            onActionTap: () => ref.read(podcastsExpandedProvider.notifier).toggle(),
          ),
        ),
      ),
      podcastsAsync.when(
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (e, _) => SliverToBoxAdapter(child: _buildError('Không tải được podcast')),
        data: (podcasts) {
          if (podcasts.isEmpty) return SliverToBoxAdapter(child: _buildEmpty('Chưa có podcast nào'));
          final shown = expanded ? podcasts : podcasts.take(defaultCount).toList();
          
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ...shown.map((p) => PodcastCard(
                        podcast: p,
                        onTap: () => context.pushSafe('/podcast/${p.id}', extra: p),
                      )),
                  if (podcasts.length > defaultCount)
                    _buildExpandCollapseButton(
                      expanded: expanded,
                      onTap: () => ref.read(podcastsExpandedProvider.notifier).toggle(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  STATE WIDGETS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildError(String msg) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(msg, style: const TextStyle(color: AppTheme.textSecondary))),
      );

  Widget _buildEmpty(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(child: Text(msg, style: const TextStyle(color: AppTheme.textSecondary))),
      );

  Widget _buildLoginPrompt(String action) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.lock, size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Đăng nhập để $action',
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandCollapseButton({required bool expanded, required VoidCallback onTap}) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(expanded ? LucideIcons.chevronsUp : LucideIcons.chevronsDown, size: 16),
      label: Text(expanded ? 'Thu gọn' : 'Hiển thị thêm'),
      style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
    );
  }
}
