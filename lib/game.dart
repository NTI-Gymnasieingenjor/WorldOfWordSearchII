import "dart:developer" as dev;
import "dart:math";

import "package:firebase_database/firebase_database.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart" show rootBundle;

import "main.dart";
import "stopwatch_widget.dart";
import "tile.dart";

class Difficulty {
  final String name;
  final int rowSizeMin, rowSizeMax;
  final String backgroundPath;
  final Color baseColor;

  const Difficulty(this.name, this.rowSizeMin, this.rowSizeMax, this.backgroundPath, this.baseColor);
}

class Game extends StatefulWidget {
  const Game({Key key}) : super(key: key);

  static const List<Difficulty> difficulties = <Difficulty>[
    Difficulty("Baby Mode", 3, 5, "./assets/background_baby.jpg", Colors.teal),
    Difficulty("Normal", 6, 8, "./assets/background_normal.png", Colors.lightBlue),
    Difficulty("Hellish", 9, 11, "./assets/background_hellish.jpg", Colors.orange)
  ];

  @override
  GameState createState() => GameState();
}

class GameState extends State<Game> {
  List<int> usedLetters = <int>[];
  List<String> correctWords = <String>[];
  bool finishDialogOpen = false;
  Random rand = Random();
  List<String> words;
  List<Char> grid;

  static const double gridMargin = 20;
  static const double timerHeight = 60;

  StopWatchWidget stopWatchWidget;

  List<GlobalKey<TileState>> listOfKeys;
  List<Tile> tiles;

  int currentDifficulty = 0;
  int rowSize = 0;
  int wordCount = 0;

  // When clicking each game tile
  void tileClick(Char char, bool notSelected) {
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
    final List<int> usedLettersOld = List<int>.from(usedLetters);
    if (hasWon()) {
      for (final int pos in usedLettersOld) {
        final GlobalKey<TileState> key = listOfKeys[pos];
        key.currentState.setState(() {
          key.currentState.setCorrect(true);
        });
      }
      stopWatchWidget.stop();
      win();
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
      if (usedLetters.length >= rowSize) clear();
    }
  }

  // Tries to place word in grid and returns the grid if if fits
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

  int binarySearchPrefix(List<String> arr, String prefix) {
    int l = 0;
    int r = arr.length - 1;
    while (l <= r) {
      final int mid = (l + (r - l) / 2).toInt();

      final int res = prefix.compareTo(arr[mid]);

      if (res == 0) return -2;

      if (arr[mid].startsWith(prefix)) {
        return mid;
      } else {
        if (res > 0) {
          l = mid + 1;
        } else {
          r = mid - 1;
        }
      }
    }

    return -1;
  }

  void filterBadWords(
      List<Char> grid, List<String> badWords, List<String> arr, int depth, int dir, int pos, bool forceDir) {
    if (depth >= rowSize) {
      return;
    }

    if (dir == 0) {
      filterBadWords(grid, badWords, <String>[], depth, 0x1, pos, forceDir);
      filterBadWords(grid, badWords, <String>[], depth, 0x2, pos, forceDir);
    } else {
      for (int i = arr.length - 1; i >= 0; i--) {
        final int result = binarySearchPrefix(badWords, arr[i] + grid[pos].toString());
        if (result == -2) {
          if (grid[pos].char.toUpperCase() == grid[pos].char) {
            grid[pos] = Char(i, String.fromCharCode(rand.nextInt(26) + 65));
          }
          //return true;
        } else if (result == -1) {
          arr.removeAt(i);
        } else {
          arr[i] = arr[i] + grid[pos].toString();
        }
      }

      arr.add(grid[pos].toString());

      if (!forceDir) {
        filterBadWords(grid, badWords, <String>[], 0, (~dir) & 0x3, pos, true);
        filterBadWords(grid, badWords, <String>[], depth, 0x3, pos, true);
      }

      pos += ((dir & 0x2) >> 1) * rowSize + (dir & 0x1);

      filterBadWords(grid, badWords, arr, depth + 1, dir, pos, forceDir);
    }
  }

  List<Char> generateGrid(List<String> words, int gridSize, List<String> bWords) {
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

    // Places random letters in the empty spaces
    for (int i = 0; i < wordStack.last.grid.length; i++) {
      if (wordStack.last.grid[i] == null) {
        wordStack.last.grid[i] = Char(i, String.fromCharCode(rand.nextInt(26) + 65));
      }
    }

    filterBadWords(wordStack.last.grid, bWords, <String>[], 0, 0, 0, false);

    return wordStack.last.grid;
  }

  // Clears all tiles
  void clear() {
    usedLetters.clear();
    listOfKeys.forEach((GlobalKey<TileState> key) {
      key.currentState.setState(() {
        key.currentState.tileColor = key.currentState.normalColor;
        key.currentState.notSelected = true;
      });
    });
  }

  // Shows the winning dialog
  void win() async {
    try {
      final DatabaseReference winsRef = FirebaseDatabase.instance.reference().child("AmountOfGames");
      winsRef.once().then((DataSnapshot value) => winsRef.set((int.parse(value.value.toString()) ?? 0) + 1));
    } catch (e) {
      dev.log(e.toString());
    }
    await showDialog<AlertDialog>(
      context: context,
      builder: (BuildContext context) {
        finishDialogOpen = true;
        return AlertDialog(
          content: Text("Your time: ${stopWatchWidget.formatTime()}"),
          title: const Text("You completed this level"),
          actions: <Widget>[
            CupertinoButton(
              child: const Text("Continue to next level"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
    setState(() {
      currentDifficulty = (currentDifficulty + 1) % Game.difficulties.length;
      finishDialogOpen = false;
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
    final List<String> compatibleWords = words.where((String w) => w.length <= rowSize).toList();
    compatibleWords.shuffle();
    return compatibleWords.getRange(0, wordCount).toList();
  }

  void startGame(AsyncSnapshot<dynamic> wordsSnapshot, AsyncSnapshot<dynamic> bWordsSnapshot) {
    if (correctWords.isEmpty && !finishDialogOpen) {
      final int max = Game.difficulties[currentDifficulty].rowSizeMax;
      final int min = Game.difficulties[currentDifficulty].rowSizeMin;
      rowSize = Random().nextInt(max - min + 1) + min;
      wordCount = rand.nextInt(rowSize - (rowSize / 2).ceil()) + (rowSize / 2).ceil();
      dev.log(wordCount.toString());

      List<String> bWords = bWordsSnapshot.data.toString().replaceAll("\r", "").split("\n");
      words = getWords(wordsSnapshot.data.toString().replaceAll("\r", "").split("\n"));
      grid = generateGrid(words, rowSize, bWords);
      listOfKeys = List<GlobalKey<TileState>>.generate(rowSize * rowSize, (int i) => GlobalKey<TileState>());
      tiles = List<Tile>.generate(
        rowSize * rowSize,
        (int index) => Tile(
          key: listOfKeys[index],
          baseColor: Game.difficulties[currentDifficulty].baseColor,
          char: Char(index, grid[index]?.char ?? "_"),
          onClick: (Char char, bool notSelected) => tileClick(char, notSelected),
        ),
      );
      stopWatchWidget = StopWatchWidget(timerHeight: timerHeight / 2 - 5);
      stopWatchWidget.reset();
      stopWatchWidget.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> bWordsYeet = ["bajs", "magnus", "mamma", "yeet"];

    dev.log(bWordsYeet[binarySearchPrefix(bWordsYeet, "ba")]);
    dev.log(bWordsYeet[binarySearchPrefix(bWordsYeet, "ma")]);

    final MediaQueryData mqData = MediaQuery.of(context);
    // Scales the grid to fit the screen
    double gridSize = 200;
    if (mqData.size.height > mqData.size.width) {
      final double horPadding = mqData.padding.left + mqData.padding.right;
      gridSize = mqData.size.width - gridMargin - horPadding;
    } else {
      final double vertPadding = mqData.padding.top + mqData.padding.bottom;
      gridSize = mqData.size.height - gridMargin - vertPadding - timerHeight;
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            Game.difficulties[currentDifficulty].backgroundPath,
            alignment: Alignment.topCenter,
            fit: BoxFit.cover,
          ),
          Center(
            child: SafeArea(
              child: FutureBuilder<dynamic>(
                  future: rootBundle.loadString("assets/bwords.txt"),
                  builder: (BuildContext context, AsyncSnapshot<dynamic> bWordsSnapshot) {
                    if (!bWordsSnapshot.hasData) return Container();
                    return FutureBuilder<dynamic>(
                      future: rootBundle.loadString("assets/words.txt"),
                      builder: (BuildContext context, AsyncSnapshot<dynamic> wordsSnapshot) {
                        if (!wordsSnapshot.hasData) return Container();
                        startGame(wordsSnapshot, bWordsSnapshot);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              height: timerHeight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  stopWatchWidget,
                                  Text(
                                    Game.difficulties[currentDifficulty].name,
                                    style: const TextStyle(
                                      fontSize: timerHeight / 2 - 5,
                                      color: Colors.white,
                                      shadows: <Shadow>[
                                        Shadow(
                                          color: Colors.black,
                                          offset: Offset(3, 5),
                                          blurRadius: 8,
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: gridSize,
                              width: gridSize,
                              margin: const EdgeInsets.all(gridMargin / 2),
                              color: Colors.grey[900],
                              child: GridView.count(
                                childAspectRatio: 1,
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(Tile.tileMargin),
                                crossAxisCount: rowSize,
                                children: List<Widget>.generate(
                                  rowSize * rowSize,
                                  (int index) => tiles[index],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}
