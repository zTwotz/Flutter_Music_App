import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';

class GuestGuard {
  /// Works from both ConsumerWidget (WidgetRef) and Notifier (Ref).
  static bool ensureAuthenticated(BuildContext context, dynamic ref, {String? message}) {
    final user = ref.read(authStateProvider).value?.session?.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Vui lòng đăng nhập để thực hiện hành động này.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primary,
          action: SnackBarAction(
            label: 'ĐĂNG NHẬP',
            textColor: Colors.white,
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return false;
    }
    return true;
  }
}
