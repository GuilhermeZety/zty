import 'dart:convert';
import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/paths.dart';
import 'package:zty/rotating_loader.dart';
import 'package:zty/zty.dart';

class Update {
  static Future run(List<String> arguments) async {
    var loader = Loader();
    stdout.write('\r${zty()}$name - Iniciando... \n');
    stdout.write('\r${zty()}$name - Buscando Atualizações   ');
    loader.start();
    var has = await hasUpdates();
    loader.stop();

    if (!has) {
      stdout.write('\r${zty()}$name - ${AnsiStyles.green('[ZTY está na ultima versão]')} \n');
      return;
    }

    stdout.write('\r${zty()}$name - Atualizando pacote   ');
    loader.start();

    var paths = await getProjectsPaths();
    paths = paths.where((element) {
      return ['zty'].contains(element.$1.split('/').last);
    }).toList();

    if (paths.isEmpty) {
      throw Exception('Suporte a atualização não disponível!');
    }

    Directory.current = paths.first.$1;

    // Executa git pull
    var pullProcess = await Process.start('git', ['pull']);
    await pullProcess.exitCode;

    // Ativa o pacote localmente
    var activateProcess = await Process.start('dart', ['pub', 'global', 'activate', '--source', 'path', '.']);
    await activateProcess.exitCode;

    loader.stop();
    stdout.write('\r${zty()}$name - ${AnsiStyles.green('Pacote atualizado com sucesso')} \n');
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

  // Atualiza referências remotas
  var fetchProcess = await Process.start('git', ['fetch']);
  await fetchProcess.exitCode;

  // Verifica se há commits para puxar do remoto
  var revListProcess = await Process.start('git', ['rev-list', 'HEAD..origin/main', '--count']);
  var commitCount = '';
  revListProcess.stdout.transform(utf8.decoder).listen((data) {
    commitCount += data;
  });
  await revListProcess.exitCode;

  // Se houver commits pendentes para puxar, retorna true
  if (int.parse(commitCount.trim()) > 0) {
    has = true;
  }

  return has;
}

String get name => AnsiStyles.dim('[UPDATE]');
