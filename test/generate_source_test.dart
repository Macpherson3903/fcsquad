import 'package:fc_squad/services/generate_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenerateSource.parseNames', () {
    test('strips numbering and returns uppercase names', () {
      expect(
        GenerateSource.parseNames('1. alex\n2. jordan\n• casey'),
        ['ALEX', 'JORDAN', 'CASEY'],
      );
    });

    test('returns an empty list for blank input', () {
      expect(GenerateSource.parseNames('  \n  '), isEmpty);
    });
  });

  group('GenerateSource.namesToGenerate', () {
    test('prefers pasted names over the saved roster', () {
      expect(
        GenerateSource.namesToGenerate(
          pastedNames: ['ALEX'],
          rosterNames: ['SAM', 'LEO'],
        ),
        ['ALEX'],
      );
    });

    test('falls back to the saved roster when nothing is pasted', () {
      expect(
        GenerateSource.namesToGenerate(
          pastedNames: const [],
          rosterNames: ['SAM', 'LEO'],
        ),
        ['SAM', 'LEO'],
      );
    });

    test('returns null when both paste and roster are empty', () {
      expect(
        GenerateSource.namesToGenerate(
          pastedNames: const [],
          rosterNames: const [],
        ),
        isNull,
      );
    });
  });
}
