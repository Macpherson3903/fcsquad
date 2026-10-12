import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../storage/hive_storage.dart';
import '../services/demo_roster.dart';

/// Provider that handles the async initialization of Hive storage.
///
/// Moving this from `main()` to a provider allows the app to launch
/// immediately while showing a loading state, improving perceived startup time.
final storageInitializerProvider = FutureProvider<void>((ref) async {
  HiveStorage.registerAdapters();

  if (!HiveStorage.isReady) {
    await Hive.initFlutter();
    try {
      await HiveStorage.init();
    } catch (e) {
      await Hive.deleteBoxFromDisk('players');
      await Hive.deleteBoxFromDisk('history');
      await HiveStorage.init();
    }
  }

  await DemoRoster.persistIfNeeded();
});
