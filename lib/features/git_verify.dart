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

      final statusResult = await Process.run('git', ['status']);
      if (statusResult.exitCode != 0) {
        print(AnsiStyles.red('Erro ao executar git status na branch $branch'));
        continue;
      }

      if (statusResult.stdout.contains('Your branch is up to date')) {
        stdout.write('\r${zty()}$name-${AnsiStyles.cyanBright('{$branch}')} - ${AnsiStyles.green('TUDO OK')} \n');
      } else {
        stdout.write('\r${zty()}$name-${AnsiStyles.cyanBright('{$branch}')} - ${AnsiStyles.red('ATUALIZAÇÕES PENDENTES')} \n');
      }
    }

    // Voltar para a branch original
    await Process.run('git', ['checkout', '-']);
  }
}

String get name => AnsiStyles.magenta('[GIT-VERIFY]');
