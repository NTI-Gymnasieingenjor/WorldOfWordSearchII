import "dart:developer" as dev;
import "dart:math";
import "package:firebase_database/firebase_database.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart" show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Flutter Demo",
      home: MyHomePage(
        rowSize: 7,
        numberOfWords: 3,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, @required this.rowSize, @required this.numberOfWords}) : super(key: key);

  final int rowSize;
  final int numberOfWords;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  List<int> usedLetters = <int>[];
  List<String> correctWords = <String>[];
  bool finishDialogOpen = false;
  Random rand = Random();

  List<GlobalKey<TileState>> listOfKeys;

  List<Char> tryWord(List<Char> grid, String word, int gridSize, int position, int dir) {
    final int xPos = position % gridSize;
    final int yPos = (position / gridSize).floor();
    final List<int> indices = <int>[];
    int diagInc = 0;
    int index = dir == 0 ? xPos : yPos;
    if ((dir == 1 || dir == 2) && yPos > gridSize - word.length) return null;
    if ((dir == 0 || dir == 2) && xPos > gridSize - word.length) return null;

    for (final String char in word.split("").toList()) {
      int i = dir == 0 ? (index + gridSize * yPos) : (xPos + gridSize * index);
      if (dir == 2) {
        i += diagInc;
        diagInc++;
      }
      if (grid[i] == null || grid[i].char == char) {
        indices.add(i);
        index++;
      } else {
        return null;
      }
    }
    final List<Char> tempGrid = List<Char>.from(grid);
    int tempIndex = 0;
    for (final int pos in indices) {
      tempGrid[pos] = Char(pos, word[tempIndex]);
      tempIndex++;
    }
    correctWords.add(indices.join(","));
    return tempGrid;
  }

  List<Char> generateGrid(List<String> words, int gridSize) {
    correctWords.clear();
    usedLetters.clear();
    words.shuffle();
    final List<int> positions = List<int>.generate(gridSize * gridSize, (int index) => index);
    final List<int> directions = List<int>.generate(3, (int index) => index);

    final List<Word> wordStack = <Word>[];

    wordStack.add(Word(words[0], List<Char>(gridSize * gridSize), positions, directions));

    while (true) {
      if (wordStack.isEmpty) {
        throw Exception("Word does not fit on the grid");
      }

      if (wordStack.last.directions.isEmpty) {
        wordStack.last.positions.removeLast();
        wordStack.last.directions = List<int>.from(directions);
        wordStack.last.directions.shuffle();
      }

      final int dir = wordStack.last.directions.removeLast();

      if (wordStack.last.positions.isEmpty) {
        wordStack.removeLast();
        correctWords.removeLast();
      } else {
        final int pos = wordStack.last.positions.last;
        final List<Char> grid = tryWord(wordStack.last.grid, wordStack.last.word, gridSize, pos, dir);
        if (grid != null) {
          if (wordStack.length < words.length) {
            wordStack.add(Word(words[wordStack.length], grid, positions, directions));
          } else {
            wordStack.add(Word(words[0], grid, positions, directions));
            break;
          }
        }
      }
    }

    for (int i = 0; i < wordStack.last.grid.length; i++) {
      if (wordStack.last.grid[i] == null) {
        wordStack.last.grid[i] = Char(i, String.fromCharCode(rand.nextInt(26) + 65));
      }
    }

    return wordStack.last.grid;
  }

  // Clears all tiles
  void clear() {
    usedLetters.clear();
    listOfKeys.forEach((GlobalKey<TileState> key) {
      key.currentState.setState(() {
        key.currentState.baseColor = key.currentState.normalColor;
        key.currentState.notSelected = true;
      });
    });
  }

  void winnerWinner() async {
    // TODO(EVERYONE): REGENERATE!
    final DatabaseReference winsRef = FirebaseDatabase.instance.reference().child("AmountOfGames");
    winsRef.once().then((DataSnapshot value) => winsRef.set((int.parse(value.value.toString()) ?? 0) + 1));
    await showDialog<AlertDialog>(
      context: context,
      builder: (BuildContext context) {
        finishDialogOpen = true;
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            margin: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                children: <Widget>[
                  Image.asset("assets/Ratwithegg.png"),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 10, top: 4),
                          child: Text(
                            "You won!",
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.none,
                              fontSize: 40,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                          child: CupertinoButton(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(5),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                            child: const Text("Restart", style: TextStyle(color: Colors.black)),
                            onPressed: () {
                              Navigator.pop(context);
                              finishDialogOpen = false;
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    setState(() {
      clear();
      listOfKeys.forEach((GlobalKey<TileState> key) {
        key.currentState.setState(() {
          key.currentState.setCorrect(false);
        });
      });
    });
  }

  // Removes one word from the list if the user has selected the word
  bool hasWon() => (correctWords = correctWords.where((String e) => usedLetters.join(",") != e).toList()).isEmpty;

  List<String> getWords(List<String> words) {
    final List<String> compatibleWords =
        words.where((String w) => w.length >= 2 && w.length <= widget.rowSize && w != "step").toList();
    compatibleWords.shuffle();
    return compatibleWords.getRange(0, widget.numberOfWords).toList();
  }

  @override
  Widget build(BuildContext context) {
    listOfKeys =
        List<GlobalKey<TileState>>.generate(widget.rowSize * widget.rowSize, (int i) => GlobalKey<TileState>());

    final MediaQueryData mqData = MediaQuery.of(context);
    const double gridMargin = 20;
    // Scales the grid to fit the screen
    double gridSize = 200;
    if (mqData.size.height > mqData.size.width) {
      final double horPadding = mqData.padding.left + mqData.padding.right;
      gridSize = mqData.size.width - gridMargin - horPadding;
    } else {
      final double vertPadding = mqData.padding.top + mqData.padding.bottom;
      gridSize = mqData.size.height - gridMargin - vertPadding;
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            "assets/background.png",
            alignment: Alignment.center,
            fit: BoxFit.cover,
          ),
          Center(
            child: SafeArea(
              child: Container(
                height: gridSize,
                width: gridSize,
                margin: const EdgeInsets.all(gridMargin / 2),
                color: Colors.purple,
                child: FutureBuilder<dynamic>(
                  future: rootBundle.loadString("assets/words.txt"),
                  builder: (BuildContext context, AsyncSnapshot<dynamic> wordsSnapshot) {
                    if (!wordsSnapshot.hasData) return Container();
                    final List<String> words = getWords(wordsSnapshot.data.toString().replaceAll("\r", "").split("\n"));
                    final List<Char> grid = generateGrid(words, widget.rowSize);
                    return GridView.count(
                      childAspectRatio: 1,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(2),
                      crossAxisCount: widget.rowSize,
                      children: List<Widget>.generate(
                        widget.rowSize * widget.rowSize,
                        (int index) => Tile(
                          key: listOfKeys[index],
                          char: Char(index, grid[index]?.char ?? "_"),
                          onClick: (Char char, bool notSelected) async {
                            if (!notSelected) {
                              usedLetters.add(char.id);
                              usedLetters.sort();
                            } else {
                              usedLetters.remove(char.id);
                            }
                            dev.log(words.toString());
                            dev.log(correctWords.toString());
                            dev.log(usedLetters.toString());
                            final int correctWordsLen = correctWords.length;
                            if (hasWon()) {
                              winnerWinner();
                              clear();
                            } else {
                              // If word was correct but not all words selected
                              if (correctWordsLen != correctWords.length) {
                                for (final int pos in usedLetters) {
                                  final GlobalKey<TileState> key = listOfKeys[pos];
                                  key.currentState.setState(() {
                                    key.currentState.setCorrect(true);
                                  });
                                }
                                clear();
                              }
                              if (usedLetters.length >= widget.rowSize) clear();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Tile extends StatefulWidget {
  const Tile({Key key, this.char, this.onClick, this.winnerWinner}) : super(key: key);
  final Char char;
  final void Function(Char letter, bool selected) onClick;
  final void Function() winnerWinner;
  @override
  TileState createState() => TileState();
}

class TileState extends State<Tile> {
  bool notSelected = true;
  final Color colorClicked = const Color(0xff98fb98);
  Color normalColor = Colors.yellow;
  Color baseColor = Colors.yellow;

  void setCorrect(bool correct) {
    setState(() {
      normalColor = correct ? Colors.white : Colors.yellow;
      baseColor = normalColor;
      notSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        notSelected = !notSelected;
        setState(() {
          final DatabaseReference clicksRef = FirebaseDatabase.instance.reference().child("AmountOfClicks");
          clicksRef.once().then((DataSnapshot value) => clicksRef.set((int.parse(value.value.toString()) ?? 0) + 1));
          baseColor = notSelected ? normalColor : colorClicked;
          widget.onClick(widget.char, notSelected);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        color: baseColor,
        child: Center(
          child: Text(
            widget.char.char.toUpperCase(),
            style: const TextStyle(color: Colors.pinkAccent, fontSize: 35),
          ),
        ),
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
