import 'playlist.dart';
import 'album.dart';

enum CollectionType {
  systemPlaylist,
  userPlaylist,
  album,
}

/// A unified model to pass data into the unified CollectionDetailScreen.
class CollectionItem {
  final int id;
  final String title;
  final String? coverUrl;
  final String? description;
  final String? subtitle; // 'album', release date, or artist name
  final CollectionType type;
  final bool isOwner;

  CollectionItem({
    required this.id,
    required this.title,
    this.coverUrl,
    this.description,
    this.subtitle,
    required this.type,
    this.isOwner = false,
  });

  /// Convert from a Playlist model. 
  /// Needs to check if the user is the owner (requires passing the current userId).
  factory CollectionItem.fromPlaylist(Playlist playlist, {String? currentUserId}) {
    return CollectionItem(
      id: playlist.id,
      title: playlist.name,
      coverUrl: playlist.coverUrl,
      description: playlist.description,
      type: playlist.isSystem 
          ? CollectionType.systemPlaylist 
          : CollectionType.userPlaylist,
      // If it's a user playlist, we need to know who the owner is.
      // But actually, `playlist` model doesn't currently expose `user_id` directly in the dart class.
      // We'll treat `isOwner` as true only if `collectionType` == userPlaylist.
      // For a stricter check, `Playlist` model should expose `userId`.
      isOwner: playlist.isSystem ? false : true, 
    );
  }

  /// Convert from an Album model.
  factory CollectionItem.fromAlbum(Album album, {String? artistName}) {
    String sub = 'Album';
    if (artistName != null) {
      sub = 'Album • $artistName';
    } else if (album.releaseDate != null) {
      sub = 'Album • ${album.releaseDate!.year}';
    }

    return CollectionItem(
      id: album.id,
      title: album.title,
      coverUrl: album.coverUrl,
      description: 'Lắng nghe trọn bộ album ${album.title}',
      subtitle: sub,
      type: CollectionType.album,
      isOwner: false,
    );
  }
}
