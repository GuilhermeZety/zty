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

    if (arguments.contains('--only')) {
      var index = arguments.indexOf('--only');
      if (arguments.length <= index + 1) {
        throw Exception('--only precisa que você referencie um projeto');
      }
      List<String> only = arguments[index + 1].split(',');

      paths = paths.where((element) {
        return only.contains(element.$1.split('/').last);
      }).toList();
    }
    if (arguments.contains('--ignore')) {
      var index = arguments.indexOf('--ignore');
      if (arguments.length <= index + 1) {
        throw Exception('--ignore precisa que você referencie um projeto');
      }
      List<String> ignore = arguments[index + 1].split(',');

      paths.removeWhere((element) {
        return ignore.contains(element.$1.split('/').last);
      });
    }

    stdout.write('\r${zty()}$name - ${paths.length} Projetos Encontrados      \n');

    for (var path in paths) {
      if (arguments.contains('--apply')) {
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
            if (path.$2 == "JavaScript" || path.$2 == "Typescript") {
              Directory.current = path.$1;
              List<String> args = ['-rf', 'node_modules'];
              Process process = await Process.start('rm', args);

              // Aguarda o término do processo e obtém o código de saída
              int exitCode = await process.exitCode;

              if (exitCode != 0) {
                throw Exception('$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(path.$1.split('/').last)} EXITCODE != 0');
              }
            }
          },
        ).run();
      } else {
        var splitted = path.$1.split('/');
        bool has = false;

        if (path.$2 == "JavaScript" || path.$2 == "Typescript") {
          has = await Directory('${path.$1}/node_modules/').exists();
        } else if (path.$2 == 'Flutter' || path.$2 == 'Dart') {
          has = await Directory('${path.$1}/build/').exists();
        }

        if (has) {
          stdout.write('\r${zty()}$name ${typeNamed(path.$2)} ${AnsiStyles.yellow('${splitted[splitted.length - 2]}/${splitted.last}')} ${AnsiStyles.red('PENDENTE')} \n');
        } else {
          stdout.write('\r${zty()}$name ${typeNamed(path.$2)} ${AnsiStyles.yellow('${splitted[splitted.length - 2]}/${splitted.last}')} ${AnsiStyles.green('OK')} \n');
        }

        // caso tenha pasta /build retornar como pendente
      }
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
