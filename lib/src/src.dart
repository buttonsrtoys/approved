// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:approved/src/common.dart';
import 'package:approved/src/get_widget_names.dart';
import 'package:approved/src/widget_meta/collect_widgets_meta_data.dart' as wm;
import 'package:flutter_test/flutter_test.dart';

import 'git_diffs.dart';

Set<String>? _widgetNames;
final _executedApprovedFullPaths = <String>{};
bool _allTestsPassed = true;

/// Adds package:approved functionality to WidgetTester
extension WidgetTesterApprovedExtension on WidgetTester {
  /// Returns a string representing states of widgets.
  Future<String> widgetStatesString({bool? showDiff}) async {
    final completer = Completer<String>();
    assert(_widgetNames != null, '''$topBar
    It appears that Approved.setUpAll() was not called before running an approvalTest. Typically, 
    this issue is solved by calling Approved.setUpAll() from within setUpAll. You may also want to call
    Approved.tearDownAll() to perform checks after testing completes.
    
        void main() {
            setUpAll(() async {
                await Approved.setUpAll();
            });
            tearDownAll(() async {
                Approved.tearDownAll();
            });
$bottomBar''');

    wm
        .collectWidgetsMetaData(
      this,
      outputMeta: true,
      verbose: false,
      compareWithPrevious: showDiff ?? false,
      widgetNames: Approved.widgetNames,
    )
        .then((stringList) {
      completer.complete(stringList.join('\n'));
    });

    return completer.future;
  }

  /// Performs an approval test on widgets managed by a WidgetTester.
  ///
  /// [description] is the name of the test. It is appended to the description in [Tester].
  /// [textForReview] is the meta data text used in the approval test.
  ///
  /// To test the current state of the widgets:
  ///
  ///     testWidgets('home page', () {
  ///         await tester.pumpWidget(const MyApp());
  ///         await tester.pumpAndSettle();
  ///
  ///         await tester.approvalTest('all widgets load correctly');
  ///     });
  ///
  /// To show only diffs, such as after a gesture, use ApprovalTestOptions(showDiffs: true):
  ///
  ///     testWidgets('home page', () {
  ///         await tester.pumpWidget(const MyApp());
  ///         await tester.pumpAndSettle();
  ///
  ///         await tester.approvalTest('all widgets load correctly');
  ///
  ///         await tester.tap(find.byType(FloatingActionButton));
  ///         await tester.pumpAndSettle();
  ///
  ///         // Show only diffs from the previous call to tester.approvalTest() above
  ///         await tester.approvalTest('after fab tap', ApprovalTestOptions(showDiff: true));
  ///   });
  ///
  Future<void> approvalTest([String? description, ApprovalTestOptions? options]) async {
    final resultCompleter = Completer<void>();
    final widgetsMetaCompleter = Completer<String>();
    String updatedTestDescription = description == null ? testDescription : '$testDescription $description';

    // Get the test path before the stack gets too deep.
    _testFilePath();

    widgetStatesString(showDiff: options?.showDiff ?? false).then((value) {
      widgetsMetaCompleter.complete(value);
    });

    widgetsMetaCompleter.future.then((value) {
      resultCompleter.complete(_globalApprovalTest(updatedTestDescription, value));
    });

    return resultCompleter.future;
  }

  /// Output expect statements to the console.
  Future<void> printExpects() {
    return wm.printExpects(this);
  }
}

/// A data class to hold options for the function call [approvalTest]
///
/// [showDiff]: true to show only diffs from the previous call to [approvalTest]. False shows all of the
/// current widget states.
class ApprovalTestOptions {
  final bool showDiff;

  ApprovalTestOptions({
    this.showDiff = false,
  });
}

/// A namespace for static functions for package:approved initialization and teardown
class Approved {
  /// Initializes the approval test by building a database of project classes.
  ///
  /// Typically called from within flutter_tests function 'setUpAll'
  static Future<Set<String>> setUpAll() async {
    final completer = Completer<Set<String>>();
    getWidgetNames().then((value) {
      _widgetNames = value;
      completer.complete(value);
    });
    return completer.future;
  }

  /// Performs checks after testing is complete.
  ///
  /// Checks performed
  /// - If all tests passed, it confirms there are no unnecessary .approved.txt or .unapproved.txt files hanging around.
  static Future<void> tearDownAll() async {
    if (!_allTestsPassed) return;

    final testPath = _testFilePath();
    final testDirectory = Directory(testPath);
    final approvedFullPaths = testDirectory.filesWithExtension('.$approvedExtension').map((file) => file.path).toSet();
    final unapprovedFullPaths =
        testDirectory.filesWithExtension('.$unapprovedExtension').map((file) => file.path).toSet();

    for (final approvedFullPath in _executedApprovedFullPaths) {
      if (approvedFullPaths.contains(approvedFullPath)) {
        approvedFullPaths.remove(approvedFullPath);
      }
      final unapprovedFullPath = approvedFullPath.replaceAll(approvedExtension, unapprovedExtension);
      if (unapprovedFullPaths.contains(unapprovedFullPath)) {
        unapprovedFullPaths.remove(unapprovedFullPath);
      }
    }

    if (approvedFullPaths.isNotEmpty || approvedFullPaths.isNotEmpty) {
      print('''topBar 
    The files listed below were generated by approvalTest but are no longer used:\n''');
      for (final approvedFullPath in approvedFullPaths) {
        print('    $approvedFullPath');
      }
      for (final unapprovedFullPath in unapprovedFullPaths) {
        print('    $unapprovedFullPath');
      }
      print(bottomBar);
    }

    final completer = Completer<void>();
    getWidgetNames().then((value) {
      _widgetNames = value;
      completer.complete(null);
    });
    return completer.future;
  }

  static Set<String>? get widgetNames => _widgetNames;
}

/// Performs an approval test.
///
/// [testDescription] is the name of the test, which is used to name the associated files.
/// [dataString] is the string to review for approval.
///
/// For any approval test, the data must be representable as text. If the data is not already in text
/// format, typically a `toString` or `toJson` method is used:
///
///     test('MyObject test', () {
///         final myObject = MyObject();
///
///         approvalTest('Confirm default MyObject', myObject.toString());
///     });
///
Future<void> approvalTest(
  String testDescription,
  String dataString,
) async {
  try {
    String outputPath = _testFilePath();

    final approvedFullPath = '$outputPath/$testDescription.$approvedExtension';
    final unapprovedFullPath = '$outputPath/$testDescription.$unapprovedExtension';

    if (_executedApprovedFullPaths.contains(approvedFullPath)) {
      _allTestsPassed = false;
      print('''$topBar
    A call to approvalTest with a prior test description '$testDescription' was detected in path '$outputPath'.
    Approval tests must have unique descriptions. E.g.,
    
        await tester.approvalTest('my unique description');
$bottomBar''');
      throw Exception(
          'approvalTest failed due to redundant description. See message above for instructions on how to fix.');
    }

    _executedApprovedFullPaths.add(approvedFullPath);

    final approvedFile = File(approvedFullPath);
    final unapprovedFile = File(unapprovedFullPath);

    if (unapprovedFile.existsSync()) {
      unapprovedFile.deleteSync();
    }

    String? textForReview;
    if (approvedFile.existsSync()) {
      final approvedText = approvedFile.readAsStringSync();
      if (approvedText != dataString.endWithNewline) {
        unapprovedFile.writeAsStringSync(dataString.endWithNewline);
        final gitDiff = gitDiffFiles(approvedFile, unapprovedFile);
        textForReview = '$diffReviewHeader\n$gitDiff';
      }
    } else {
      unapprovedFile.writeAsStringSync(dataString.endWithNewline);
      textForReview = dataString;
    }

    if (textForReview != null) {
      _allTestsPassed = false;
      printGitDiffs(unapprovedFullPath, textForReview, true);
      throw Exception("Approval test '$testDescription' failed. The file diff is listed above.");
    }
  } catch (e) {
    print(e.toString());
    rethrow;
  }
}

/// [_globalApprovalTest] resolves the name conflict with [WidgetTester.approvalTest]
Future<void> Function(String, String) _globalApprovalTest = approvalTest;

/// Typically, .approved.txt files are stored alongside the flutter test file. However, there may be edge cases
/// where the path to the test cannot be determined because the stack is too deep. If so, create a local path for
/// storing .approved.txt
String _previousTestFilePath = resourceLocalPath;

/// The path to the consumer's '..._test.dart' file that is executing the test
///
/// Search the stacktrace from the calling ..._test.dart. If the file is not found, a previous path is used.
/// (This should never happen, but the logic is here just in case to prevent files written to the root directory.)
String _testFilePath() {
  String? result;

  final stackTrace = StackTrace.current;
  final lines = stackTrace.toString().split('\n');
  final pathLine = lines.firstWhere((line) => line.contains('_test.dart'), orElse: () => '');

  if (pathLine.isNotEmpty) {
    var match = RegExp(r'\(file:\/\/(.*\/)').firstMatch(pathLine);
    if (match != null && match.groupCount > 0) {
      result = Uri.parse(match.group(1)!).toFilePath();
      result = result.endsWith('/') ? result.substring(0, result.length - 1) : result;
    }
  }

  // If result is null, then "..._test.dart" filename not found, likely because stack was too deep, so use previous path.
  if (result == null) {
    result = _previousTestFilePath;
    // make sure the path exists (e.g., could be "./approved")
    final dir = Directory(result);
    if (!dir.existsSync()) {
      dir.createSync();
    }
  } else {
    _previousTestFilePath = result;
  }

  return result;
}
