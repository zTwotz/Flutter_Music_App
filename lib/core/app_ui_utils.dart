import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'app_theme.dart';

extension AppUIExtension on BuildContext {
  void showSuccess(String message) {
    _showSnackBar(
      message: message,
      icon: LucideIcons.checkCircle,
      color: AppTheme.primary,
    );
  }

  void showError(String message) {
    _showSnackBar(
      message: message,
      icon: LucideIcons.alertCircle,
      color: Colors.red[700]!,
    );
  }

  void showInfo(String message) {
    _showSnackBar(
      message: message,
      icon: LucideIcons.info,
      color: AppTheme.surfaceHighlight,
    );
  }

  void showWarning(String message) {
    _showSnackBar(
      message: message,
      icon: LucideIcons.alertTriangle,
      color: Colors.orange[700]!,
    );
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        margin: const EdgeInsets.all(AppSpacing.m),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Helper for responsive checks
  bool get isSmallScreen => MediaQuery.of(this).size.width < 360;
  bool get isTablet => MediaQuery.of(this).size.width >= 600;
}
