import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/artist.dart';

class ArtistService {
  static Future<Artist?> findArtistByName(String name) async {
    try {
      final sanitizedName = name.trim();
      final response = await Supabase.instance.client
          .from('artists')
          .select()
          .ilike('name', sanitizedName)
          .maybeSingle();

      if (response != null) {
        return Artist.fromJson(response);
      }
    } catch (_) {
      // Log or handle error
    }
    return null;
  }
}
