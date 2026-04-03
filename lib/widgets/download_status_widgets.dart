import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/app_theme.dart';

class DownloadStatusWidget extends StatelessWidget {
  final double? progress;
  final bool isDownloaded;
  final bool isError;
  final VoidCallback? onRetry;

  const DownloadStatusWidget({
    super.key,
    this.progress,
    this.isDownloaded = false,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isError) {
      return GestureDetector(
        onTap: onRetry,
        child: const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 20),
      );
    }

    if (progress != null && progress! < 1.0) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 2,
          backgroundColor: Colors.white10,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      );
    }

    if (isDownloaded) {
      return const Icon(LucideIcons.checkCircle2, color: Color(0xFF1DB954), size: 20);
    }

    return const SizedBox.shrink();
  }
}

class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.3), width: 0.5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.downloadCloud, color: Color(0xFF1DB954), size: 10),
          SizedBox(width: 4),
          Text(
            'OFFLINE',
            style: TextStyle(
              color: Color(0xFF1DB954),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
