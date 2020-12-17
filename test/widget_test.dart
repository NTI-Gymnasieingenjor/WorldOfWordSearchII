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
}
