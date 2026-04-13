import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:path/path.dart' as p;
import 'package:zty/zty.dart';

class ConvertIcons {
  static Future run(List<String> arguments) async {
    stdout.write('${zty()}$name - Iniciando pipeline de ícones...\n\n');

    // 1. Verificação do Inkscape
    stdout.write('${zty()}$name - Verificando dependências (Inkscape)... ');
    if (!await _isInkscapeInstalled()) {
      stdout.write(AnsiStyles.red('FALHOU\n'));
      throw Exception('O Inkscape não está instalado ou não está no PATH do sistema.\n'
          'Por favor, instale o Inkscape (https://inkscape.org/) para usar esta função.');
    }
    stdout.write(AnsiStyles.green('OK\n'));

    // 2. Mapeamento de Arquivos
    final layoutDir = Directory.current;
    final files = layoutDir
        .listSync()
        .whereType<File>()
        .where(
          (f) => f.path.toLowerCase().endsWith('.svg'),
        )
        .toList();

    if (files.isEmpty) {
      stdout.write('${zty()}$name - ${AnsiStyles.yellow('Nenhum arquivo .svg encontrado.')}\n\n');
      stdout.write('   Você executou o comando no diretório:\n');
      stdout.write('   📁 ${AnsiStyles.gray(layoutDir.path)}\n\n');
      stdout.write(
          '   ${AnsiStyles.cyan.bold('💡 Dica:')} Navegue até a pasta que contém os seus ícones antes de rodar a CLI:\n');
      stdout.write('   👉 ${AnsiStyles.yellow('cd caminho/para/sua/pasta/de/assets')}\n');
      stdout.write('   👉 ${AnsiStyles.yellow('zty icons')}\n\n');
      return;
    }

    final corrigidosDir = Directory('converted_icons');
    if (!corrigidosDir.existsSync()) corrigidosDir.createSync();

    int totalFiles = files.length;
    int filesProcessed = 0;

    stdout.write('${zty()}$name - Convertendo SVG e padronizando geometria: [0/$totalFiles]');

    // 3. Processamento
    for (var file in files) {
      String baseName = p.basename(file.path);
      String tempFile = p.join(corrigidosDir.path, 'temp_$baseName');

      // PASSO 1: Inkscape Engine
      final result = await Process.run('inkscape', [
        file.path,
        '--export-plain-svg',
        '--actions=select-all;object-stroke-to-path;export-filename:$tempFile;export-do',
      ]);

      if (result.exitCode != 0) {
        throw Exception('Erro ao converter $baseName pelo Inkscape: ${result.stderr}');
      }

      // PASSO 2: Limpeza Extrema (Dart)
      File tempSvg = File(tempFile);
      String conteudo = await tempSvg.readAsString();

      // Limpa metadados do Inkscape
      conteudo = conteudo.replaceAll(
          RegExp(r'<sodipodi:namedview.*?</sodipodi:namedview>', dotAll: true), '');
      conteudo = conteudo.replaceAll(RegExp(r'xmlns:sodipodi="[^"]*"'), '');
      conteudo = conteudo.replaceAll(RegExp(r'xmlns:inkscape="[^"]*"'), '');

      // Remove tags de <style> e atributos style="..."
      conteudo = conteudo.replaceAll(RegExp(r'<style.*?</style>', dotAll: true), '');
      conteudo = conteudo.replaceAll(RegExp(r'\s*style="[^"]*"'), '');

      // Limpa preenchimentos e bordas sujas
      conteudo = conteudo.replaceAll(RegExp(r'\s*fill-rule="evenodd"\s*fill="black"'), '');
      conteudo = conteudo.replaceAll(RegExp(r'\s*fill-rule="evenodd"'), '');
      conteudo = conteudo.replaceAll(RegExp(r'\s*stroke="none"'), '');
      conteudo = conteudo.replaceAll(RegExp(r'fill="none"'), 'fill="black"');

      // Força a tag <path a ter o fill="black"
      if (!conteudo.contains('fill="black"')) {
        conteudo = conteudo.replaceAll('<path ', '<path fill="black" ');
      }

      // PASSO 3: Higienização do Nome (Snake Case)
      String cleanName = baseName.replaceAll(RegExp(r'\.svg$', caseSensitive: false), '');
      cleanName = _removerAcentos(cleanName)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');

      if (RegExp(r'^[0-9]').hasMatch(cleanName)) cleanName = 'icon_$cleanName';

      final finalFilePath = p.join(corrigidosDir.path, '$cleanName.svg');

      // Salvar e apagar temporário
      await File(finalFilePath).writeAsString(conteudo);
      await tempSvg.delete();

      filesProcessed++;
      stdout.write(
          '\r${zty()}$name - Convertendo SVG e padronizando geometria: [${AnsiStyles.yellow('$filesProcessed/$totalFiles')}]');
    }

    stdout.write(' ${AnsiStyles.green('OK')}\n\n');
    stdout.write('${zty()}$name - ${AnsiStyles.green('✔ Pipeline finalizado com sucesso!')}\n');
    stdout.write(
        '${zty()}$name - Seus ícones formatados estão na pasta: ${AnsiStyles.yellow('converted_icons/')}\n');
  }

  // Verifica se o Inkscape está no PATH
  static Future<bool> _isInkscapeInstalled() async {
    try {
      final result = await Process.run('inkscape', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static String _removerAcentos(String texto) {
    var comAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var semAcento = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < comAcento.length; i++) {
      texto = texto.replaceAll(comAcento[i], semAcento[i]);
    }
    return texto;
  }

  static String get name => AnsiStyles.yellow('[CONVERT_ICONS]');
}
