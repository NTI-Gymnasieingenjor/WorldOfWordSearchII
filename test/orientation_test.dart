import "package:WorldOfWordSearchII/stopwatch_widget.dart";
import "package:flutter_test/flutter_test.dart";

import "package:WorldOfWordSearchII/main.dart";
import "package:WorldOfWordSearchII/game.dart";
import "package:WorldOfWordSearchII/tile.dart";

// A firebase database warning is expected but the tests still work
void main() {
  testWidgets("Tests clicking correct letter in a word and rotating display", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final GameState pageState = tester.state(find.byType(Game));
      await tester.pumpAndSettle();
      await tester.pump();

      final Finder tile = find.byType(Tile).at(0);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      await tester.pump();

      // Resets state to simulate rotation
      pageState.setState(() {});
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      final TileState tileState = tester.state(tile);
      expect(tileState.notSelected, false);
    });
  });

  testWidgets("Checking if grid stays the same when rotate", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final GameState pageState = tester.state(find.byType(Game));
      final List<Char> grid = pageState.grid;

      // Resets state to simulate rotation
      pageState.setState(() {});
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      expect(grid, pageState.grid);
    });
  });

  testWidgets("Selecting word and rotating device", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final GameState pageState = tester.state(find.byType(Game));
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

      // Resets state to simulate rotation
      pageState.setState(() {});
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      expect(wordsLength, pageState.correctWords.length);
    });
  });

  testWidgets("Check stopwatch value doesn't reset on rotate", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final GameState pageState = tester.state(find.byType(Game));
      final StopWatchWidgetState stopWatchWidget = tester.state(find.byType(StopWatchWidget));

      stopWatchWidget.widget.stop();
      await Future<dynamic>.delayed(const Duration(seconds: 2));
      final String firstTime = stopWatchWidget.widget.formatTime();

      // Resets state to simulate rotation
      pageState.setState(() {});
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      expect(firstTime, stopWatchWidget.widget.formatTime());
    });
  });
}
