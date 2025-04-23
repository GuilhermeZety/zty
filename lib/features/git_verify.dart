import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/zty.dart';

class GitVerify {
  static Future run(List<String> arguments) async {
    final gitVersionResult = await Process.run('git', ['--version']);
    if (gitVersionResult.exitCode != 0) {
      stdout.write('\r${zty()}$name - ${AnsiStyles.red('Erro: Git não está instalado ou não está disponível no PATH.')}\n');
      return;
    }

    final fetchResult = await Process.run('git', ['fetch']);
    if (fetchResult.exitCode != 0) {
      stdout.write('\r${zty()}$name - ${AnsiStyles.red('Erro ao executar git fetch:')} ${fetchResult.stderr}\n');
      return;
    }

    final branchResult = await Process.run('git', ['branch']);
    if (branchResult.exitCode != 0) {
      stdout.write('\r${zty()}$name - ${AnsiStyles.red('Erro ao listar branches:')} ${branchResult.stderr}\n');
      return;
    }
    final branchesRaw = (branchResult.stdout as String).trim().split('\n');
    final branches = branchesRaw.map((b) => b.trim().replaceAll('* ', '')).where((b) => b.isNotEmpty).toList();

    int processed = 0;
    int total = branches.length;
    String currentBranch = '';
    // Get current branch to checkout back later
    final currentBranchResult = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
    if (currentBranchResult.exitCode == 0) {
      currentBranch = currentBranchResult.stdout.toString().trim();
    }

    for (final branch in branches) {
      processed++;
      String progress = AnsiStyles.cyan('[$processed/$total]');

      final checkoutResult = await Process.run('git', ['checkout', branch]);
      if (checkoutResult.exitCode != 0) {
        stdout.write('$progress ${zty()}$name - ${AnsiStyles.red('Erro ao mudar para a branch $branch:')} ${checkoutResult.stderr}\n');

        continue;
      }

      // Verifica se há commits para puxar do remoto (behind)
      final behindResult = await Process.run('git', ['rev-list', '--count', 'HEAD..origin/$branch']);
      if (behindResult.exitCode != 0) {
        // Try default branch if origin/$branch doesn't exist
        final behindDefaultResult = await Process.run('git', ['rev-list', '--count', 'HEAD..origin/main']); // Assuming 'main' is default
        if (behindDefaultResult.exitCode != 0) {
          stdout.write(
              '$progress ${zty()}$name - ${AnsiStyles.yellow('Aviso:')} Não foi possível verificar commits remotos para a branch ${AnsiStyles.yellow(branch)}. Pode não existir remotamente ou o nome diverge (e.g., main vs master).\n');
        } else {
          final behindCount = int.tryParse(behindDefaultResult.stdout.toString().trim()) ?? 0;
          if (behindCount > 0) {
            stdout.write('$progress ${zty()}$name - Branch ${AnsiStyles.yellow(branch)}: ${AnsiStyles.magenta('BEHIND')} ($behindCount commits)\n');
          } else {
            // Check if ahead of origin/main
            final aheadDefaultResult = await Process.run('git', ['rev-list', '--count', 'origin/main..HEAD']);
            final aheadCount = int.tryParse(aheadDefaultResult.stdout.toString().trim()) ?? 0;
            if (aheadCount > 0) {
              stdout.write('$progress ${zty()}$name - Branch ${AnsiStyles.yellow(branch)}: ${AnsiStyles.cyan('AHEAD')} de origin/main ($aheadCount commits)\n');
            } else {
              stdout.write('$progress ${zty()}$name - Branch ${AnsiStyles.yellow(branch)}: ${AnsiStyles.green('OK')} (Sincronizada com origin/main)\n');
            }
          }
        }
      } else {
        final behindCount = int.tryParse(behindResult.stdout.toString().trim()) ?? 0;
        // Check if ahead
        final aheadResult = await Process.run('git', ['rev-list', '--count', 'origin/$branch..HEAD']);
        final aheadCount = int.tryParse(aheadResult.stdout.toString().trim()) ?? 0;

        if (behindCount > 0 && aheadCount > 0) {
          stdout.write('$progress ${zty()}$name - Branch ${AnsiStyles.yellow(branch)}: ${AnsiStyles.yellow('DIVERGED')} (Ahead: $aheadCount, Behind: $behindCount)\n');
        } else if (behindCount > 0) {
          stdout.write('$progress ${zty()}$name - Branch ${AnsiStyles.yellow(branch)}: ${AnsiStyles.magenta('BEHIND')} ($behindCount commits)\n');
        } else if (aheadCount > 0) {
          stdout.write('$progress ${zty()}$name - Branch ${AnsiStyles.yellow(branch)}: ${AnsiStyles.cyan('AHEAD')} ($aheadCount commits)\n');
        } else {
          stdout.write('$progress ${zty()}$name - Branch ${AnsiStyles.yellow(branch)}: ${AnsiStyles.green('OK')}\n');
        }
      }
    }

    // Checkout back to the original branch
    if (currentBranch.isNotEmpty && currentBranch != (await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD'])).stdout.toString().trim()) {
      stdout.write('\n${zty()}$name - Retornando para a branch original (${AnsiStyles.yellow(currentBranch)})... ');
      final checkoutBackResult = await Process.run('git', ['checkout', currentBranch]);
      if (checkoutBackResult.exitCode == 0) {
        stdout.write('${AnsiStyles.green('OK')}\n');
      } else {
        stdout.write('${AnsiStyles.red('Erro:')} ${checkoutBackResult.stderr}\n');
      }
    }
  }
}

String get name => AnsiStyles.magenta('[GIT-VERIFY]');
