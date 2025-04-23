import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';

void showHelp() {
  stdout.write('\r\n');
  stdout.write('\r${AnsiStyles.bold.yellow('ZTY CLI - Gerenciador de Projetos')}\n');
  stdout.write('\r\n');

  // Comandos Principais
  stdout.write('\r${AnsiStyles.underline.yellow('Comandos Principais')}:\n');
  stdout.write('\r  ${AnsiStyles.green('verify')}        Verifica se há atualizações pendentes nos repositórios Git.\n');
  stdout.write('\r  ${AnsiStyles.green('status')}        Verifica o status Git dos projetos (pendências para commit/push).\n');
  stdout.write('\r  ${AnsiStyles.green('clean')}         Verifica quais projetos podem precisar de limpeza (ex: Flutter/Dart clean).\n');
  stdout.write('\r  ${AnsiStyles.green('clean --apply')} Executa a limpeza nos projetos identificados.\n');
  stdout.write('\r  ${AnsiStyles.green('delete')}        Lista projetos que podem ser movidos para a lixeira (sem atividade Git recente).\n');
  stdout.write('\r  ${AnsiStyles.green('delete --apply')} Move os projetos selecionados para a lixeira.\n');
  stdout.write('\r  ${AnsiStyles.green('update')}        Atualiza a CLI ZTY para a versão mais recente.\n');
  stdout.write('\r\n');

  // Opções de Filtragem
  stdout.write('\r${AnsiStyles.underline.yellow('Opções de Filtragem')} (use com os comandos principais):\n');
  stdout.write('\r  ${AnsiStyles.cyan('--only')} ${AnsiStyles.italic('proj1,proj2')} Executa o comando apenas nos projetos especificados.\n');
  stdout.write('\r                 Ex: zty clean --only meu_app,outro_projeto\n');
  stdout.write('\r  ${AnsiStyles.cyan('--ignore')} ${AnsiStyles.italic('proj1,proj2')} Executa o comando em todos, exceto nos projetos especificados.\n');
  stdout.write('\r                 Ex: zty status --ignore backend,docs\n');
  stdout.write('\r\n');

  // Opções Gerais
  stdout.write('\r${AnsiStyles.underline.yellow('Opções Gerais')}:\n');
  stdout.write('\r  ${AnsiStyles.blue('--help, -h')}    Exibe esta mensagem de ajuda.\n');
  stdout.write('\r  ${AnsiStyles.blue('--version, -v')} Exibe a versão atual da CLI.\n');
  stdout.write('\r\n');

  // TODO: Adicionar a funcionalidade de update
  // stdout.write('\r${AnsiStyles.green('update')}  Atualiza a CLI ZTY para a versão mais recente\n');
  // stdout.write('\r\n');
}

//TODO: criar função "update" para ir para pasta principal, verificar se ha alterações, caso tiver ja rodar um git pull
