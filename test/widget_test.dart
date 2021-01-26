import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:WorldOfWordSearchII/main.dart";
import "package:WorldOfWordSearchII/game.dart";
import "package:WorldOfWordSearchII/tile.dart";
import "package:WorldOfWordSearchII/stopwatch_widget.dart";

// A firebase database warning is expected but the tests still work
void main() {
  testWidgets("Tests clicking correct letters in a word", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final GameState pageState = tester.state(find.byType(Game));
      await tester.pumpAndSettle();

      final Finder tiles = find.byType(Tile);
      final int wordsLength = pageState.correctWords.length;
      for (final String id in pageState.correctWords[0].split(",")) {
        await tester.tap(tiles.at(int.parse(id)));
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      expect(wordsLength - 1, pageState.correctWords.length);
    });
  });

  testWidgets("Tests clicking incorrect letters in a word", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final GameState pageState = tester.state(find.byType(Game));
      await tester.pumpAndSettle();

      final Finder tiles = find.byType(Tile);
      final int wordsLength = pageState.correctWords.length;
      final List<String> firstWord = pageState.correctWords.first.split(",");
      // Clicks all tiles except for the last one
      for (final String id in firstWord.getRange(0, firstWord.length - 2)) {
        await tester.tap(tiles.at(int.parse(id)));
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      expect(wordsLength, pageState.correctWords.length);
    });
  });

  testWidgets("Tests completing the puzzle", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final GameState pageState = tester.state(find.byType(Game));
      await tester.pumpAndSettle();

      final Finder tiles = find.byType(Tile);
      for (final String word in pageState.correctWords) {
        for (final String id in word.split(",")) {
          await tester.tap(tiles.at(int.parse(id)));
          await tester.pumpAndSettle();
        }
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      expect(pageState.correctWords.length, 0);
      expect(pageState.finishDialogOpen, true);
    });
  });

  testWidgets("Check grid change after restart", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final GameState pageState = tester.state(find.byType(Game));
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
      final GameState pageState = tester.state(find.byType(Game));
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

  testWidgets("Check stopwatch increment", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final StopWatchWidgetState stopWatchWidget = tester.state(find.byType(StopWatchWidget));

      final String firstTime = stopWatchWidget.widget.formatTime();
      await Future<dynamic>.delayed(const Duration(seconds: 2));
      expect(firstTime != stopWatchWidget.widget.formatTime(), true);
      expect(stopWatchWidget.widget.formatTime() != "00:00:00", true);
    });
  });

  testWidgets("Check stopwatch restart on game restart", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final GameState pageState = tester.state(find.byType(Game));
      final StopWatchWidgetState stopWatchWidget = tester.state(find.byType(StopWatchWidget));

      await Future<dynamic>.delayed(const Duration(seconds: 2));
      final String firstTime = stopWatchWidget.widget.formatTime();

      pageState.correctWords.clear();
      await tester.pumpAndSettle();

      final Finder tiles = find.byType(Tile);
      await tester.tap(tiles.at(0));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CupertinoButton));
      await tester.pumpAndSettle();
      stopWatchWidget.widget.stop();

      expect(firstTime != stopWatchWidget.widget.formatTime(), true);
      expect(stopWatchWidget.widget.formatTime() == "00:00:00", true);
    });
  });
}
