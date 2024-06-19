import 'package:approved/src/src.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MaterialApp _buildApp(Widget widget) {
  return MaterialApp(
    home: MyCustomClass(
      widget: widget,
    ),
  );
}

class MyCustomClass extends StatelessWidget {
  const MyCustomClass({
    required this.widget,
    super.key,
  });

  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget,
    );
  }
}

enum MyEnumKeys {
  myKeyName,
}

void main() {
  setUpAll(() async {
    await Approved.setUpAll();
  });

  group('Approved test', () {
    testWidgets('smoke test', (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(const Text('Testing 1, 2, 3')));
      await tester.pumpAndSettle();

      await tester.approvalTest();
    });
  });
}
