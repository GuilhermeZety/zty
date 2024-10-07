import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';

void showHelp() {
  stdout.write('\r\n');
  stdout.write('\r${AnsiStyles.yellow('Opções')}:\n');
  stdout.write('\r\n');
  stdout.write('\r${AnsiStyles.green('status')}  Verifica se possui algum projeto com pendências para subir ao git\n');
  stdout.write('\r${AnsiStyles.green('clean')}  Verifica se há algum projeto que precisa de limpeza\n');
  stdout.write('\r${AnsiStyles.green('clean --apply')} Verifica e limpa todos os projetos\n');
  stdout.write('\r\n');
  stdout.write('\r${AnsiStyles.green('--only projeto1')}  Usa a função em N projetos especificos, EX: "zty clean --only projeto1,projeto2"\n');
  stdout.write('\r${AnsiStyles.green('--ignore projeto1')}  Usa a função em todos IGNORANDO o projeto especificado, EX: "zty clean --only projeto1,projeto2"\n');
  stdout.write('\r\n');
  stdout.write('\r${AnsiStyles.green('--help,-h')}  Exibe esta mensagem de ajuda\n');
  stdout.write('\r\n');
}

//TODO: criar função "update" para ir para pasta principal, verificar se ha alterações, caso tiver ja rodar um git pull