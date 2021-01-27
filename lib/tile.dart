import "dart:developer" as dev;

import "package:firebase_database/firebase_database.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:auto_size_text/auto_size_text.dart";

import "main.dart";

class Tile extends StatefulWidget {
  const Tile({Key key, this.char, this.onClick, this.baseColor}) : super(key: key);

  static const double tileMargin = 0.75;

  final Color baseColor;
  final Char char;
  final void Function(Char letter, bool selected) onClick;
  @override
  TileState createState() => TileState();
}

class TileState extends State<Tile> {
  // static const Color correctBaseColor = Colors.white;

  bool notSelected = true;
  Color normalColor;
  Color tileColor;
  Color colorClicked;
  Color correctBaseColor;

  @override
  void initState() {
    super.initState();
    normalColor = widget.baseColor;
    tileColor = widget.baseColor;
    colorClicked = widget.baseColor.withOpacity(0.75);
    correctBaseColor = widget.baseColor.withOpacity(0.4);
  }

  void setCorrect(bool correct) {
    setState(() {
      normalColor = correct ? correctBaseColor : widget.baseColor;
      tileColor = normalColor;
      notSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    tileColor = notSelected ? normalColor : colorClicked;
    return GestureDetector(
      onTap: () {
        notSelected = !notSelected;
        setState(() {
          try {
            final DatabaseReference clicksRef = FirebaseDatabase.instance.reference().child("AmountOfClicks");
            clicksRef.once().then((DataSnapshot value) => clicksRef.set((int.parse(value.value.toString()) ?? 0) + 1));
          } catch (e) {
            dev.log(e.toString());
          }
          tileColor = notSelected ? normalColor : colorClicked;
          widget.onClick(widget.char, notSelected);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        margin: const EdgeInsets.all(Tile.tileMargin),
        color: tileColor,
        child: Center(
          child: AutoSizeText(
            widget.char.char.toUpperCase(),
            style: const TextStyle(color: Colors.black, fontSize: 35),
            maxLines: 1,
            minFontSize: 23,
            maxFontSize: 35,
          ),
        ),
      ),
    );
  }
}
