import 'dart:io';

import 'package:fc_squad/main.dart';
import 'package:fc_squad/services/demo_roster.dart';
import 'package:fc_squad/storage/hive_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('simulator first launch shows demo squad and GENERATE TEAMS', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('fc_squad_integ');
    await HiveStorage.initAtPath(dir.path);
    await DemoRoster.persistIfNeeded();

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(
      find.text('SAM WALKER'),
      findsWidgets,
      reason: 'First launch should seed the sample MY SQUAD roster',
    );
    expect(
      find.text('GENERATE TEAMS'),
      findsWidgets,
      reason: 'GENERATE TEAMS must be visible without pasting names',
    );
  });
}
