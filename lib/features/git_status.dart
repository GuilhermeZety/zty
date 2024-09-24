import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/paths.dart';
import 'package:zty/rotating_loader.dart';
import 'package:zty/zty.dart';

class GitStatus {
  static Future run(List<String> arguments) async {
    var loader = Loader();
    stdout.write('\r${zty()}$name - Iniciando... \n');
    stdout.write('\r${zty()}$name - Buscando Projetos Válidos   ');
    loader.start();
    await Future.delayed(Duration(seconds: 2));
    var paths = await getProjectsPaths();
    loader.stop();
    stdout.write('\r${zty()}$name - ${paths.length} Projetos Encontrados      \n');
  }
}

String get name => AnsiStyles.yellowBright('[GIT-STATUS]');
