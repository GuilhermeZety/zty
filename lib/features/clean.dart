import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/paths.dart';
import 'package:zty/rotating_loader.dart';
import 'package:zty/task.dart';
import 'package:zty/zty.dart';

class Clean {
  static Future run(List<String> arguments) async {
    var loader = Loader();
    stdout.write('\r${zty()}$name - Iniciando... \n');
    stdout.write('\r${zty()}$name - Buscando Projetos Válidos   ');
    loader.start();
    var paths = await getProjectsPaths(ignoreZty: true);
    loader.stop();

    stdout.write('\r${zty()}$name - ${paths.length} Projetos Encontrados      \n');

    for (var path in paths) {
      if (path.$2 == "JavaScript" || path.$2 == "Typescript") {
        // Não suportado
        stdout.write('\r${zty()}$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(path.$1.split('/').last)} ${AnsiStyles.red('NÃO SUPORTADO')} \n');
        continue;
      }
      await Task(
        tag: '$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(path.$1.split('/').last)}',
        description: 'Limpando',
        task: () async {
          if (path.$2 == 'Flutter' || path.$2 == 'Dart') {
            Directory.current = path.$1;
            List<String> args = ['clean'];
            Process process = await Process.start(path.$2 == 'Flutter' ? 'flutter' : 'dart', args);

            // Aguarda o término do processo e obtém o código de saída
            int exitCode = await process.exitCode;

            if (exitCode != 0) {
              throw Exception('$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(path.$1.split('/').last)} EXITCODE != 0');
            }
          }
        },
      ).run();
    }
  }
}

String typeNamed(String? type) {
  if (type == null) {
    return '';
  }
  switch (type) {
    case 'Flutter':
      return AnsiStyles.blue('[Flutter]');
    case 'Dart':
      return AnsiStyles.blue('[Dart]');
    case 'Typescript':
      return AnsiStyles.cyan('[Typescript]');
    case 'JavaScript':
      return AnsiStyles.yellow('[JavaScript]');
    default:
      return 'Nenhum';
  }
}

String get name => AnsiStyles.cyan('[CLEAN]');
