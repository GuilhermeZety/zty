import 'dart:async';

import 'package:zty/features/build.dart';
import 'package:zty/features/clean.dart';
import 'package:zty/features/convert_icons.dart';
import 'package:zty/features/delete.dart';
import 'package:zty/features/find.dart';
import 'package:zty/features/find_strings.dart' hide Find;
import 'package:zty/features/git_status.dart';
import 'package:zty/features/git_verify.dart';
import 'package:zty/features/update.dart';
import 'package:zty/features/version.dart';
import 'package:zty/help.dart';
import 'package:zty/utils.dart';

// Cria o spinner

Future<void> main(List<String> arguments) async {
  ocultarCursor();
  if (arguments.contains('--help') || arguments.contains('-h') || arguments.isEmpty) {
    showHelp();
    return;
  }

  if (arguments.contains('--version') || arguments.contains('-v')) {
    await Version.run();
    mostrarCursor();
    return;
  }

  if (arguments.contains('clean')) {
    await Clean.run(arguments);
    mostrarCursor();
    return;
  }
  if (arguments.contains('status')) {
    await GitStatus.run(arguments);
    mostrarCursor();
    return;
  }
  if (arguments.contains('update')) {
    await Update.run(arguments);
    mostrarCursor();
    return;
  }
  if (arguments.contains('delete')) {
    await Delete.run(arguments);
    mostrarCursor();
    return;
  }
  if (arguments.contains('verify')) {
    await GitVerify.run(arguments);
    mostrarCursor();
    return;
  }
  if (arguments.contains('build')) {
    await Build.run(arguments);
    mostrarCursor();
    return;
  }

  if (arguments.contains('find-strings')) {
    await FindStrings.run(arguments);
    mostrarCursor();
    return;
  }

  if (arguments.contains('find')) {
    await Find.run(arguments);
    mostrarCursor();
    return;
  }

  if (arguments.contains('convert-icons')) {
    await ConvertIcons.run(arguments);
    mostrarCursor();
    return;
  }

  showHelp();
}
