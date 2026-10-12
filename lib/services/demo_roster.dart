import '../models/player.dart';
import '../storage/hive_storage.dart';

/// First-launch sample squad so App Review (and new users) see a working app
/// instead of three empty tabs.
///
/// Seeded once. Clearing the roster later does not re-insert these players.
class DemoRoster {
  DemoRoster._();

  static bool shouldSeed({
    required bool alreadySeeded,
    required bool rosterIsEmpty,
  }) {
    return !alreadySeeded && rosterIsEmpty;
  }

  static List<Player> buildPlayers() {
    return [
      _player('demo-def-1', 'SAM WALKER', PlayerPosition.def, 2),
      _player('demo-def-2', 'LEO MARTIN', PlayerPosition.def, 5),
      _player('demo-mid-1', 'JORDAN CHEN', PlayerPosition.mid, 8),
      _player('demo-mid-2', 'ALEX RIVERA', PlayerPosition.mid, 10),
      _player('demo-fwd-1', 'CASEY BROOKS', PlayerPosition.fwd, 9),
      _player('demo-fwd-2', 'RILEY ADAMS', PlayerPosition.fwd, 11),
    ];
  }

  static const List<({String name, int goals, int assists, int cleanSheets})>
  sampleStats = [
    (name: 'SAM WALKER', goals: 0, assists: 1, cleanSheets: 2),
    (name: 'LEO MARTIN', goals: 0, assists: 0, cleanSheets: 1),
    (name: 'JORDAN CHEN', goals: 1, assists: 2, cleanSheets: 0),
    (name: 'ALEX RIVERA', goals: 3, assists: 2, cleanSheets: 0),
    (name: 'CASEY BROOKS', goals: 4, assists: 1, cleanSheets: 0),
    (name: 'RILEY ADAMS', goals: 2, assists: 1, cleanSheets: 0),
  ];

  static Player _player(
    String id,
    String name,
    PlayerPosition position,
    int number,
  ) {
    final stats = sampleStats.firstWhere((s) => s.name == name);
    return Player(
      id: id,
      name: name,
      positions: [position],
      number: number,
      goals: stats.goals,
      assists: stats.assists,
      cleanSheets: stats.cleanSheets,
    );
  }

  /// Writes the sample squad once, after Hive is open.
  static Future<void> persistIfNeeded() async {
    final alreadySeeded = HiveStorage.getHasSeededDemoRoster();
    final players = HiveStorage.loadPlayers();
    if (shouldSeed(alreadySeeded: alreadySeeded, rosterIsEmpty: players.isEmpty)) {
      await HiveStorage.savePlayers(buildPlayers());
      for (final stat in sampleStats) {
        await HiveStorage.archiveStatsForPlayer(
          stat.name,
          stat.goals,
          stat.assists,
          stat.cleanSheets,
        );
      }
    }
    if (!alreadySeeded) {
      await HiveStorage.setHasSeededDemoRoster(true);
    }
  }
}
