import 'dart:convert';
import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:zty/rotating_loader.dart';
import 'package:zty/task.dart';
import 'package:zty/zty.dart';

class Build {
  static Future run(List<String> arguments) async {
    var loader = Loader();
    stdout.write('${zty()}$name - Iniciando...\n');

    // Verificar se é um projeto Flutter
    if (!await File('pubspec.yaml').exists()) {
      throw Exception('Este comando só pode ser executado em um projeto Flutter');
    }

    // Ler o pubspec.yaml para obter o nome e versão do projeto
    var pubspecFile = File('pubspec.yaml');
    var pubspecContent = await pubspecFile.readAsString();
    var pubspec = loadYaml(pubspecContent);
    var projectName = pubspec['name'];
    var projectVersion = pubspec['version'];

    // Verificar plataformas suportadas
    var platformsSupported = <String>[];

    // Verificar suporte Android
    if (await Directory('android').exists()) {
      platformsSupported.add('android');
    }

    // Verificar suporte iOS
    if (await Directory('ios').exists()) {
      platformsSupported.add('ios');
    }

    if (platformsSupported.isEmpty) {
      throw Exception('Este projeto não possui suporte para builds mobile (Android/iOS). Verifique se as pastas "android" ou "ios" existem no projeto.');
    }

    stdout.write('${zty()}$name - Gerando builds para $projectName v$projectVersion\n');
    stdout.write('${zty()}$name - Plataformas detectadas: ${platformsSupported.join(", ")}\n\n');

    // Criar diretório .bundles se não existir
    var bundlesDir = Directory('.bundles');
    if (!await bundlesDir.exists()) {
      await bundlesDir.create();
    } else {
      // Limpar diretório .bundles
      await bundlesDir.delete(recursive: true);
      await bundlesDir.create();
    }

    // Gerar Android App Bundle
    if (platformsSupported.contains('android')) {
      // Verificar se existe o arquivo key.properties
      var keyPropertiesFile = File('android/key.properties');
      if (!await keyPropertiesFile.exists()) {
        throw Exception('Arquivo android/key.properties não encontrado. Este arquivo é necessário para gerar o build Android.');
      }

      await Task(
          tag: '$name ${AnsiStyles.green('[Android]')} ${AnsiStyles.yellow(projectName)}',
          description: 'Gerando App Bundle',
          task: () async {
            var process = await Process.start('flutter', ['build', 'appbundle', '--release']);
            process.stdout.transform(utf8.decoder).listen((data) {
              stdout.write(data);
            });
            process.stderr.transform(utf8.decoder).listen((data) {
              stderr.write(data);
            });

            var exitCode = await process.exitCode;
            if (exitCode != 0) {
              throw Exception('Erro ao gerar App Bundle');
            }

            // Mover e renomear o arquivo .aab
            var aabFile = File('build/app/outputs/bundle/release/app-release.aab');
            if (await aabFile.exists()) {
              var newPath = path.join('.bundles', '${projectName}_$projectVersion.aab');
              await aabFile.copy(newPath);
            }
          }).run();
    }

    // Gerar iOS IPA
    if (platformsSupported.contains('ios')) {
      await Task(
          tag: '$name ${AnsiStyles.cyan('[iOS]')} ${AnsiStyles.yellow(projectName)}',
          description: 'Gerando IPA',
          task: () async {
            var process = await Process.start('flutter', ['build', 'ipa', '--release']);
            process.stdout.transform(utf8.decoder).listen((data) {
              stdout.write(data);
            });
            process.stderr.transform(utf8.decoder).listen((data) {
              stderr.write(data);
            });

            var exitCode = await process.exitCode;
            if (exitCode != 0) {
              throw Exception('Erro ao gerar IPA');
            }

            // Mover e renomear o arquivo .ipa
            var ipaFile = File('build/ios/ipa/$projectName.ipa');
            if (await ipaFile.exists()) {
              var newPath = path.join('.bundles', '${projectName}_$projectVersion.ipa');
              await ipaFile.copy(newPath);
            }
          }).run();
    }

    stdout.write('\n${zty()}$name - ${AnsiStyles.green('✔ Builds gerados com sucesso!')}\n');
    stdout.write('${zty()}$name - Os arquivos foram salvos em: ${AnsiStyles.yellow('.bundles/')}\n');
  }
}

String get name => AnsiStyles.magenta('[BUILD]');
