import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:ppg/chart.dart';
import 'package:wakelock/wakelock.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageView createState() {
    return HomePageView();
  }
}

class HomePageView extends HomePageState {
  double average = 0;
  double value = 0;
  int ts = 30;
  double alpha = 0.01;
  int windowLen = 30 * 3;
  List<SensorValue> data = [];
  bool _reading = false;
  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  _startImageStream() {
    if (controller != null) {
      try {
        Future.delayed(Duration(seconds: 1))
            .then((onValue) => controller.flash(true));
        controller.startImageStream((CameraImage availableImage) {
          if (!_processing) {
            setState(() {
              _processing = true;
            });
            _scanImage(availableImage);
          }
        });
        setState(() {
          // To keep the screen on:
          Wakelock.enable();
          _reading = true;
        });
      } catch (Exception) {
        _initCamera().then((onValue) {
          _startImageStream();
        });
      }
    }
  }

  _stopImageStream() {
    if (controller != null) {
      controller.flash(false);
      controller.stopImageStream();
    }
    setState(() {
      Wakelock.disable();
      _reading = false;
    });
  }

  _initCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
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
      value = avg - average;
      average = ((1 - alpha) * average + alpha * avg).clamp(0, 255);
      data.add(SensorValue(DateTime.now().millisecondsSinceEpoch, value));
      _processing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  (controller != null && _reading)
                      ? AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: CameraPreview(controller),
                        )
                      : Container(),
                  Center(
                    child: Text(
                      value.toStringAsFixed(3),
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ],
              )),
          Expanded(
            flex: 1,
            child: Center(
              child: IconButton(
                icon: Icon(_reading ? Icons.favorite : Icons.favorite_border),
                color: Colors.red,
                iconSize: 128,
                onPressed: () {
                  _reading ? _stopImageStream() : _startImageStream();
                },
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(18),
                  ),
                  color: const Color(0xff232d37)),
              child: Padding(
                padding: const EdgeInsets.only(
                    right: 18.0, left: 12.0, top: 24, bottom: 12),
                child: Chart(getChart(data)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

abstract class HomePageState extends State<HomePage> {
  CameraController controller;
  List<CameraDescription> cameras;
  bool _processing = false;
}
