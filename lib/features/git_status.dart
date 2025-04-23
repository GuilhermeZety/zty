import 'dart:convert';
import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/features/clean.dart';
import 'package:zty/paths.dart';
import 'package:zty/rotating_loader.dart';
import 'package:zty/zty.dart';

class GitStatus {
  static Future run(List<String> arguments) async {
    var loader = Loader();
    stdout.write('${zty()}$name - Iniciando...\r');
    stdout.write('${zty()}$name - Buscando Projetos Válidos... ');
    loader.start();
    var paths = await getProjectsPaths();
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

      Directory.current = path.$1;
      List<String> args = ['status', '--porcelain']; // Use --porcelain for easier parsing
      Process process = await Process.start('git', args);

      String output = '';
      process.stdout.transform(utf8.decoder).listen((data) {
        output += data;
      });

      // Aguarda o término do processo e obtém o código de saída
      int exitCode = await process.exitCode;

      if (exitCode == 0) {
        if (output.trim().isEmpty) {
          // Check remote status
          Process aheadProcess = await Process.start('git', ['rev-list', '--count', 'HEAD@{u}..HEAD']);
          String aheadCount = '';
          aheadProcess.stdout.transform(utf8.decoder).listen((data) => aheadCount += data);
          await aheadProcess.exitCode;

          Process behindProcess = await Process.start('git', ['rev-list', '--count', 'HEAD..HEAD@{u}']);
          String behindCount = '';
          behindProcess.stdout.transform(utf8.decoder).listen((data) => behindCount += data);
          await behindProcess.exitCode;

          int ahead = int.tryParse(aheadCount.trim()) ?? 0;
          int behind = int.tryParse(behindCount.trim()) ?? 0;

          if (ahead > 0 && behind > 0) {
            stdout.write('$progress ${zty()}$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(projeto)} - ${AnsiStyles.yellow('DIVERGED')} (Ahead: $ahead, Behind: $behind)\n');
          } else if (ahead > 0) {
            stdout.write('$progress ${zty()}$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(projeto)} - ${AnsiStyles.cyan('AHEAD')} ($ahead commits)\n');
          } else if (behind > 0) {
            stdout.write('$progress ${zty()}$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(projeto)} - ${AnsiStyles.magenta('BEHIND')} ($behind commits)\n');
          } else {
            stdout.write('$progress ${zty()}$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(projeto)} - ${AnsiStyles.green('OK')}\n');
          }
        } else {
          stdout.write('$progress ${zty()}$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(projeto)} - ${AnsiStyles.red('COM PENDÊNCIAS')}\n');
        }
      } else {
        stdout.write('$progress ${zty()}$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(projeto)} - ${AnsiStyles.red('ERRO AO VERIFICAR STATUS')}\n');
      }
    }
    stdout.write('\n${zty()}$name - Finalizado.\n');
  }
}

String get name => AnsiStyles.green('[GIT-STATUS]');
