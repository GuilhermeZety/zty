import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:zty/zty.dart';

void main(List<String> arguments) async {
  try {
    if (arguments.isEmpty) {
      stdout.write('Uso: dart run <script>.dart [find|strings]\n');
      return;
    }

    final command = arguments.first.toLowerCase();
    if (command == 'find') {
      await Find.run(arguments.sublist(1));
    } else if (command == 'strings') {
      await FindStrings.run(arguments.sublist(1));
    } else {
      stdout.write('Comando não reconhecido. Use "find" ou "strings".\n');
    }
  } catch (e) {
    stderr.write(AnsiStyles.red('Erro: ${e.toString()}\n'));
    exit(1);
  }
}

// =========================================================================
// ANALISADOR ORIGINAL (Apenas pacotes, assets e arquivos órfãos)
// =========================================================================
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
    List<String> realAssetFiles = [];
    for (var assetPath in declaredAssets) {
      if (assetPath.endsWith('/')) {
        var dir = Directory(assetPath);
        if (await dir.exists()) {
          var files = await dir.list(recursive: true).where((e) => e is File).toList();
          for (var f in files) {
            if (!f.path.contains('.DS_Store') && !f.path.contains('Thumbs.db')) {
              realAssetFiles.add(
                path.basename(f.path),
              );
            }
          }
        }
      } else {
        realAssetFiles.add(path.basename(assetPath));
      }
    }
    realAssetFiles = realAssetFiles.toSet().toList();
    stdout.write(AnsiStyles.green('OK (${realAssetFiles.length} arquivos encontrados)\n'));

    // --- FASE 3: Mapeando diretórios do Monorepo ---
    stdout.write('${zty()}$name - Buscando pastas de código (Monorepo)... ');
    List<File> allDartFiles = [];
    var rootDir = Directory.current;

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

    await for (var entity in rootDir.list(recursive: false)) {
      if (entity is Directory) {
        String dirName = path.basename(entity.path);

        if (dirName.startsWith('.') || ignoredFolders.contains(dirName)) {
          continue;
        }

        if (dirName == 'lib') {
          var files = await entity
              .list(recursive: true)
              .where((e) => e is File && e.path.endsWith('.dart'))
              .toList();
          allDartFiles.addAll(files.cast<File>());
          continue;
        }

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

    for (var assetFileName in realAssetFiles) {
      bool isUsed = false;

      for (var content in fileContents.values) {
        if (content.contains(assetFileName)) {
          isUsed = true;
          break;
        }
      }
      if (!isUsed) unusedAssets.add(assetFileName);
    }

    for (var currentFilePath in fileContents.keys) {
      String currentFileName = path.basename(currentFilePath);

      if (currentFileName == 'main.dart' ||
          currentFileName.endsWith('.g.dart') ||
          currentFileName.endsWith('.freezed.dart') ||
          currentFileName.endsWith('koin_core_assets.dart')) {
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

// =========================================================================
// NOVO ANALISADOR (Busca de strings não utilizadas)
// =========================================================================
class ClassDefinition {
  final String name;
  final List<String> lines;
  ClassDefinition(this.name, this.lines);
}

class StringClass {
  final String className;
  final Map<String, String> nestedFields; // fieldName -> TargetClassName
  final List<String> stringKeys; // Chaves literais (getters, métodos, variáveis)
  StringClass(this.className, this.nestedFields, this.stringKeys);
}

class StringFileInfo {
  final String filePath;
  final List<String> rootClassNames;
  final List<String> generatedPaths;

  StringFileInfo({
    required this.filePath,
    required this.rootClassNames,
    required this.generatedPaths,
  });
}

class FindStrings {
  static Future run(List<String> arguments) async {
    stdout.write('${zty()}$name - Iniciando análise de strings mortas...\n\n');

    if (!await File('pubspec.yaml').exists()) {
      throw Exception(
        'Este comando só pode ser executado na raiz de um projeto Flutter/Dart (pubspec.yaml não encontrado).',
      );
    }

    var rootDir = Directory.current;
    List<File> allDartFiles = [];
    List<File> stringFiles = [];

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

    stdout.write('${zty()}$name - Buscando pastas de código (Monorepo)... ');

    // Coleta recursiva de arquivos Dart nos módulos
    await for (var entity in rootDir.list(recursive: false)) {
      if (entity is Directory) {
        String dirName = path.basename(entity.path);

        if (dirName.startsWith('.') || ignoredFolders.contains(dirName)) {
          continue;
        }

        if (dirName == 'lib') {
          var files = await entity
              .list(recursive: true)
              .where((e) => e is File && e.path.endsWith('.dart'))
              .toList();
          allDartFiles.addAll(files.cast<File>());
          continue;
        }

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

    stdout.write(
      AnsiStyles.green(
        'OK (${stringFiles.length} arquivos de strings e ${allDartFiles.length - stringFiles.length} de código comuns)\n',
      ),
    );

    if (stringFiles.isEmpty) {
      stdout.write('${zty()}$name - Nenhum arquivo *_strings.dart foi localizado.\n\n');
      return;
    }

    // --- FASE 2: Carregando código comum para a memória (Lotes concorrentes) ---
    List<File> codeFiles =
        allDartFiles.where((f) => !path.basename(f.path).endsWith('_strings.dart')).toList();
    int totalFiles = codeFiles.length;
    Map<String, String> fileContents = {};

    stdout.write('${zty()}$name - Carregando código para a memória: [0/$totalFiles]');

    int filesRead = 0;
    int chunkSize = 50;

    for (int i = 0; i < totalFiles; i += chunkSize) {
      var chunk = codeFiles.skip(i).take(chunkSize);
      await Future.wait(
        chunk.map((file) async {
          try {
            String content = await file.readAsString();
            String relativePath = path.relative(file.path, from: rootDir.path);
            fileContents[relativePath.replaceAll('\\', '/')] = content;
          } catch (e) {
            // Ignora se houver algum arquivo ilegível
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

    // --- FASE 3: Processando os arquivos de strings e gerando as árvores (Interativo) ---
    stdout.write('${zty()}$name - Mapeando árvores de strings: [0/${stringFiles.length}]');
    List<StringFileInfo> stringInfos = [];
    for (int i = 0; i < stringFiles.length; i++) {
      var file = stringFiles[i];
      String relativePath = path.relative(file.path, from: rootDir.path);
      var info = await _parseStringFile(file, relativePath);
      if (info != null && info.generatedPaths.isNotEmpty) {
        stringInfos.add(info);
      }
      stdout.write(
        '\r${zty()}$name - Mapeando árvores de strings: [${AnsiStyles.yellow('${i + 1}/${stringFiles.length}')}]',
      );
    }

    int totalKeysMapped = stringInfos.fold<int>(0, (sum, item) => sum + item.generatedPaths.length);
    stdout.write(' ${AnsiStyles.green('OK ($totalKeysMapped caminhos mapeados)')}\n\n');

    // --- FASE 4: Análise de Referências (Interativo, Multilinhas e com Alias-Tracking) ---
    stdout.write('${zty()}$name - Analisando referências de strings: [0/$totalKeysMapped]');
    Map<String, List<String>> unusedStringsByFile = {};
    int analyzedKeys = 0;

    for (var info in stringInfos) {
      List<String> unusedKeys = [];

      // Otimização: Filtra arquivos candidatos que contenham a classe raiz
      var candidateFiles = fileContents.entries.where((entry) {
        return info.rootClassNames.any((rootName) => entry.value.contains(rootName));
      }).toList();

      // Mapeamento de variáveis locais criadas a partir das classes de string (Alias Tracker)
      // Ex: final strings = AuthenticationStrings.idValidationInstructions; -> strings mapeado para AuthenticationStrings.idValidationInstructions
      Map<String, Map<String, String>> fileAliases =
          {}; // filePath -> {aliasVariable: assignedPrefixPath}
      for (var entry in candidateFiles) {
        fileAliases[entry.key] = _findLocalAliases(entry.value, info.rootClassNames);
      }

      for (var keyPath in info.generatedPaths) {
        // Expressão regular tolerante a quebras de linhas no padrão tradicional: Class.branch.leaf
        var pattern = keyPath.split('.').map(RegExp.escape).join(r'\s*\.\s*');
        var regExp = RegExp(pattern);

        bool isUsed = false;
        for (var entry in candidateFiles) {
          // 1. Validação padrão pelo caminho absoluto completo (direto)
          if (regExp.hasMatch(entry.value)) {
            isUsed = true;
            break;
          }

          // 2. Validação alternativa por meio de aliases mapeados no arquivo atual
          var aliases = fileAliases[entry.key] ?? {};
          if (aliases.isNotEmpty) {
            bool usedByAlias = false;
            for (var aliasEntry in aliases.entries) {
              var varName = aliasEntry.key;
              var pathPrefix = aliasEntry.value;

              // Se a chave absoluta começar com o caminho mapeado no alias (ex: 'AuthenticationStrings.idValidationInstructions.')
              if (keyPath.startsWith('$pathPrefix.')) {
                // Remove o prefixo para extrair o resto do caminho (ex: 'title')
                var suffix = keyPath.substring(pathPrefix.length + 1);

                // Constrói regex que procura o uso do alias: varName.suffix (tolerando multilinhas)
                var aliasPattern = RegExp.escape(varName) +
                    r'\s*\.\s*' +
                    suffix.split('.').map(RegExp.escape).join(r'\s*\.\s*');
                var aliasRegExp = RegExp(aliasPattern);

                if (aliasRegExp.hasMatch(entry.value)) {
                  usedByAlias = true;
                  break;
                }
              }
            }
            if (usedByAlias) {
              isUsed = true;
              break;
            }
          }
        }
        if (!isUsed) {
          unusedKeys.add(keyPath);
        }

        analyzedKeys++;
        stdout.write(
          '\r${zty()}$name - Analisando referências de strings: [${AnsiStyles.yellow('$analyzedKeys/$totalKeysMapped')}]',
        );
      }

      if (unusedKeys.isNotEmpty) {
        unusedStringsByFile[info.filePath] = unusedKeys;
      }
    }
    stdout.write(' ${AnsiStyles.green('OK')}\n');

    // --- FASE 5: Exibir Resultados ---
    _printResults(unusedStringsByFile);
  }

  /// Lê o arquivo de strings e gera todas as combinações de caminhos de acesso possíveis.
  static Future<StringFileInfo?> _parseStringFile(File file, String relativePath) async {
    try {
      String content = await file.readAsString();
      List<ClassDefinition> classes = _parseClasses(content);

      if (classes.isEmpty) return null;

      Map<String, StringClass> classesByName = {};
      List<String> rootClassNames = [];

      for (var classDef in classes) {
        var className = classDef.name;

        // Junta as linhas da classe e limpa para uma análise isolada de chaves
        String classBody = classDef.lines.join('\n');

        // 1. Remove comentários de linha e de bloco
        classBody = classBody.replaceAll(RegExp(r'//.*'), '');
        classBody = classBody.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

        // 2. Normaliza literais de string para evitar captura de palavras dentro de aspas
        classBody = classBody.replaceAll(RegExp(r"'.*?'|\" ".*?\""), "''");

        // 3. Remove todo o conteúdo de parênteses (assinaturas de métodos), tornando-os vazios: ()
        // Isso previne que tipos de parâmetros (ex: String name) entrem na regex de propriedades da classe
        classBody = classBody.replaceAll(RegExp(r'\([\s\S]*?\)'), '()');

        Map<String, String> nestedFields = {};
        // Captura instanciamentos do tipo: static const promotional = _Promotional(); ou static const _Promotional promotional = _Promotional();
        var nestedRegex = RegExp(
          r'\b(?:static\s+|final\s+|const\s+)+(?:[a-zA-Z0-9_]+\s+)?([a-zA-Z0-9_]+)\s*=\s*(?:const\s+)?(_?[A-Z][a-zA-Z0-9_]*)\(\)',
        );

        var nestedMatches = nestedRegex.allMatches(classBody);
        for (var match in nestedMatches) {
          var fieldName = match.group(1)!;
          var targetClass = match.group(2)!;
          nestedFields[fieldName] = targetClass;
        }

        List<String> stringKeys = [];
        // Captura getters, métodos ou declarações com tipo explícito String
        var stringRegexTyped = RegExp(r'\bString\s+(?:get\s+)?([a-zA-Z0-9_]+)\b');
        var typedMatches = stringRegexTyped.allMatches(classBody);
        for (var match in typedMatches) {
          var keyName = match.group(1)!;
          if (keyName != className) {
            stringKeys.add(keyName);
          }
        }

        // Captura atribuições implícitas a strings literais: static const display = 'title';
        var stringRegexImplicit =
            RegExp(r'\b(?:static|final|const)\s+([a-zA-Z0-9_]+)\s*=\s*[\x27\x22]');
        var implicitMatches = stringRegexImplicit.allMatches(classBody);
        for (var match in implicitMatches) {
          var keyName = match.group(1)!;
          if (keyName != className) {
            stringKeys.add(keyName);
          }
        }

        stringKeys = stringKeys.toSet().toList();
        classesByName[className] = StringClass(className, nestedFields, stringKeys);

        // Se a classe não começar com underline (ex: HomeStrings), ela é considerada uma raiz acessível.
        if (!className.startsWith('_')) {
          rootClassNames.add(className);
        }
      }

      // Fallback: se por algum motivo não houver classe pública, assume a primeira declarada no arquivo
      if (rootClassNames.isEmpty && classes.isNotEmpty) {
        rootClassNames.add(classes.first.name);
      }

      List<String> generatedPaths = [];
      for (var root in rootClassNames) {
        _resolvePaths(root, root, classesByName, generatedPaths);
      }

      return StringFileInfo(
        filePath: relativePath.replaceAll('\\', '/'),
        rootClassNames: rootClassNames,
        generatedPaths: generatedPaths,
      );
    } catch (e) {
      return null;
    }
  }

  /// Recorta o conteúdo do arquivo separando o bloco de cada classe individualmente
  static List<ClassDefinition> _parseClasses(String content) {
    List<ClassDefinition> classes = [];
    var lines = content.split('\n');
    String? currentClassName;
    List<String> currentClassLines = [];
    int braceCount = 0;

    for (var line in lines) {
      var trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      var classMatch = RegExp(r'\bclass\s+([a-zA-Z0-9_]+)\b').firstMatch(trimmed);
      if (classMatch != null && braceCount == 0) {
        currentClassName = classMatch.group(1);
        currentClassLines = [];
      }

      if (currentClassName != null) {
        currentClassLines.add(line);

        // Remove comentários de linha inteira para evitar falsa contagem de chaves curly {}
        String cleanLine = line.split('//').first;
        // Limpa literais de texto com aspas simples/duplas para que chaves dentro dos textos não quebrem o balanceamento
        cleanLine = cleanLine.replaceAll(RegExp(r"'.*?'|\" ".*?\""), '');

        for (var char in cleanLine.codeUnits) {
          if (char == 123) braceCount++; // '{'
          if (char == 125) braceCount--; // '}'
        }

        if (braceCount == 0) {
          classes.add(ClassDefinition(currentClassName, currentClassLines));
          currentClassName = null;
        }
      }
    }
    return classes;
  }

  /// Resolve recursivamente todos os caminhos gerados pelas estruturas de classes
  static void _resolvePaths(
    String currentPath,
    String currentClassName,
    Map<String, StringClass> classesByName,
    List<String> results,
  ) {
    var currentClass = classesByName[currentClassName];
    if (currentClass == null) return;

    for (var key in currentClass.stringKeys) {
      results.add('$currentPath.$key');
    }

    for (var entry in currentClass.nestedFields.entries) {
      var fieldName = entry.key;
      var targetClassName = entry.value;
      _resolvePaths('$currentPath.$fieldName', targetClassName, classesByName, results);
    }
  }

  /// Busca mapeamentos locais (apelidos/aliases) que representam caminhos de strings neste arquivo.
  /// Ex: final s = AuthenticationStrings.idValidation; -> retorna { 's': 'AuthenticationStrings.idValidation' }
  static Map<String, String> _findLocalAliases(String fileContent, List<String> rootClassNames) {
    Map<String, String> aliases = {};

    for (var root in rootClassNames) {
      // Regex que busca atribuições de caminhos com ou sem tipagem explícita
      var pattern =
          r'\b(?:const|final|var|_?[A-Z][a-zA-Z0-9_]*|dynamic)\s+([a-zA-Z0-9_]+)\s*=\s*(' +
              RegExp.escape(root) +
              r'(?:\s*\.\s*[a-zA-Z0-9_]+)*)\b';
      var regex = RegExp(pattern);

      for (var match in regex.allMatches(fileContent)) {
        var varName = match.group(1)!;
        // Normaliza eventuais quebras de linha/espaços na declaração do caminho atribuído
        var assignedPath = match.group(2)!.replaceAll(RegExp(r'\s+'), '');
        aliases[varName] = assignedPath;
      }
    }
    return aliases;
  }

  static void _printResults(Map<String, List<String>> unusedStringsByFile) {
    stdout.write('\n${zty()}$name - ${AnsiStyles.green('✔ Análise de strings concluída!')}\n\n');

    if (unusedStringsByFile.isEmpty) {
      stdout.write(
        '  🎉 ${AnsiStyles.green.bold('Todas as strings mapeadas estão sendo utilizadas no seu app!')}\n\n',
      );
      return;
    }

    int totalUnused = unusedStringsByFile.values.fold(0, (sum, list) => sum + list.length);
    stdout.write(
      '📝 ${AnsiStyles.yellow.bold('Strings Declaradas mas Não Utilizadas ($totalUnused encontradas):')}\n\n',
    );

    unusedStringsByFile.forEach((filePath, keys) {
      stdout.write('📍 ${AnsiStyles.cyan.bold(filePath)} (${keys.length} sem uso):\n');
      for (var key in keys) {
        stdout.write('   - ${AnsiStyles.red(key)}\n');
      }
      stdout.write('\n');
    });

    stdout.write(
      '   ${AnsiStyles.gray('(Dica: Verifique estas variáveis no projeto para garantir que não são chamadas de forma dinâmica)')}\n\n',
    );
  }

  static String get name => AnsiStyles.yellow('[STRINGS]');
}
