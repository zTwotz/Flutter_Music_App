import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../providers/search_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/supabase_provider.dart'; // Add this line
import '../widgets/user_avatar.dart';
import '../widgets/user_drawer.dart';
import '../widgets/search_widgets.dart';

// Import new modular UI widgets
import '../widgets/search/search_bar_widget.dart';
import '../widgets/search/recent_search_section.dart';
import '../widgets/search/browse_categories_section.dart';
import '../widgets/search/trending_section.dart';
import '../widgets/search/search_state_widgets.dart';
import '../widgets/search/live_suggestion_list.dart';
import '../widgets/search/full_search_result_list.dart';

import '../models/collection_item.dart';
import '../models/song.dart';
import '../models/podcast.dart';
import '../models/artist.dart';
import '../core/app_ui_utils.dart';
import '../core/player_utils.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text;
      // Use setQuery for debounce on typing
      ref.read(searchQueryProvider.notifier).setQuery(query);
      
      if (_isSubmitted && _focusNode.hasFocus && query.isNotEmpty) {
        setState(() {
          _isSubmitted = false;
        });
      }
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
    ref.read(searchQueryProvider.notifier).setQueryImmediate('');
    _focusNode.unfocus();
    setState(() {
      _isSubmitted = false;
    });
  }

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

  void _saveRecentSearchItem({
    required String keyword,
    required String contentType,
    String? contentId,
    required String title,
    String? subtitle,
    String? imageUrl,
  }) async {
    final user = ref.read(authStateProvider).value?.session?.user;
    await ref.read(searchRepositoryProvider).saveSearchItem(
      userId: user?.id,
      keyword: keyword,
      contentType: contentType,
      contentId: contentId,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
    );
    ref.invalidate(recentSearchesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Dark theme as requested
      drawer: UserDrawer(),
      body: CustomScrollView(
        slivers: [
          // ─── Header: Avatar + Title ──────────────────────────────────────
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            leadingWidth: 68,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: const UserAvatar(),
                ),
              ),
            ),
            title: const Text(
              'Tìm kiếm',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 28, 
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: SearchBarWidget(
                controller: _searchController,
                focusNode: _focusNode,
                onClear: _clearSearch,
                onSubmitted: (value) async {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) {
                    ref.read(searchQueryProvider.notifier).setQueryImmediate(trimmed);
                    _saveRecentSearchItem(
                      keyword: trimmed,
                      contentType: 'keyword',
                      title: trimmed,
                    );
                    setState(() {
                      _isSubmitted = true;
                    });
                  }
                  _focusNode.unfocus();
                },
              ),
            ),
          ),

          // ─── Content ─────────────────────────────────────────────────────
          if (query.isEmpty)
            _buildDiscoveryView()
          else if (!_isSubmitted)
            LiveSuggestionList(
              results: searchResults,
              onSaveRecent: _saveRecentSearchItem,
            )
          else
            FullSearchResultList(
              results: searchResults,
              onSaveRecent: _saveRecentSearchItem,
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildDiscoveryView() {
    // Fetch discovery data
    final recent = ref.watch(recentSearchesProvider).value ?? [];
    final hashtagsData = ref.watch(hashtagsProvider).value ?? [];
    final hashtagKeywords = hashtagsData.map((h) => h['name'] as String).toList();
    final genresList = ref.watch(genresProvider).value;
    final moodsList = ref.watch(moodsProvider).value;

    return SliverList(
      delegate: SliverChildListDelegate([
        
        // 1. Gợi ý cho bạn (Trending Keywords from Hashtags)
        TrendingSection(
          trendingKeywords: hashtagKeywords,
          onKeywordTap: (keyword) {
            _searchController.text = keyword;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length)
            );
            ref.read(searchQueryProvider.notifier).setQueryImmediate(keyword);
            setState(() {
              _isSubmitted = true;
            });
            _focusNode.unfocus();
          },
        ),

        // 2. Lịch sử tìm kiếm gần đây
        RecentSearchSection(
          recentSearches: recent,
          onClearHistory: () async {
            final user = ref.read(authStateProvider).value?.session?.user;
            await ref.read(searchRepositoryProvider).clearRecentSearches(user?.id);
            ref.invalidate(recentSearchesProvider);
          },
          onSearchItemTap: (item) {
            final contentType = item['content_type'] as String;
            if (contentType == 'artist') {
              final artist = Artist(
                id: item['content_id'].toString(),
                name: item['title'] ?? '',
                avatarUrl: item['image_url'],
              );
              context.pushSafe('/artist/${artist.id}', extra: artist);
            } else if (contentType == 'album') {
              final album = CollectionItem(
                id: int.tryParse(item['content_id'].toString()) ?? 0,
                title: item['title'] ?? '',
                coverUrl: item['image_url'],
                type: CollectionType.album,
              );
              context.pushSafe('/album/${album.id}', extra: album);
            } else if (contentType == 'playlist') {
              final playlist = CollectionItem(
                id: int.tryParse(item['content_id'].toString()) ?? 0,
                title: item['title'] ?? '',
                coverUrl: item['image_url'],
                type: CollectionType.userPlaylist,
              );
              context.pushSafe('/playlist/${playlist.id}', extra: playlist);
            } else if (contentType == 'genre' || contentType == 'mood' || contentType == 'hashtag') {
              context.pushSafe('/category/${item['title']}', extra: {'title': item['title'], 'type': contentType});
            } else {
              // For keyword, song, podcast -> put into search bar and search
              // because we lack audioUrl & full dataset to immediately play them from history
              _searchController.text = item['keyword'] ?? item['title'] ?? '';
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: _searchController.text.length)
              );
              _focusNode.unfocus();
              setState(() {
                _isSubmitted = true;
              });
            }
          },
          onDeleteItem: (item) async {
            final user = ref.read(authStateProvider).value?.session?.user;
            await ref.read(searchRepositoryProvider).removeSearchItem(
              userId: user?.id,
              contentType: item['content_type'],
              contentId: item['content_id'],
              keyword: item['keyword'],
            );
            ref.invalidate(recentSearchesProvider);
          },
        ),

        // 3. Khám phá theo Thể Loại
        BrowseCategoriesSection(
          title: 'Thể Loại',
          categoriesData: genresList,
          onCategoryTap: (category) {
            _searchController.text = category;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length)
            );
            ref.read(searchQueryProvider.notifier).setQueryImmediate(category);
            setState(() {
              _isSubmitted = true;
            });
            _focusNode.unfocus();
          },
        ),

        // 4. Khám phá theo Tâm trạng
        BrowseCategoriesSection(
          title: 'Tâm trạng',
          categoriesData: moodsList,
          onCategoryTap: (mood) {
            _searchController.text = mood;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length)
            );
            ref.read(searchQueryProvider.notifier).setQueryImmediate(mood);
            setState(() {
              _isSubmitted = true;
            });
            _focusNode.unfocus();
          },
        ),
      ]),
    );
  }

  // Method removed.
}
