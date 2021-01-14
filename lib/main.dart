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

class Char {
  const Char(this.pos, this.char);
  final int pos;
  final String char;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  bool loadedWords = false;

  List<int> usedWords = <int>[];
  bool finishDialogOpen = false;

  List<GlobalKey<TileState>> listOfKeys = List<GlobalKey<TileState>>.generate(9, (int i) => GlobalKey<TileState>());

  Future<dynamic> getWords() async {
    return (await FirebaseDatabase.instance.reference().child("Levels").child("1").once()).value;
  }

  void clear() {
    usedWords.clear();
    if (loadedWords) {
      listOfKeys.forEach((GlobalKey<TileState> key) {
        key.currentState.setState(() {
          key.currentState.baseColor = Colors.green;
        });
      });
    }
  }

  void winnerWinner() async {
    FirebaseDatabase.instance.reference().child("AmountOfWins").once().then((DataSnapshot value) =>
        FirebaseDatabase.instance.reference().child("AmountOfWins").set((int.parse(value.value.toString()) ?? 0) + 1));
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
                  Image.asset("assets/present.png"),
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

  bool hasWon(List<String> correctWords) => correctWords.where((String e) => usedWords.join(",") == e).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mqData = MediaQuery.of(context);
    const double gridMargin = 20;
    // Scales the grid to fit
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
                color: Colors.red,
                child: FutureBuilder<dynamic>(
                    future: getWords(),
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      if (!snapshot.hasData) return Container();
                      loadedWords = true;
                      final dynamic data = snapshot.data;

                      final int rowSize = int.parse(data["gridSize"]?.toString());

                      final List<String> correctWords =
                          (data["correctWords"] as List<dynamic>).map((dynamic e) => e.toString()).toList();

                      final List<List<Char>> words = <List<Char>>[];
                      final String letters = data["letters"].toString();
                      int index = 0;
                      for (final String char in letters.split("")) {
                        final int row = (index / rowSize).floor();
                        if (words.isEmpty || words.length == row) words.add(<Char>[]);
                        words[row].add(Char(index, char));
                        index++;
                      }
                      return GridView.count(
                        childAspectRatio: 1,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(2),
                        crossAxisCount: rowSize,
                        children: List<Widget>.generate(9, (int index) {
                          return Tile(
                            key: listOfKeys[index],
                            char: words[(index / words.length).floor()][index % words.length],
                            onClick: (Char char, bool selected) async {
                              if (!selected) {
                                usedWords.add(char.pos);
                                usedWords.sort();
                                if (usedWords.length >= 3) {
                                  if (hasWon(correctWords)) {
                                    winnerWinner();
                                  } else {
                                    final DatabaseReference ref =
                                        FirebaseDatabase.instance.reference().child("AmountOfLosses");
                                    ref.once().then(
                                        (DataSnapshot value) => ref.set((int.parse(value.value.toString()) ?? 0) + 1));
                                  }
                                  clear();

                                  FirebaseDatabase.instance.reference().child("AmountOfGames").once().then(
                                      (DataSnapshot value) => FirebaseDatabase.instance
                                          .reference()
                                          .child("AmountOfGames")
                                          .set((int.parse(value.value.toString()) ?? 0) + 1));
                                }
                              } else {
                                usedWords.remove(char.pos);
                              }
                            },
                          );
                        }),
                      );
                    }),
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
  Color baseColor = Colors.green;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          FirebaseDatabase.instance.reference().child("AmountOfClicks").once().then((DataSnapshot value) =>
              FirebaseDatabase.instance
                  .reference()
                  .child("AmountOfClicks")
                  .set((int.parse(value.value.toString()) ?? 0) + 1));
          final bool selected = baseColor == colorClicked;
          baseColor = selected ? Colors.green : colorClicked;
          widget.onClick(widget.char, selected);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        color: baseColor,
        child: Center(
          child: Text(
            widget.char.char,
            style: const TextStyle(color: Colors.yellowAccent, fontSize: 35),
          ),
        ),
      ),
    );
  }
}
