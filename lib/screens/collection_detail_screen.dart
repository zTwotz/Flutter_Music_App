import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/collection_item.dart';
import '../models/song.dart';
import '../providers/collection_detail_provider.dart';
import '../providers/supabase_provider.dart';
import '../providers/library_providers.dart';
import '../widgets/song_list_item.dart';
import '../widgets/state_widgets.dart';
import '../core/app_theme.dart';
import '../core/app_ui_utils.dart';
import '../core/guest_guard.dart';
import '../providers/saved_playlists_provider.dart';
import '../core/player_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final CollectionItem item;

  const CollectionDetailScreen({super.key, required this.item});

  @override
  ConsumerState<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends ConsumerState<CollectionDetailScreen> {
  // Use local state to override the UI title if owner renames it successfully.
  late String _localTitle;

  @override
  void initState() {
    super.initState();
    _localTitle = widget.item.title;
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _localTitle);
    
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Đổi tên danh sách phát'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên mới...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Huỷ', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != _localTitle) {
                try {
                  await ref.read(playlistRepositoryProvider).renamePlaylist(widget.item.id, newName);
                  ref.invalidate(userPlaylistsProvider);
                  setState(() => _localTitle = newName);
                  if (!context.mounted) return;
                  Navigator.pop(dialogCtx);
                  context.showSuccess('Đổi tên thành công');
                } catch (e) {
                  if (!context.mounted) return;
                  context.showError('Lỗi: $e');
                }
              } else {
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                _localTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(color: AppTheme.textSecondary),
            ListTile(
              leading: const Icon(LucideIcons.pencil, color: AppTheme.textPrimary),
              title: const Text('Đổi tên danh sách phát'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog();
              },
            ),
            // Will implement Delete Playlist later
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(collectionDetailProvider(widget.item));

    return Material(
      color: AppTheme.background,
      child: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (widget.item.isOwner)
                IconButton(
                  icon: const Icon(LucideIcons.moreVertical, size: 22),
                  onPressed: _showOptionsMenu,
                )
              else if (widget.item.type != CollectionType.album) // System playlist
                ref.watch(isPlaylistSavedProvider(widget.item.id)).when(
                      data: (isSaved) => IconButton(
                        icon: Icon(
                          isSaved ? LucideIcons.check : LucideIcons.plus,
                          color: isSaved ? AppTheme.primary : Colors.white,
                        ),
                        onPressed: () {
                          if (!GuestGuard.ensureAuthenticated(context, ref)) return;
                          ref.read(savedPlaylistNotifierProvider.notifier).toggleSave(widget.item.id, isSaved);
                        },
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.item.coverUrl != null)
                    CachedNetworkImage(
                      imageUrl: widget.item.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildCoverFallback(),
                    )
                  else
                    _buildCoverFallback(),
                  // Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.background],
                      ),
                    ),
                  ),
                  // Title at bottom
                  Positioned(
                    bottom: AppSpacing.m,
                    left: AppSpacing.m,
                    right: AppSpacing.m,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _localTitle,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        if (widget.item.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.item.subtitle!,
                            style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w600),
                          ).animate().fadeIn(delay: 300.ms),
                        ],
                        if (widget.item.description != null && widget.item.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.item.description!,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ).animate().fadeIn(delay: 400.ms),
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // ── Loading / Error / Content ──
          songsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: AppLoadingIndicator()),
              ),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: AppErrorState(
                error: err.toString(),
                onRetry: () => ref.invalidate(collectionDetailProvider(widget.item)),
              ),
            ),
            data: (songs) {
              if (songs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: LucideIcons.music,
                    title: 'Trống',
                    message: 'Bộ sưu tập này chưa có bài hát nào.',
                  ),
                );
              }

              return SliverMainAxisGroup(
                slivers: [
                  // Play Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.playOrNavigate(ref, songs.first, songs);
                              },
                              icon: const Icon(LucideIcons.play, size: 18),
                              label: const Text('Phát tất cả'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final shuffled = List<Song>.from(songs)..shuffle();
                                context.playOrNavigate(ref, shuffled.first, shuffled);
                              },
                              icon: const Icon(LucideIcons.shuffle, size: 18),
                              label: const Text('Trộn bài'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                side: const BorderSide(color: AppTheme.textSecondary),
                                minimumSize: const Size(0, 48),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tracklist
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = songs[index];
                        return SongListItem(
                          song: song,
                          trailing: widget.item.isOwner
                              ? IconButton(
                                  icon: const Icon(LucideIcons.minusCircle, color: AppTheme.textSecondary),
                                  onPressed: () => _removeSong(song.id, song.title),
                                )
                              : null,
                          onTap: () {
                            context.playOrNavigate(ref, song, songs, initialIndex: index);
                          },
                        ).animate().fadeIn(delay: (index * 20).ms).slideX(begin: 0.05);
                      },
                      childCount: songs.length,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 120)), // Space for MiniPlayer
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _removeSong(int songId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá bài hát?'),
        content: Text('Bạn có chắc muốn xoá "$title" khỏi danh sách này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(playlistRepositoryProvider).removeSongFromPlaylist(widget.item.id, songId);
        ref.invalidate(collectionDetailProvider(widget.item));
        if (context.mounted) {
          context.showSuccess('Đã xoá bài hát');
        }
      } catch (e) {
        if (context.mounted) {
          context.showError('Lỗi: $e');
        }
      }
    }
  }

  Widget _buildCoverFallback() {
    return Container(
      color: AppTheme.surface,
      child: Icon(
        widget.item.type == CollectionType.album ? LucideIcons.disc : LucideIcons.listMusic, 
        size: 80, 
        color: Colors.white12
      ),
    );
  }
}
