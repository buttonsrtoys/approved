# approved

![approved](https://raw.githubusercontent.com/buttonsrtoys/approved/main/assets/approved_logo.png)

An approval-tests library for quickly writing unit, widget, and integration tests.

## How package:approved works

Instead of writing:

    testWidgets('home page', (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        expect(find.text('You have pushed the button this many times:'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.byWidgetPredicate(
            (Widget widget) => widget is Text && widget.data == 'hello' && 
            widget.key == ValueKey('myKey'),
        ), findsOneWidget);
        expect(find.text('Approved Example'), findsOneWidget);
    });

Write this:

    testWidgets('smoke test', (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        await tester.approvalTest();
    });

## Introduction videos

[Here's a 60-second overview to package:approved](https://www.youtube.com)

[Here's a 5-minute video with enough info to get you started](https://www.youtube.com)

# TL;DR

## What are Approval Tests?

After manually testing code, developers often write automated tests to guard against regressions.
Typically, this is done by writing code that contains the expected states of a test. Approval 
testing is the same process, except the expected states are captured in a file instead of code. 
Because the file is written by the approval test library, rather than the developer, writing and
maintaining code is faster, which frees up the developer to focus on feature code, rather than test
code.

## How Package:accepted Works

Suppose you wanted to confirm that a page loaded with all the widget you expected. To do this,
perform an approval test by calling `tester.approvalTest`, and give your test a suitable name:

    testWidget('home page', () {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        await tester.approvalTest('all widgets load correctly');
    });

The first time the test is run, package:approved creates an `.unapproved.txt` and uses the name of the
test as the file name:

    home page all widgets display.unapproved.txt

Because this file is not yet approved, the test fails. To review the file for approval, run

    dart run approved:review

To include your project's custom widget types in your test, and to perform post-test checks, add 
calls to `Approved.setUpAll()` and `Approved.tearDownAll()` to your tests' `setUpAll` and 
`tearDownAll` calls, like so:

    main() {
        setUpAll(() {
            Approved.setUpAll();
        });

        tearDownAll(() {
            Approved.tearDownAll();
        });

## More Information on Approval Tests

Approval tests have been around for over twenty years but are still not a mainstream approach to 
testing. For more information on approval tests, check out the resources below.

[What is Approval Testing](https://www.linkedin.com/pulse/what-approval-testing-john-ferguson-smart/)

[Software Engineering Radio 595: Llewelyn Falco on Approval Testing](https://se-radio.net/2023/12/se-radio-595-llewelyn-falco-on-approval-testing/)

[I Regret Not Telling Dave Farley THIS about Approval Testing](https://www.youtube.com/watch?v=jOuqE_o9rmg)

## Suggestions are Welcome!

Help package:approved reach more devs by showing us some 💙with a 🌟or 👍.

Is package:approved missing a feature? Let us know by raising an Github issue or by emailing me at 
richard@richardcoutts.com! 🙌

Want to contribute? Send me a note and we'll discuss your idea! 🎉