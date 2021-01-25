import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/binding.dart';
import "package:flutter_test/flutter_test.dart";
import "package:WorldOfWordSearchII/main.dart";
import "dart:developer" as dev;

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

  testWidgets("Tests clicking correct letters in a word and rotating display", (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();
      final MyHomePageState pageState = tester.state(find.byType(MyHomePage));
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
}
