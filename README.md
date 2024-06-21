# approved

![approved](https://raw.githubusercontent.com/buttonsrtoys/approved/main/assets/approved_logo.png)

An Flutter approval-tests library for quickly writing unit, widget, and integration tests.

## How package:approved works

Instead of writing tests like this:

    void main() {
        testWidgets('Confirm all widgets appear', (WidgetTester tester) async {
            await tester.pumpWidget(const MyApp());

            await genExpects(tester);
        });
    }

Write them like this:

## That's it!

For questions or anything else GenExpects, feel free to create an issue or contact me.
