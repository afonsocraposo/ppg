import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:wakelock/wakelock.dart';

import 'chart.dart';

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
  double alpha = 1 / 30;
  int windowLen = 30 * 2;
  List<TimeSeriesSales> data = [];
  bool _reading = false;

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
      data.add(TimeSeriesSales(DateTime.now(), (value * 100).round()));
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
              padding: EdgeInsets.all(32),
              child: charts.TimeSeriesChart(
                [
                  charts.Series<TimeSeriesSales, DateTime>(
                    id: 'Sales',
                    colorFn: (_, __) =>
                        charts.MaterialPalette.blue.shadeDefault,
                    domainFn: (TimeSeriesSales sales, _) => sales.time,
                    measureFn: (TimeSeriesSales sales, _) => sales.sales,
                    data: data,
                  )
                ],
                animate: false,
                dateTimeFactory: const charts.LocalDateTimeFactory(),
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
