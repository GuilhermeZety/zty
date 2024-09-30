import 'dart:io';

Future<List<(String path, String? type)>> getProjectsPaths({bool getType = true, bool ignoreZty = false}) async {
  List<(String, String?)> projects = [];
  List<Directory> childrens = [];

  var allFiles = Directory('${Platform.environment['HOME']}').listSync();

  var allFolders = allFiles.whereType<Directory>().where((e) => !e.path.contains('/.')).toList();

  for (var folder in allFolders) {
    String? type;
    if (File('${folder.path}/pubspec.lock').existsSync()) {
      type = 'Flutter';
    } else if (File('${folder.path}/pubspec.yaml').existsSync()) {
      type = 'Dart';
    } else if (File('${folder.path}/tsconfig.json').existsSync()) {
      type = 'Typescript';
    } else if (File('${folder.path}/package.json').existsSync()) {
      type = 'JavaScript';
    }

    if (type != null) {
      projects.add((folder.path, type));
    }
    var childrenFiles = folder.listSync();
    var childrenFolders = childrenFiles.whereType<Directory>().where((e) => !e.path.contains('/.')).toList();

    childrens.addAll(childrenFolders);
  }

  for (var folder in childrens) {
    String? type;
    if (File('${folder.path}/pubspec.lock').existsSync()) {
      type = 'Flutter';
    } else if (File('${folder.path}/pubspec.yaml').existsSync()) {
      type = 'Dart';
    } else if (File('${folder.path}/tsconfig.json').existsSync()) {
      type = 'Typescript';
    } else if (File('${folder.path}/package.json').existsSync()) {
      type = 'JavaScript';
    }

    if (type != null) {
      projects.add((folder.path, type));
    }
  }
  if (ignoreZty) {
    projects.removeWhere((e) => e.$1.contains('my_cli_app') || e.$1.contains('zty'));
  }
  return projects;
}
