import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:zty/rotating_loader.dart'; // Certifique-se que o caminho está correto

class Task {
  final String? tag;
  final String description;
  final Future Function() task;

  Task({required this.tag, required this.description, required this.task});

  Future run() async {
    var loader = Loader();
    // Mensagem inicial (não precisa mais do espaço duplo no final)
    final message = '${AnsiStyles.red('[ZTY]')}${tag != null ? '$tag' : ''} - $description';
    stdout.write(message); // Escreve a mensagem inicial (sem \n)

    loader.start(); // O loader adicionará seu próprio espaço inicial

    try {
      await task(); // Executa a tarefa

      // Pega o tempo final ANTES de parar o loader
      final finalElapsed = loader.elapsed;
      final timeString = (finalElapsed.inMilliseconds / 1000.0).toStringAsFixed(1);
      final finalTimeString = AnsiStyles.gray('(${timeString}s)'); // Formata o tempo final

      // Chama stop UMA VEZ, passando a mensagem completa com o tempo
      loader.stop(finalMessage: ' ✔ OK $finalTimeString', success: true);

      // REMOVIDO: stdout.write('\r$message  ${AnsiStyles.green('✔ OK')} \n');
    } catch (e) {
      // Pega o tempo final ANTES de parar o loader (mesmo em caso de erro)
      final finalElapsed = loader.elapsed;
      final timeString = (finalElapsed.inMilliseconds / 1000.0).toStringAsFixed(1);
      final finalTimeString = AnsiStyles.gray('(${timeString}s)'); // Formata o tempo final

      final errorMessage = e.toString().startsWith('Exception: ') ? e.toString().substring('Exception: '.length) : e.toString();

      // Chama stop UMA VEZ, passando a mensagem completa com o tempo
      loader.stop(finalMessage: '✗ Erro: $errorMessage $finalTimeString', success: false);

      // REMOVIDO: stdout.write('\r$message  ${AnsiStyles.red('Erro:')} ${e.toString().replaceAll('Exception: ', '')} \n');

      // Se precisar relançar a exceção, faça aqui:
      // rethrow;
    }
  }
}
