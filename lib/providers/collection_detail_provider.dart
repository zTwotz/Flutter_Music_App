import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/collection_item.dart';
import 'supabase_provider.dart';

final collectionDetailProvider = FutureProvider.family<List<Song>, CollectionItem>((ref, arg) async {
  final repo = ref.read(collectionRepositoryProvider);
  switch (arg.type) {
    case CollectionType.album:
      return await repo.fetchAlbumSongs(arg.id);
    case CollectionType.systemPlaylist:
    case CollectionType.userPlaylist:
      return await repo.fetchPlaylistSongs(arg.id);
  }
});
