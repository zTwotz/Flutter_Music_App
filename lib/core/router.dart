import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/artist.dart';
import '../models/podcast.dart';
import '../models/collection_item.dart';
import '../screens/main_screen.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/library_screen.dart';
import '../screens/liked_songs_screen.dart';
import '../screens/player_screen.dart';
import '../screens/collection_detail_screen.dart';
import '../screens/artist_detail_screen.dart';
import '../screens/podcast_detail_screen.dart';
import '../screens/podcast_channel_screen.dart';
import '../screens/create_playlist_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/reset_password_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // ── Auth routes (no shell / no bottom nav) ─────────────────────────────
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final email = state.extra as String? ?? '';
        return OtpVerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),

    // ── Full-screen routes (no shell) ──────────────────────────────────────
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/player',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const PlayerScreen(),
        transitionsBuilder: (context, animation, secondary, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/playlist/:id',
      builder: (context, state) {
        final playlistItem = state.extra as CollectionItem;
        return CollectionDetailScreen(item: playlistItem);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/album/:id',
      builder: (context, state) {
        final albumItem = state.extra as CollectionItem;
        return CollectionDetailScreen(item: albumItem);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/artist/:id',
      builder: (context, state) {
        final artist = state.extra as Artist;
        return ArtistDetailScreen(artist: artist);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/podcast/:id',
      builder: (context, state) {
        final podcast = state.extra as Podcast;
        return PodcastDetailScreen(podcast: podcast);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/podcast-channel/:id',
      builder: (context, state) {
        final channelId = state.pathParameters['id']!;
        return PodcastChannelScreen(channelId: channelId);
      },
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/liked-songs',
      builder: (context, state) => const LikedSongsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: '/create-playlist',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const CreatePlaylistScreen(),
        transitionsBuilder: (context, animation, secondary, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    ),

    // ── Shell (with bottom nav) ────────────────────────────────────────────
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        return MainScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryScreen(),
        ),
      ],
    ),
  ],
);
