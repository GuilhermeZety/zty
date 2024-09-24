import 'dart:async';
import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';

class Loader {
  static const List<String> _spinners = ['|', '/', '-', '\\'];
  int _index = 0;
  Timer? _timer;

  // Inicia o spinner
  void start() {
    _timer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      // Adiciona uma cor diferente a cada símbolo do spinner
      var color = _index % 2 == 0 ? AnsiStyles.blue : AnsiStyles.cyan;
      stdout.write('\b${color(_spinners[_index])}'); // \b remove o último caractere
      _index = (_index + 1) % _spinners.length;
    });
  }

  // Para o spinner
  void stop() {
    if (_timer != null) {
      _timer!.cancel();
      stdout.write('\b'); // Remove o último spinner antes de escrever "OK"
    }
  }
}

class ColoredSpinner {
  static const List<String> _spinners = ['◐', '◓', '◑', '◒'];
  int _index = 0;
  Timer? _timer;

  // Inicia o spinner com cor
  void start() {
    _timer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      // Adiciona uma cor diferente a cada símbolo do spinner
      var color = _index % 2 == 0 ? AnsiStyles.blue : AnsiStyles.cyan;
      stdout.write('\b${color(_spinners[_index])}'); // \b remove o último caractere
      _index = (_index + 1) % _spinners.length;
    });
  }

  // Para o spinner
  void stop() {
    if (_timer != null) {
      _timer!.cancel();
      stdout.write('\b'); // Remove o último spinner antes de escrever "OK"
    }
  }
}
