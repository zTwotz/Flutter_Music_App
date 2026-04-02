import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';

class ShareService {
  static Future<void> shareSong(Song song) async {
    String message = 'Nghe bài hát: ${song.title} - ${song.artistName}';
    
    // Attempt to get Album name if available
    if (song.albumId != null) {
      try {
        final albumData = await Supabase.instance.client
            .from('albums')
            .select('title')
            .eq('id', song.albumId!)
            .maybeSingle();
            
        if (albumData != null && albumData['title'] != null) {
          message += '\nAlbum: ${albumData['title']}';
        }
      } catch (_) {
        // Silently continue if album fetch fails
      }
    }

    // Add public link if audioUrl seems like a public one (Supabase Storage URL)
    if (song.audioUrl.startsWith('http')) {
      message += '\n\nPhát tại đây:\n${song.audioUrl}';
    }

    await Share.share(message, subject: song.title);
  }
}
