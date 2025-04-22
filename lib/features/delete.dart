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
          description: 'Movendo para lixeira',
          task: () async {
            Directory directory = Directory(path.$1);
            if (await directory.exists()) {
              // No macOS, usar o comando 'mv' com a pasta .Trash
              String trashPath = '${Platform.environment['HOME']}/.Trash';
              String projectName = path.$1.split('/').last;
              String destinationPath = '$trashPath/$projectName';

              // Verifica se já existe um arquivo com o mesmo nome na lixeira
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
      } else {
        var splitted = path.$1.split('/');
        stdout.write('\r${zty()}$name ${typeNamed(path.$2)} ${await getDirectorySize(path.$1)} ${AnsiStyles.yellow('${splitted[splitted.length - 2]}/${splitted.last}')} \n');
      }
    }
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
