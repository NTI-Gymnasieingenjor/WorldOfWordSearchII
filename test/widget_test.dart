import "package:firebase_core/firebase_core.dart";
import 'package:firebase_database/firebase_database.dart';
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:WorldOfWordSearchII/main.dart";

// A firebase database warning is expected but the tests still work
void main() {
  testWidgets("Tests clicking correct letters in a word", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final MyHomePageState pageState = tester.state(find.byType(MyHomePage));
      await tester.pumpAndSettle();
      await tester.pump();

      final Finder tiles = find.byType(Tile);
      final int wordsLength = pageState.correctWords.length;
      for (final String id in pageState.correctWords[0].split(",")) {
        await tester.tap(tiles.at(int.parse(id)));
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      await tester.pump();
      expect(wordsLength - 1, pageState.correctWords.length);
    });
  });

  testWidgets("Tests clicking incorrect letters in a word", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final MyHomePageState pageState = tester.state(find.byType(MyHomePage));
      await tester.pumpAndSettle();
      await tester.pump();

      final Finder tiles = find.byType(Tile);
      final int wordsLength = pageState.correctWords.length;
      final List<String> firstWord = pageState.correctWords.first.split(",");
      // Clicks all tiles except for the last one
      for (final String id in firstWord.getRange(0, firstWord.length - 2)) {
        await tester.tap(tiles.at(int.parse(id)));
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      await tester.pump();
      expect(wordsLength, pageState.correctWords.length);
    });
  });

  testWidgets("Tests completing the puzzle", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final MyHomePageState pageState = tester.state(find.byType(MyHomePage));
      await tester.pumpAndSettle();
      await tester.pump();

      final Finder tiles = find.byType(Tile);
      for (final String word in pageState.correctWords) {
        for (final String id in word.split(",")) {
          await tester.tap(tiles.at(int.parse(id)));
          await tester.pumpAndSettle();
        }
        await tester.pumpAndSettle();
        await tester.pump();
      }
      await tester.pumpAndSettle();
      await tester.pump();
      expect(pageState.correctWords.length, 0);
      expect(pageState.finishDialogOpen, true);
    });
  });

  testWidgets("Check grid change after restart", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final MyHomePageState pageState = tester.state(find.byType(MyHomePage));
      await tester.pumpAndSettle();

      final List<Char> initGrid = pageState.grid;
      pageState.correctWords.clear();
      await tester.pumpAndSettle();

      final Finder tiles = find.byType(Tile);
      await tester.tap(tiles.at(0));
      await tester.pumpAndSettle();
      expect(pageState.correctWords.length, 0);
      expect(pageState.finishDialogOpen, true);

      await tester.tap(find.byType(CupertinoButton));
      await tester.pumpAndSettle();
      expect(pageState.finishDialogOpen, false);
      expect(initGrid == pageState.grid, false);
    });
  });

  testWidgets("Check tiles aren't selected after restart", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final MyHomePageState pageState = tester.state(find.byType(MyHomePage));
      await tester.pumpAndSettle();

      pageState.correctWords.clear();
      await tester.pumpAndSettle();

      // Click the first tile to show the win dialog
      await tester.tap(find.byType(Tile).at(0));
      await tester.pumpAndSettle();
      // Click the restart button
      await tester.tap(find.byType(CupertinoButton));
      await tester.pumpAndSettle();

      expect(pageState.usedLetters.isEmpty, true);
      for (final GlobalKey<TileState> key in pageState.listOfKeys) {
        final TileState state = key.currentState;
        expect(state.tileColor, TileState.baseColor);
        expect(state.notSelected, true);
      }
    });
  });
}
