import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/auth_provider.dart';

class UserAvatar extends ConsumerWidget {
  final VoidCallback? onTap;

  const UserAvatar({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value?.session?.user;
    final profile = ref.watch(profileProvider).value;

    return GestureDetector(
      onTap: onTap ?? () {
        Scaffold.of(context).openDrawer();
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildAvatar(user, profile),
      ),
    );
  }

  Widget _buildAvatar(dynamic user, dynamic profile) {
    if (user == null) {
      // Guest mode
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    final avatarUrl = profile?.avatarUrl;
    final displayName = profile?.displayName ?? 'User';

    if (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('https://ui-avatars.com')) {
      return CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
      );
    }

    // Fallback or explicit initials
    final firstLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    
    // Hash string to color
    final int hash = displayName.hashCode;
    final Color color = Color.fromARGB(
      255,
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      (hash & 0x0000FF),
    ).withOpacity(0.8);

    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        firstLetter,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
