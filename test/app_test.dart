import 'package:basicflashcards/data/set_repository.dart';
import 'package:basicflashcards/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('create a set, then flip a card and take a quiz', (tester) async {
    await tester.pumpWidget(
      EasyFlashcardsApp(repository: LocalSetRepository()),
    );
    await tester.pumpAndSettle();
    expect(find.text('No study sets yet'), findsOneWidget);

    await tester.tap(find.text('New set'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Animals',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Term 1'), 'Cat');
    await tester.enterText(find.widgetWithText(TextField, 'Term 2'), 'Dog');
    final definitions = find.widgetWithText(TextField, 'Definition');
    await tester.enterText(definitions.at(0), 'A small pet');
    await tester.enterText(definitions.at(1), 'A loyal pet');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Animals'), findsOneWidget);
    expect(find.text('2 cards'), findsOneWidget);

    await tester.tap(find.text('Animals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flashcards'));
    await tester.pumpAndSettle();
    expect(find.text('Tap to flip'), findsOneWidget);
    await tester.tap(find.text('Tap to flip'));
    await tester.pumpAndSettle();
    expect(find.text('Definition'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Round complete'), findsOneWidget);
  });

  testWidgets('saving without a title is refused', (tester) async {
    await tester.pumpWidget(
      EasyFlashcardsApp(repository: LocalSetRepository()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('New set'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Give the set a title'), findsOneWidget);
  });
}
