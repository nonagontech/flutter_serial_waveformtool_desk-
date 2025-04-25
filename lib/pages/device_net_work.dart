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
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'data_visualization.dart';
import 'package:intl/intl.dart';
import 'package:usb_serial/usb_serial.dart';
import '../common/utils/storage.dart';
import '../common/value/server.dart';
import 'package:getwidget/components/dropdown/gf_dropdown.dart';
import 'package:flutter_usb_event/flutter_usb_event.dart';

/// @file  device_net_work
/// @author https://aiflutter.com/
/// @description 整个页面的布局可以是垂直分区的，上半部分是数据接收区，下半部分是数据发送区。
/// @createDate 2025-04-25 15:24:12
class DeviceNetWork extends StatefulWidget {
  const DeviceNetWork({super.key});

  @override
  State<DeviceNetWork> createState() => _DeviceNetWorkState();
}

class _DeviceNetWorkState extends State<DeviceNetWork> {
  String data = "";
  List res = [];
  String _dropDownValue = ""; // 选择wifi名称
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
  var dataController = TextEditingController();

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
          customCode1();
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
          customCode1();
        },
      );
    }
    _initAction();
    dataController.text = data;
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
    customCode1();
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

  // Custom Code: 串口列表初始化
  customCode1() {
    if (Platform.isAndroid) {
      return;
    }
    availablePorts = SerialPort.availablePorts;

    print("availablePorts==== ${availablePorts}");

    if (availablePorts.isEmpty) {
      return;
    }

    _dropDownValue = availablePorts[0];
    setState(() {});
  }

// Custom Code: 断开连接
  customCode2() {
    serialPort?.close();
    serialPort = null;
    setState(() {});
  }

// Custom Code: 桌面端连接串口
  customCode3() {
    try {
      serialPort?.close();
      serialPort = SerialPort(_dropDownValue);
      if (serialPort == null) {
        print("打开串口失败");
        EasyLoading.showError("打开串口失败");
        return;
      }
      SerialPortConfig config = serialPort?.config ?? SerialPortConfig();
      config.baudRate = 115200;
      serialPort?.openReadWrite();
      serialPort?.config = config;
      print("打开串口成功");
    } catch (e) {
      print("打开串口失败");
      serialPort?.close();
      serialPort = null;
      EasyLoading.showError(
          "检测到串口故障，错误：UnsupportedOperationError ${e.toString().substring(e.toString().length - 10)}");
    }

    setState(() {});
  }

// Custom Code: 接收串口数据
  customCode4(param) {
    res.add({
      "type": "接收",
      "data": param.join(),
      "time": DateFormat("HH:mm:ss").format(DateTime.now()),
    });
    setState(() {});
  }

// Custom Code: 发送数据
  customCode5() {
    if (data.isEmpty) {
      EasyLoading.showError("请输入发送数据内容");
      return;
    }
    sendDataSerial(data);

    res.add({
      "data": data,
      "time": DateFormat("HH:mm:ss").format(DateTime.now()),
      "type": "发送",
    });

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
            "串口调试助手".tr,
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
                  Get.to(const DataVisualization(),
                      transition: Transition.native,
                      duration: const Duration(milliseconds: 0));
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
                  width: 30,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/statistic.png"),
                      fit: BoxFit.scaleDown,
                      alignment: Alignment(0, 0),
                    ),
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.black,
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
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
                  height: 700,
                  alignment: Alignment(-1, -1),
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: Color(13158600),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        verticalDirection: VerticalDirection.down,
                        children: [
                          Container(
                            width: 500,
                            height: 40,
                            child: DropdownButtonHideUnderline(
                              child: GFDropdown(
                                hint: Text('请选择...',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                icon: Icon(
                                    IconData(0xe098,
                                        fontFamily: 'MaterialIcons'),
                                    size: 24,
                                    color: Colors.grey),
                                elevation: 8,
                                focusColor: Colors.transparent,
                                isExpanded: true,
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    BorderSide(color: Colors.black12, width: 1),
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                value: _dropDownValue,
                                isDense: false,
                                itemHeight: 40,
                                onChanged: (newValue) {
                                  if (newValue is String) {
                                    setState(() {
                                      _dropDownValue = newValue;
                                    });
                                  }
                                },
                                items: availablePorts
                                    .map((value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(
                                            value,
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
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                          Builder(builder: (context) {
                            if (serialPort != null) {
                              return Visibility(
                                child: Container(
                                  margin: EdgeInsets.zero,
                                  width: 50,
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      customCode2();
                                    },
                                    style: ButtonStyle(
                                      minimumSize:
                                          WidgetStateProperty.all(Size.zero),
                                      backgroundColor: WidgetStateProperty.all(
                                          Color(4294198070)),
                                      padding: WidgetStateProperty.all(
                                          EdgeInsets.only(
                                              left: 0,
                                              right: 0,
                                              top: 0,
                                              bottom: 0)),
                                      elevation: WidgetStateProperty.all(4),
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(),
                                      ),
                                      side: WidgetStateProperty.all(
                                          BorderSide.none),
                                    ),
                                    child: Text(
                                      "断开".tr,
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        decoration: TextDecoration.none,
                                        fontWeight: FontWeight.w500,
                                        color: Color(4294967295),
                                        height: null,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return Visibility(
                                child: Container(
                                  margin: EdgeInsets.zero,
                                  width: 50,
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      customCode3();
                                      if (Platform.isAndroid) {
                                        _serialData?.cancel();
                                        _serialData = port?.inputStream
                                            ?.listen((Uint8List event) async {
                                          if (event.isEmpty) {
                                            return;
                                          }
                                          List<String> strList = [];
                                          event.forEach((element) {
                                            strList.add(element
                                                .toRadixString(16)
                                                .padLeft(2, '0'));
                                          });
                                          customCode4(strList);
                                        }); // read 截止
                                      } else {
                                        SerialPortReader reader =
                                            SerialPortReader(serialPort!,
                                                timeout: 40);
                                        _serialDeskData?.cancel();
                                        _serialDeskData =
                                            reader.stream.listen((event) async {
                                          List<String> strList = [];
                                          event.forEach((element) {
                                            strList.add(element
                                                .toRadixString(16)
                                                .padLeft(2, '0'));
                                          });
                                          customCode4(strList);
                                        });
                                      }
                                    },
                                    style: ButtonStyle(
                                      minimumSize:
                                          WidgetStateProperty.all(Size.zero),
                                      backgroundColor: WidgetStateProperty.all(
                                          Color(4278218751)),
                                      padding: WidgetStateProperty.all(
                                          EdgeInsets.only(
                                              left: 0,
                                              right: 0,
                                              top: 0,
                                              bottom: 0)),
                                      elevation: WidgetStateProperty.all(4),
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(),
                                      ),
                                      side: WidgetStateProperty.all(
                                          BorderSide.none),
                                    ),
                                    child: Text(
                                      "连接".tr,
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        decoration: TextDecoration.none,
                                        fontWeight: FontWeight.w500,
                                        color: Color(4294967295),
                                        height: null,
                                        fontStyle: FontStyle.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          }),
                        ],
                      ), //Row
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        verticalDirection: VerticalDirection.down,
                        children: [
                          Container(
                            clipBehavior: Clip.none,
                            width: double.infinity,
                            height: 40,
                            alignment: Alignment(-1, 0),
                            padding: EdgeInsets.zero,
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: Color(13158600),
                              gradient: null,
                              border: Border.all(
                                color: Colors.black,
                                width: 0,
                                style: BorderStyle.none,
                              ),
                            ),
                            child: Text(
                              "数据收发内容".tr,
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
                          ), //Container
                          Container(
                            clipBehavior: Clip.none,
                            width: double.infinity,
                            height: 300,
                            alignment: Alignment(-1, -1),
                            padding: EdgeInsets.zero,
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: Color(13158600),
                              gradient: null,
                              border: Border.all(
                                color: Color(4278190080),
                                width: 1,
                                style: BorderStyle.solid,
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
                                  scrollDirection: Axis.vertical,
                                  reverse: false,
                                  shrinkWrap: false,
                                  padding: EdgeInsets.zero,
                                  itemCount: res.length,
                                  itemBuilder: (context, index) => Text(
                                    "${res[index]['time']}${res[index]['type']}: ${res[index]['data']}",
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
                          ), //Container
                          Container(
                            clipBehavior: Clip.none,
                            width: double.infinity,
                            height: 40,
                            alignment: Alignment(-1, 0),
                            padding: EdgeInsets.zero,
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: Color(13158600),
                              gradient: null,
                              border: Border.all(
                                color: Colors.black,
                                width: 0,
                                style: BorderStyle.none,
                              ),
                            ),
                            child: Text(
                              "发送数据内容".tr,
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
                          ), //Container
                          Container(
                            clipBehavior: Clip.none,
                            width: double.infinity,
                            height: 50,
                            alignment: Alignment(-1, -1),
                            padding: EdgeInsets.zero,
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: Color(13158600),
                              gradient: null,
                              border: Border(
                                top: BorderSide.none,
                                bottom: BorderSide(
                                  color: Color(4288256409),
                                  width: 1,
                                  style: BorderStyle.solid,
                                ),
                                left: BorderSide.none,
                                right: BorderSide.none,
                              ),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: TextField(
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
                                decoration: InputDecoration(
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    decoration: TextDecoration.none,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? DarkAppColor.primaryText
                                        : AppColor.primaryText,
                                    height: null,
                                    fontStyle: FontStyle.normal,
                                  ),
                                  labelStyle: TextStyle(
                                    fontSize: 14,
                                    decoration: TextDecoration.none,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? DarkAppColor.primaryText
                                        : AppColor.primaryText,
                                    height: null,
                                    fontStyle: FontStyle.normal,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.black,
                                          width: 1,
                                          style: BorderStyle.none),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(4.0))),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.black,
                                          width: 1,
                                          style: BorderStyle.none),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(4.0))),
                                ),
                                keyboardType: TextInputType.text,
                                maxLength: null,
                                obscureText: false,
                                maxLengthEnforcement: MaxLengthEnforcement.none,
                                cursorColor: Color(4278218751),
                                readOnly: false,
                                controller: dataController,
                                onChanged: (p0) {
                                  this.data = p0;
                                  setState(() {});
                                },
                              ),
                            ),
                          ), //Container
                        ],
                      ), //Column
                      Container(
                        clipBehavior: Clip.none,
                        width: double.infinity,
                        height: 30,
                        alignment: Alignment(-1, -1),
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Color(2960895),
                          gradient: null,
                          border: Border.all(
                            color: Colors.black,
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                        child: Text(
                          "注意: 数据采用16进制格式发送，例如5aa5".tr,
                          textAlign: TextAlign.left,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w500,
                            color: Color(4294901760),
                            height: null,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ), //Container
                      Container(
                        clipBehavior: Clip.none,
                        width: 80,
                        height: 20,
                        alignment: Alignment(-1, -1),
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Color(2500096),
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
                        width: 200,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () async {
                            customCode5();
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
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            side: WidgetStateProperty.all(BorderSide.none),
                          ),
                          child: Text(
                            "发送数据".tr,
                            textAlign: TextAlign.left,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.w500,
                              color: Color(4294967295),
                              height: null,
                              fontStyle: FontStyle.normal,
                            ),
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
