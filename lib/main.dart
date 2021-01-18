import "package:firebase_database/firebase_database.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

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

class MyHomePageState extends State<MyHomePage> {
  bool loadedWords = false;

  List<int> usedLetters = <int>[];
  List<String> correctWords = <String>[];
  List<String> originalWords = <String>[];
  bool finishDialogOpen = false;

  List<GlobalKey<TileState>> listOfKeys;

  Future<dynamic> getWords() async =>
      (await FirebaseDatabase.instance.reference().child("Levels").child("1").once()).value;

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
                    loadedWords = true;
                    // Gets the column and row child count
                    final int rowSize = int.parse(snapshot.data["gridSize"]?.toString());
                    listOfKeys =
                        List<GlobalKey<TileState>>.generate(rowSize * rowSize, (int i) => GlobalKey<TileState>());

                    originalWords =
                        (snapshot.data["correctWords"] as List<dynamic>).map((dynamic e) => e.toString()).toList();
                    correctWords = originalWords;

                    // [["M", "A", "G"], ["N", "U", "S"], ["M", "O", "R"]]
                    final List<List<Char>> words = <List<Char>>[];
                    int i = 0;
                    for (final String char in snapshot.data["letters"].toString().split("")) {
                      final int row = (i / rowSize).floor();
                      if (words.isEmpty || words.length == row) words.add(<Char>[]);
                      words[row].add(Char(i, char));
                      i++;
                    }
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
                              if (hasWon()) {
                                winnerWinner();
                                clear();
                              } else {
                                final DatabaseReference lossesRef =
                                    FirebaseDatabase.instance.reference().child("AmountOfLosses");
                                lossesRef.once().then((DataSnapshot value) =>
                                    lossesRef.set((int.parse(value.value.toString()) ?? 0) + 1));
                                if (usedLetters.length >= rowSize) {
                                  clear();
                                }
                              }
                              final DatabaseReference gamesRef =
                                  FirebaseDatabase.instance.reference().child("AmountOfGames");
                              gamesRef.once().then(
                                  (DataSnapshot value) => gamesRef.set((int.parse(value.value.toString()) ?? 0) + 1));
                            } else {
                              usedLetters.remove(char.id);
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
