import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';
import '../providers/search_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_drawer.dart';
import '../widgets/search_widgets.dart';
import '../widgets/state_widgets.dart';
import '../models/collection_item.dart';
import '../core/app_ui_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text;
      ref.read(searchQueryProvider.notifier).setQuery(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      drawer: const UserDrawer(),
      appBar: AppBar(
        leading: const UserAvatar(),
        title: query.isEmpty
            ? const Text('Tìm kiếm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28))
            : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: _clearSearch,
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ─── Search Bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Bạn muốn nghe gì?',
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                ),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                onSubmitted: (value) async {
                  final user = ref.read(authStateProvider).value?.session?.user;
                  if (user != null && value.trim().isNotEmpty) {
                    await ref.read(searchRepositoryProvider).saveSearch(user.id, value.trim());
                    ref.invalidate(recentSearchesProvider);
                  }
                },
              ),
            ),
          ),

          // ─── Content ─────────────────────────────────────────────────────
          if (query.isEmpty)
            _buildDiscoveryView()
          else
            _buildResultsView(searchResults),
        ],
      ),
    );
  }

  Widget _buildDiscoveryView() {
    return SliverList(
      delegate: SliverChildListDelegate([
        // hashtags section
        _buildSectionHeader('Khám phá nội dung mới mẻ'),
        _buildHashtagsSection(),

        // browse all (Genres/Categories)
        _buildSectionHeader('Duyệt tìm tất cả'),
        _buildGenresGrid(),
        
        // trending
        _buildSectionHeader('Từ khóa xu hướng'),
        _buildTrendingKeywords(),

        // history (if logged in)
        _buildRecentSearches(),

        const SizedBox(height: 120),
      ]),
    );
  }

  Widget _buildResultsView(AsyncValue<SearchResults> results) {
    return results.when(
      data: (data) {
        if (data.isEmpty) {
          return SliverFillRemaining(
            child: AppEmptyState(
              icon: LucideIcons.search,
              title: 'Không tìm thấy kết quả',
              message: 'Vui lòng kiểm tra lại từ khóa hoặc thử một nội dung khác.',
            ),
          );
        }

        return SliverList(
          delegate: SliverChildListDelegate([
            if (data.songs.isNotEmpty) ...[
              _buildSectionHeader('Bài hát'),
              ...data.songs.asMap().entries.map((e) => SearchResultTile(
                    title: e.value.title,
                    subtitle: e.value.artistName ?? 'Âm nhạc',
                    imageUrl: e.value.coverUrl,
                    type: 'song',
                    onTap: () async {
                      ref.read(currentSongProvider.notifier).setSong(e.value);
                      await ref.read(audioHandlerProvider).playSong(e.value);
                      context.pushSafe('/player');
                    },
                  ).animate().fadeIn(delay: (e.key * 20).ms).slideX(begin: 0.05)),
            ],
            if (data.artists.isNotEmpty) ...[
              _buildSectionHeader('Nghệ sĩ'),
              ...data.artists.map((a) => SearchResultTile(
                    title: a.name,
                    subtitle: 'Hồ sơ',
                    imageUrl: a.avatarUrl,
                    type: 'artist',
                    onTap: () => context.pushSafe('/artist/${a.id}', extra: a),
                  )),
            ],
            if (data.albums.isNotEmpty) ...[
              _buildSectionHeader('Albums'),
              ...data.albums.map((al) => SearchResultTile(
                    title: al.title,
                    subtitle: 'Album',
                    imageUrl: al.coverUrl,
                    type: 'album',
                    onTap: () => context.pushSafe('/album/${al.id}', extra: CollectionItem.fromAlbum(al)),
                  )),
            ],
            if (data.playlists.isNotEmpty) ...[
              _buildSectionHeader('Danh sách phát'),
              ...data.playlists.map((p) => SearchResultTile(
                    title: p.name,
                    subtitle: 'Playlist',
                    imageUrl: p.coverUrl,
                    type: 'playlist',
                    onTap: () {
                      final user = ref.read(authStateProvider).value?.session?.user;
                      context.pushSafe('/playlist/${p.id}', extra: CollectionItem.fromPlaylist(p, currentUserId: user?.id));
                    },
                  )),
            ],
            if (data.podcasts.isNotEmpty) ...[
              _buildSectionHeader('Podcasts'),
              ...data.podcasts.map((pd) => SearchResultTile(
                    title: pd.title,
                    subtitle: pd.channelName ?? 'Podcast',
                    imageUrl: pd.coverUrl,
                    type: 'podcast',
                    onTap: () {
                      // Handle podcast playback or detail
                    },
                  )),
            ],
            const SizedBox(height: 120),
          ]),
        );
      },
      loading: () => const SliverFillRemaining(
        child: AppLoadingIndicator(),
      ),
      error: (e, st) => SliverFillRemaining(
        child: AppErrorState(
          error: e.toString(),
          onRetry: () => ref.invalidate(searchResultsProvider),
        ),
      ),
    );
  }

  // ─── Private Helper Widgets ───────────────────────────────────────────────

  Widget _buildSectionHeader(String title, {VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.l, AppSpacing.m, AppSpacing.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: const Text('Xoá lịch sử', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildHashtagsSection() {
    final hashtags = ref.watch(hashtagsProvider);
    return hashtags.when(
      data: (data) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          children: data.map((h) => HashtagChip(
            label: h['name'], 
            onTap: () {
              _searchController.text = h['name'];
              _focusNode.requestFocus();
            }
          )).toList(),
        ),
      ),
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildGenresGrid() {
    final genres = ref.watch(genresProvider);
    return genres.when(
      data: (data) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final g = data[index];
            // Curated colors for categories
            final List<Color> cardColors = [
              const Color(0xFFE8115B),
              const Color(0xFF148A08),
              const Color(0xFF8D67AB),
              const Color(0xFFE13300),
              const Color(0xFF7358FF),
              const Color(0xFF1E3264),
              const Color(0xFFAF2896),
              const Color(0xFF509BF5),
            ];
            return SearchCategoryCard(
              title: g['name'],
              color: cardColors[index % cardColors.length],
              imageUrl: g['cover_url'],
              onTap: () {
                _searchController.text = g['name'];
                _focusNode.requestFocus();
              },
            );
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildTrendingKeywords() {
    final trends = ref.watch(trendingKeywordsProvider);
    return trends.when(
      data: (data) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: data.map((k) => ActionChip(
            label: Text(k),
            onPressed: () {
              _searchController.text = k;
              _focusNode.requestFocus();
            },
            backgroundColor: AppTheme.surfaceHighlight,
          )).toList(),
        ),
      ),
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildRecentSearches() {
    final recent = ref.watch(recentSearchesProvider);
    return recent.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox();
        return Column(
          children: [
            _buildSectionHeader('Tìm kiếm gần đây', onAction: () async {
              final user = ref.read(authStateProvider).value?.session?.user;
              if (user != null) {
                await ref.read(searchRepositoryProvider).clearRecentSearches(user.id);
                ref.invalidate(recentSearchesProvider);
              }
            }),
            ...data.map((r) => ListTile(
                  leading: const Icon(LucideIcons.history, color: AppTheme.textSecondary),
                  title: Text(r['keyword']),
                  trailing: const Icon(LucideIcons.arrowUpLeft, size: 20),
                  onTap: () {
                    _searchController.text = r['keyword'];
                    _focusNode.requestFocus();
                  },
                )),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}
