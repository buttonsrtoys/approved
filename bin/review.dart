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

  Future<List<File>> getUnapprovedFiles() async {
    final files = <File>[];
    final searchDirectory = Directory.current;

    await for (final file in searchDirectory.list(recursive: true)) {
      if (file.path.endsWith('.unapproved.txt')) {
        files.add(file as File);
      }
    }

    return files;
  }

  /// If no args, then searching the whole project
  if (args.isEmpty || args[0].isEmpty) {
    for (final file in await getUnapprovedFiles()) {
      if (file.path.endsWith('.unapproved.txt')) {
        processUnapprovedFile(file);
      }
    }
  } else {
    /// If here, have args. If arg is an option...
    if (args[0][0] == '-') {
      if (args[0] == '--help') {
        print('''Manage your package:approved files.

Common usage:

  dart run approved:review 
    Reviews all project .unapproved.txt files

  dart run approved:review --list
    List project's .unapproved.txt files

Usage: dart run approved:review [arguments]

Arguments:
--help                      Print this usage information.
--list                      Print a list of project .unapproved.txt files.
<index>                     Review an .unapproved.txt file indexed by --list.
<path/to/.unapproved.txt>   Review an .unapproved.txt file.''');
      } else if (args[0] == '--list') {
        final unapprovedFiles = await getUnapprovedFiles();
        final fileCount = unapprovedFiles.length;
        for (int i = 0; i < fileCount; i++) {
          print('${i.toString().padLeft(3, ' ')} ${unapprovedFiles[i].path}');
        }
        if (fileCount > 0) {
          print('Found $fileCount unapproved files, listed above.');
          print("${highlightCliColor}To review one, run:$resetCliColor dart run approved:review <index>");
          print("${highlightCliColor}To review all, run:$resetCliColor dart run approved:review");
        }

        writeUnapprovedFiles(unapprovedFiles);
      } else {
        print("Unknown option '${args[0]}'. See '--help' for more details.");
      }
    } else {
      /// If here, arg is a path or an index in the list of paths
      File? unapprovedFile;
      final arg = args[0];
      final int? maybeIntValue = int.tryParse(arg);
      if (maybeIntValue == null) {
        unapprovedFile = File(arg);
      } else {
        final unapprovedFilePaths = readUnapprovedFiles();
        if (maybeIntValue >= 0 && maybeIntValue < unapprovedFilePaths.length) {
          unapprovedFile = File(unapprovedFilePaths[maybeIntValue]);
        } else {
          print('No unapproved file with an index of $maybeIntValue');
        }
      }
      if (unapprovedFile != null) {
        processUnapprovedFile(unapprovedFile);
      }
    }
  }

  if (tasks.isEmpty) {
    print('Found 0 unapproved files.');
  } else {
    final tasksCount = tasks.length;
    await Future.wait(tasks);
    print('Review completed. $tasksCount test results reviewed.');
  }
}

void writeUnapprovedFiles(List<File>? unapprovedFiles) {
  final file = File(unapprovedFilesPath)..createSync(recursive: true);
  if (unapprovedFiles == null) {
    file.writeAsStringSync('');
  } else {
    file.writeAsStringSync(unapprovedFiles.map((file) => file.path).join('\n'));
  }
}

List<String> readUnapprovedFiles() {
  List<String> result = <String>[];

  final file = File(unapprovedFilesPath);
  if (file.existsSync()) {
    String fileContents = file.readAsStringSync();
    result = fileContents.split('\n');
  } else {
    result = [];
  }

  return result;
}

/// Check of the files are different using "git diff"
Future<void> processFile(File? approvedFile, File unapprovedFile) async {
  late String resultString;
  if (approvedFile == null) {
    final unapprovedText = unapprovedFile.readAsStringSync();
    resultString = "Data in '${unapprovedFile.path}':\n$unapprovedText";
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
