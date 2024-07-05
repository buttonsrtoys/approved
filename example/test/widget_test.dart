import 'package:approved/approved.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async => await Approved.setUpAll());
  tearDownAll(() async => await Approved.tearDownAll());

  testWidgets('smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.approvalTest();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.approvalTest('after fab tap', ApprovalTestOptions(showDiff: true));
  });

  test('Default person', () {
    final person = Person();

    approvalTest('confirm John Doe', person.toJson());
  });
}
