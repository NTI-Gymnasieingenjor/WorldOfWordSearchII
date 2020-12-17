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
  List<String> words = <String>["J", "U", "L", "A", "V", "Ö", "K", "B", "C"];
  List<String> usedWords = <String>[];
  bool finishDialogOpen = false;

  List<GlobalKey<TileState>> listOfKeys = List<GlobalKey<TileState>>.generate(9, (int i) => GlobalKey<TileState>());

  void clear() {
    usedWords.clear();
    listOfKeys.forEach((GlobalKey<TileState> key) {
      key.currentState.setState(() {
        key.currentState.baseColor = Colors.green;
      });
    });
  }

  void winnerWinner() async {
    finishDialogOpen = true;
    await showDialog<AlertDialog>(
      context: context,
      builder: (BuildContext context) {
        finishDialogOpen = true;
        return AlertDialog(
          key: const Key("WonDialog"),
          title: const Text("You won!"),
          actions: <Widget>[
            MaterialButton(
              child: const Text("Restart"),
              onPressed: () {
                Navigator.pop(context);
                finishDialogOpen = false;
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          color: Colors.red,
          child: GridView.count(
            shrinkWrap: true,
            padding: const EdgeInsets.all(2),
            crossAxisCount: 3,
            children: List<Widget>.generate(9, (int index) {
              return Tile(
                key: listOfKeys[index],
                letter: words[index],
                onClick: (String letter, bool selected) async {
                  if (!selected) {
                    usedWords.add(letter);
                    if (usedWords.length >= 3) {
                      if (usedWords.join("") == ("JUL")) winnerWinner();
                      clear();
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
    );
  }
}

class Tile extends StatefulWidget {
  const Tile({Key key, this.letter, this.onClick, this.winnerWinner}) : super(key: key);
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
