import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

import "game.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Word Of Wordsearch",
      home: Game(
        rowSize: 7,
        numberOfWords: 3,
      ),
    );
  }
}

class Char {
  const Char(this.id, this.char);
  final int id;

  final String char;

  @override
  String toString() {
    return char;
  }
}

class Word {
  Word(this.word, this.grid, List<int> positions, List<int> directions) {
    this.positions = List<int>.from(positions);
    this.positions.shuffle();
    this.directions = List<int>.from(directions);
    this.directions.shuffle();
  }

  String word;
  List<int> positions;
  List<int> directions;
  List<Char> grid;
}
