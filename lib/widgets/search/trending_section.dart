import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class TrendingSection extends StatelessWidget {
  final List<String>? trendingKeywords;
  final Function(String) onKeywordTap;

  const TrendingSection({
    super.key,
    this.trendingKeywords,
    required this.onKeywordTap,
  });

  @override
  Widget build(BuildContext context) {
    // If no real data is passed, use placeholder data per requirement
    final keywords = (trendingKeywords != null) ? trendingKeywords! : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: const Text(
            'Gợi ý cho bạn',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            children: keywords.map((k) => _buildKeywordChip(k)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordChip(String keyword) {
    return GestureDetector(
      onTap: () => onKeywordTap(keyword),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Text(
          keyword,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}
