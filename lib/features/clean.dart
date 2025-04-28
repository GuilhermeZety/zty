import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/paths.dart';
import 'package:zty/rotating_loader.dart';
import 'package:zty/task.dart';
import 'package:zty/zty.dart';

class Clean {
  static Future run(List<String> arguments) async {
    var loader = Loader();
    stdout.write('${zty()}$name - Iniciando...');
    stdout.write('\n\n${zty()}$name - Buscando Projetos Válidos... ');
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
        stdout.write('${AnsiStyles.bgYellow.black.bold(' Atenção! ')} Você tem certeza que deseja limpar o projeto ${AnsiStyles.yellow(projeto)}? [s/N]: ');
        String? confirm = stdin.readLineSync();
        if (confirm == null || confirm.toLowerCase() != 's') {
          stdout.write('$progress ${AnsiStyles.yellow('Ação cancelada para')} $projeto.\n');

          continue;
        }
        await Task(
          tag: '$progress $name ${typeNamed(path.$2)} ${AnsiStyles.yellow(projeto)}',
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
            if (path.$2 == "PHP") {
              Directory.current = path.$1;
              // Remover pasta node_modules// Para PHP, limpar o cache do Composer e arquivos temporários
              // List<String> args = ['clear-cache'];
              // Process process = await Process.start('composer', args);

              // int exitCode = await process.exitCode;
              // if (exitCode != 0) {
              //   throw Exception('$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(path.$1.split('/').last)} EXITCODE != 0');
              // }
              if (await Directory('${path.$1}/node_modules').exists()) {
                List<String> nodeArgs = ['-rf', 'node_modules'];
                Process nodeProcess = await Process.start('rm', nodeArgs);
                int nodeExitCode = await nodeProcess.exitCode;
                if (nodeExitCode != 0) {
                  throw Exception('$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(path.$1.split('/').last)} EXITCODE != 0');
                }
              }
              // Remover pasta vendor
              if (await Directory('${path.$1}/vendor').exists()) {
                List<String> vendorArgs = ['-rf', 'vendor'];
                Process vendorProcess = await Process.start('rm', vendorArgs);
                int vendorExitCode = await vendorProcess.exitCode;
                if (vendorExitCode != 0) {
                  throw Exception('$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(path.$1.split('/').last)} EXITCODE != 0');
                }
              }
            }
          },
        ).run();
        stdout.write('${AnsiStyles.red('[ZTY]')}$name  ${AnsiStyles.green('✔ Limpeza concluída para:')} ${AnsiStyles.yellow(projeto)}\n');
      } else {
        Directory? directory;

        if (path.$2 == "JavaScript" || path.$2 == "Typescript") {
          directory = Directory('${path.$1}/node_modules');
        } else if (path.$2 == 'Flutter' || path.$2 == 'Dart') {
          directory = Directory('${path.$1}/build');
        } else if (path.$2 == 'PHP') {
          var nodeModules = Directory('${path.$1}/node_modules');
          var vendor = Directory('${path.$1}/vendor');
          if (await nodeModules.exists() || await vendor.exists()) {
            directory = Directory(path.$1);
          }
        }
        if (directory == null) return;

        if (await directory.exists()) {
          stdout.write('$progress ${zty()}$name ${typeNamed(path.$2)} ${await getDirectorySize(path.$1)} ${AnsiStyles.yellow(projeto)} ${AnsiStyles.red('PENDENTE')} \n');
        } else {
          stdout.write('$progress ${zty()}$name ${typeNamed(path.$2)} ${await getDirectorySize(path.$1)} ${AnsiStyles.yellow(projeto)} ${AnsiStyles.green('OK')} \n');
        }

        // caso tenha pasta /build retornar como pendente
      }
    }
    stdout.write('\n${zty()}$name - Finalizado.\n');
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
    case 'PHP':
      return AnsiStyles.magenta('[PHP]');
    default:
      return 'Nenhum';
  }
}

String get name => AnsiStyles.cyan('[CLEAN]');

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
