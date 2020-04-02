import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ppg/chart.dart';
import 'package:wakelock/wakelock.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageView createState() {
    return HomePageView();
  }
}

class HomePageView extends HomePageState with SingleTickerProviderStateMixin {
  int ts = 30;
  int windowLen = 30 * 2;
  List<SensorValue> data = [];
  bool _reading = false;
  AnimationController animationController;
  Animation sizeAnimation;
  double iconScale = 1;
  double _bpm = 0;
  double alpha = 0.3;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < windowLen; i++)
      data.add(SensorValue(DateTime.now(), 0));
    animationController =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    sizeAnimation = Tween(begin: 0.0, end: 1).animate(CurvedAnimation(
        parent: animationController, curve: Curves.bounceInOut));
    animationController
      ..addListener(() {
        setState(() {
          iconScale = 1.0 + animationController.value * 0.4;
        });
      });
  }

  void dispose() {
    super.dispose();
    _stopImageStream();
  }

  _startImageStream() async {
    try {
      await _initCamera();
      Future.delayed(Duration(milliseconds: 500))
          .then((onValue) => controller.flash(true));
      controller.startImageStream((CameraImage availableImage) {
        if (!_processing) {
          setState(() {
            _processing = true;
          });
          _scanImage(availableImage);
        }
      });
      animationController.repeat(reverse: true);
      // To keep the screen on:
      Wakelock.enable();
      setState(() {
        _reading = true;
      });
      updateBPM();
    } catch (Exception) {
      controller = null;
    }
  }

  _stopImageStream() {
    if (controller != null) {
      controller.flash(false);
      controller.stopImageStream();
      controller = null;
    }
    animationController.stop();
    animationController.value = 0.0;
    Wakelock.disable();
    setState(() {
      _reading = false;
    });
  }

  _initCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.low);
    await controller.initialize();
  }

  void _scanImage(CameraImage availableImage) async {
    double avg = 0;
    int n = availableImage.planes[0].bytes.length;
    availableImage.planes[0].bytes.forEach((int value) {
      avg += value / n;
    });
    if (data.length >= windowLen) {
      data.removeAt(0);
    }
    await Future.delayed(Duration(milliseconds: 1000 ~/ ts));
    setState(() {
      data.add(SensorValue(DateTime.now(), avg));
      _processing = false;
    });
  }

  updateBPM() async {
    List<SensorValue> values = List.from(data);
    double avg = 0;
    int n = values.length;
    double m = 0;
    values.forEach((SensorValue value) {
      avg += value.value / n;
      if (value.value > m) m = value.value;
    });
    double threshold = (m + avg) / 2;
    double bpm = 0;
    int counter = 0;
    int previous = 0;
    for (int i = 1; i < n; i++) {
      if (values[i - 1].value < threshold && values[i].value > threshold) {
        if (previous != 0) {
          counter++;
          bpm += 60000 / (values[i].time.millisecondsSinceEpoch - previous);
        }
        previous = values[i].time.millisecondsSinceEpoch;
      }
    }
    if (_reading) {
      if (counter > 0) {
        print(bpm ~/ counter);
        setState(() {
          _bpm = (1 - alpha) * bpm + alpha * bpm / counter;
        });
      }
      Future.delayed(Duration(milliseconds: (1000 * windowLen / ts).round()))
          .then((onValue) => updateBPM());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(18),
                          ),
                          child: Stack(
                            children: <Widget>[
                              controller != null && _reading
                                  ? AspectRatio(
                                      aspectRatio: controller.value.aspectRatio,
                                      child: CameraPreview(controller),
                                    )
                                  : Container(
                                      padding: EdgeInsets.all(12),
                                      alignment: Alignment.center,
                                      color: Colors.grey,
                                    ),
                              Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.all(4),
                                child: Text(
                                  _reading
                                      ? "Cover both the camera and the flash with your finger"
                                      : "Camera feed will display here",
                                  style: TextStyle(
                                      backgroundColor: _reading
                                          ? Colors.white
                                          : Colors.transparent),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          "BPM:\n" +
                              (_bpm > 30 && _bpm < 150
                                  ? _bpm.round().toString()
                                  : "--"),
                          style: TextStyle(fontSize: 32),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )),
            Expanded(
              flex: 1,
              child: Center(
                child: Transform.scale(
                  scale: iconScale,
                  child: IconButton(
                    icon:
                        Icon(_reading ? Icons.favorite : Icons.favorite_border),
                    color: Colors.red,
                    iconSize: 128,
                    onPressed: () {
                      if (_reading) {
                        _stopImageStream();
                      } else {
                        _startImageStream();
                      }
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(18),
                    ),
                    color: Colors.black),
                child: Chart(getChart(data)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract class HomePageState extends State<HomePage> {
  CameraController controller;
  List<CameraDescription> cameras;
  bool _processing = false;
}
