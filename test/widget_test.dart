import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:WorldOfWordSearchII/main.dart";

void main() {
  testWidgets("When button pressed change color", (WidgetTester tester) async {
    // ASSAMBLE
    await tester.pumpWidget(MyApp());
    final Finder firstButton = find.byType(Tile).first;
    final TileState state = tester.state(firstButton);

    // ACT
    await tester.tap(firstButton);
    await tester.pump();

    //ASSERT
    final Color baseColor = state.baseColor;
    final Color colorClicked = state.colorClicked;
    expect(baseColor, colorClicked);
  });

  testWidgets("Test: usedWords is cleared", (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    final MyHomePageState pageState = tester.state(find.byType(MyHomePage));

    pageState.clear();
    expect(pageState.usedWords.length, 0);
  });

  testWidgets("description", (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    final MyHomePageState pageState = tester.state(find.byType(MyHomePage));
    final Finder jTile = find.text("J");
    final Finder uTile = find.text("U");
    final Finder lTile = find.text("L");

    await tester.tap(jTile);
    await tester.pump();
    await tester.tap(uTile);
    await tester.pump();
    await tester.tap(lTile);
    await tester.pump();

    print(pageState.usedWords);
    expect(pageState.finishDialogOpen, true);
  });
}
