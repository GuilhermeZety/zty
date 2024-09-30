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
    stdout.write('\r${zty()}$name - Iniciando... \n');
    stdout.write('\r${zty()}$name - Buscando Projetos Válidos   ');
    loader.start();
    var paths = await getProjectsPaths();
    loader.stop();
    stdout.write('\r${zty()}$name - ${paths.length} Projetos Encontrados      \n');

    for (var path in paths) {
      Directory.current = path.$1;
      List<String> args = ['status'];
      Process process = await Process.start('git', args);

      // Retorna se tem algum projeto esperando dar commit
      process.stdout.transform(utf8.decoder).listen((data) {
        if (data.contains('Changes not staged for commit') ||
            data.contains('Untracked files') ||
            data.contains('Changes to be committed') ||
            data.contains("Your branch is ahead of 'origin/main' by")) {
          stdout.write('\r${zty()}$name ${typeNamed(path.$2)} ${AnsiStyles.yellow(path.$1.split('/').last)}  -  COM PENDENCIAS   \n');
        }
      });

      // Aguarda o término do processo e obtém o código de saída
      await process.exitCode;
    }
  }
}

String get name => AnsiStyles.green('[GIT-STATUS]');
