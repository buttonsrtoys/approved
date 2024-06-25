// ignore_for_file: avoid_print

import 'dart:io';

import 'common.dart';

void printGitDiffs(String unapprovedFullPath, String differences, bool showTip) {
  const blueCliColor = '\x1B[94m';
  const resetCliColor = '\x1B[0m';

  print(topBar);
  print(differences.trim());
  if (showTip) {
    print("${blueCliColor}To review this result, run:$resetCliColor dart run approved:review '$unapprovedFullPath'");
    print("${blueCliColor}To review all results, run:$resetCliColor dart run approved:review");
  }
  print(bottomBar);
}

/// return the diff of two files
String gitDiffFiles(File path0, FileSystemEntity path1) {
  final processResult = Process.runSync('git', ['diff', '--no-index', path0.path, path1.path]);

  final processString = processResult.stdout.isNotEmpty || processResult.stderr.isNotEmpty ? processResult.stdout : '';

  return _stripGitDiff(processString);
}

/// Format the git --diff if superfluous text
String _stripGitDiff(String multiLineString) {
  bool startsWithAny(String line, List<String> prefixes) {
    return prefixes.any((prefix) => line.startsWith(prefix));
  }

  List<String> lines = multiLineString.split('\n');
  List<String> filteredLines = lines.where((line) => !startsWithAny(line, ['diff', 'index', '@@'])).toList();

  String result = filteredLines.join('\n');

  return result;
}
