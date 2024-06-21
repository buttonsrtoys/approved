# approved

![approved](https://raw.githubusercontent.com/buttonsrtoys/approved/main/assets/approved_logo.png)

An Flutter approval-tests library for quickly writing unit, widget, and integration tests.

## How package:approved works

Instead of writing this:

    testWidgets('smoke test', (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        expect(find.text('You have pushed the button this many times:'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.byWidgetPredicate(
            (Widget widget) => widget is Text && widget.data == 'hello' && 
            widget.key == ValueKey('myKey'),
        ), findsOneWidget);
        expect(find.text('Approved Example'), findsOneWidget);
    }

Accomplish the same thing with this:

    testWidgets('smoke test', (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        await tester.approvalTest();
    }

## That's it!

For questions or anything else Approved, feel free to create an issue or contact me.
