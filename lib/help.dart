import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';

void showHelp() {
  stdout.write('\r\n');
  stdout.write('\r${AnsiStyles.yellow('Opções')}:\n');
  stdout.write('\r\n');
  stdout.write('\r${AnsiStyles.green('status')}  Verifica se possui algum projeto com pendências para subir ao git\n');
  stdout.write('\r${AnsiStyles.green('clean')}  Verifica se há algum projeto que precisa de limpeza\n');
  stdout.write('\r${AnsiStyles.green('clean --only projeto, ...')}  Verifica se há pendencia de limpeza em N projetos especificos, ex: clean --only meu_projeto,segundo_projeto\n');
  stdout.write('\r${AnsiStyles.green('clean --apply')} Verifica e limpa todos os projetos\n');
  stdout.write('\r${AnsiStyles.green('clean --apply --only projeto, ...')}  Verifica e limpa N projetos especificos, ex: clean --apply --only meu_projeto,segundo_projeto\n');
  stdout.write('\r\n');
  stdout.write('\r${AnsiStyles.green('--help,-h')}  Exibe esta mensagem de ajuda\n');
  stdout.write('\r\n');
}

//TODO: criar função "update" para ir para pasta principal, verificar se ha alterações, caso tiver ja rodar um git pull