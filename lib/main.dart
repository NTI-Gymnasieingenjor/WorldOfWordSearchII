import 'package:flutter/material.dart';
import "dart:math" as math;
import 'dart:collection';
import 'dart:developer' as developer;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Magnus testar'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  List<String> words = ['J', 'C', 'F', 'A', 'U', 'Ö', 'G', 'U', 'L'];
  List<String> usedWords = [];

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  void winnerWinner() {
    showDialog<AlertDialog>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("You won!"),
          actions: <Widget>[
            MaterialButton(
              child: const Text("Restart"),
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                });
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Center(
        child: Container(
          color: Colors.red,
          child: GridView.count(
            shrinkWrap: true,
            padding: const EdgeInsets.all(2),
            crossAxisCount: 3,
            children: List.generate(9, (word) {
              return Tile(
                letter: words[word],
                onClick: (String letter, bool selected) {
                  if (usedWords.length >= 3) {
                    developer.log(usedWords.toString());
                    usedWords = [];
                  } else {
                    if (!selected) {
                      usedWords.add(letter);
                      developer.log(usedWords.toString());
                      if (usedWords.join("") == ("JUL")) {
                        winnerWinner();

                        usedWords = [];
                      }
                    }
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
  Tile({Key key, this.letter, this.onClick, this.winnerWinner})
      : super(key: key);
  final String letter;
  final void Function(String letter, bool selected) onClick;
  final void Function() winnerWinner;
  @override
  _TileState createState() => _TileState();
}

class _TileState extends State<Tile> {
  Color colorClicked = Color(0xff98fb98);
  Color baseColor = Colors.green;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onClick(widget.letter, baseColor == colorClicked);
        setState(() {
          baseColor = (baseColor == colorClicked ? Colors.green : colorClicked);
        });
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        color: baseColor,
        child: Center(
          child: Text(
            widget.letter,
            style: TextStyle(color: Colors.yellowAccent, fontSize: 35),
          ),
        ),
      ),
    );
  }
}
