import 'dart:convert';
import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/paths.dart';
import 'package:zty/rotating_loader.dart';
import 'package:zty/zty.dart';

class Update {
  static Future run(List<String> arguments) async {
    var loader = Loader();
    stdout.write('${zty()}$name - Iniciando...');
    stdout.write('${zty()}$name - Buscando Atualizações... ');
    loader.start();
    bool hasUpdatesResult = false;
    try {
      hasUpdatesResult = await hasUpdates();
    } catch (e) {
      loader.stop();
      stdout.write('\r${zty()}$name - ${AnsiStyles.red('Erro ao verificar atualizações:')} ${e.toString().replaceAll('Exception: ', '')} \n');
      return;
    }
    loader.stop();

    if (!hasUpdatesResult) {
      stdout.write('\r${zty()}$name - ${AnsiStyles.green('✔ ZTY já está na última versão!')} \n');
      return;
    }

    stdout.write('\r${zty()}$name - ${AnsiStyles.yellow('Atualização encontrada!')} Iniciando atualização... ');
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

    // Executa dart run para atualizar
    var runProcess = await Process.start('dart', ['run']);
    int runExitCode = await runProcess.exitCode;

    loader.stop();
    if (runExitCode == 0) {
      stdout.write('\r${zty()}$name - ${AnsiStyles.green('✔ Pacote atualizado com sucesso!')} \n');
    } else {
      stdout.write('\r${zty()}$name - ${AnsiStyles.red('Erro ao atualizar o pacote (dart run).')} \n');
    }
    stdout.write('\n${zty()}$name - Finalizado.\n');
  }
}

Future<bool> hasUpdates() async {
  var paths = await getProjectsPaths();
  bool has = false;

  var ztyPath = paths.where((element) {
    return ['zty'].contains(element.$1.split('/').last);
  }).toList();

  if (ztyPath.isEmpty) {
    throw Exception('Diretório do ZTY não encontrado para verificação de atualizações.');
  }
  Directory.current = ztyPath.first.$1;

  // Atualiza referências remotas
  var fetchProcess = await Process.start('git', ['fetch']);
  await fetchProcess.exitCode;

  // Verifica se há commits para puxar do remoto
  var revListProcess = await Process.start('git', ['rev-list', '--count', 'HEAD..origin/main']);
  var commitCountOutput = '';
  var errorOutput = '';
  revListProcess.stdout.transform(utf8.decoder).listen((data) {
    commitCountOutput += data;
  });
  revListProcess.stderr.transform(utf8.decoder).listen((data) {
    errorOutput += data;
  });
  int exitCode = await revListProcess.exitCode;

  if (exitCode != 0) {
    throw Exception('Erro ao verificar commits remotos: ${errorOutput.trim()}');
  }

  // Se houver commits pendentes para puxar, retorna true
  if (int.tryParse(commitCountOutput.trim()) != null && int.parse(commitCountOutput.trim()) > 0) {
    has = true;
  }

  return has;
}

String get name => AnsiStyles.dim('[UPDATE]');
