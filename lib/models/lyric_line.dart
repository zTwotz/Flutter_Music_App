class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});

  @override
  String toString() => 'LyricLine(time: $time, text: $text)';
}
