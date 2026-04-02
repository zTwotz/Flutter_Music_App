import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

import '../core/app_ui_utils.dart';

class GuestGuard {
  /// Works from both ConsumerWidget (WidgetRef) and Notifier (Ref).
  static bool ensureAuthenticated(BuildContext context, dynamic ref, {String? message}) {
    final user = ref.read(authStateProvider).value?.session?.user;

    if (user == null) {
      context.showInfo(
        message ?? 'Vui lòng đăng nhập để thực hiện hành động này.',
        action: SnackBarAction(
          label: 'ĐĂNG NHẬP',
          textColor: Colors.white,
          onPressed: () => context.push('/login'),
        ),
      );
      return false;
    }
    return true;
  }
}
