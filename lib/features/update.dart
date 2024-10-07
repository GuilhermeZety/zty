import 'dart:convert';
import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/paths.dart';
import 'package:zty/rotating_loader.dart';
import 'package:zty/zty.dart';

class Update {
  static Future run(List<String> arguments) async {
    var loader = Loader();
    stdout.write('\r${zty()}$name - [INDISPONIVEL NO MOMENTO] \n');
    return;
    stdout.write('\r${zty()}$name - Iniciando... \n');
    stdout.write('\r${zty()}$name - Buscando Atualizações   ');
    loader.start();
    var has = await hasUpdates();
    loader.stop();
    stdout.write('\r${zty()}$name - ${has ? 'Ha atualizações' : 'Nenhuma atualização'} \n');
  }
}

Future<bool> hasUpdates() async {
  var paths = await getProjectsPaths();
  bool has = false;

  paths = paths.where((element) {
    return ['zty'].contains(element.$1.split('/').last);
  }).toList();

  if (paths.isEmpty) {
    throw Exception('Suporte a atualização não disponível!');
  }
  Directory.current = paths.first.$1;
  List<String> args = ['status'];
  Process process = await Process.start('git', args);

  // Retorna se tem algum projeto esperando dar commit
  process.stdout.transform(utf8.decoder).listen((data) {
    if (data.contains('Changes not staged for commit') ||
        data.contains('Untracked files') ||
        data.contains('Changes to be committed') ||
        data.contains(
          "Your branch is ahead of 'origin/main' by",
        )) {
      has = true;
    }
  });

  // Aguarda o término do processo e obtém o código de saída
  await process.exitCode;

  return has;
}

String get name => AnsiStyles.dim('[UPDATE]');
