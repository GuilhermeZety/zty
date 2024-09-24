import 'dart:io';

void ocultarCursor() {
  stdout.write('\x1B[?25l');
}

void mostrarCursor() {
  stdout.write('\x1B[?25h');
}
