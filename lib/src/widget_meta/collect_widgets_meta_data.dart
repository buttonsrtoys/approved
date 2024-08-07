import 'package:approved/src/widget_meta/expect_meta.dart';
import 'package:approved/src/widget_meta/load_string_en.dart';
import 'package:approved/src/widget_meta/matcher_types.dart';
import 'package:approved/src/widget_meta/register_types.dart';
import 'package:approved/src/widget_meta/widget_meta.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Set<String> registeredNames = {};

const String instructions = '/// Replace your call to generateExpects with the code below.';
List<WidgetMeta> _previousWidgetMetas = [];
List<String> _previousExpectStrings = [];
bool _isEnStringReverseLookupLoaded = false;
bool _isCommonTypesLoaded = false;
Map<String, List<String>> _enStringReverseLookup = <String, List<String>>{};

/// Output widget tests to the console.
///
/// [widgetTypes] is a set of custom classes to generate expects for.
/// [pathToStrings] is the path to a json file containing string constants. E.g., generated by the intl package.
/// [silent] determines whether to suppress output to console.
/// [compareWithPrevious] determines whether only changed tests from the previous run are displayed
/// [verbose] determines whether the cut-and-paste tip is shown (should be false inside generated widgetTests)
Future<void> printExpects(
  WidgetTester tester, {
  Set<Type>? widgetTypes,
  Set<String>? widgetNames,
  String? pathToStrings,
  bool silent = false,
  bool verbose = true,
  bool compareWithPrevious = true,
}) async {
  final text = await collectWidgetsMetaData(
    tester,
    widgetTypes: widgetTypes,
    widgetNames: widgetNames,
    pathToStrings: pathToStrings,
    silent: silent,
    verbose: verbose,
    compareWithPrevious: compareWithPrevious,
  );

  _outputText(text);
}

Future<void> _loadEnStringReverseLookupIfNecessary(String path) async {
  if (!_isEnStringReverseLookupLoaded) {
    _enStringReverseLookup = await loadEnStringReverseLookup(path);
  }
}

Future<void> _loadCommonTypesIfNecessary(Set<Type> commonTypes) async {
  if (!_isCommonTypesLoaded) {
    registerTypes(commonTypes);
    _isCommonTypesLoaded = true;
  }
}

/// Manually adds text to the reverse lookup map (instead of loading from file).
/// [markEnStringFileAsLoaded] as true blocks loads from file. This is primarily for testing.
Future<void> addTextToIntlReverseLookup({
  required String stringId,
  required String stringContent,
  bool markEnStringFileAsLoaded = true,
}) async {
  if (markEnStringFileAsLoaded) {
    _isEnStringReverseLookupLoaded = true;
  }

  addToReverseLookup(
    reverseLookupMap: _enStringReverseLookup,
    stringId: stringId,
    stringContent: stringContent,
  );
}

/// Outputs widget meta data as an expect statement or as text.
///
/// [tester] is the tester passed from a flutter test. E.g., from within [testWidget]
/// [widgetTypes] is a set of widget types to match and include in a test.
/// [widgetNames] is a set of widget names to search for. (Specify [widgetTypes] or [widgetNames] but not both.
/// [pathToStrings] is the path to a json file containing string constants. E.g., generated by the intl package.
///     (This feature is currently not supported, but will be reinstated if requested.)
/// [silent ] is true to suppress output to console and file (should be false inside generated widgetTests).
/// [verbose] shows explanatory text that explains meta data.
/// [compareWithPrevious ] is true to compare the current states with previous to display diffs.
/// [outputExpects] is true to print expect statements to console.
/// [outputMeta] is true to output data to an approval-test file.
Future<List<String>> collectWidgetsMetaData(
  WidgetTester tester, {
  Set<Type>? widgetTypes,
  Set<String>? widgetNames,
  String? pathToStrings,
  bool silent = false,
  bool verbose = true,
  bool compareWithPrevious = true,
  bool? outputExpects,
  bool? outputMeta,
}) async {
  assert(outputExpects == null || outputMeta == null);

  registeredNames = widgetNames ?? {};

  if (pathToStrings != null) {
    await _loadEnStringReverseLookupIfNecessary(pathToStrings);
  }
  if (widgetTypes != null) {
    await _loadCommonTypesIfNecessary(widgetTypes);
  }

  final text = <String>[];

  if (!compareWithPrevious) {
    _previousWidgetMetas = [];
    _previousExpectStrings = [];
  }

  final widgets = _getWidgetsForExpects(tester, widgetNames ?? <String>{});

  if (widgets.isEmpty) {
    text.add('No widgets found for approval testing.');
  } else {
    text.addAll(
      await _generateExpectsForWidgets(
        widgets,
        tester: tester,
        verbose: verbose,
        silent: silent,
        outputType: outputMeta == true ? OutputType.widgetMeta : OutputType.expects,
      ),
    );
  }

  return text;
}

Future<List<String>> _generateExpectsForWidgets(
  List<Widget> widgets, {
  required WidgetTester tester,
  required bool verbose,
  required bool silent,
  required OutputType outputType,
}) async {
  final text = <String>[];

  final currentWidgetMetas = _widgetMetasFromWidgets(widgets);
  final deltaWidgetMetas = _getDeltaWidgetMetas(currentWidgetMetas, _previousWidgetMetas);
  currentWidgetMetas.addAll(deltaWidgetMetas);
  final currentExpectStrings = _outputStringsFromWidgetMetas(currentWidgetMetas, outputType, verbose);
  final deltaExpectStrings = _getDeltaExpectStrings(currentExpectStrings, _previousExpectStrings);

  if (!silent) {
    if (deltaExpectStrings.isEmpty) {
      if (_previousWidgetMetas.isEmpty) {
        text.add('/// No widget with keys or custom types found to test');
      } else {
        text.add("/// No changes to widget with keys or custom types since the prior call to 'generateExpects'");
      }
    } else {
      if (verbose && outputType == OutputType.expects) {
        text.add(instructions);
      }
      text.addAll(deltaExpectStrings);
    }
  }

  _previousWidgetMetas = currentWidgetMetas;
  _previousExpectStrings = currentExpectStrings;

  return text;
}

List<String> _getDeltaExpectStrings(List<String> currentExpectStrings, List<String> previousExpectStrings) {
  final deltaExpectStrings = currentExpectStrings.where((item) => !previousExpectStrings.contains(item)).toList();

  return deltaExpectStrings;
}

/// Convert Widgets into [WidgetMeta]s
///
/// Result contains no duplicates (because duplicate [WidgetMeta]s result in duplicate generated tests
List<WidgetMeta> _widgetMetasFromWidgets(List<Widget> widgets) {
  final widgetMetas = <WidgetMeta>[];

  for (final widget in widgets) {
    // Ignore widgets Flutter adds with prefixes (e.g., "[key <")
    if (widget.key == null || _isProperlyFormattedKey(widget)) {
      final widgetMeta = WidgetMeta(widget: widget);
      if (!widgetMetas.contains(widgetMeta)) {
        widgetMetas.add(widgetMeta);
      }
    }
  }

  return widgetMetas;
}

bool _isProperlyFormattedKey(Widget widget) => widget.key.toString().indexOf('[<') == 0;

/// The order to output expects
enum _ExpectTypeOrder {
  noText,
  intlText,
  nonIntlText,
}

enum OutputType {
  expects,
  widgetMeta;
}

/// Generates expect() strings from [WidgetMeta]s. Sorts strings in order of [_ExpectTypeOrder]
List<String> _outputStringsFromWidgetMetas(
  List<WidgetMeta> widgetMetas,
  OutputType outputType,
  bool verbose,
) {
  final expectMetas = <ExpectMeta>[];
  final result = <String>[];

  for (final widgetMeta in widgetMetas) {
    final expectMetaFromWidgetMeta = _expectMetaFromWidgetMeta(widgetMeta);
    expectMetas.add(expectMetaFromWidgetMeta);
  }

  int sortOrder(ExpectMeta expectMeta) {
    _ExpectTypeOrder result = _ExpectTypeOrder.noText;
    if (expectMeta.widgetMeta.hasText) {
      result = _ExpectTypeOrder.intlText;
      if (!expectMeta.isIntl) {
        result = _ExpectTypeOrder.nonIntlText;
      }
    }
    return result.index;
  }

  expectMetas.sort((a, b) => sortOrder(a).compareTo(sortOrder(b)));

  bool generatedNonIntlTextComment = false;

  for (final expectMeta in expectMetas) {
    if (!generatedNonIntlTextComment && sortOrder(expectMeta) == 2) {
      generatedNonIntlTextComment = true;
      if (verbose) {
        result.add('\t// No reverse lookup found for the text in the expect statements below');
      }
    }

    late final List<String> expectStringsFromWidgetMeta;
    if (outputType == OutputType.expects) {
      expectStringsFromWidgetMeta = _expectStringsFromExpectMeta(expectMeta);
    } else if (outputType == OutputType.widgetMeta) {
      expectStringsFromWidgetMeta = _metaStringsFromExpectMeta(expectMeta);
    }

    result.addAll(expectStringsFromWidgetMeta);
  }

  return result;
}

void _outputText(List<String> strings) {
  for (final expectString in strings) {
    debugPrint('\t$expectString');
  }
}

List<WidgetMeta> _getDeltaWidgetMetas(List<WidgetMeta> currentWidgetMetas, List<WidgetMeta> previousWidgetMetas) {
  final deltaPreviousWidgetMetas = previousWidgetMetas.where((item) => !currentWidgetMetas.contains(item)).toList();

  // Matchers may have changed for the previous tests (e.g., findsOneWidget may now be findNothing), so update
  final updatedDeltaPreviousWidgetMetas =
      deltaPreviousWidgetMetas.map((widgetMeta) => WidgetMeta(widget: widgetMeta.widget)).toList();

  return updatedDeltaPreviousWidgetMetas;
}

/// Get all the widgets of interest for testing (e.g., has keys, has text, is registered)
///
/// Traverses the widget testing tree to build a list of widgets for testing.
///
/// The returned list is in no particular order.
List<Widget> _getWidgetsForExpects(
  WidgetTester tester,
  Set<String> widgetNames,
) {
  final widgets = <Widget>[];

  bool isEmptyTextWidget(Widget widget) {
    final bool result;
    if (widget is Text && (widget.data == null || widget.data == '')) {
      result = true;
    } else {
      result = false;
    }
    return result;
  }

  bool isWidgetForExpect(Widget widget) {
    final bool result;
    if (isEmptyTextWidget(widget)) {
      result = false;
    } else {
      result = (widget.key != null && (widget.key.toString().isCustomString || widget.key.toString().isEnumString)) ||
          registeredTypes.contains(widget.runtimeType) ||
          widgetNames.contains(widget.runtimeType.toString()) ||
          WidgetMeta.isTextEnabled(widget);
    }
    return result;
  }

  for (final widget in tester.allWidgets) {
    if (isWidgetForExpect(widget)) {
      widgets.add(widget);
    }
  }

  return widgets;
}

List<String> _expectStringsFromExpectMeta(ExpectMeta expectMeta) {
  final expects = <String>[];

  // Number of attributes (e.g., Type, key, text) to match in expect
  final int attributesToMatchCount = (expectMeta.widgetMeta.keyString.isNotEmpty ? 1 : 0) +
      (expectMeta.widgetMeta.widgetText.isNotEmpty ? 1 : 0) +
      (expectMeta.widgetMeta.isWidgetTypeRegistered ? 1 : 0);

  if (attributesToMatchCount >= 1) {
    if (_haveEnString(expectMeta.widgetMeta.widgetText) || attributesToMatchCount >= 2) {
      expects.addAll(_generateExpectWidgets(expectMeta.widgetMeta, attributesToMatchCount));
    } else {
      expects.add(_generateExpect(expectMeta.widgetMeta));
    }
  }

  return expects;
}

List<String> _metaStringsFromExpectMeta(ExpectMeta expectMeta) {
  final expects = <String>[];

  expects.add(_generateWidgetMeta(expectMeta.widgetMeta));

  return expects;
}

String _generateExpect(WidgetMeta widgetMeta) {
  late final String generatedExpect;

  if (widgetMeta.keyString.isNotEmpty) {
    if (widgetMeta.keyType == KeyType.enumValue) {
      generatedExpect =
          '\texpect(find.byKey(const ValueKey(${widgetMeta.keyString})), ${widgetMeta.matcherType.matcherName});';
    } else if (widgetMeta.keyType == KeyType.stringValueKey) {
      generatedExpect = '\texpect(find.byKey(${widgetMeta.keyString}), ${widgetMeta.matcherType.matcherName});';
    } else {
      throw Exception('Unexpected keyType');
    }
  } else if (widgetMeta.widgetText.isNotEmpty) {
    generatedExpect = "\texpect(find.text('${widgetMeta.widgetText}'), ${widgetMeta.matcherType.matcherName});";
  } else if (widgetMeta.isWidgetTypeRegistered) {
    generatedExpect = '\texpect(find.byType(${widgetMeta.widgetType}), ${widgetMeta.matcherType.matcherName});';
  } else {
    generatedExpect = '(Internal error. Expect not generated.)';
  }

  return generatedExpect;
}

ExpectMeta _expectMetaFromWidgetMeta(WidgetMeta widgetMeta) {
  final expectMeta = ExpectMeta(widgetMeta: widgetMeta);

  if (widgetMeta.widgetText.isNotEmpty) {
    if (_haveEnString(widgetMeta.widgetText)) {
      expectMeta.intlKeys = _enStringReverseLookup[widgetMeta.widgetText];
    }
  }

  return expectMeta;
}

List<String> _generateExpectWidgets(
  WidgetMeta widgetMeta,
  int attributesToMatch,
) {
  final buffer = StringBuffer();
  const intlPlaceHolder = '__INTL_PLACE_HOLDER__';
  List<String>? intlKeys;
  int attributesWrittenToBuffer = 0;

  void addTextAttributeToBuffer() {
    if (_haveEnString(widgetMeta.widgetText)) {
      intlKeys = _enStringReverseLookup[widgetMeta.widgetText];
      if (intlKeys != null) {
        buffer.write("intl: (s) => s.$intlPlaceHolder");
      }
    } else {
      buffer.write("data: '${widgetMeta.widgetText}'");
    }
  }

  void addTypeAttributeToBuffer() {
    buffer.write('widgetType: ${widgetMeta.widgetType}');
  }

  void addKeyAttributeToBuffer() {
    buffer.write("key: ${widgetMeta.keyString}");
  }

  void addMatcherAttributeToBuffer() {
    buffer.write(', matcher: ${widgetMeta.matcherType.matcherName},');
  }

  bool haveMoreAttributesToProcess() => ++attributesWrittenToBuffer < attributesToMatch;

  buffer.write('\ttester.expectWidget(');

  if (widgetMeta.widgetText.isNotEmpty) {
    addTextAttributeToBuffer();
    if (haveMoreAttributesToProcess()) {
      buffer.write(', ');
    }
  }

  if (widgetMeta.isWidgetTypeRegistered) {
    addTypeAttributeToBuffer();
    if (haveMoreAttributesToProcess()) {
      buffer.write(', ');
    }
  }

  if (widgetMeta.keyString.isNotEmpty) {
    addKeyAttributeToBuffer();
  }

  if (widgetMeta.matcherType.matcher != findsOneWidget) {
    addMatcherAttributeToBuffer();
  }

  buffer.write(');');

  final result = <String>[];

  if (intlKeys == null) {
    result.add(buffer.toString());
  } else {
    final bufferString = buffer.toString();
    if (intlKeys!.length > 1) {
      result.add('\t// Multiple matches for "${widgetMeta.widgetText}" in string_en.json. Pick one.');
    }
    for (final intlKey in intlKeys!) {
      result.add(bufferString.replaceAll(intlPlaceHolder, intlKey));
    }
    if (intlKeys!.length > 1) {
      result.add('\t// (End of matches)');
    }
  }

  return result;
}

String _generateWidgetMeta(
  WidgetMeta widgetMeta,
) {
  final buffer = StringBuffer();
  bool isFirstAttribute = true;

  void addCommaIfNecessary() {
    if (isFirstAttribute) {
      isFirstAttribute = false;
    } else {
      buffer.write(', ');
    }
  }

  void addTextAttributeToBuffer() {
    addCommaIfNecessary();
    buffer.write("data: '${widgetMeta.widgetText}'");
  }

  void addKeyAttributeToBuffer() {
    addCommaIfNecessary();
    buffer.write("key: ${widgetMeta.keyString}");
  }

  void addMatcherAttributeToBuffer() {
    addCommaIfNecessary();
    buffer.write('count: ');
    if (widgetMeta.matcherType == MatcherTypes.findsNothing) {
      buffer.write('0');
    } else if (widgetMeta.matcherType == MatcherTypes.findsOneWidget) {
      buffer.write('1');
    } else if (widgetMeta.matcherType == MatcherTypes.findsWidgets) {
      buffer.write('many');
    }
  }

  buffer.write('${widgetMeta.widgetType}: {');

  if (widgetMeta.keyString.isNotEmpty) {
    addKeyAttributeToBuffer();
  }

  if (widgetMeta.widgetText.isNotEmpty) {
    addTextAttributeToBuffer();
  }

  addMatcherAttributeToBuffer();

  buffer.write('}');

  final result = buffer.toString();

  return result;
}

bool _haveEnString(key) {
  return _enStringReverseLookup.containsKey(key);
}

/// Meta data for gestures
/// Per EWP-1519, this is a work in progress
class _GestureMeta {
  _GestureMeta(this.keyword, this.gestureCallbackName);

  String keyword;
  String gestureCallbackName;

  static List<_GestureMeta> get all => <_GestureMeta>[
        _GestureMeta('button', 'onTap'),
        _GestureMeta('toggle', 'onTap'),
      ];
}

/// Get the gesture associated with the widget key name. E.g., [keyName] containing "button" returns "tap"
String? getGesture(String keyName) {
  String? gestureName;

  if (keyName.isNotEmpty) {
    final keyNameLowerCase = keyName.toLowerCase();
    for (final gestureMeta in _GestureMeta.all) {
      if (keyNameLowerCase.contains(gestureMeta.keyword)) {
        gestureName = gestureMeta.gestureCallbackName;
      }
    }
  }

  return gestureName;
}
