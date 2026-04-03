import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;
  final Function(String) onSubmitted;
  final ValueChanged<String>? onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onClear,
    required this.onSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: Colors.black, 
          fontSize: 16, 
          fontWeight: FontWeight.w500,
          decorationThickness: 0,
        ),
        cursorColor: Colors.black,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Bạn muốn nghe gì?',
          hintStyle: TextStyle(
            color: Colors.grey[600], 
            fontSize: 16, 
            fontWeight: FontWeight.w500
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(LucideIcons.search, color: Colors.black.withOpacity(0.8), size: 24),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.black54, size: 20),
                  onPressed: onClear,
                  splashRadius: 24,
                )
              : const SizedBox(width: 48), // Preserve space to prevent jumping
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
