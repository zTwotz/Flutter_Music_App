import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/supabase_provider.dart';
import '../core/app_theme.dart';
import 'user_avatar.dart';

class UserDrawer extends ConsumerWidget {
  const UserDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value?.session?.user;
    final profile = ref.watch(profileProvider).value;

    final isLoggedIn = user != null;
    final displayName = profile?.displayName ?? (isLoggedIn ? 'Tài khoản' : 'Chưa đăng nhập');
    final email = user?.email ?? 'Chưa có email';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: UserAvatar(onTap: () {}),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(LucideIcons.userPlus),
              title: const Text('Thêm tài khoản'),
              onTap: () {
                Navigator.pop(context);
                context.push('/login');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.zap),
              title: const Text('Có gì mới'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(LucideIcons.clock),
              title: const Text('Gần đây'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(LucideIcons.settings),
              title: const Text('Cài đặt và quyền riêng tư'),
              onTap: () {},
            ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: isLoggedIn
                    ? OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close Drawer
                          await ref.read(authRepositoryProvider).signOut();
                          if (context.mounted) {
                            context.push('/login');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        child: const Text('Đăng xuất'),
                      )
                    : OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close Drawer
                          context.push('/login');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                        ),
                        child: const Text('Đăng nhập'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
