import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:zty/zty.dart';

class Find {
  static Future run(List<String> arguments) async {
    stdout.write('${zty()}$name - Iniciando análise de código morto...\n\n');

    if (!await File('pubspec.yaml').exists()) {
      throw Exception(
        'Este comando só pode ser executado na raiz de um projeto Flutter/Dart (pubspec.yaml não encontrado).',
      );
    }

    List<String> unusedPackages = [];
    List<String> unusedAssets = [];
    List<String> unusedDartFiles = [];

    // --- FASE 1: Lendo Pubspec ---
    stdout.write('${zty()}$name - Lendo pubspec.yaml... ');
    var pubspecContent = await File('pubspec.yaml').readAsString();
    var pubspec = loadYaml(pubspecContent);

    List<String> packages = [];
    if (pubspec['dependencies'] != null) {
      packages = (pubspec['dependencies'] as Map).keys.cast<String>().toList();
      packages.removeWhere(
        (p) => p == 'flutter' || p == 'cupertino_icons' || p == 'flutter_localizations',
      );
    }

    List<String> declaredAssets = [];
    if (pubspec['flutter'] != null && pubspec['flutter']['assets'] != null) {
      declaredAssets = (pubspec['flutter']['assets'] as List).cast<String>();
    }
    stdout.write(AnsiStyles.green('OK\n'));

    // --- FASE 2: Resolvendo Assets reais no disco ---
    stdout.write('${zty()}$name - Mapeando assets no disco... ');
    List<String> realAssetFiles = []; // Vamos guardar apenas os NOMES dos arquivos
    for (var assetPath in declaredAssets) {
      if (assetPath.endsWith('/')) {
        var dir = Directory(assetPath);
        if (await dir.exists()) {
          var files = await dir.list(recursive: true).where((e) => e is File).toList();
          for (var f in files) {
            if (!f.path.contains('.DS_Store') && !f.path.contains('Thumbs.db')) {
              realAssetFiles.add(
                path.basename(f.path),
              ); // Guarda APENAS o nome (ex: img_welcome_1.png)
            }
          }
        }
      } else {
        realAssetFiles.add(path.basename(assetPath));
      }
    }
    // Remove duplicatas caso existam arquivos com mesmo nome em pastas diferentes
    realAssetFiles = realAssetFiles.toSet().toList();
    stdout.write(AnsiStyles.green('OK (${realAssetFiles.length} arquivos encontrados)\n'));

    // --- FASE 3: Mapeando diretórios do Monorepo ---
    stdout.write('${zty()}$name - Buscando pastas de código (Monorepo)... ');
    List<File> allDartFiles = [];
    var rootDir = Directory.current;

    // Pastas que NUNCA devemos analisar o código Dart
    final ignoredFolders = [
      'android',
      'ios',
      'windows',
      'linux',
      'macos',
      'web',
      'test',
      'integration_test',
      'coverage',
      'assets',
      'fonts',
      'build',
    ];

    // Função recursiva para achar todos os arquivos dart dentro de qualquer pasta "lib" válida
    await for (var entity in rootDir.list(recursive: false)) {
      if (entity is Directory) {
        String dirName = path.basename(entity.path);

        // Ignora pastas ocultas (ex: .git, .dart_tool) e as nativas/build
        if (dirName.startsWith('.') || ignoredFolders.contains(dirName)) {
          continue;
        }

        // Se for a pasta raiz 'lib', adiciona tudo
        if (dirName == 'lib') {
          var files = await entity
              .list(recursive: true)
              .where((e) => e is File && e.path.endsWith('.dart'))
              .toList();
          allDartFiles.addAll(files.cast<File>());
          continue;
        }

        // Se for uma sub-pasta (ex: design_system), verifica se tem uma pasta 'lib' dentro dela
        var subLibDir = Directory(path.join(entity.path, 'lib'));
        if (await subLibDir.exists()) {
          var files = await subLibDir
              .list(recursive: true)
              .where((e) => e is File && e.path.endsWith('.dart'))
              .toList();
          allDartFiles.addAll(files.cast<File>());
        }
      }
    }
    stdout.write(AnsiStyles.green('OK (${allDartFiles.length} arquivos Dart encontrados)\n'));

    // --- FASE 4: Lendo arquivos Dart (Concorrente em Lotes) ---
    int totalFiles = allDartFiles.length;
    Map<String, String> fileContents = {};

    stdout.write('${zty()}$name - Carregando código para a memória: [0/$totalFiles]');

    int filesRead = 0;
    int chunkSize = 50;

    for (int i = 0; i < totalFiles; i += chunkSize) {
      var chunk = allDartFiles.skip(i).take(chunkSize);
      await Future.wait(
        chunk.map((file) async {
          try {
            String content = await file.readAsString();
            // Guarda o path relativo a partir do root para ficar bonito no print
            String relativePath = path.relative(file.path, from: rootDir.path);
            fileContents[relativePath.replaceAll('\\', '/')] = content;
          } catch (e) {
            // Ignora arquivos ilegíveis
          } finally {
            filesRead++;
            stdout.write(
              '\r${zty()}$name - Carregando código para a memória: [${AnsiStyles.yellow('$filesRead/$totalFiles')}]',
            );
          }
        }),
      );
    }
    stdout.write(' ${AnsiStyles.green('OK')}\n\n');

    // --- FASE 5: Análise Pesada (Em Memória) ---
    stdout.write('${zty()}$name - Analisando referências cruzadas... aguarde.\n');

    // 5.1 Validar Packages
    for (var package in packages) {
      bool isUsed = false;
      for (var content in fileContents.values) {
        if (content.contains('package:$package/')) {
          isUsed = true;
          break;
        }
      }
      if (!isUsed) unusedPackages.add(package);
    }

    // 5.2 Validar Assets (Agora busca SÓ pelo nome do arquivo)
    for (var assetFileName in realAssetFiles) {
      bool isUsed = false;

      for (var content in fileContents.values) {
        // Ex: Procura exatamente por 'img_welcome_1.png' dentro da String do arquivo Dart
        if (content.contains(assetFileName)) {
          isUsed = true;
          break;
        }
      }
      if (!isUsed) unusedAssets.add(assetFileName);
    }

    // 5.3 Validar Arquivos Dart (Dead Code)
    for (var currentFilePath in fileContents.keys) {
      String currentFileName = path.basename(currentFilePath);

      if (currentFileName == 'main.dart' ||
          currentFileName.endsWith('.g.dart') ||
          currentFileName.endsWith('.freezed.dart') ||
          currentFileName.endsWith('koin_core_assets.dart')) {
        // Ignora arquivos base geradores
        continue;
      }

      bool isImported = false;
      for (var entry in fileContents.entries) {
        String otherFilePath = entry.key;
        String otherFileContent = entry.value;

        if (currentFilePath == otherFilePath) continue;

        if (otherFileContent.contains(currentFileName)) {
          isImported = true;
          break;
        }
      }

      if (!isImported) unusedDartFiles.add(currentFilePath);
    }

    // --- FASE 6: Exibir Resultados ---
    _printResults(unusedPackages, unusedAssets, unusedDartFiles);
  }

  static void _printResults(List<String> packages, List<String> assets, List<String> files) {
    stdout.write('\n${zty()}$name - ${AnsiStyles.green('✔ Análise concluída!')}\n\n');

    if (packages.isEmpty && assets.isEmpty && files.isEmpty) {
      stdout.write(
        '  🎉 ${AnsiStyles.green.bold('Seu projeto está impecável! Nenhum lixo encontrado.')}\n\n',
      );
      return;
    }

    if (packages.isNotEmpty) {
      stdout.write(
        '📦 ${AnsiStyles.red.bold('Packages Não Utilizados no código (${packages.length}):')}\n',
      );
      for (var p in packages) {
        stdout.write('   - $p\n');
      }
      stdout.write('   ${AnsiStyles.gray('(Dica: Remova-os do pubspec.yaml)')}\n\n');
    }

    if (assets.isNotEmpty) {
      stdout.write(
        '🖼️  ${AnsiStyles.yellow.bold('Assets Não Referenciados (${assets.length}):')}\n',
      );
      for (var a in assets) {
        stdout.write('   - $a\n');
      }
      stdout.write('   ${AnsiStyles.gray('(Dica: Apague os arquivos ou use-os no código)')}\n\n');
    }

    if (files.isNotEmpty) {
      stdout.write(
        '📄 ${AnsiStyles.cyan.bold('Arquivos Dart Órfãos / Não Importados (${files.length}):')}\n',
      );
      for (var f in files) {
        stdout.write('   - $f\n');
      }
      stdout.write(
        '   ${AnsiStyles.gray('(Dica: Verifique se são telas/widgets esquecidos e exclua-os)')}\n\n',
      );
    }
  }

  static String get name => AnsiStyles.green('[FIND]');
}
