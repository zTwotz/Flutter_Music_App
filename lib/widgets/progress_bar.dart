import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_theme.dart';
import '../providers/player_provider.dart';

class ProgressBar extends ConsumerStatefulWidget {
  final Duration position;
  final Duration duration;

  const ProgressBar({super.key, required this.position, required this.duration});

  @override
  ConsumerState<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends ConsumerState<ProgressBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = widget.duration.inMilliseconds.toDouble();
    final effectivePosition = _dragValue ?? widget.position.inMilliseconds.toDouble().clamp(0.0, effectiveDuration > 0 ? effectiveDuration : 1.0);
    final displayDuration = effectiveDuration > 0 ? effectiveDuration : 1.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
          child: Slider(
            min: 0,
            max: displayDuration,
            value: effectivePosition.clamp(0.0, displayDuration),
            onChanged: (val) {
              setState(() {
                _dragValue = val;
              });
            },
            onChangeEnd: (val) {
              ref.read(audioHandlerProvider).seek(Duration(milliseconds: val.toInt()));
              setState(() {
                _dragValue = null;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(Duration(milliseconds: effectivePosition.toInt())), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(_formatDuration(widget.duration), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
