import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/features/clean.dart';
import 'package:zty/paths.dart';
import 'package:zty/rotating_loader.dart';
import 'package:zty/task.dart';
import 'package:zty/zty.dart';

class Delete {
  static Future run(List<String> arguments) async {
    var loader = Loader();
    stdout.write('${zty()}$name - Iniciando...\r');
    stdout.write('${zty()}$name - Buscando Projetos Válidos... ');
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

    stdout.write('\r${zty()}$name - ${paths.length} Projeto${paths.length > 1 ? 's' : ''} Encontrado${paths.length > 1 ? 's' : ''}      \n\n');
    int processed = 0;
    int total = paths.length;
    for (var path in paths) {
      processed++;
      var splitted = path.$1.split('/');
      String projeto = '${splitted[splitted.length - 2]}/${splitted.last}';
      String progress = AnsiStyles.cyan('[$processed/$total]');

      if (arguments.contains('--apply')) {
        stdout.write('${AnsiStyles.bgRed.white.bold(' Atenção! ')} Você tem certeza que deseja mover o projeto ${AnsiStyles.yellow(projeto)} para a lixeira? [s/N]: ');
        String? confirm = stdin.readLineSync();
        if (confirm == null || confirm.toLowerCase() != 's') {
          stdout.write('$progress ${AnsiStyles.yellow('Ação cancelada para')} $projeto.\n');

          continue;
        }
        try {
          await Task(
            tag: '$progress $name ${typeNamed(path.$2)} ${AnsiStyles.yellow(projeto)}',
            description: 'Movendo para lixeira',
            task: () async {
              Directory directory = Directory(path.$1);
              if (await directory.exists()) {
                String trashPath = '${Platform.environment['HOME']}/.Trash';
                String projectName = path.$1.split('/').last;
                String destinationPath = '$trashPath/$projectName';
                int counter = 1;
                while (await Directory(destinationPath).exists()) {
                  destinationPath = '$trashPath/${projectName}_$counter';
                  counter++;
                }
                List<String> args = [path.$1, destinationPath];
                Process process = await Process.start('mv', args);
                int exitCode = await process.exitCode;
                if (exitCode != 0) {
                  throw Exception('$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(projectName)} EXITCODE != 0');
                }
              }
            },
          ).run();
          stdout.write('$progress ${AnsiStyles.green('✔ Projeto movido para a lixeira:')} ${AnsiStyles.yellow(projeto)}\n');
        } catch (e) {
          stdout.write('$progress ${AnsiStyles.red('Erro ao mover')} $projeto: ${e.toString()}\n');
        }
      } else {
        try {
          String size = await getDirectorySize(path.$1);
          stdout.write('$progress ${zty()}$name ${typeNamed(path.$2)} $size ${AnsiStyles.yellow(projeto)}\n');
        } catch (e) {
          stdout.write('$progress ${AnsiStyles.red('Erro ao calcular tamanho de')} $projeto: ${e.toString()}\n');
        }
      }
    }
    stdout.write('\n${zty()}$name - Finalizado.\n');
  }
}

String get name => AnsiStyles.red('[DELETE]');

Future<String> getDirectorySize(String directory) async {
  int totalSize = 0;

  // Lista todos os arquivos e diretórios dentro do diretório
  await for (FileSystemEntity entity in (Directory(directory)).list(recursive: true, followLinks: false)) {
    if (entity is File) {
      // Somar o tamanho dos arquivos
      totalSize += await entity.length();
    }
  }

  return '[${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB]';
}
