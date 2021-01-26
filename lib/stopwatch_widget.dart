import "dart:async";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class StopWatchWidget extends StatefulWidget {
  StopWatchWidget({Key key, this.timerHeight}) : super(key: key);

  final double timerHeight;

  Stopwatch stopwatch = Stopwatch();

  void stop() {
    stopwatch.stop();
  }

  void start() {
    stopwatch.start();
  }

  void reset() {
    stopwatch.reset();
  }

  String formatTime() {
    final String hours = stopwatch.elapsed.inHours.toString().padLeft(2, "0");
    final String mins = stopwatch.elapsed.inMinutes.remainder(60).toString().padLeft(2, "0");
    final String secs = stopwatch.elapsed.inSeconds.remainder(60).toString().padLeft(2, "0");
    return "$hours:$mins:$secs";
  }

  @override
  StopWatchWidgetState createState() => StopWatchWidgetState();
}

class StopWatchWidgetState extends State<StopWatchWidget> {
  Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (Timer timer) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    widget.stopwatch.reset();
    widget.stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.timerHeight,
      child: Text(
        widget.formatTime(),
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.timerHeight,
          shadows: const <Shadow>[
            Shadow(
              color: Colors.purple,
              offset: Offset(3, 5),
              blurRadius: 8,
            )
          ],
        ),
      ),
    );
  }
}
