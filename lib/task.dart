import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/rotating_loader.dart';

class Task {
  final String? tag;
  final String description;
  final Future Function() task;

  Task({required this.tag, required this.description, required this.task});

  Future run() async {
    var loader = Loader();
    //
    final message = '${AnsiStyles.red('[ZTY]')}${tag != null ? '$tag' : ''} - $description';
    stdout.write('$message  ');
    loader.start();
    await task();
    loader.stop();
    stdout.write('\r$message  ${AnsiStyles.green('OK')} \n');
  }
}
