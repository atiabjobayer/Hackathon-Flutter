import 'dart:async';
import 'dart:convert' show utf8;

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:all_sensors2/all_sensors2.dart';

Future<void> main() async {
  runApp(MainScreen());
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JRC Hackathon App',
      debugShowCheckedModeBanner: false,
      home: Transmitter(),
      theme: ThemeData.dark(),
    );
  }
}

class Transmitter extends StatefulWidget {
  const Transmitter({this.device});
  final BluetoothDevice? device;

  @override
  _TransmitterState createState() => _TransmitterState();
}

class _TransmitterState extends State<Transmitter> {
  final String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String targetDeviceName = "ESP32 GET NOTI FROM DEVICE";

  List<double> _accelerometerValues = [0, 0, 0];
  List<double> _gyroscopeValues = [0, 0, 0];
  List<double> _proximityValues = [0, 0, 0];

  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? scanSubScription;

  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? targetCharacteristic;

  String connectionText = "";

  bool sendState = false;

  var lastTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // startScan();
    targetDevice = widget.device;
    discoverServices();
  }

  // startScan() {
  //   setState(() {
  //     connectionText = "Start Scanning";
  //   });

  //   scanSubScription = flutterBlue.scan().listen((scanResult) {
  //     if (scanResult.device.name == targetDeviceName) {
  //       print('DEVICE found');
  //       stopScan();
  //       setState(() {
  //         connectionText = "Found Target Device";
  //       });

  //       targetDevice = scanResult.device;
  //       connectToDevice();
  //     }
  //   }, onDone: () => stopScan());
  // }

  // stopScan() {
  //   scanSubScription?.cancel();
  //   scanSubScription = null;
  // }

  // connectToDevice() async {
  //   if (targetDevice == null) return;

  //   setState(() {
  //     connectionText = "Device Connecting";
  //   });

  //   await targetDevice.connect();
  //   print('DEVICE CONNECTED');
  //   setState(() {
  //     connectionText = "Device Connected";
  //   });

  //   discoverServices();
  // }

  // disconnectFromDevice() {
  //   if (targetDevice == null) return;

  //   targetDevice.disconnect();

  //   setState(() {
  //     connectionText = "Device Disconnected";
  //   });
  // }

  discoverServices() async {
    if (targetDevice == null) return;

    List<BluetoothService> services = await targetDevice!.discoverServices();
    services.forEach((service) {
      // do something with service
      if (service.uuid.toString() == serviceUUID) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == characteristicUUID) {
            targetCharacteristic = characteristic;
            writeData("Hi there, ESP32!!");
            setState(() {
              connectionText = "All Ready with ${targetDevice?.name}";
            });
          }
        });
      }
    });
  }

  writeData(String data) {
    if (targetCharacteristic == null) return;

    List<int> bytes = utf8.encode(data);
    targetCharacteristic?.write(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(connectionText),
      ),
      body: Container(
        child: targetCharacteristic == null
            ? Center(
                child: Text(
                  "Waiting...",
                  style: TextStyle(fontSize: 24, color: Colors.red),
                ),
              )
            : Column(
                children: [
                  DropdownButton<String>(
                    items: <String>[
                      'Accelerometer',
                      'Gyroscope',
                      'Proximity Sensor'
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (_) {},
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      if (sendState) ...[
                        TextButton(
                          onPressed: () {
                            setState(() {
                              sendState = false;
                            });

                            writeData("off hoise");
                          },
                          child: Text(
                            'Stop Transmitting',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ] else ...[
                        TextButton(
                          onPressed: () {
                            setState(() {
                              sendState = true;
                            });
                            accelerometerEvents
                                ?.listen((AccelerometerEvent event) {
                              if (sendState) {
                                setState(() {
                                  _accelerometerValues = <double>[
                                    event.x,
                                    event.y,
                                    event.z
                                  ];
                                });

                                var curTime = DateTime.now();

                                var diff =
                                    curTime.difference(lastTime).inMilliseconds;

                                if (diff > 200) {
                                  print(event);
                                  writeData(
                                      "${_accelerometerValues[0].toStringAsFixed(2)} ${_accelerometerValues[1].toStringAsFixed(2)} ${_accelerometerValues[2].toStringAsFixed(2)}");

                                  lastTime = curTime;
                                }
                              }
                            });
                            print("on pressed");
                            writeData("on hoise");
                          },
                          child: Text('Start Transmitting'),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
