import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/rotating_loader.dart';
import 'package:zty/zty.dart';

class Update {
  static Future run(List<String> arguments) async {
    var loader = Loader();
    stdout.write('${zty()}$name - Localizando instalação... ');
    loader.start();

    try {
      // 1. Descobrir o path via global list
      var listProcess = await Process.run('dart', ['pub', 'global', 'list']);
      String? ztyPath;
      for (var line in listProcess.stdout.toString().split('\n')) {
        if (line.contains('zty') && line.contains('at path')) {
          ztyPath = line.split('at path').last.trim().replaceAll('"', '');
          break;
        }
      }

      if (ztyPath == null) throw Exception('ZTY não localizado no pub global list.');

      Directory.current = ztyPath;

      // 2. Verificar updates
      await Process.run('git', ['fetch']);
      var revList = await Process.run('git', ['rev-list', '--count', 'HEAD..origin/main']);
      int commitsBehind = int.tryParse(revList.stdout.toString().trim()) ?? 0;

      if (commitsBehind == 0) {
        loader.stop();
        stdout.write('\r${zty()}$name - ${AnsiStyles.green('✔ ZTY já está na última versão!')} \n');
        return;
      }

      stdout
          .write('\r${zty()}$name - ${AnsiStyles.yellow('Atualização encontrada!')} Aplicando... ');

      // 3. Git Pull
      await Process.run('git', ['pull', 'origin', 'main']);

      // 4. Dart Run (Silencioso)
      // Usamos Process.run e simplesmente não exibimos o stdout.
      // Isso executará o comando, mas o help que ele gera ficará "preso" na memória.
      await Process.run('dart', ['run']);

      // 5. Re-compilação e Ativação
      var activate =
          await Process.run('dart', ['pub', 'global', 'activate', '--source', 'path', '.']);

      loader.stop();
      if (activate.exitCode == 0) {
        stdout.write('\r${zty()}$name - ${AnsiStyles.green('✔ ZTY atualizado com sucesso!')} \n');
      } else {
        throw Exception('Erro ao recompilar: ${activate.stderr}');
      }
    } catch (e) {
      loader.stop();
      stdout.write('\r${zty()}$name - ${AnsiStyles.red('Erro:')} $e \n');
    }
  }
}

String get name => AnsiStyles.dim('[UPDATE]');
