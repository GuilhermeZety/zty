import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/zty.dart';

class Version {
  static Future<void> run() async {
    final pubspecFile = File('${Directory.current.path}/pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      throw Exception('Could not find pubspec.yaml');
    }

    final content = pubspecFile.readAsStringSync();
    final versionLine = content.split('\n').firstWhere(
          (line) => line.trim().startsWith('version:'),
          orElse: () => 'version: 0.0.0',
        );

    final version = versionLine.split(':')[1].trim();
    stdout.write('\r${zty()}${AnsiStyles.green(version)}\n');
  }
}
