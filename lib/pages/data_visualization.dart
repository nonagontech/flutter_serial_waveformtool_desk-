import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import '../../common/utils/utils.dart';

import 'package:flutter/services.dart';
import '../common/style/color.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../common/routes/pages.dart';
import 'help.dart';
import 'package:usb_serial/usb_serial.dart';
import '../common/utils/storage.dart';
import '../common/value/server.dart';
import '../common/utils/ble.dart';

import 'package:flutter_usb_event/flutter_usb_event.dart';

/// @file  data_visualization
/// @author https://aiflutter.com/
/// @description 用于展示和分析数据波形。该页面通过对接STAMP协议接收设备数据，并将这些数据以折线图的形式展示给用户。
/// @createDate 2025-04-25 15:38:54
class DataVisualization extends StatefulWidget {
  const DataVisualization({super.key});

  @override
  State<DataVisualization> createState() => _DataVisualizationState();
}

class _DataVisualizationState extends State<DataVisualization> {
  var disconnectTimer;
  List password = [];
  bool scaning = false;
  String data = "";
  List res = [];
  List selectData1 = [];
  var _connectionSubscription;
  var _getData;
  bool isConnected = true;
  String wifiname = "";
  List selectData2 = [];
  List selectData3 = [];
  List selectData4 = [];
  bool isScanding = false;
  List selectData1X = [];
  List selectData2X = [];
  List selectData3X = [];
  List selectData4X = [];
  List rawData = [];
  StreamSubscription? _serialData;
  StreamSubscription? _usbEventSubscription;
  UsbPort? port;
  List<UsbDevice> devices = [];
  Timer? timer2;
  Timer? deskSerialTimer;
  StreamSubscription? _serialDeskData;
  StreamSubscription? _serialDeskStatus;
  SerialPort? serialPort;
  bool canSerialScan = false; //是否可以扫描
  Timer? serialTimer; //准备轮询查看是否有设备
  List availablePorts = [];
  int macAddr = 0x08005000;
  List<double> normalData = []; //正常数据
  int averageNum = 4; //截取长度
  int normalNum = 28; //正常长度
  int chartLength = 100; //折线图
  List<double> queue = []; //队列
  List<double> chart1 = [0]; //图表
  File? currentFile;
  StreamSubscription? _upgradeData;
  StreamSubscription? _upgradeStatus;
  List<List<int>> chunks = [];
  int clickNum = 0;
  int errNum = 0;
  int num = 0;
  bool canSend = false;
  bool canSendTwo = false;
  String mac = '';

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _usbEventSubscription?.cancel();
      _usbEventSubscription = UsbSerial.usbEventStream!.listen((msg) {
        if (msg.event == UsbEvent.ACTION_USB_ATTACHED) {
          _initAction();
        } else {
          _serialData?.cancel();
          port == null;
          setState(() {});
        }
      });
    } else {
      canSerialScan = true;
      FlutterUsbEvent.startListening(
        onDeviceConnected: (deviceName) {
          deskSerialTimer?.cancel();
          deskSerialTimer = Timer(Duration(seconds: 1), _initAction);
        },
        onDeviceDisconnected: (deviceName) {
          serialPort = null;
          setState(() {});
        },
      );
    }
    _initAction();
  }

  @override
  void dispose() {
    _serialData?.cancel();
    _usbEventSubscription?.cancel();
    canSerialScan = false;
    serialPort?.close();
    serialTimer?.cancel();
    _serialDeskStatus?.cancel();
    _serialDeskData?.cancel();
    if (!Platform.isAndroid) {
      FlutterUsbEvent.stopListening();
    }
    _upgradeData?.cancel();
    _upgradeStatus?.cancel();
    _closeAction();

    super.dispose();
  }

  void _initAction() async {
    if (Platform.isAndroid) {
      devices = await UsbSerial.listDevices();
    } else {
      availablePorts = SerialPort.availablePorts;
    }
    if (Platform.isAndroid) {
      int index = -1;
      for (var i = 0; i < devices.length; i++) {
        try {
          if (i == 2) {
            index = i;
            break;
          }
        } catch (e) {
          print(e);
        }
      }
      if (index == -1) {
// 说明没有找到设备
        return;
      }
      port?.close();
      port = await devices[index].create();
      if (port == null) {
        return;
      }
      bool? openResult = await port?.open();
      if (openResult != null && !openResult) {
        return;
      }
      await port?.setDTR(true);
      await port?.setRTS(true);
      await port?.setPortParameters(115200, 8, 1, 0);
    } else {
      int index = -1;
      for (var i = 0; i < availablePorts.length; i++) {
        try {
          final port = SerialPort(availablePorts[i]);
          if (i == 2) {
            index = i;
            break;
          }
        } catch (e) {
          print(e);
        }
      }
      if (index == -1) {
// 说明没有找到设备
        return;
      }
      print("object=========${availablePorts[index]}");
      serialPort?.close();
      serialPort = SerialPort(availablePorts[index]);
      SerialPortConfig config = serialPort?.config ?? SerialPortConfig();
      config.baudRate = 115200;
      serialPort?.openReadWrite();
      // serialPort?.config = config;
    }
    if (canSend) {
      sendDataSerial("5aa5");
    }
    if (Platform.isAndroid) {
      _serialData?.cancel();
      _serialData = port?.inputStream?.listen((Uint8List event) async {
        if (event.isEmpty) {
          return;
        }
        List<String> strList = [];
        event.forEach((element) {
          strList.add(element.toRadixString(16).padLeft(2, '0'));
        });
        customCode1(strList);
      }); // read 截止
    } else {
      SerialPortReader reader = SerialPortReader(serialPort!, timeout: 40);
      _serialDeskData?.cancel();
      _serialDeskData = reader.stream.listen((event) async {
        List<String> strList = [];
        event.forEach((element) {
          strList.add(element.toRadixString(16).padLeft(2, '0'));
        });
        customCode1(strList);
      });
    }
  }

  sendFunBySerial() async {
    int num = 0;
    if (clickNum >= chunks.length || !canSend) {
      return;
    }
    List<int> element = chunks[clickNum];
    List<int> rawList = [];
    rawList.add(0x31);
    rawList.addAll(numberToBytes(macAddr));
    rawList.addAll(element);
    rawList.add(calculateChecksum(rawList.sublist(1)));
    for (var i = 0; i < rawList.length; i += 640) {
      if (i + 640 > rawList.length) {
        await sendDataSerial(rawList
            .sublist(i, rawList.length)
            .map((e) => e.toRadixString(16).padLeft(2, '0'))
            .toList()
            .join());
      } else {
        await sendDataSerial(rawList
            .sublist(i, i + 640)
            .map((e) => e.toRadixString(16).padLeft(2, '0'))
            .toList()
            .join());
      }
      await Future.delayed(Duration(milliseconds: 500));
    }
    setState(() {
      clickNum++;
      macAddr += 2048;
    });
  } // sendFunBySerial

  sendDataSerial(String data, {bool isReportId = false}) async {
    List<int> bytes = [];
    int i = 0;
    for (; i < data.length; i = i + 2) {
      if (i + 1 == data.length) {
        bytes.add(int.parse("0${data[i]}", radix: 16));
      } else {
        bytes.add(int.parse("${data[i]}${data[i + 1]}", radix: 16));
      }
    }
    if (Platform.isAndroid) {
      await port?.write(Uint8List.fromList(bytes));
    } else {
      await serialPort?.write(Uint8List.fromList(bytes));
    }
  } // sendDataSerial

  _getNormalData(initY) {
//将initY根据normalNum分割成一个二维数组
    List<List<double>> splitListData = _splitListFun(initY);
    List<double> normalized = [];
    for (var i = 0; i < splitListData.length; i++) {
      List<double> element = _normalizeData(splitListData[i]);
      normalized.addAll(element);
    }
    return normalized;
  }

  /// 归一化数据到 [a, b] 范围
  List<double> _normalizeData(List<double> data) {
// 找到数据中的最小值和最大值
    double min = data.reduce((a, b) => a < b ? a : b);
    double max = data.reduce((a, b) => a > b ? a : b);
    double range = max - min;
// 处理数据归一化
    List<double> returnData = [];
    returnData = data.map((value) {
      if (range == 0) {
        return 0.5;
      }
      return (value - min) / range;
    }).toList();
    return returnData;
  }

  List<List<double>> _splitListFun(List<double> list) {
    List<List<double>> result = [];
    for (int i = 0; i < list.length; i += normalNum) {
      int end = (i + normalNum < list.length) ? i + normalNum : list.length;
      result.add(list.sublist(i, end));
    }
    return result;
  }

  List<double> _getAverageData(normalY) {
    List<double> average = [];
    for (var i = 0; i < normalY.length; i++) {
      double sum = 0;
      int length = averageNum;
      if (i - length >= 0) {
        for (var j = i - length; j <= i; j++) {
          if (j >= 0 && j < normalY.length) {
            sum += normalY[j];
          }
        }
        average.add(sum / length);
      }
    }
    return average;
  }

  /// 将整数转换为四个字节的数组
  List<int> numberToBytes(int number) {
    List<int> bytes = [];
    for (int i = 0; i < 4; i++) {
      bytes.add(number & 0xFF); // 取最低8位
      number = number >> 8; // 右移8位
    }
    return bytes.reversed.toList();
  }

  void _closeAction() async {}

  // Custom Code: customCode1
  customCode1(List<String> strList) {
    print("object接收到数据");
    List<int> newArr = strList.map((str) => int.parse(str, radix: 16)).toList();

    String text = String.fromCharCodes(newArr);

    RegExp regExp = RegExp(r'<(.+?)>\{(.+?)\}(.+)');
    // 使用正则表达式进行匹配
    Match? match = regExp.firstMatch(text);

    if (match != null) {
      // 提取匹配的部分
      var value1 = match.group(1)!;
      var value2 = match.group(2)!;
      var value3 = match.group(3)!;

      rawData.add("${value2},${value1},${value3}");

      List data = value3
          .split(",")
          .map((e) => {
                'x': [double.parse(value1)],
                'y': [double.tryParse(e) ?? 0]
              })
          .toList();
      var item = null;
      for (var element in res) {
        if (element["name"] == value2) {
          item = element;
          print("找到了");
          break;
        }
      }

      if (item == null) {
        res.add({
          "name": value2,
          "data": data,
        });
        if (data.length >= 1) {
          selectData1 = data[0]['y'];
          selectData1X = data[0]['x'];
        }

        if (data.length >= 2) {
          selectData2 = data[1]['y'];
          selectData2X = data[1]['x'];
        }

        if (data.length >= 3) {
          selectData3 = data[2]['y'];
          selectData3X = data[2]['x'];
        }

        if (data.length >= 4) {
          selectData4 = data[3]['y'];
          selectData4X = data[3]['x'];
        }
      } else {
        for (int i = 0; i < min(item['data'].length, data.length); i++) {
          item['data'][i]['x'].addAll(data[i]['x']);
          item['data'][i]['y'].addAll(data[i]['y']);
        }

        var data1 = item['data'];
        if (data1.length >= 1) {
          selectData1 = data1[0]['y'];
          selectData1X = data1[0]['x'];
        }

        if (data1.length >= 2) {
          selectData2 = data1[1]['y'];
          selectData2X = data1[1]['x'];
        }

        if (data1.length >= 3) {
          selectData3 = data1[2]['y'];
          selectData3X = data1[2]['x'];
        }

        if (data1.length >= 4) {
          selectData4 = data1[3]['y'];
          selectData4X = data1[3]['x'];
        }
      }
    } else {
      print('没有匹配到任何内容');
    }

    int length = 100;
    print("object======${selectData1X.length}");
    if (selectData1X.length > length) {
      print("object======");
      selectData1.removeRange(0, selectData1.length - length);
      selectData1X.removeRange(0, selectData1X.length - length);
    }

    if (selectData2X.length > length) {
      selectData2X.removeRange(0, selectData2X.length - length);
      selectData2.removeRange(0, selectData2.length - length);
    }

    if (selectData3X.length > length) {
      selectData3X.removeRange(0, selectData3X.length - length);
      selectData3.removeRange(0, selectData3.length - length);
    }

    if (selectData4X.length > length) {
      selectData4X.removeRange(0, selectData4X.length - length);
      selectData4.removeRange(0, selectData4.length - length);
    }

    if (res.length >= length) {
      res.removeRange(0, res.length - length);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前主题的亮度
    Brightness brightness = Theme.of(context).brightness;
    bool isDark = brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        floatingActionButton: null,
        drawer: null,
        endDrawer: null,
        appBar: AppBar(
          backgroundColor: Color(4278218751),
          title: Text(
            "数据分窗".tr,
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              decoration: TextDecoration.none,
              fontWeight: FontWeight.w500,
              color: Color(4294967295),
              height: null,
              fontStyle: FontStyle.normal,
            ),
          ),
          actions: [
            Container(
              margin: EdgeInsets.zero,
              width: 40,
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  devices = await UsbSerial.listDevices();
                  int index = -1;
                  for (var i = 0; i < devices.length; i++) {
                    try {
                      if (i == 3) {
                        index = i;
                        break;
                      }
                    } catch (e) {
                      print(e);
                    }
                  }
                  if (index == -1) {
// 说明没有找到设备
                    return;
                  }
                  port?.close();
                  port = await devices[index].create();
                  if (port == null) {
                    return;
                  }
                  bool? openResult = await port?.open();
                  if (openResult != null && !openResult) {
                    return;
                  }
                  await port?.setDTR(true);
                  await port?.setRTS(true);
                  await port?.setPortParameters(115200, 8, 1, 0);
                  if (canSend) {
                    sendDataSerial("5aa5");
                  }
                  _serialData?.cancel();
                  _serialData =
                      port?.inputStream?.listen((Uint8List event) async {
                    if (event.isEmpty) {
                      return;
                    }
                    List<String> strList = [];
                    event.forEach((element) {
                      strList.add(element.toRadixString(16).padLeft(2, '0'));
                    });
                    customCode1(strList);
                  }); // read 截止
                },
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(Size.zero),
                  backgroundColor: WidgetStateProperty.all(Color(16579836)),
                  padding: WidgetStateProperty.all(
                      EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0)),
                  elevation: WidgetStateProperty.all(0),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(),
                  ),
                  side: WidgetStateProperty.all(BorderSide.none),
                ),
                child: Container(
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero,
                  child: Icon(IconData(58189, fontFamily: 'MaterialIcons'),
                      size: 24, color: Color(4294967295)),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? DarkAppColor.primaryBackground
            : AppColor.primaryBackground,
        body: SingleChildScrollView(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              hideKeyboard(context);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              verticalDirection: VerticalDirection.down,
              children: [
                Container(
                  clipBehavior: Clip.none,
                  width: double.infinity,
                  height: 750,
                  alignment: Alignment(-1, -1),
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Color(16777215),
                    gradient: null,
                    border: Border.all(
                      color: Colors.black,
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    verticalDirection: VerticalDirection.down,
                    children: [
                      Container(
                        clipBehavior: Clip.none,
                        width: double.infinity,
                        height: 40,
                        alignment: Alignment(-1, -1),
                        padding: EdgeInsets.only(
                          top: 0,
                          right: 10,
                          bottom: 0,
                          left: 10,
                        ),
                        margin: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Color(16777215),
                          gradient: null,
                          borderRadius: BorderRadius.circular(120),
                          border: Border.all(
                            color: Color(4288651167),
                            width: 0,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          verticalDirection: VerticalDirection.down,
                          children: [
                            SizedBox(
                              width: 320,
                              height: 40,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                reverse: false,
                                shrinkWrap: false,
                                padding: EdgeInsets.zero,
                                itemCount: res.length,
                                itemBuilder: (context, index) => Container(
                                  margin: EdgeInsets.zero,
                                  width: 80,
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () async {},
                                    style: ButtonStyle(
                                      minimumSize:
                                          WidgetStateProperty.all(Size.zero),
                                      backgroundColor: WidgetStateProperty.all(
                                          Color(4294769916)),
                                      padding: WidgetStateProperty.all(
                                          EdgeInsets.only(
                                              left: 0,
                                              right: 0,
                                              top: 0,
                                              bottom: 0)),
                                      elevation: WidgetStateProperty.all(0),
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(),
                                      ),
                                      side: WidgetStateProperty.all(BorderSide(
                                        color: Color(4288585374),
                                        width: 1,
                                        style: BorderStyle.solid,
                                      )),
                                    ),
                                    child: Text(
                                      "${res[index]['name']}",
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        decoration: TextDecoration.none,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? DarkAppColor.primaryText
                                            : AppColor.primaryText,
                                        height: null,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ), //Row
                      ), //Container
                      Container(
                        clipBehavior: Clip.none,
                        width: 340,
                        height: 160,
                        alignment: Alignment(-1, -1),
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.only(
                          top: 10,
                          right: 0,
                          bottom: 10,
                          left: 0,
                        ),
                        decoration: BoxDecoration(
                          color: Color(4294967295),
                          gradient: null,
                          border: Border.all(
                            color: Colors.black,
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                        child: RawScrollbar(
                          thickness: 4,
                          thumbVisibility: false,
                          trackVisibility: false,
                          radius: Radius.circular(12),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              reverse: false,
                              shrinkWrap: false,
                              padding: EdgeInsets.zero,
                              itemCount: 1,
                              itemBuilder: (context, index) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                verticalDirection: VerticalDirection.down,
                                children: [
                                  Container(
                                      width: selectData1.length > 100
                                          ? 300 +
                                              (selectData1.length - 100) /
                                                  100 *
                                                  300
                                          : 300,
                                      height: 100,
                                      child: Builder(builder: (context) {
                                        double xFlSpot = 0;
                                        return LineChart(
                                          duration:
                                              const Duration(milliseconds: 10),
                                          curve: Curves.linear,
                                          LineChartData(
                                            backgroundColor: Colors.transparent,
                                            titlesData: FlTitlesData(
                                              show: true,
                                              rightTitles: AxisTitles(),
                                              topTitles: AxisTitles(),
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 60,
                                                ),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 30,
                                                ),
                                              ),
                                            ),
                                            gridData: FlGridData(
                                              show: false,
                                            ),
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: List.generate(
                                                    min(selectData1X.length,
                                                        selectData1.length),
                                                    (i) => FlSpot(
                                                        selectData1X[i],
                                                        selectData1[i])),
                                                color: Color(4278583807),
                                                barWidth: 1,
                                                isCurved: true,
                                                dotData: FlDotData(
                                                  show: false,
                                                ),
                                                belowBarData: BarAreaData(
                                                  show: false,
                                                  color: Color(4294959234),
                                                  gradient: null,
                                                ),
                                              ),
                                            ],
                                            borderData: FlBorderData(
                                              show: false,
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 1),
                                            ),
                                            lineTouchData: LineTouchData(
                                              enabled: false,
                                            ),
                                          ),
                                        );
                                      })),
                                ],
                              ), //Column
                            ),
                          ),
                        ),
                      ), //Container
                      Container(
                        clipBehavior: Clip.none,
                        width: 340,
                        height: 160,
                        alignment: Alignment(-1, -1),
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.only(
                          top: 10,
                          right: 0,
                          bottom: 10,
                          left: 0,
                        ),
                        decoration: BoxDecoration(
                          color: Color(4294967295),
                          gradient: null,
                          border: Border.all(
                            color: Colors.black,
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                        child: RawScrollbar(
                          thickness: 4,
                          thumbVisibility: false,
                          trackVisibility: false,
                          radius: Radius.circular(12),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              reverse: false,
                              shrinkWrap: false,
                              padding: EdgeInsets.zero,
                              itemCount: 1,
                              itemBuilder: (context, index) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                verticalDirection: VerticalDirection.down,
                                children: [
                                  Container(
                                      width: selectData2.length > 100
                                          ? 300 +
                                              (selectData2.length - 100) /
                                                  100 *
                                                  300
                                          : 300,
                                      height: 100,
                                      child: Builder(builder: (context) {
                                        double xFlSpot = 0;
                                        return LineChart(
                                          duration:
                                              const Duration(milliseconds: 10),
                                          curve: Curves.linear,
                                          LineChartData(
                                            backgroundColor: Colors.transparent,
                                            titlesData: FlTitlesData(
                                              show: true,
                                              rightTitles: AxisTitles(),
                                              topTitles: AxisTitles(),
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 60,
                                                ),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 30,
                                                ),
                                              ),
                                            ),
                                            gridData: FlGridData(
                                              show: false,
                                            ),
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: List.generate(
                                                    min(selectData2X.length,
                                                        selectData2.length),
                                                    (i) => FlSpot(
                                                        selectData2X[i],
                                                        selectData2[i])),
                                                color: Color(4278583807),
                                                barWidth: 1,
                                                isCurved: true,
                                                dotData: FlDotData(
                                                  show: false,
                                                ),
                                                belowBarData: BarAreaData(
                                                  show: false,
                                                  color: Color(4294959234),
                                                  gradient: null,
                                                ),
                                              ),
                                            ],
                                            borderData: FlBorderData(
                                              show: false,
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 1),
                                            ),
                                            lineTouchData: LineTouchData(
                                              enabled: false,
                                            ),
                                          ),
                                        );
                                      })),
                                ],
                              ), //Column
                            ),
                          ),
                        ),
                      ), //Container
                      Container(
                        clipBehavior: Clip.none,
                        width: 340,
                        height: 160,
                        alignment: Alignment(-1, -1),
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.only(
                          top: 10,
                          right: 0,
                          bottom: 10,
                          left: 0,
                        ),
                        decoration: BoxDecoration(
                          color: Color(4294967295),
                          gradient: null,
                          border: Border.all(
                            color: Colors.black,
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                        child: RawScrollbar(
                          thickness: 4,
                          thumbVisibility: false,
                          trackVisibility: false,
                          radius: Radius.circular(12),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              reverse: false,
                              shrinkWrap: false,
                              padding: EdgeInsets.zero,
                              itemCount: 1,
                              itemBuilder: (context, index) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.max,
                                verticalDirection: VerticalDirection.down,
                                children: [
                                  Container(
                                      width: selectData3.length > 100
                                          ? 300 +
                                              (selectData3.length - 100) /
                                                  100 *
                                                  300
                                          : 300,
                                      height: 100,
                                      child: Builder(builder: (context) {
                                        double xFlSpot = 0;
                                        return LineChart(
                                          duration:
                                              const Duration(milliseconds: 10),
                                          curve: Curves.linear,
                                          LineChartData(
                                            backgroundColor: Colors.transparent,
                                            titlesData: FlTitlesData(
                                              show: true,
                                              rightTitles: AxisTitles(),
                                              topTitles: AxisTitles(),
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 60,
                                                ),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 30,
                                                ),
                                              ),
                                            ),
                                            gridData: FlGridData(
                                              show: false,
                                            ),
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: List.generate(
                                                    min(selectData3X.length,
                                                        selectData3.length),
                                                    (i) => FlSpot(
                                                        selectData3X[i],
                                                        selectData3[i])),
                                                color: Color(4278583807),
                                                barWidth: 1,
                                                isCurved: true,
                                                dotData: FlDotData(
                                                  show: false,
                                                ),
                                                belowBarData: BarAreaData(
                                                  show: false,
                                                  color: Color(4294959234),
                                                  gradient: null,
                                                ),
                                              ),
                                            ],
                                            borderData: FlBorderData(
                                              show: false,
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 1),
                                            ),
                                            lineTouchData: LineTouchData(
                                              enabled: false,
                                            ),
                                          ),
                                        );
                                      })),
                                ],
                              ), //Column
                            ),
                          ),
                        ),
                      ), //Container
                      Container(
                        clipBehavior: Clip.none,
                        width: 80,
                        height: 80,
                        alignment: Alignment(-1, -1),
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Color(7883338),
                          gradient: null,
                          border: Border.all(
                            color: Colors.black,
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                        child: Container(),
                      ), //Container
                      Container(
                        margin: EdgeInsets.zero,
                        width: 40,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () async {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Center(
                                  child: help(),
                                );
                              },
                            );
                          },
                          style: ButtonStyle(
                            minimumSize: WidgetStateProperty.all(Size.zero),
                            backgroundColor:
                                WidgetStateProperty.all(Color(4278218751)),
                            padding: WidgetStateProperty.all(EdgeInsets.only(
                                left: 0, right: 0, top: 0, bottom: 0)),
                            elevation: WidgetStateProperty.all(4),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(1200),
                              ),
                            ),
                            side: WidgetStateProperty.all(BorderSide.none),
                          ),
                          child: Container(
                            padding: EdgeInsets.zero,
                            margin: EdgeInsets.zero,
                            child: Icon(
                                IconData(984405, fontFamily: 'MaterialIcons'),
                                size: 24,
                                color: Color(4294967295)),
                          ),
                        ),
                      ),
                    ],
                  ), //Column
                ), //Container
              ],
            ), //Column
          ),
        ),
      ),
    );
  }
}
