import 'dart:async';
import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';

class Loader {
  static const List<String> _defaultSpinners = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

  final List<String> _spinners;
  final Duration _updateInterval;
  Duration get elapsed => _stopwatch.elapsed;
  int _index = 0;
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  int _lastOutputLength = 0; // Armazena o comprimento VISÍVEL da última saída

  Loader({
    List<String>? spinners,
    Duration updateInterval = const Duration(milliseconds: 100),
  })  : _spinners = spinners ?? _defaultSpinners,
        _updateInterval = updateInterval;

  /// Inicia o spinner e o timer APÓS o texto já existente na linha.
  void start() {
    if (_timer != null) return; // Já está rodando

    _index = 0;
    _stopwatch.reset();
    _stopwatch.start();
    _lastOutputLength = 0; // Reseta o comprimento

    // Esconde o cursor para estética
    stdout.write('\x1B[?25l');

    // Chama a atualização uma vez para mostrar imediatamente
    _updateDisplay();

    // Inicia o timer para atualizações periódicas
    _timer = Timer.periodic(_updateInterval, (timer) {
      _updateDisplay();
    });
  }

  /// Para o spinner, limpa apenas a sua própria saída e imprime uma mensagem final.
  /// A mensagem final INCLUI uma nova linha.
  void stop({String finalMessage = '✔ OK', bool success = true}) {
    if (_timer == null) return; // Não estava rodando

    _timer!.cancel();
    _timer = null;
    _stopwatch.stop();

    // Apaga a última saída do spinner/timer usando backspaces
    stdout.write('\b' * _lastOutputLength);

    // Define a cor da mensagem final
    var color = success ? AnsiStyles.green : AnsiStyles.red;
    // Escreve a mensagem final e adiciona uma NOVA LINHA
    stdout.write('${color(finalMessage)}\n');

    // Mostra o cursor novamente
    stdout.write('\x1B[?25h');

    // Reseta estado
    _index = 0;
    _lastOutputLength = 0;
  }

  /// Atualiza a exibição do spinner e do timer no console, apagando a saída anterior.
  void _updateDisplay() {
    // Seleciona a cor (pode personalizar)
    var spinnerColor = _index % 2 == 0 ? AnsiStyles.blue : AnsiStyles.cyan;
    var timeColor = AnsiStyles.gray; // Cor para o tempo

    // Obtém o caractere atual do spinner
    final spinnerChar = spinnerColor(_spinners[_index]);

    // Calcula e formata o tempo decorrido
    final elapsedSeconds = (_stopwatch.elapsedMilliseconds / 1000.0);
    final timeString = timeColor('${elapsedSeconds.toStringAsFixed(1)}s');

    // Monta a string de saída atual (com um espaço inicial)
    final currentOutput = ' $spinnerChar $timeString';
    // Calcula o comprimento VISÍVEL (sem códigos ANSI) para os backspaces
    final currentVisibleLength = AnsiStyles.strip(currentOutput).length;

    // Apaga a saída anterior (se houver) usando backspaces
    stdout.write('\b' * _lastOutputLength);
    // Escreve a nova saída
    stdout.write(currentOutput);

    // Armazena o comprimento visível para a próxima atualização
    _lastOutputLength = currentVisibleLength;

    // Avança para o próximo caractere do spinner
    _index = (_index + 1) % _spinners.length;
  }

  /// Cancela o spinner limpando sua saída e movendo para a próxima linha.
  void cancel() {
    if (_timer == null) return;

    _timer!.cancel();
    _timer = null;
    _stopwatch.stop();
    _stopwatch.reset();

    // Apaga a última saída do spinner/timer
    stdout.write('\b' * _lastOutputLength);
    // Garante que qualquer coisa restante seja limpa (opcional, mas seguro)
    // stdout.write(' ' * _lastOutputLength);
    // stdout.write('\b' * _lastOutputLength);

    // Move para a próxima linha para não interferir com saídas futuras
    stdout.write('\n');

    // Mostra o cursor novamente
    stdout.write('\x1B[?25h');
    _index = 0;
    _lastOutputLength = 0;
  }
}
