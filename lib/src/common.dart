import 'dart:io';

const topBar = '▼▼▼▼▼▼▼▼';
const bottomBar = '▲▲▲▲▲▲▲▲';
const firstReviewHeader = 'Data for review:';
const diffReviewHeader = 'Results of git diff:';
const approvedExtension = 'approved.txt';
const unapprovedExtension = 'unapproved.txt';
const resourceLocalPath = './test/.approved';

/// [String] extension
extension StringApprovedExtension on String {
  /// git diff complains when file doesn't end in newline. This getter ensures a string does.
  String get endWithNewline => endsWith('\n') ? this : '$this\n';
}

extension DirectoryApprovedExtension on Directory {
  Set<File> filesWithExtension(String extension) {
    final fileSystemEntities = listSync().where((entity) => entity is File && entity.path.endsWith(extension));
    return fileSystemEntities.whereType<File>().toSet();
  }
}
