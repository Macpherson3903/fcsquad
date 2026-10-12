import 'package:fc_squad/models/player.dart';
import 'package:fc_squad/services/demo_roster.dart';
import 'package:fc_squad/services/generate_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DemoRoster.shouldSeed', () {
    test('seeds only on first launch when the roster is empty', () {
      expect(
        DemoRoster.shouldSeed(alreadySeeded: false, rosterIsEmpty: true),
        isTrue,
      );
    });

    test('does not seed when the user already has players', () {
      expect(
        DemoRoster.shouldSeed(alreadySeeded: false, rosterIsEmpty: false),
        isFalse,
      );
    });

    test('does not re-seed after the user clears the squad', () {
      expect(
        DemoRoster.shouldSeed(alreadySeeded: true, rosterIsEmpty: true),
        isFalse,
      );
    });
  });

  group('DemoRoster.buildPlayers', () {
    test('ships six sample players with even DEF/MID/FWD counts', () {
      final players = DemoRoster.buildPlayers();

      expect(players, hasLength(6));
      expect(
        players.where((p) => p.positions.first == PlayerPosition.def),
        hasLength(2),
      );
      expect(
        players.where((p) => p.positions.first == PlayerPosition.mid),
        hasLength(2),
      );
      expect(
        players.where((p) => p.positions.first == PlayerPosition.fwd),
        hasLength(2),
      );
    });

    test('splits evenly across the default team count so review is not blocked', () {
      final players = DemoRoster.buildPlayers();
      expect(
        players.length % GenerateSource.defaultTeamCount,
        0,
      );
      for (final position in PlayerPosition.values) {
        final count =
            players.where((p) => p.positions.first == position).length;
        expect(count % GenerateSource.defaultTeamCount, 0);
      }
    });

    test('uses stable ids so reinstalls do not duplicate demo rows', () {
      final ids = DemoRoster.buildPlayers().map((p) => p.id).toSet();
      expect(ids, hasLength(6));
      expect(ids.every((id) => id.startsWith('demo-')), isTrue);
    });
  });
}
