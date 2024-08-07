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

Write:

    testWidgets('home page', (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        await tester.approvalTest();
    });

## Quick Start Videos

[Here's a 60-second introduction to Flutter approval tests with package:approved](https://youtu.be/pcku-ZZPevE)

[For a slightly longer and more thorough introduction, tap here](https://youtu.be/XHxqxrq_52g)

# TL;DR

## What are Approval Tests?

Typically, tests contain hard-coded values of expected states. Approval tests also contain 
expected values of states. The difference is the expected states of approval tests are captured 
in a file instead of code. 
Because the file is written by the approval test library, rather than the developer, writing and
maintaining tests is faster, freeing the developer to focus on feature code, rather than test
code.

## How Package:approved Works

Suppose you wanted to confirm that a page loaded with all the widget you expected. To do this,
perform an approval test by calling `tester.approvalTest`, and give your test a suitable name:

    testWidgets('home page', () {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        await tester.approvalTest('all widgets load correctly');
    });

The first time the test is run, package:approved creates a file with extension `.unapproved.txt` and 
the name of the test as the filename:

    'home page all widgets display.unapproved.txt'

Because this file is not yet approved, the test fails. To review the file for approval, run

    dart run approved:review

The command `dart run approved:review` has additional options, including listing files, selecting
files to review from this list by index, and more. For its current capabilities, run 

    dart run approved:review --help

To include your project's custom widget types in your test file, and to perform post-test checks, add
calls to `Approved.setUpAll()` and `Approved.tearDownAll()` to your tests' `setUpAll` and
`tearDownAll` calls, like so:

    main() {
        setUpAll(() {
            Approved.setUpAll();
        });

        tearDownAll(() {
            Approved.tearDownAll();
        });
    }

Typing 'dart run approved:review' is tedious! To reduce your typing, alias the command in your 
.zshrc or .bashrc file

    alias review='dart run approved:review'

or PowerShell profile

    function review {
        dart run approved:review
    }

## Non-widget Approval Tests

Approval tests can be used on any type of test, not just widget states. So, approval tests can be 
used for unit testing, bloc testing, and more. 

To review test data that isn't widget states, rather than calling the `tester.approvalTest`, simply
call `approvalTest` with your test data in text format:

    test('my initialization test', () {
        final myObject = MyObject();

        approvalTest('myObject builds correctly', myObject.toString());
    });

The same approach applies to any data that can be represented as a text file, including json, lists,
sets, maps, etc.

## More Information on Approval Tests

Approval tests have been around for over twenty years but are still not a mainstream approach to 
testing. For more information on approval tests, check out the resources below.

[What is Approval Testing](https://www.linkedin.com/pulse/what-approval-testing-john-ferguson-smart/)

[Software Engineering Radio 595: Llewelyn Falco on Approval Testing](https://se-radio.net/2023/12/se-radio-595-llewelyn-falco-on-approval-testing/)

[I Regret Not Telling Dave Farley THIS about Approval Testing](https://www.youtube.com/watch?v=jOuqE_o9rmg)

## Suggestions Welcome!

Help package:approved reach more devs by showing us some 💙 with a 🌟 or 👍.

Is package:approved missing a feature? Let us know by raising a Github issue or by emailing me at 
richard@richardcoutts.com! 🙌

Want to contribute? Send me a note and we'll discuss your idea! 🎉