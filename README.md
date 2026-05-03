# 🎵 Flutter Music App

Ứng dụng nghe nhạc và podcast đa nền tảng được xây dựng bằng **Flutter** và **Supabase**, lấy cảm hứng từ giao diện của Spotify. Hỗ trợ chạy trên **Web**, **Android**, **iOS**, **macOS**, **Linux** và **Windows**.

---

## 📋 Mục lục

- [Tổng quan](#-tổng-quan)
- [Tính năng](#-tính-năng)
- [Công nghệ sử dụng](#-công-nghệ-sử-dụng)
- [Kiến trúc dự án](#-kiến-trúc-dự-án)
- [Yêu cầu hệ thống](#-yêu-cầu-hệ-thống)
- [Cài đặt & Chạy dự án](#-cài-đặt--chạy-dự-án)
- [Cơ sở dữ liệu](#-cơ-sở-dữ-liệu)
- [Cấu trúc thư mục](#-cấu-trúc-thư-mục)
- [Đổi Logo ứng dụng](#-đổi-logo-ứng-dụng)
- [Tác giả](#-tác-giả)

---

## 🎯 Tổng quan

**Flutter Music App** là một ứng dụng nghe nhạc trực tuyến hoàn chỉnh với các chức năng:
- Stream nhạc và podcast trực tuyến từ Supabase Storage
- Hệ thống tài khoản người dùng với xác thực qua email
- Thư viện cá nhân, playlist tùy chỉnh và bài hát yêu thích
- Giao diện tối (Dark Mode) hiện đại, mượt mà với hiệu ứng động

---

## ✨ Tính năng

### 🎶 Âm nhạc
- Phát nhạc trực tuyến với trình phát toàn màn hình
- Hiển thị lời bài hát đồng bộ theo thời gian thực (LRC format)
- Tìm kiếm bài hát theo **tên**, **thể loại**, **tâm trạng**, **hashtag**
- Xem chi tiết nghệ sĩ, album và danh sách bài hát liên quan
- Chế độ phát: Shuffle, Lặp lại (một bài / tất cả)
- Tải nhạc về thiết bị để nghe ngoại tuyến (Offline)

### 🎙️ Podcast
- Duyệt và nghe podcast theo kênh (Channel)
- Theo dõi kênh podcast yêu thích
- Hiển thị tập mới từ các kênh đã đăng ký

### 📚 Thư viện cá nhân
- Bài hát đã thích (Liked Songs)
- Tạo và quản lý playlist riêng
- Lưu playlist của hệ thống
- Theo dõi nghệ sĩ yêu thích
- Lịch sử nghe gần đây

### 🔍 Tìm kiếm
- Tìm kiếm đa thực thể: Bài hát, Nghệ sĩ, Album, Playlist, Podcast
- Từ khóa thịnh hành (Trending)
- Gợi ý tìm kiếm trực tiếp (Live Suggestions)
- Duyệt theo thể loại và tâm trạng

### 👤 Tài khoản
- Đăng ký / Đăng nhập bằng email
- Quên mật khẩu với xác thực OTP
- Chế độ khách (Guest) - nghe nhạc không cần đăng nhập

---

## 🛠️ Công nghệ sử dụng

| Thành phần | Công nghệ |
|---|---|
| **Framework** | Flutter (Dart) |
| **State Management** | Riverpod |
| **Routing** | GoRouter |
| **Backend / Database** | Supabase (PostgreSQL) |
| **Authentication** | Supabase Auth |
| **Storage** | Supabase Storage |
| **Audio Player** | just_audio |
| **Image Caching** | cached_network_image |
| **HTTP Client** | Dio |
| **Icons** | Lucide Icons |
| **Fonts** | Google Fonts |
| **Animations** | flutter_animate |
| **Chia sẻ** | share_plus |
| **Environment** | flutter_dotenv |

---

## 🏗️ Kiến trúc dự án

Dự án sử dụng kiến trúc **Repository Pattern** kết hợp với **Riverpod** cho quản lý trạng thái:

```
┌─────────────────────────────────────────────────┐
│                    UI Layer                      │
│         (Screens, Widgets, Pages)                │
├─────────────────────────────────────────────────┤
│                Provider Layer                    │
│     (Riverpod Providers & Notifiers)             │
├─────────────────────────────────────────────────┤
│              Repository Layer                    │
│   (Data access, API calls, Business logic)       │
├─────────────────────────────────────────────────┤
│              Service Layer                       │
│    (Audio Handler, Download, Share, ...)         │
├─────────────────────────────────────────────────┤
│                Data Layer                        │
│        (Supabase Client, Models)                 │
└─────────────────────────────────────────────────┘
```

---

## 💻 Yêu cầu hệ thống

- **Flutter SDK**: >= 3.10.7
- **Dart SDK**: >= 3.10.7
- **Supabase Account**: Cần tạo project trên [supabase.com](https://supabase.com)
- **IDE**: VS Code hoặc Android Studio (khuyến nghị VS Code)
- **Git**: Để clone dự án

### Nền tảng hỗ trợ
- ✅ Web (Chrome, Edge, Firefox)
- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ✅ macOS
- ✅ Linux
- ✅ Windows

---

## 🚀 Cài đặt & Chạy dự án

### 1. Clone dự án

```bash
git clone https://github.com/zTwotz/Flutter_Music_App.git
cd Flutter_Music_App
```

### 2. Cấu hình môi trường

Tạo file `.env` tại thư mục gốc của dự án:

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

> ⚠️ **Lưu ý**: File `.env` chứa thông tin nhạy cảm, không được push lên GitHub. File này đã được thêm vào `.gitignore`.

### 3. Cài đặt dependencies

```bash
flutter pub get
```

### 4. Chạy ứng dụng

```bash
# Chạy trên Chrome (Web)
flutter run -d chrome

# Chạy trên thiết bị Android đang kết nối
flutter run -d android

# Chạy trên iOS Simulator
flutter run -d ios

# Chạy trên macOS
flutter run -d macos
```

### 5. Lệnh nhanh (Clean build)

Nếu gặp lỗi build hoặc muốn build sạch:

```bash
flutter clean && flutter pub get && flutter run -d chrome
```

### 6. Build bản Release

```bash
# Build Web
flutter build web

# Build APK (Android)
flutter build apk

# Build iOS
flutter build ios
```

---

## 🗃️ Cơ sở dữ liệu

Dự án sử dụng **Supabase** (PostgreSQL) với các nhóm bảng chính:

### Bảng dữ liệu chính
| Bảng | Mô tả |
|---|---|
| `profiles` | Thông tin người dùng |
| `songs` | Danh sách bài hát |
| `artists` | Thông tin nghệ sĩ |
| `albums` | Album nhạc |
| `playlists` | Danh sách phát |
| `podcasts` | Tập podcast |
| `podcast_channels` | Kênh podcast |
| `genres` | Thể loại nhạc |
| `moods` | Tâm trạng |
| `hashtags` | Hashtag phân loại |

### Bảng quan hệ (Junction Tables)
| Bảng | Mô tả |
|---|---|
| `song_artists` | Nghệ sĩ ↔ Bài hát |
| `song_genres` | Bài hát ↔ Thể loại |
| `song_moods` | Bài hát ↔ Tâm trạng |
| `song_hashtags` | Bài hát ↔ Hashtag |
| `album_artists` | Album ↔ Nghệ sĩ |
| `album_songs` | Album ↔ Bài hát |
| `playlist_songs` | Playlist ↔ Bài hát |

### Bảng hoạt động người dùng
| Bảng | Mô tả |
|---|---|
| `favorites` | Bài hát đã thích |
| `listens` | Lịch sử nghe |
| `user_followed_artists` | Nghệ sĩ đang theo dõi |
| `channel_subscriptions` | Kênh podcast đã đăng ký |
| `user_player_state` | Trạng thái trình phát |
| `user_saved_playlists` | Playlist đã lưu |
| `user_recent_items` | Mục đã xem gần đây |
| `user_recent_searches` | Lịch sử tìm kiếm |

### Supabase Storage Buckets
| Bucket | Mô tả |
|---|---|
| `song-files` | File nhạc MP3 |
| `song-covers` | Ảnh bìa bài hát |
| `artist-avatars` | Ảnh đại diện nghệ sĩ |
| `artist-covers` | Ảnh bìa nghệ sĩ |
| `album-covers` | Ảnh bìa album |
| `playlist-covers` | Ảnh bìa playlist |
| `podcast-files` | File podcast MP3 |
| `podcast-covers` | Ảnh bìa podcast |
| `lyrics-files` | File lời bài hát (.lrc) |

---

## 📁 Cấu trúc thư mục

```
flutter_music_app/
├── lib/
│   ├── main.dart                 # Entry point
│   ├── core/                     # Theme, Router, Utilities
│   │   ├── app_theme.dart        # Hệ thống màu sắc & typography
│   │   ├── router.dart           # Cấu hình GoRouter
│   │   ├── app_ui_utils.dart     # Tiện ích UI
│   │   ├── guest_guard.dart      # Kiểm tra quyền khách
│   │   └── player_utils.dart     # Tiện ích trình phát
│   ├── models/                   # Data Models
│   │   ├── song.dart
│   │   ├── artist.dart
│   │   ├── album.dart
│   │   ├── playlist.dart
│   │   ├── podcast.dart
│   │   ├── podcast_channel.dart
│   │   ├── profile.dart
│   │   └── ...
│   ├── providers/                # Riverpod Providers
│   │   ├── auth_provider.dart
│   │   ├── home_providers.dart
│   │   ├── player_provider.dart
│   │   ├── search_providers.dart
│   │   ├── supabase_provider.dart
│   │   └── ...
│   ├── repositories/             # Data Access Layer
│   │   ├── artist_repository.dart
│   │   ├── song_repository.dart
│   │   ├── search_repository.dart
│   │   ├── playlist_repository.dart
│   │   └── ...
│   ├── services/                 # Business Services
│   │   ├── audio_handler.dart    # Điều khiển audio
│   │   ├── download_service.dart # Tải nhạc offline
│   │   ├── artist_service.dart
│   │   └── share_service.dart
│   ├── screens/                  # Các màn hình
│   │   ├── home_screen.dart
│   │   ├── search_screen.dart
│   │   ├── library_screen.dart
│   │   ├── player_screen.dart
│   │   ├── artist_detail_screen.dart
│   │   ├── collection_detail_screen.dart
│   │   ├── auth/                 # Màn hình xác thực
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── ...
│   │   └── ...
│   └── widgets/                  # Widget tái sử dụng
│       ├── mini_player.dart
│       ├── song_list_item.dart
│       ├── playlist_card.dart
│       ├── artist_avatar_row.dart
│       ├── search/               # Widget tìm kiếm
│       └── ...
├── assets/
│   └── images/                   # Hình ảnh, logo
├── android/                      # Cấu hình Android
├── ios/                          # Cấu hình iOS
├── web/                          # Cấu hình Web
├── macos/                        # Cấu hình macOS
├── linux/                        # Cấu hình Linux
├── windows/                      # Cấu hình Windows
├── .env                          # Biến môi trường (không push lên git)
├── .gitignore                    # Danh sách file bỏ qua
├── pubspec.yaml                  # Cấu hình dependencies
└── README.md                     # Tài liệu dự án
```

---

## 🎨 Đổi Logo ứng dụng

1. Đặt file ảnh logo mới vào `assets/images/` (ví dụ: `my_logo.png`)
2. Mở file `pubspec.yaml`, tìm phần `flutter_launcher_icons` và sửa:
   ```yaml
   flutter_launcher_icons:
     android: "launcher_icon"
     ios: true
     image_path: "assets/images/my_logo.png"
     min_sdk_android: 21
   ```
3. Chạy lệnh:
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```
4. Gỡ app cũ và cài lại app mới để thấy logo mới.

---

## 👨‍💻 Tác giả

- **GitHub**: [zTwotz](https://github.com/zTwotz)

---

## 📄 Giấy phép

Dự án này được phát triển cho mục đích học tập và nghiên cứu.
