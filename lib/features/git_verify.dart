import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/zty.dart';

class GitVerify {
  static Future run(List<String> arguments) async {
    // Verificar se o Git está instalado
    final gitVersionResult = await Process.run('git', ['--version']);
    if (gitVersionResult.exitCode != 0) {
      print(AnsiStyles.red('Git não está instalado ou não está disponível no PATH'));
      return;
    }

    final fetchResult = await Process.run('git', ['fetch']);
    if (fetchResult.exitCode != 0) {
      print(AnsiStyles.red('Erro ao executar git fetch'));
      return;
    }

    final branchResult = await Process.run('git', ['branch']);
    if (branchResult.exitCode != 0) {
      print(AnsiStyles.red('Erro ao listar branches'));
      return;
    }

    final branches = (branchResult.stdout as String).trim().split(' ').where((e) => e.isNotEmpty).toList();

    branches.remove('*');

    for (final branch in branches) {
      final checkoutResult = await Process.run('git', ['checkout', branch]);
      if (checkoutResult.exitCode != 0) {
        print(AnsiStyles.red('Erro ao mudar para a branch $branch'));
        continue;
      }

      // Verifica se há commits para puxar do remoto
      final revListResult = await Process.run('git', ['rev-list', 'HEAD..origin/$branch', '--count']);
      if (revListResult.exitCode != 0) {
        print(AnsiStyles.red('Erro ao verificar commits pendentes na branch $branch'));
        continue;
      }

      final commitCount = int.parse(revListResult.stdout.toString().trim());
      if (commitCount == 0) {
        stdout.write('\r${zty()}$name-${AnsiStyles.cyanBright('{$branch}')} - ${AnsiStyles.green('TUDO OK')} \n');
      } else {
        stdout.write('\r${zty()}$name-${AnsiStyles.cyanBright('{$branch}')} - ${AnsiStyles.red('$commitCount ATUALIZAÇÕES PENDENTES')} \n');
      }
    }

    // Voltar para a branch original
    await Process.run('git', ['checkout', '-']);
  }
}

String get name => AnsiStyles.magenta('[GIT-VERIFY]');
