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

  //TODO: Criar um retorno para caso não houver opções
  showHelp();
}
