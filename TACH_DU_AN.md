# 🔀 Kế hoạch tách dự án: Backend & Frontend

## Đánh giá khả thi

**✅ Hoàn toàn khả thi** — và thực tế **rất nên làm** vì:

| Hiện tại | Vấn đề |
|---|---|
| Flutter gọi trực tiếp Supabase tables | Tight coupling, khó bảo trì |
| RPC functions nằm rải rác trong SQL files | Không có version control rõ ràng |
| Không có API layer trung gian | Frontend biết quá nhiều về database schema |
| 30+ SECURITY DEFINER functions callable bởi `anon` | Lỗ hổng bảo mật |

### Mô hình đề xuất

```
┌─────────────────────┐          ┌──────────────────────────────┐
│   FRONTEND (Flutter) │  ◄────► │     BACKEND (Supabase)       │
│                     │  HTTP    │                              │
│ • UI/Screens        │  REST    │ • Edge Functions (API layer) │
│ • Riverpod          │          │ • PostgreSQL + RPC           │
│ • Models            │          │ • Auth                       │
│ • Services          │          │ • Storage                    │
│ • GoRouter          │          │ • Migrations                 │
└─────────────────────┘          └──────────────────────────────┘
     Repo: flutter_music_app          Repo: flutter_music_backend
```

---

## PHẦN A — Ghi chú trước khi triển khai

### A1. Kiểm kê hiện trạng

- [ ] **33 tables** trong public schema — tất cả đều có RLS trừ `podcast_favorites`
- [ ] **30+ RPC functions** — đều là SECURITY DEFINER, anon-callable
- [ ] **20+ views** `v_*_for_app` — đã tạo nhưng chưa sử dụng trong Flutter
- [ ] **9 Storage buckets** — cần giữ nguyên, chỉ cần tổ chức policies
- [ ] **12 repositories** trong Flutter — đều import `SupabaseClient` trực tiếp
- [ ] **0 Edge Functions** hiện tại — sẽ cần tạo mới cho API layer

### A2. Quyết định cần đưa ra trước

| # | Quyết định | Lựa chọn | Khuyến nghị |
|---|---|---|---|
| 1 | **API layer** | (a) Edge Functions (b) Giữ direct Supabase | **(a)** — bảo mật hơn, tách biệt hơn |
| 2 | **Mức độ tách** | (a) 2 repos riêng (b) Monorepo | **(a)** — dễ deploy độc lập |
| 3 | **Auth strategy** | (a) Giữ Supabase Auth trực tiếp (b) Qua API | **(a)** — Supabase Auth đã tốt, không cần proxy |
| 4 | **Storage access** | (a) Trực tiếp từ Flutter (b) Qua API | **(a)** — signed URLs hiệu quả hơn |
| 5 | **Migration tool** | (a) Supabase CLI (b) Raw SQL files | **(a)** — có version control, rollback |

### A3. Rủi ro cần lưu ý

1. **Downtime**: Không có nếu làm từng bước (backward compatible)
2. **Breaking changes**: Đổi response format từ direct query → API response
3. **Performance**: Edge Functions thêm 1 hop, nhưng có thể cache
4. **Supabase Free tier**: Edge Functions có giới hạn 500K invocations/tháng

### A4. Prerequisite — Cài đặt trước

```bash
# Cài Supabase CLI
npm install -g supabase

# Login
supabase login

# Link project
supabase link --project-ref <your-project-ref>
```

---

## PHẦN B — Triển khai từng bước

---

### Phase 1: Chuẩn bị Backend Project (Không ảnh hưởng Frontend)

#### Task 1.1: Khởi tạo Supabase project structure

```bash
mkdir flutter_music_backend
cd flutter_music_backend
supabase init
```

Kết quả:
```
flutter_music_backend/
├── supabase/
│   ├── config.toml
│   ├── migrations/       # SQL migrations
│   ├── functions/        # Edge Functions
│   └── seed.sql          # Seed data
├── .gitignore
└── README.md
```

- [ ] Tạo repo mới `flutter_music_backend`
- [ ] Chạy `supabase init`
- [ ] Link với project hiện tại: `supabase link`

#### Task 1.2: Export schema hiện tại thành migrations

Chuyển `DATA_APP/database/schema.sql` thành migrations có version:

```
supabase/migrations/
├── 20260504000001_create_core_tables.sql        # profiles, songs, artists, albums
├── 20260504000002_create_junction_tables.sql     # song_artists, song_genres, etc.
├── 20260504000003_create_user_activity_tables.sql # favorites, listens, follows
├── 20260504000004_create_playlist_tables.sql     # playlists, playlist_songs
├── 20260504000005_create_podcast_tables.sql      # podcasts, channels, subscriptions
├── 20260504000006_create_discovery_tables.sql    # genres, moods, hashtags, home_*
├── 20260504000007_create_rpc_functions.sql       # All 30+ RPC functions
├── 20260504000008_create_views.sql               # All 20+ views
├── 20260504000009_create_rls_policies.sql        # RLS policies
├── 20260504000010_create_triggers.sql            # Cache update triggers
└── 20260504000011_seed_data.sql                  # Initial data
```

- [ ] Tách `schema.sql` (141KB) thành các migration files riêng biệt
- [ ] Tách `data.sql` (274KB) thành `seed.sql`
- [ ] Test: `supabase db reset` phải tái tạo được toàn bộ database

#### Task 1.3: Tổ chức Storage policies

```sql
-- File: migrations/20260504000012_storage_policies.sql
-- Tạo buckets + policies cho từng bucket
```

- [ ] Document tất cả 9 buckets và policies hiện tại
- [ ] Viết migration cho storage setup

#### Task 1.4: Fix security issues

```sql
-- File: migrations/20260504000013_fix_security.sql

-- 1. Bật RLS cho podcast_favorites
ALTER TABLE public.podcast_favorites ENABLE ROW LEVEL SECURITY;

-- 2. Revoke anon access cho các functions cần auth
REVOKE EXECUTE ON FUNCTION public.like_song FROM anon;
REVOKE EXECUTE ON FUNCTION public.follow_artist FROM anon;
-- ... (tất cả 30+ functions)

-- 3. Chuyển views sang SECURITY INVOKER
ALTER VIEW public.v_songs_for_app SET (security_invoker = true);
-- ... (tất cả 20+ views)
```

- [ ] Bật RLS cho `podcast_favorites`
- [ ] Revoke `anon` EXECUTE trên tất cả user-specific functions
- [ ] Chuyển views sang `SECURITY INVOKER`
- [ ] Test lại toàn bộ auth flow

---

### Phase 2: Tạo API Layer (Edge Functions)

#### Task 2.1: Thiết kế API endpoints

| Method | Endpoint | Thay thế cho | Priority |
|---|---|---|---|
| GET | `/api/songs/trending` | `song_repository.fetchTrendingSongs()` | 🔴 High |
| GET | `/api/songs/:id` | `song_repository.getSongById()` | 🔴 High |
| GET | `/api/songs/random` | `song_repository.fetchRandomSong()` | 🟡 Medium |
| GET | `/api/artists` | `artist_repository.fetchPopularArtists()` | 🔴 High |
| GET | `/api/artists/:id` | `artist_repository.getArtistDetail()` | 🔴 High |
| GET | `/api/artists/:id/songs` | `artist_repository.getArtistSongs()` | 🔴 High |
| GET | `/api/artists/:id/albums` | `artist_repository.getArtistAlbums()` | 🟡 Medium |
| GET | `/api/albums/new` | `collection_repository.fetchNewAlbums()` | 🟡 Medium |
| GET | `/api/playlists/system` | `collection_repository.fetchSystemPlaylists()` | 🟡 Medium |
| GET | `/api/playlists/:id/songs` | `collection_repository.fetchPlaylistSongs()` | 🔴 High |
| GET | `/api/albums/:id/songs` | `collection_repository.fetchAlbumSongs()` | 🔴 High |
| GET | `/api/search?q=...` | `search_repository.search*()` | 🔴 High |
| GET | `/api/search/trending` | `search_repository.getTrendingKeywords()` | 🟢 Low |
| GET | `/api/podcasts` | `podcast_repository.fetchAllPodcasts()` | 🟡 Medium |
| GET | `/api/podcasts/channels` | `podcast_repository.fetchChannels()` | 🟡 Medium |
| POST | `/api/player/state` | `player_repository.updatePlayerState()` | 🟡 Medium |
| POST | `/api/player/listen` | `player_repository.logListen()` | 🟡 Medium |
| POST | `/api/favorites/toggle` | `favorite_repository.toggleFavorite()` | 🔴 High |
| POST | `/api/follows/toggle` | `follow_repository.toggleFollow()` | 🟡 Medium |
| GET | `/api/library/playlists` | `playlist_repository.fetchUserPlaylists()` | 🔴 High |
| POST | `/api/library/playlists` | `playlist_repository.createPlaylist()` | 🟡 Medium |

- [ ] Finalize API design
- [ ] Tạo OpenAPI/Swagger spec (optional nhưng khuyến nghị)

#### Task 2.2: Implement Edge Functions (theo priority)

Ví dụ Edge Function cho `/api/songs/trending`:

```typescript
// supabase/functions/api/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // GET /api/songs/trending
  if (url.pathname === "/api/songs/trending") {
    const { data, error } = await supabase
      .from("songs")
      .select("*")
      .eq("is_active", true)
      .order("like_count_cache", { ascending: false })
      .limit(50);

    return new Response(JSON.stringify({ data, error }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response("Not found", { status: 404 });
});
```

- [ ] Implement **High priority** endpoints trước (7 endpoints)
- [ ] Implement **Medium priority** endpoints (9 endpoints)
- [ ] Implement **Low priority** endpoints (còn lại)
- [ ] Deploy: `supabase functions deploy api`

#### Task 2.3: Unified Search endpoint

```typescript
// Gộp 4 queries search hiện tại thành 1 endpoint duy nhất
// GET /api/search?q=love&types=songs,artists,albums,playlists,podcasts

// Sử dụng Promise.allSettled để parallel query
const [songs, artists, albums, playlists, podcasts] = await Promise.allSettled([
  supabase.from("songs").select("*").ilike("title", `%${q}%`).limit(20),
  supabase.from("artists").select("*").ilike("name", `%${q}%`).limit(20),
  // ...
]);
```

- [ ] Implement unified search endpoint
- [ ] Thêm full-text search nếu cần (`to_tsvector`)

---

### Phase 3: Refactor Frontend (Flutter)

#### Task 3.1: Tạo API client service

```dart
// lib/services/api_client.dart
class ApiClient {
  final String baseUrl;
  final Dio _dio;

  ApiClient({required this.baseUrl}) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  // Tự động attach auth token
  Future<void> setAuthToken(String? token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) {
    return _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }
}
```

- [ ] Tạo `ApiClient` class với Dio
- [ ] Tạo provider: `apiClientProvider`
- [ ] Config base URL từ `.env`

#### Task 3.2: Refactor repositories (từng cái một)

**Chiến lược**: Refactor 1 repository tại 1 thời điểm, test xong mới chuyển cái tiếp theo.

**Thứ tự refactor** (theo dependency + priority):

| # | Repository | Lý do ưu tiên |
|---|---|---|
| 1 | `song_repository.dart` | Core — mọi screen đều dùng |
| 2 | `artist_repository.dart` | Home + Detail screens |
| 3 | `collection_repository.dart` | Playlist + Album detail |
| 4 | `search_repository.dart` | Search screen |
| 5 | `favorite_repository.dart` | Like/unlike |
| 6 | `follow_repository.dart` | Follow artists |
| 7 | `player_repository.dart` | Player state sync |
| 8 | `playlist_repository.dart` | User playlists |
| 9 | `podcast_repository.dart` | Podcast features |
| 10 | `lyrics_repository.dart` | Lyrics (có thể giữ direct Supabase Storage) |
| 11 | `auth_repository.dart` | Giữ Supabase Auth trực tiếp |
| 12 | `offline_repository.dart` | Local only — không cần đổi |

Ví dụ refactor `song_repository.dart`:

```dart
// TRƯỚC (direct Supabase)
class SongRepository {
  final SupabaseClient _supabase;
  SongRepository(this._supabase);

  Future<List<Song>> fetchTrendingSongs({int limit = 50}) async {
    final response = await _supabase
        .from('songs').select().eq('is_active', true)
        .order('like_count_cache', ascending: false).limit(limit);
    return (response as List).map((e) => Song.fromJson(e)).toList();
  }
}

// SAU (through API)
class SongRepository {
  final ApiClient _api;
  SongRepository(this._api);

  Future<List<Song>> fetchTrendingSongs({int limit = 50}) async {
    final response = await _api.get('/api/songs/trending', params: {'limit': limit});
    return (response.data['data'] as List).map((e) => Song.fromJson(e)).toList();
  }
}
```

- [ ] Refactor `song_repository.dart` → test
- [ ] Refactor `artist_repository.dart` → test
- [ ] Refactor `collection_repository.dart` → test
- [ ] Refactor `search_repository.dart` → test
- [ ] Refactor `favorite_repository.dart` → test
- [ ] Refactor `follow_repository.dart` → test
- [ ] Refactor `player_repository.dart` → test
- [ ] Refactor `playlist_repository.dart` → test
- [ ] Refactor `podcast_repository.dart` → test
- [ ] Giữ nguyên `auth_repository.dart` (Supabase Auth trực tiếp)
- [ ] Giữ nguyên `lyrics_repository.dart` (Supabase Storage trực tiếp)
- [ ] Giữ nguyên `offline_repository.dart` (local only)

#### Task 3.3: Cập nhật supabase_provider.dart

```dart
// TRƯỚC: Tất cả repos nhận SupabaseClient
final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepository(ref.watch(supabaseClientProvider));
});

// SAU: Repos API nhận ApiClient, repos auth/storage giữ Supabase
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: dotenv.env['API_BASE_URL']!);
});

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepository(ref.watch(apiClientProvider));
});

// Giữ nguyên cho auth + storage
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
```

- [ ] Tạo `apiClientProvider`
- [ ] Cập nhật tất cả repository providers
- [ ] Xóa `artistRepositoryProvider` trùng lặp trong `artist_repository.dart`

#### Task 3.4: Cập nhật .env

```env
# TRƯỚC
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx

# SAU — thêm API URL
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
API_BASE_URL=https://xxx.supabase.co/functions/v1
```

- [ ] Thêm `API_BASE_URL` vào `.env`
- [ ] Cập nhật `.env.example`

#### Task 3.5: Dọn dẹp Frontend

- [ ] Xóa thư mục `DATA_APP/database/` (đã chuyển sang backend repo)
- [ ] Xóa `database.sql`, `database_migration_recent_search.sql` ở root
- [ ] Cập nhật `README.md` — chỉ giữ phần Frontend
- [ ] Cập nhật `.gitignore`

---

### Phase 4: Testing & Documentation

#### Task 4.1: Test Backend

- [ ] `supabase db reset` — đảm bảo migrations chạy đúng
- [ ] Test từng Edge Function endpoint bằng `curl` hoặc Postman
- [ ] Test auth flow (register → login → access protected endpoint)
- [ ] Test RLS policies (user A không thấy data của user B)

#### Task 4.2: Test Frontend

- [ ] Test Home screen load data qua API
- [ ] Test Search hoạt động
- [ ] Test Player (play, pause, next, previous)
- [ ] Test Auth flow (login, register, guest mode)
- [ ] Test Library (liked songs, playlists, followed artists)
- [ ] Test Podcast
- [ ] Test Offline downloads (vẫn hoạt động)

#### Task 4.3: Documentation

- [ ] Backend README: setup guide, API docs, migration guide
- [ ] Frontend README: setup guide, .env config, build commands
- [ ] API documentation (endpoints, request/response format)

---

## Cấu trúc thư mục cuối cùng

```
# Repo 1: flutter_music_backend
flutter_music_backend/
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   │   ├── 20260504000001_create_core_tables.sql
│   │   ├── 20260504000002_create_junction_tables.sql
│   │   ├── ...
│   │   └── 20260504000013_fix_security.sql
│   ├── functions/
│   │   └── api/
│   │       └── index.ts
│   └── seed.sql
├── docs/
│   └── api.md
├── .gitignore
└── README.md

# Repo 2: flutter_music_app (giữ tên cũ)
flutter_music_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   ├── models/
│   ├── providers/
│   ├── repositories/    # Giờ gọi API thay vì direct Supabase
│   ├── services/
│   │   ├── api_client.dart   # MỚI
│   │   ├── audio_handler.dart
│   │   ├── download_service.dart
│   │   └── share_service.dart
│   ├── screens/
│   └── widgets/
├── assets/
├── .env
├── pubspec.yaml
└── README.md
```

---

## Timeline ước tính

| Phase | Thời gian | Ghi chú |
|---|---|---|
| **Phase 1**: Chuẩn bị Backend | 2-3 ngày | Không ảnh hưởng app đang chạy |
| **Phase 2**: Edge Functions | 3-5 ngày | Deploy song song, app vẫn dùng direct |
| **Phase 3**: Refactor Frontend | 5-7 ngày | Chuyển từng repo, test từng cái |
| **Phase 4**: Testing & Docs | 2-3 ngày | End-to-end testing |
| **Tổng** | **~2-3 tuần** | Làm part-time |

---

## Lưu ý quan trọng

1. **Không cần downtime**: Mọi thay đổi đều backward compatible — app cũ vẫn chạy song song với API mới
2. **Auth giữ nguyên**: Supabase Auth hoạt động trực tiếp từ Flutter, không cần proxy
3. **Storage giữ nguyên**: Signed URLs cho audio/image vẫn từ Supabase Storage trực tiếp
4. **Edge Functions miễn phí**: 500K invocations/tháng trên Free tier — đủ cho development
5. **Có thể làm dần**: Không bắt buộc chuyển hết 1 lần — có thể mix direct + API
