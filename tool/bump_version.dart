import 'dart:io';

/// Automated version bumper for FC Squad.
/// Usage: dart run tool/bump_version.dart <major|minor|patch|build>
void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tool/bump_version.dart <major|minor|patch|build>');
    exit(1);
  }

  final target = args[0].toLowerCase();
  final pubspecFile = File('pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found.');
    exit(1);
  }

  final lines = pubspecFile.readAsLinesSync();
  int versionLineIndex = -1;
  String? currentVersionString;

  for (int i = 0; i < lines.length; i++) {
    // Exact match for 'version:' at start of line
    if (lines[i].startsWith('version:')) {
      versionLineIndex = i;
      currentVersionString = lines[i].replaceFirst('version:', '').trim();
      break;
    }
  }

  if (versionLineIndex == -1 || currentVersionString == null) {
    print('Error: version line not found in pubspec.yaml.');
    exit(1);
  }

  // Parse version format e.g. "1.0.0+1"
  final parts = currentVersionString.split('+');
  final semver = parts[0];
  final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

  final semverParts = semver
      .split('.')
      .map((e) => int.tryParse(e) ?? 0)
      .toList();
  // Ensure we have [major, minor, patch]
  while (semverParts.length < 3) {
    semverParts.add(0);
  }

  int major = semverParts[0];
  int minor = semverParts[1];
  int patch = semverParts[2];
  int newBuild = build;

  switch (target) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      break;
    case 'minor':
      minor++;
      patch = 0;
      break;
    case 'patch':
      patch++;
      break;
    case 'build':
      newBuild++;
      break;
    default:
      print('Invalid target: $target. Use major, minor, patch, or build.');
      exit(1);
  }

  final newVersion = '$major.$minor.$patch+$newBuild';
  lines[versionLineIndex] = 'version: $newVersion';

  // Write back to file, ensuring a single trailing newline if the file had one.
  pubspecFile.writeAsStringSync(lines.join('\n') + '\n');
  print('✅ Successfully bumped version to: $newVersion');
}
