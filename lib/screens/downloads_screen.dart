import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/download_provider.dart';
import '../widgets/song_list_item.dart';
import '../widgets/player_options_bottom_sheet.dart';
import '../core/player_utils.dart';
import '../core/app_theme.dart';
import '../widgets/state_widgets.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadedSongsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('Nhạc ngoại tuyến', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: downloadsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return const AppEmptyState(
              icon: LucideIcons.downloadCloud,
              title: 'Chưa có nhạc tải về',
              message: 'Bạn có thể tải nhạc để nghe khi không có kết nối mạng.',
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text('${songs.length} bài hát', style: const TextStyle(color: AppTheme.textSecondary)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(LucideIcons.playCircle, color: AppTheme.primary, size: 48),
                      onPressed: () => context.playOrNavigate(ref, songs.first, songs, initialIndex: 0),
                    ),

                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return SongListItem(
                      song: song,
                      onTap: () => context.playOrNavigate(ref, song, songs, initialIndex: index),
                      onMoreTap: () {
                        showPlayerOptionsBottomSheet(context, ref, song);
                      },
                    );

                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}
