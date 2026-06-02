enum MobileOcrScript { auto, korean, latin }

class MobileOcrLine {
  const MobileOcrLine({required this.text});

  final String text;
}

class MobileOcrResult {
  const MobileOcrResult({
    required this.text,
    required this.lines,
    required this.script,
    required this.processingMs,
    required this.sourcePath,
  });

  final String text;
  final List<MobileOcrLine> lines;
  final MobileOcrScript script;
  final int processingMs;
  final String sourcePath;
}
