import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist.dart';
import '../core/app_theme.dart';

class ArtistAvatarRow extends StatelessWidget {
  final List<Artist> artists;
  final void Function(Artist artist) onTap;

  const ArtistAvatarRow({
    super.key,
    required this.artists,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return _ArtistAvatar(artist: artist, onTap: () => onTap(artist));
        },
      ),
    );
  }
}

class _ArtistAvatar extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const _ArtistAvatar({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final firstLetter = artist.name.isNotEmpty ? artist.name[0].toUpperCase() : 'A';
    final int hash = artist.name.hashCode.abs();
    final Color color = Color.fromARGB(
      255,
      80 + (hash % 140),
      60 + ((hash >> 8) % 140),
      80 + ((hash >> 16) % 140),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: color,
              backgroundImage: artist.avatarUrl != null
                  ? CachedNetworkImageProvider(artist.avatarUrl!)
                  : null,
              child: artist.avatarUrl == null
                  ? Text(
                      firstLetter,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              artist.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
