import "package:firebase_database/firebase_database.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart" show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Flutter Demo",
      home: MyHomePage(title: "Game Prototype"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
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

class MyHomePageState extends State<MyHomePage> {
  bool loadedWords = false;

  List<int> usedLetters = <int>[];
  List<String> correctWords = <String>[];
  List<String> originalWords = <String>[];
  bool finishDialogOpen = false;

  List<GlobalKey<TileState>> listOfKeys;

  // Gets words from Firebase
  Future<dynamic> getWords() async =>
      (await FirebaseDatabase.instance.reference().child("Levels").child("1").once()).value;

  List<Char> tryWord(List<Char> grid, String word, int gridSize, int position, int dir) {
    final int xPos = position % gridSize;
    final int yPos = (position / gridSize).floor();
    switch (dir) {
      case 0:
        // Horizontal
        if (xPos > gridSize - word.length) return null;
        int index = xPos;
        for (final String char in word.split("").toList()) {
          final int i = index + (gridSize * yPos);
          if (grid[i] != null || grid[i]?.char != char) return null;
          grid[i] = Char(i, char);
          index++;
        }
        break;
      case 1:
        // Vertical
        if (yPos > gridSize - word.length) return null;
        int index = yPos;
        for (final String char in word.split("").toList()) {
          final int i = xPos + (gridSize * index);
          if (grid[i] != null || grid[i]?.char != char) return null;
          grid[i] = Char(i, char);
          index++;
        }
        break;
      case 2:
        // Diagonally
        if (yPos > gridSize - word.length || xPos > gridSize - word.length) return null;
        int index = yPos;
        int diag = 0;
        for (final String char in word.split("").toList()) {
          final int i = xPos + (gridSize * index) + diag;
          if (grid[i] != null || grid[i]?.char != char) return null;
          grid[i] = Char(i, char);
          index++;
          diag++;
        }
        break;
      default:
    }
    return grid;
  }

  List<Char> generateGrid(List<String> words, int gridSize) {
    words.shuffle();
    final List<int> positions = List<int>.generate(gridSize * gridSize, (int index) => index);
    final List<int> directions = List<int>.generate(3, (int index) => index);

    final List<Word> wordStack = <Word>[];

    int wordIndex = 0;

    wordStack.add(Word(words[wordIndex], List<Char>(gridSize * gridSize), positions, directions));

    while (wordIndex < words.length) {
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
        wordIndex--;
        wordStack.removeLast();
      } else {
        final int pos = wordStack.last.positions.last;
        final List<Char> grid = tryWord(wordStack.last.grid, wordStack.last.word, gridSize, pos, dir);
        if (grid != null) {
          if (wordIndex < words.length - 1) {
            wordIndex++;
            wordStack.add(Word(words[wordIndex], grid, positions, directions));
          } else {
            break;
          }
        }
      }
    }

    /*for (int i = 0; i < grid.length; i++) {
      if (wordStack.grid[i] == null) {
        
      }
    }*/

    print(wordStack.last.grid);

    return wordStack.last.grid;
  }

  // Clears all tiles
  void clear() {
    usedLetters.clear();
    if (loadedWords) {
      listOfKeys.forEach((GlobalKey<TileState> key) {
        key.currentState.setState(() {
          key.currentState.baseColor = Colors.yellow;
        });
      });
    }
  }

  void winnerWinner() async {
    correctWords = originalWords;
    final DatabaseReference winsRef = FirebaseDatabase.instance.reference().child("AmountOfWins");
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
  }

  // Removes one word from the list if the user has selected the word
  bool hasWon() => (correctWords = correctWords.where((String e) => usedLetters.join(",") != e).toList()).isEmpty;

  @override
  Widget build(BuildContext context) {
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
                  future: getWords(),
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (!snapshot.hasData) return Container();
                    return FutureBuilder<dynamic>(
                      future: rootBundle.loadString("assets/words.txt"),
                      builder: (BuildContext context, AsyncSnapshot<dynamic> wordsSnapshot) {
                        if (!wordsSnapshot.hasData) return Container();
                        loadedWords = true;
                        // Gets the column and row child count
                        final int rowSize = int.parse(snapshot.data["gridSize"]?.toString());
                        listOfKeys =
                            List<GlobalKey<TileState>>.generate(rowSize * rowSize, (int i) => GlobalKey<TileState>());

                        originalWords =
                            (snapshot.data["correctWords"] as List<dynamic>).map((dynamic e) => e.toString()).toList();
                        correctWords = originalWords;

                        final List<String> data = (wordsSnapshot.data as String).split("\n");
                        final List<String> compatibleWords =
                            data.where((String w) => w.length >= 2 && w.length <= rowSize).toList();
                        compatibleWords.shuffle();
                        final List<String> words2 = compatibleWords.getRange(0, 4).toList();
                        print(words2);

                        final List<Char> grid = generateGrid(words2, rowSize);
                        print(grid);

                        final List<String> allWords = snapshot.data["letters"].toString().split("");
                        final List<List<Char>> words = List<List<Char>>.generate(rowSize, (int i) {
                          int index = 0;
                          return allWords
                              .getRange(i * rowSize, (i * rowSize) + rowSize)
                              .toList()
                              .map((String e) => Char(index++ + (i * rowSize), e))
                              .toList();
                        });
                        return GridView.count(
                          childAspectRatio: 1,
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(2),
                          crossAxisCount: rowSize,
                          children: List<Widget>.generate(
                            rowSize * rowSize,
                            (int index) => Tile(
                              key: listOfKeys[index],
                              char: words[(index / rowSize).floor()][index % rowSize],
                              onClick: (Char char, bool selected) async {
                                if (!selected) {
                                  usedLetters.add(char.id);
                                  usedLetters.sort();
                                  final int correctWordsLen = correctWords.length;
                                  if (hasWon()) {
                                    winnerWinner();
                                    clear();
                                  } else {
                                    final DatabaseReference lossesRef =
                                        FirebaseDatabase.instance.reference().child("AmountOfLosses");
                                    lossesRef.once().then((DataSnapshot value) =>
                                        lossesRef.set((int.parse(value.value.toString()) ?? 0) + 1));
                                    if (correctWordsLen != correctWords.length || usedLetters.length >= rowSize)
                                      clear();
                                  }
                                  final DatabaseReference gamesRef =
                                      FirebaseDatabase.instance.reference().child("AmountOfGames");
                                  gamesRef.once().then((DataSnapshot value) =>
                                      gamesRef.set((int.parse(value.value.toString()) ?? 0) + 1));
                                } else {
                                  usedLetters.remove(char.id);
                                }
                              },
                            ),
                          ),
                        );
                      },
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
  Color colorClicked = const Color(0xff98fb98);
  Color baseColor = Colors.yellow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          final DatabaseReference clicksRef = FirebaseDatabase.instance.reference().child("AmountOfClicks");
          clicksRef.once().then((DataSnapshot value) => clicksRef.set((int.parse(value.value.toString()) ?? 0) + 1));
          final bool selected = baseColor == colorClicked;
          baseColor = selected ? Colors.yellow : colorClicked;
          widget.onClick(widget.char, selected);
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
}
