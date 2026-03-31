import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/app_theme.dart';
import '../core/app_ui_utils.dart';
import '../models/song.dart';
import '../models/collection_item.dart';
import '../providers/auth_provider.dart';
import '../providers/create_playlist_provider.dart';
import '../providers/library_providers.dart';
import '../widgets/state_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreatePlaylistScreen extends ConsumerStatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  ConsumerState<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends ConsumerState<CreatePlaylistScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load songs for step 2 in background right away
    Future.microtask(() => ref.read(createPlaylistProvider.notifier).loadSongs());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _onNextStep() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showError('Vui lòng nhập tên danh sách phát');
      _nameFocus.requestFocus();
      return;
    }
    ref.read(createPlaylistProvider.notifier).setName(name);
    ref.read(createPlaylistProvider.notifier).setDescription(_descController.text.trim());
    ref.read(createPlaylistProvider.notifier).goToStep2();
  }

  Future<void> _onSave() async {
    final user = ref.read(authStateProvider).value?.session?.user;
    if (user == null) {
      context.push('/login');
      return;
    }

    final notifier = ref.read(createPlaylistProvider.notifier);
    final selectedCount = ref.read(createPlaylistProvider).selectedSongs.length;

    if (selectedCount == 0) {
      // Gợi ý nhưng vẫn cho phép lưu playlist trống
      final confirmed = await _showEmptyPlaylistDialog();
      if (!confirmed) return;
    }

    final playlist = await notifier.save(user.id);

    if (!mounted) return;

    if (playlist != null) {
      ref.invalidate(userPlaylistsProvider);
      context.showSuccess('Đã tạo "${playlist.name}" thành công!');
      context.pop(); 
      context.push('/playlist/${playlist.id}', extra: CollectionItem.fromPlaylist(playlist, currentUserId: user.id));
    } else {
      final error = ref.read(createPlaylistProvider).error;
      context.showError(error ?? 'Đã có lỗi xảy ra');
    }
  }

  Future<bool> _showEmptyPlaylistDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Chưa có bài hát'),
            content: const Text(
              'Bạn chưa thêm bài hát nào. Vẫn muốn tạo playlist trống?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Thêm bài hát'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Tạo trống'),
              ),
            ],
          ),
        ) ??
        false;
  }

  SnackBar _snackBar(String msg, {bool isError = false}) {
    return SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createPlaylistProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          tooltip: 'Đóng',
          onPressed: () {
            ref.read(createPlaylistProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Text(
          state.step == 1 ? 'Tạo danh sách phát' : 'Thêm bài hát',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (state.step == 2)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: state.isLoading ? null : _onSave,
                child: state.isLoading
                    ? const AppLoadingIndicator(size: 18, color: AppTheme.primary)
                    : const Text(
                        'Tạo',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: state.step == 1
            ? _Step1(
                key: const ValueKey('step1'),
                nameController: _nameController,
                descController: _descController,
                nameFocus: _nameFocus,
                onNext: _onNextStep,
              )
            : _Step2(
                key: const ValueKey('step2'),
                searchController: _searchController,
                onSave: _onSave,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — Playlist Info
// ─────────────────────────────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final FocusNode nameFocus;
  final VoidCallback onNext;

  const _Step1({
    super.key,
    required this.nameController,
    required this.descController,
    required this.nameFocus,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24, 32, 24, 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover art placeholder with gradient
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1DB954), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.l),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1DB954).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.listMusic,
                  size: 56,
                  color: Colors.white,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            ),
            const SizedBox(height: AppSpacing.xl),

            const Text(
              'Tên danh sách phát',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              focusNode: nameFocus,
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Tên danh sách phát...',
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _next(context),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),

            const SizedBox(height: AppSpacing.l),
            const Text(
              'Mô tả (tuỳ chọn)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: descController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Thêm mô tả cho danh sách...',
              ),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _next(context),
                child: const Text('Tiếp theo'),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            const SizedBox(height: AppSpacing.s),
            Center(
              child: TextButton(
                onPressed: onNext,
                child: const Text(
                  'Bỏ qua, tạo playlist trống',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }

  void _next(BuildContext context) => onNext();
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — Song Picker
// ─────────────────────────────────────────────────────────────────────────────

class _Step2 extends ConsumerWidget {
  final TextEditingController searchController;
  final VoidCallback onSave;

  const _Step2({
    super.key,
    required this.searchController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createPlaylistProvider);
    final notifier = ref.read(createPlaylistProvider.notifier);
    final songs = state.filteredSongs;

    return Column(
      children: [
        // ── Selected songs summary ─────────────────────────────────────────
        if (state.selectedSongs.isNotEmpty)
          _SelectedSongsBar(
            songs: state.selectedSongs,
            onRemove: (id) => notifier.removeSong(id),
          ),

        // ── Search bar ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, AppSpacing.s),
          child: TextField(
            controller: searchController,
            onChanged: (q) => notifier.setSearchQuery(q),
            decoration: InputDecoration(
              hintText: 'Tìm bài hát để thêm...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        searchController.clear();
                        notifier.setSearchQuery('');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // ── Song count info ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
          child: Row(
            children: [
              Text(
                state.selectedSongs.isEmpty
                    ? 'Chọn bài hát của bạn'
                    : 'Đã chọn ${state.selectedSongs.length} bài hát',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (state.allSongs.isEmpty)
                const AppLoadingIndicator(size: 14),
            ],
          ),
        ),

        // ── Song List ─────────────────────────────────────────────────────
        Expanded(
          child: songs.isEmpty && state.allSongs.isEmpty
              ? const AppLoadingIndicator()
              : songs.isEmpty
                  ? AppEmptyState(
                      icon: LucideIcons.searchX,
                      title: 'Không tìm thấy',
                      message: 'Không tìm thấy bài hát nào khớp với "${searchController.text}"',
                    )
                  : ListView.builder(
                      itemCount: songs.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, i) {
                        final song = songs[i];
                        final isSelected = state.isSongSelected(song.id);
                        return _SongPickerItem(
                          song: song,
                          isSelected: isSelected,
                          onToggle: () => notifier.toggleSong(song),
                        ).animate().fadeIn(delay: (i * 20).ms).slideX(begin: 0.05);
                      },
                    ),
        ),

        // ── Bottom CTA ────────────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : onSave,
                child: state.isLoading
                    ? const AppLoadingIndicator(size: 22, color: Colors.black)
                    : Text(
                        state.selectedSongs.isEmpty
                            ? 'Tạo danh sách trống'
                            : 'Tạo với ${state.selectedSongs.length} bài hát',
                      ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected Songs Horizontal Scroll Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SelectedSongsBar extends StatelessWidget {
  final List<Song> songs;
  final void Function(int id) onRemove;

  const _SelectedSongsBar({required this.songs, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Đã chọn ${songs.length} bài',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: songs.length,
              itemBuilder: (context, i) {
                final song = songs[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHighlight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: song.coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: song.coverUrl!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(LucideIcons.music, size: 22, color: Colors.white38),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => onRemove(song.id),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.x, size: 12, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Song Picker List Item
// ─────────────────────────────────────────────────────────────────────────────

class _SongPickerItem extends StatelessWidget {
  final Song song;
  final bool isSelected;
  final VoidCallback onToggle;

  const _SongPickerItem({
    required this.song,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.surfaceHighlight,
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: song.coverUrl != null
            ? CachedNetworkImage(
                imageUrl: song.coverUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(LucideIcons.music, color: Colors.white38),
              )
            : const Icon(LucideIcons.music, color: Colors.white38),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artistName ?? 'Unknown Artist',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
            : null,
      ),
      onTap: onToggle,
    );
  }
}
