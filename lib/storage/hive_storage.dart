import 'package:hive_flutter/hive_flutter.dart';
import '../models/player.dart';
import '../models/match_history.dart';

const _kBoxName = 'players';
const _kHistoryBoxName = 'history';
const _kStatsArchiveBoxName = 'stats_archive';
const _kMetadataBoxName = 'metadata';
const _kRosterCreatedAtKey = 'roster_created_at';

const _kHasSeenOnboardingKey = 'has_seen_onboarding';
const _kHasSeededDemoRosterKey = 'has_seeded_demo_roster';

class HiveStorage {
  static Box<Player>? _box;
  static Box<MatchHistory>? _historyBox;
  static Box<Map>? _statsArchiveBox;
  static Box? _metadataBox;

  static bool get isReady => _box != null && _box!.isOpen;

  static void registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PlayerPositionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PlayerAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(MatchHistoryAdapter());
    }
  }

  /// File-backed Hive for widget/integration tests. Skips path_provider.
  static Future<void> initAtPath(String path) async {
    Hive.init(path);
    registerAdapters();
    await init();
  }

  static Future<void> init() async {
    _box = await Hive.openBox<Player>(_kBoxName);
    _historyBox = await Hive.openBox<MatchHistory>(_kHistoryBoxName);
    _statsArchiveBox = await Hive.openBox<Map>(_kStatsArchiveBoxName);
    _metadataBox = await Hive.openBox(_kMetadataBoxName);
  }

  static DateTime? getRosterCreatedAt() {
    final timestamp = _metadataBox?.get(_kRosterCreatedAtKey);
    if (timestamp == null) return null;
    return DateTime.parse(timestamp as String);
  }

  static Future<void> setRosterCreatedAt(DateTime? date) async {
    if (date == null) {
      await _metadataBox?.delete(_kRosterCreatedAtKey);
    } else {
      await _metadataBox?.put(_kRosterCreatedAtKey, date.toIso8601String());
    }
  }

  static bool getHasSeenOnboarding() {
    return _metadataBox?.get(_kHasSeenOnboardingKey) as bool? ?? false;
  }

  static Future<void> setHasSeenOnboarding(bool value) async {
    await _metadataBox?.put(_kHasSeenOnboardingKey, value);
  }

  static bool getHasSeededDemoRoster() {
    return _metadataBox?.get(_kHasSeededDemoRosterKey) as bool? ?? false;
  }

  static Future<void> setHasSeededDemoRoster(bool value) async {
    await _metadataBox?.put(_kHasSeededDemoRosterKey, value);
  }

  static List<Player> loadPlayers() {
    return _box?.values.toList() ?? [];
  }

  static Future<void> savePlayers(List<Player> players) async {
    final box = _box;
    if (box == null) return;
    await box.clear();
    await box.putAll({for (final p in players) p.id: p});
  }

  // History Methods
  static List<MatchHistory> loadHistory() {
    return _historyBox?.values.toList() ?? [];
  }

  static Future<void> saveHistory(List<MatchHistory> history) async {
    final box = _historyBox;
    if (box == null) return;
    await box.clear();
    await box.putAll({for (final h in history) h.id: h});
  }

  static Future<void> addMatchToHistory(MatchHistory match) async {
    final box = _historyBox;
    if (box == null) return;
    await box.put(match.id, match);
  }

  /// Permanently saves a player's cumulative stats to the archive.
  /// This ensures that even if a player is deleted from the roster,
  /// their goals/assists are never lost.
  static Future<void> archiveStatsForPlayer(
    String name,
    int goals,
    int assists,
    int cleanSheets,
  ) async {
    final box = _statsArchiveBox;
    if (box == null) return;
    final upperName = name.trim().toUpperCase();
    await box.put(upperName, {
      'goals': goals,
      'assists': assists,
      'cleanSheets': cleanSheets,
    });
  }

  static Future<void> deleteStatsForPlayer(String name) async {
    final box = _statsArchiveBox;
    if (box == null) return;
    final upperName = name.trim().toUpperCase();
    await box.delete(upperName);
  }

  /// Returns all entries in the stats archive box.
  static List<MapEntry<String, Map>> loadAllTimeStats() {
    final box = _statsArchiveBox;
    if (box == null) return [];
    return box
        .toMap()
        .entries
        .map((e) => MapEntry(e.key as String, e.value))
        .toList();
  }

  /// Scans the stats archive and match history to calculate cumulative stats for multiple players.
  /// This is much more efficient for bulk lookups (e.g. during team generation).
  static Map<String, ({int goals, int assists, int cleanSheets})>
  getBulkStatsForNames(List<String> playerNames) {
    final Map<String, ({int goals, int assists, int cleanSheets})> results = {};
    final history = loadHistory();

    for (final name in playerNames) {
      final upperName = name.trim().toUpperCase();

      // 1. Check archive
      final archived = _statsArchiveBox?.get(upperName);
      if (archived != null) {
        results[name] = (
          goals: (archived['goals'] as int? ?? 0),
          assists: (archived['assists'] as int? ?? 0),
          cleanSheets: (archived['cleanSheets'] as int? ?? 0),
        );
        continue;
      }

      // 2. Scan History
      int totalGoals = 0;
      int totalAssists = 0;
      int totalCleanSheets = 0;

      for (final match in history) {
        String? matchedId;
        for (final team in match.teams) {
          for (final p in team) {
            if (p.name.trim().toUpperCase() == upperName) {
              matchedId = p.id;
              break;
            }
          }
          if (matchedId != null) break;
        }

        if (matchedId != null) {
          totalGoals += match.playerGoals[matchedId] ?? 0;
          totalAssists += match.playerAssists[matchedId] ?? 0;
          // Note: Clean sheets might need a more complex logic if they are to be derived from history,
          // but for now we treat them as manually tracked/imported similar to goals/assists.
          // If the user wants manual tracking, we focus on archive persistence.
        }
      }
      results[name] = (
        goals: totalGoals,
        assists: totalAssists,
        cleanSheets: totalCleanSheets,
      );
    }

    return results;
  }

  static ({int goals, int assists, int cleanSheets}) getStatsForPlayerName(
    String playerName,
  ) {
    final stats = getBulkStatsForNames([playerName])[playerName];
    return stats ?? (goals: 0, assists: 0, cleanSheets: 0);
  }
}
