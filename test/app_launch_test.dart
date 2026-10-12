import 'package:fc_squad/main.dart';
import 'package:fc_squad/models/match_history.dart';
import 'package:fc_squad/models/player.dart';
import 'package:fc_squad/providers/all_time_stats_provider.dart';
import 'package:fc_squad/providers/history_provider.dart';
import 'package:fc_squad/providers/roster_provider.dart';
import 'package:fc_squad/providers/storage_provider.dart';
import 'package:fc_squad/services/demo_roster.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededRoster extends RosterNotifier {
  @override
  Future<List<Player>> build() async => DemoRoster.buildPlayers();
}

class _EmptyHistory extends HistoryNotifier {
  @override
  Future<List<MatchHistory>> build() async => [];
}

class _EmptyStats extends AllTimeStatsNotifier {
  @override
  Future<List<PlayerAllTimeStats>> build() async => [];
}

void main() {
  testWidgets('first launch shows demo squad and GENERATE TEAMS', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageInitializerProvider.overrideWith((ref) async {}),
          rosterProvider.overrideWith(_SeededRoster.new),
          historyProvider.overrideWith(_EmptyHistory.new),
          allTimeStatsProvider.overrideWith(_EmptyStats.new),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('GENERATE TEAMS'),
      findsWidgets,
      reason: 'GENERATE TEAMS must be visible without pasting names',
    );

    await tester.tap(find.text('MY SQUAD'));
    await tester.pump();

    expect(
      find.text('SAM WALKER'),
      findsWidgets,
      reason: 'First launch should seed the sample MY SQUAD roster',
    );
  });
}
