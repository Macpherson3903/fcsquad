/// Pure helpers for the GENERATE tab: parse a pasted list and decide which
/// names to send into role assignment.
class GenerateSource {
  GenerateSource._();

  /// Default team count matches the first-launch demo roster (6 players, 2-2-2)
  /// so a reviewer can tap GENERATE TEAMS without a position-imbalance dialog.
  static const int defaultTeamCount = 2;

  static List<String> parseNames(String text) {
    if (text.trim().isEmpty) return [];
    final lines = text.split('\n');
    final scrubRegex = RegExp(r'^[\s\d\.\-\*\•\)\>]+');
    final names = <String>[];
    for (final line in lines) {
      final cleaned = line.replaceFirst(scrubRegex, '').trim();
      if (cleaned.isNotEmpty) {
        names.add(cleaned.toUpperCase());
      }
    }
    return names;
  }

  /// Pasted names win. Otherwise use the saved MY SQUAD roster.
  /// Returns null when neither source has anyone to generate from.
  static List<String>? namesToGenerate({
    required List<String> pastedNames,
    required List<String> rosterNames,
  }) {
    if (pastedNames.isNotEmpty) return pastedNames;
    if (rosterNames.isNotEmpty) return rosterNames;
    return null;
  }
}
