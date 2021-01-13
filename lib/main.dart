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
  List<List<String>> words = [
    ["J", "U", "L"],
    ["A", "V", "Ö"],
    ["K", "B", "C"],
  ];
  List<String> usedWords = <String>[];
  bool finishDialogOpen = false;

  List<GlobalKey<TileState>> listOfKeys =
      List<GlobalKey<TileState>>.generate(9, (int i) => GlobalKey<TileState>());

  void clear() {
    usedWords.clear();
    listOfKeys.forEach((GlobalKey<TileState> key) {
      key.currentState.setState(() {
        key.currentState.baseColor = Colors.green;
      });
    });
  }

  void winnerWinner() async {
    FirebaseDatabase.instance
        .reference()
        .child("AmountOfWins")
        .once()
        .then((value) => FirebaseDatabase.instance.reference().child("AmountOfWins").set((int.parse(value.value.toString()) ?? 0) + 1)
    );
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
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 5),
                          child: CupertinoButton(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 4),
                            child: const Text("Restart",
                                style: TextStyle(color: Colors.black)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            "assets/background.png",
            alignment: Alignment.center,
            fit: BoxFit.fill,
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.all(10),
              color: Colors.red,
              child: GridView.count(
                shrinkWrap: true,
                padding: const EdgeInsets.all(2),
                crossAxisCount: 3,
                children: List<Widget>.generate(9, (int index) {
                  return Tile(
                    key: listOfKeys[index],
                    letter: words[(index / words.length).floor()]
                        [index % words.length],
                    onClick: (String letter, bool selected) async {
                      if (!selected) {
                        usedWords.add(letter);
                        if (usedWords.length >= 3) {
                          if (usedWords.join("") == ("JUL")) winnerWinner();
                          else{
                            FirebaseDatabase.instance
                            .reference()
                            .child("AmountOfLosses")
                            .once()
                            .then((value) => FirebaseDatabase.instance.reference().child("AmountOfLosses").set((int.parse(value.value.toString()) ?? 0) + 1)
                        ); 

                          }
                          clear();

                        FirebaseDatabase.instance
                        .reference()
                        .child("AmountOfGames")
                        .once()
                        .then((value) => FirebaseDatabase.instance.reference().child("AmountOfGames").set((int.parse(value.value.toString()) ?? 0) + 1)
                        ); 
                        }
                      } else {
                        usedWords.remove(letter);
                      }
                    },
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
  const Tile({Key key, this.letter, this.onClick, this.winnerWinner})
      : super(key: key);
  final String letter;
  final void Function(String letter, bool selected) onClick;
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
            FirebaseDatabase.instance
            .reference()
            .child("AmountOfClicks")
            .once()
            .then((value) => FirebaseDatabase.instance.reference().child("AmountOfClicks").set((int.parse(value.value.toString()) ?? 0) + 1)
            );
          final bool selected = baseColor == colorClicked;
          baseColor = selected ? Colors.green : colorClicked;
          widget.onClick(widget.letter, selected);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        color: baseColor,
        child: Center(
          child: Text(
            widget.letter,
            style: const TextStyle(color: Colors.yellowAccent, fontSize: 35),
          ),
        ),
      ),
    );
  }
}
