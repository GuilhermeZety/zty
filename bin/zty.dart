import 'dart:async';

import 'package:zty/features/clean.dart';
import 'package:zty/features/git_status.dart';
import 'package:zty/help.dart';
import 'package:zty/utils.dart';

// Cria o spinner

Future<void> main(List<String> arguments) async {
  ocultarCursor();
  if (arguments.contains('--help') || arguments.contains('-h') || arguments.isEmpty) {
    showHelp();
    return;
  }

  if (arguments.contains('--clean') || arguments.contains('-c')) {
    await Clean.run(arguments);
  }
  if (arguments.contains('--git-status') || arguments.contains('-gs')) {
    await GitStatus.run(arguments);
  }

  mostrarCursor();
}
