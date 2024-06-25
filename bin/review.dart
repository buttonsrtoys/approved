// ignore_for_file: avoid_print

import 'dart:io';

import 'package:approved/src/common.dart';

// ignore: avoid_relative_lib_imports
import '../lib/src/git_diffs.dart';

void main(List<String> args) async {
  List<Future<void>> tasks = [];

  void processUnapprovedFile(File unapprovedFile) {
    if (!unapprovedFile.existsSync()) {
      print(topBar);
      print('Error: the file below does not exist for review comparison:');
      print(unapprovedFile.path);
      print(bottomBar);
      return;
    }

    final approvedFileName = unapprovedFile.path.replaceAll('.unapproved.txt', '.approved.txt');
    final approvedFile = File(approvedFileName);

    if (approvedFile.existsSync()) {
      tasks.add(processFile(approvedFile, unapprovedFile));
    } else {
      tasks.add(processFile(null, unapprovedFile));
    }
  }

  /// If no args, then searching the whole project
  if (args.isEmpty) {
    final searchDirectory = Directory.current;

    /// Recursively search for current files
    await for (final file in searchDirectory.list(recursive: true)) {
      if (file.path.endsWith('.unapproved.txt')) {
        processUnapprovedFile(file as File);
      }
    }
  } else {
    /// args is not empty, so running a single file review
    final unapprovedFile = File(args[0]);
    processUnapprovedFile(unapprovedFile);
  }

  await Future.wait(tasks);

  print('Review process completed.');
}

/// Check of the files are different using "git diff"
Future<void> processFile(File? approvedFile, File unapprovedFile) async {
  late String resultString;
  if (approvedFile == null) {
    final unapprovedText = unapprovedFile.readAsStringSync();
    resultString = '$firstReviewHeader\n$unapprovedText';
  } else {
    final gitDiff = gitDiffFiles(approvedFile, unapprovedFile);
    resultString = '$diffReviewHeader\n$gitDiff';
  }

  if (resultString.isNotEmpty) {
    printGitDiffs(unapprovedFile.path, resultString, false);

    String? firstCharacter;

    do {
      stdout.write('Accept changes? (y/N/[v]iew): ');
      final response = stdin.readLineSync()?.trim().toLowerCase();

      firstCharacter = null;
      if (response != null && response.isNotEmpty) {
        firstCharacter = response[0];
      }

      final unapprovedFilename = unapprovedFile.path;
      final approvedFilename = unapprovedFile.path.replaceAll(unapprovedExtension, approvedExtension);

      if (firstCharacter == 'y') {
        if (approvedFile != null) {
          await approvedFile.delete();
        }
        await unapprovedFile.rename(approvedFilename);
        print('Approval test approved');
      } else if (firstCharacter == 'v') {
        if (isCodeCommandAvailable()) {
          if (approvedFile == null) {
            print("Executing 'code $unapprovedFilename'");
            final processResult = Process.runSync('code', [unapprovedFilename]);
            print('______processResult: ${processResult.toString()}');
          } else {
            print("Executing 'code --diff $approvedFilename $unapprovedFilename'");
            final processResult = Process.runSync('code', ['--diff', approvedFilename, unapprovedFilename]);
            print('______processResult: ${processResult.toString()}');
          }
        } else {
          print('''$topBar
    To enable the 'v' command, your system must be configured to run VSCode from the command line:
    0. Install VSCode (if you haven't already)
    1. Open Visual Studio Code.
    2. Open the Command Palette by pressing Cmd + Shift + P.
    3. Type ‘Shell Command’ into the Command Palette and look for the option ‘Install ‘code’ command in PATH’.
    4. Select it and it should install the necessary scripts so that you can use code from the terminal.
$bottomBar''');
        }
      } else {
        print('Approval test rejected');
      }
    } while (firstCharacter == 'v');
  }
}

bool isCodeCommandAvailable() {
  var result = Process.runSync('which', ['code']);

  return result.exitCode == 0 ? true : false;
}
