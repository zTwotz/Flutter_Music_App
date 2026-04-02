import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../providers/player_provider.dart';
import '../providers/download_provider.dart';
import '../services/share_service.dart';
import '../services/artist_service.dart';
import 'add_to_playlist_bottom_sheet.dart';

Future<void> showPlayerOptionsBottomSheet(BuildContext context, WidgetRef ref, Song song) async {
  if (!context.mounted) return;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final isDownloaded = ref.watch(downloadProvider.notifier).isDownloaded(song.id);
          
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.m),
                          child: song.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: song.coverUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: AppTheme.surfaceHighlight,
                                  child: const Icon(LucideIcons.music, color: Colors.white54),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.artistName ?? 'Nghệ sĩ',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 32),
                  
                  // --- Options ---
                  _buildOptionTile(
                    icon: LucideIcons.listPlus,
                    title: 'Thêm vào playlist',
                    onTap: () {
                      Navigator.pop(context);
                      showAddToPlaylist(context, ref, song);
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: LucideIcons.listStart,
                    title: 'Phát tiếp theo',
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await ref.read(audioHandlerProvider).playNext(song);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã thêm vào phát tiếp theo')),
                          );
                        }
                      } catch (e) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                         }
                      }
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: LucideIcons.user,
                    title: 'Đi tới nghệ sĩ',
                    onTap: () async {
                      Navigator.pop(context);
                      final firstArtistName = (song.artistName ?? '')
                          .split(RegExp(r'(\s+ft\s+|\s+x\s+|,|\.)', caseSensitive: false))
                          .first.trim();
                      
                      final artist = await ArtistService.findArtistByName(firstArtistName);
                      if (artist != null && context.mounted) {
                        if (GoRouter.of(context).canPop()) GoRouter.of(context).pop();
                        context.push('/artist/${artist.id}', extra: artist);
                      }
                    },
                  ),

                  _buildOptionTile(
                    icon: LucideIcons.share2,
                    title: 'Chia sẻ',
                    onTap: () {
                      Navigator.pop(context);
                      ShareService.shareSong(song);
                    },
                  ),
                  
                  _buildOptionTile(
                    icon: isDownloaded ? LucideIcons.trash2 : LucideIcons.download,
                    title: isDownloaded ? 'Xóa bản tải' : 'Tải xuống',
                    onTap: () async {
                      final downloadNotifier = ref.read(downloadProvider.notifier);
                      try {
                        if (isDownloaded) {
                          await downloadNotifier.removeDownload(song.id);
                          if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bản tải ngoại tuyến')));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bắt đầu tải xuống...')));
                          await downloadNotifier.startDownload(song);
                          if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tải thành công')));
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildOptionTile({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
