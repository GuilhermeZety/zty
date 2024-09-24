import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';

void showHelp() {
  stdout.write('\r\n');
  stdout.write('\r${AnsiStyles.yellow('Opções')}:\n');
  stdout.write('\r\n');
  stdout.write('\r${AnsiStyles.green('--help,-h')}  Exibe esta mensagem de ajuda\n');
  stdout.write('\r\n');
  stdout.write('\r${AnsiStyles.green('--clean,-c')}  Roda um flutter clean em todos projetos do seu dispositivo\n');
  stdout.write('\r${AnsiStyles.green('--git-status,-gs')}  Verifica se possui algum projeto com pendências para subir ao git\n');
  stdout.write('\r\n');
}
