import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'app_theme.dart';

DateTime? _lastNavTime;

extension AppUIExtension on BuildContext {
  void showSuccess(String message, {SnackBarAction? action}) {
    _showSnackBar(
      message: message,
      icon: LucideIcons.checkCircle,
      color: AppTheme.primary,
      action: action,
    );
  }

  void showError(String message, {SnackBarAction? action}) {
    _showSnackBar(
      message: message,
      icon: LucideIcons.alertCircle,
      color: Colors.red[700]!,
      action: action,
    );
  }

  void showInfo(String message, {SnackBarAction? action}) {
    _showSnackBar(
      message: message,
      icon: LucideIcons.info,
      color: AppTheme.surfaceHighlight,
      action: action,
    );
  }

  void showWarning(String message, {SnackBarAction? action}) {
    _showSnackBar(
      message: message,
      icon: LucideIcons.alertTriangle,
      color: Colors.orange[700]!,
      action: action,
    );
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color color,
    SnackBarAction? action,
  }) {
    // Force immediate dismissal of any previous snackbars
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).clearSnackBars();
    
    final messenger = ScaffoldMessenger.of(this);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: action,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        margin: const EdgeInsets.all(AppSpacing.m),
      ),
    );

    // Guaranteed Hard Dismiss after 3.2s just in case
    Future.delayed(const Duration(milliseconds: 3200), () {
      try {
        messenger.hideCurrentSnackBar();
      } catch (_) {
        // Context might be gone, safe to ignore
      }
    });
  }

  // Helper for responsive checks
  bool get isSmallScreen => MediaQuery.of(this).size.width < 360;
  bool get isTablet => MediaQuery.of(this).size.width >= 600;

  /// Safely push a new route with a debounce to prevent double-navigation.
  void pushSafe(String location, {Object? extra}) {
    final now = DateTime.now();
    if (_lastNavTime != null && 
        now.difference(_lastNavTime!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastNavTime = now;
    push(location, extra: extra);
  }
}
