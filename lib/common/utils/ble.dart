// import 'dart:async';
// import 'dart:io';

// import 'package:app_settings/app_settings.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:geolocator/geolocator.dart' as GeolocatorPackage;
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';

// /// 重新封装一个蓝牙组件
// class Ble {
//   factory Ble() => _getInstance();
//   static Ble get instance => _getInstance();
//   static Ble? _instance;
//   static Ble _getInstance() {
//     _instance ??= Ble._internal();
//     return _instance!;
//   }

//   Ble._internal() {
// //开启日志
//     FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
//   }

// //---------------变量区域开始-------------------

//   StreamSubscription? _statusSubscription; //蓝牙状态监听
// //设备连接状态
//   BluetoothConnectionState bluetoothConnectStatus =
//       BluetoothConnectionState.disconnected;
// //   //扫描监听
//   StreamSubscription? _sacnSubscription;
// //   //是否正在扫描中
//   StreamSubscription? _sacningSubscription;
// //当前连接的设备
//   BluetoothDevice? connectDevice;
// //   //蓝牙是否连接
//   StreamSubscription? _connection;
// //   //蓝牙数据监听
//   StreamSubscription? _getBleDate;

// // 所有的notify服务
//   List<BluetoothCharacteristic> _notifyServices = [];

//   List<StreamSubscription> _notifysubscriptions = []; //所有的监听

//   //蓝牙接收数据控制流
//   final StreamController<List<int>> _getBleDateController =
//       StreamController.broadcast();
//   StreamController get getBleDateController => _getBleDateController;
//   //设备连接状态控制流
//   final StreamController<BluetoothConnectionState> _connectController =
//       StreamController.broadcast();
//   StreamController get connectController => _connectController;
//   //监听定位服务的流
//   StreamSubscription<GeolocatorPackage.ServiceStatus>? locationSub;

//   //读写的服务uuid和特征uuid
//   String serviceUUID = "ffff";
//   String readCharacteristicUUID = 'ff02';
//   String writeCharacteristicUUID = 'ff01';

//   //写特征
//   List<BluetoothCharacteristic> _writeCharacteristics = [];
//   List<BluetoothCharacteristic> _characteristics = [];

//   //---------------变量区域结束-------------------

//   //---------------函数区域开始-------------------

//   //获取蓝牙的状态,如果都正常则开始扫描,不正常则去跳出弹窗提示
//   void status({
//     Function(BluetoothAdapterState)? callback, //蓝牙状态信息返回
//     bool showPermission = true, //是否显示权限弹窗
//     List<Guid> withServices = const [], //扫描设备时按广告服务过滤
//     List<String> withRemoteIds =
//         const [], //过滤已知的remoteId（iOS：128位guid，android：48位mac地址）
//     List<String> withNames = const [], //按广告名称过滤（完全匹配）
//     List<String> withKeywords = const [], //按广告名称过滤（匹配任何子字符串）
//     List<MsdFilter> withMsd = const [], //按制造商特定数据过滤
//     List<ServiceDataFilter> withServiceData = const [], //按服务数据过滤
//     Duration? timeout = const Duration(seconds: 4), //在指定的持续时间后调用 stopScan
//     Duration? removeIfGone, //如果为 true，则在设备停止广告 X 持续时间后删除设备
//     bool continuousUpdates =
//         false, //如果true，我们通过处理重复的广告来不断更新“lastSeen”和“rssi”。这需要更多的消耗。您通常不应使用此选项。
//     int continuousDivisor =
//         1, //对提高性能很有用。如果除数为 3，则忽略三分之二的广告，处理三分之一的广告。这减少了平台通道引起的主线程使用。扫描计数是按设备进行的，因此您始终会从每台设备获得第一个广告。如果除数为1，则返回所有广告。这个论点只对模式重要continuousUpdates。
//     bool oneByOne =
//         false, //如果true，我们将逐一播放每个广告，可能包括重复的广告。如果false，我们会删除重复的广告，并返回设备列表。
//     AndroidScanMode androidScanMode =
//         AndroidScanMode.lowLatency, //选择扫描时使用的 Android 扫描模式
//     bool androidUsesFineLocation = true, //在运行时请求ACCESS_FINE_LOCATION权限
//   }) async {
//     if (await FlutterBluePlus.isSupported == false) {
//       //手机不支持蓝牙
//       EasyLoading.showError("此设备不支持BLE。".tr);
//       return;
//     }
//     _statusSubscription?.cancel();
//     _statusSubscription = FlutterBluePlus.adapterState.listen((status) async {
//       print("蓝牙适配器的状态:${status}");
//       switch (status) {
//         case BluetoothAdapterState.on: //准备好了,可以去扫描了

//           //如果是安卓还要看定位是否打开
//           if (Platform.isAndroid) {
//             var serviceEnabled =
//                 await GeolocatorPackage.Geolocator.isLocationServiceEnabled();
//             if (!serviceEnabled && showPermission) {
//               //在这里做监听
//               locationSub?.cancel();
//               locationSub =
//                   GeolocatorPackage.Geolocator.getServiceStatusStream()
//                       .listen((status) async {
//                 if (status == GeolocatorPackage.ServiceStatus.enabled) {
//                   locationSub?.cancel();
//                   scan(
//                     withServices: withServices,
//                     withRemoteIds: withRemoteIds,
//                     withNames: withNames,
//                     withKeywords: withKeywords,
//                     withMsd: withMsd,
//                     withServiceData: withServiceData,
//                     timeout: timeout,
//                     removeIfGone: removeIfGone,
//                     continuousUpdates: continuousUpdates,
//                     continuousDivisor: continuousDivisor,
//                     oneByOne: oneByOne,
//                     androidScanMode: androidScanMode,
//                     androidUsesFineLocation: androidUsesFineLocation,
//                   );
//                 }
//               });
//               //定位服务未打开,需要提醒用户打开定位才行
//               await tipModal(
//                 content: "需要打开定位才能搜索硬件".tr,
//                 confirmFun: () async {
//                   Get.back();
//                   await AppSettings.openAppSettings(
//                       type: AppSettingsType.location);
//                 },
//               );
//             } else {
//               locationSub?.cancel();
//               scan(
//                 withServices: withServices,
//                 withRemoteIds: withRemoteIds,
//                 withNames: withNames,
//                 withKeywords: withKeywords,
//                 withMsd: withMsd,
//                 withServiceData: withServiceData,
//                 timeout: timeout,
//                 removeIfGone: removeIfGone,
//                 continuousUpdates: continuousUpdates,
//                 continuousDivisor: continuousDivisor,
//                 oneByOne: oneByOne,
//                 androidScanMode: androidScanMode,
//                 androidUsesFineLocation: androidUsesFineLocation,
//               );
//             }
//           } else {
//             scan(
//               withServices: withServices,
//               withRemoteIds: withRemoteIds,
//               withNames: withNames,
//               withKeywords: withKeywords,
//               withMsd: withMsd,
//               withServiceData: withServiceData,
//               timeout: timeout,
//               removeIfGone: removeIfGone,
//               continuousUpdates: continuousUpdates,
//               continuousDivisor: continuousDivisor,
//               oneByOne: oneByOne,
//               androidScanMode: androidScanMode,
//               androidUsesFineLocation: androidUsesFineLocation,
//             );
//           }

//           break;
//         case BluetoothAdapterState.unknown: //状态尚未确定
//           break;
//         case BluetoothAdapterState.unavailable: //此设备不支持BLE。
//           EasyLoading.showError("此设备不支持BLE。".tr);
//           break;
//         case BluetoothAdapterState.unauthorized: //没权限,要去获取权限
//           if (showPermission) {
//             getBluetoothPermission();
//           }

//           break;
//         case BluetoothAdapterState.off: //蓝牙关闭,跳出弹框来打开蓝牙
//           if (showPermission) {
//             openBlu();
//           }

//           break;

//         default:
//       }
//       callback?.call(status);
//     });
//   }

//   //开始扫描蓝牙设备
//   void scan({
//     List<Guid> withServices = const [], //扫描设备时按广告服务过滤
//     List<String> withRemoteIds =
//         const [], //过滤已知的remoteId（iOS：128位guid，android：48位mac地址）
//     List<String> withNames = const [], //按广告名称过滤（完全匹配）
//     List<String> withKeywords = const [], //按广告名称过滤（匹配任何子字符串）
//     List<MsdFilter> withMsd = const [], //按制造商特定数据过滤
//     List<ServiceDataFilter> withServiceData = const [], //按服务数据过滤
//     Duration? timeout, //在指定的持续时间后调用 stopScan
//     Duration? removeIfGone, //如果为 true，则在设备停止广告 X 持续时间后删除设备
//     bool continuousUpdates =
//         false, //如果true，我们通过处理重复的广告来不断更新“lastSeen”和“rssi”。这需要更多的消耗。您通常不应使用此选项。
//     int continuousDivisor =
//         1, //对提高性能很有用。如果除数为 3，则忽略三分之二的广告，处理三分之一的广告。这减少了平台通道引起的主线程使用。扫描计数是按设备进行的，因此您始终会从每台设备获得第一个广告。如果除数为1，则返回所有广告。这个论点只对模式重要continuousUpdates。
//     bool oneByOne =
//         false, //如果true，我们将逐一播放每个广告，可能包括重复的广告。如果false，我们会删除重复的广告，并返回设备列表。
//     AndroidScanMode androidScanMode =
//         AndroidScanMode.lowLatency, //选择扫描时使用的 Android 扫描模式
//     bool androidUsesFineLocation = false, //在运行时请求ACCESS_FINE_LOCATION权限
//   }) async {
//     // 如果已经连接了则不做任何操作
//     if (bluetoothConnectStatus == BluetoothConnectionState.disconnected) {
//       //如果正在扫描则返回
//       if (isScanningNow) {
//         return;
//       }
//       try {
//         await FlutterBluePlus.startScan(
//           withServices: withServices,
//           withRemoteIds: withRemoteIds,
//           withNames: withNames,
//           withKeywords: withKeywords,
//           withMsd: withMsd,
//           withServiceData: withServiceData,
//           timeout: timeout,
//           removeIfGone: removeIfGone,
//           continuousUpdates: continuousUpdates,
//           continuousDivisor: continuousDivisor,
//           oneByOne: oneByOne,
//           androidScanMode: androidScanMode,
//           androidUsesFineLocation: androidUsesFineLocation,
//         );
//       } catch (e) {
//         print("扫描出现了错误: $e");
//         if ("$e".contains("permission")) {
//           getBluetoothPermission();
//         }
//       }
//     }
//   }

//   //停止扫描
//   stopScan() async {
//     await FlutterBluePlus.stopScan();
//   }

//   //监听扫描到的设备内容,实时扫描结果流
//   void onScanResults({
//     Function(List<ScanResult>)? callbackList,
//     Function(ScanResult)? callbackLast,
//   }) {
//     ScanResult? last;
//     _sacnSubscription?.cancel();
//     _sacnSubscription = FlutterBluePlus.onScanResults.listen(
//       (results) {
//         if (results.isNotEmpty) {
//           callbackList?.call(results);
//           //这里不知道是否有用,先做在这里
//           if (last != results[results.length - 1]) {
//             last = results[results.length - 1];
//             callbackLast?.call(last!);
//           }
//         }
//       },
//       onError: (e) => print(e),
//     );
//   }

//   ///监听广播内容
//   ///param callbackList 实时扫描广播数据处理（设备名称，广播数据）
//   ///param deviceName 设备名称
//   void onScanResultsByAdvertisement({
//     Function(String?, Map<int, List<int>>)? callback,
//     List<String>? deviceName,
//   }) {
//     _sacnSubscription?.cancel();
//     _sacnSubscription = FlutterBluePlus.onScanResults.listen(
//       (results) {
//         if (results.isEmpty) {
//           return;
//         }

//         if (deviceName == null || deviceName.isEmpty) {
//           for (var result in results) {
//             callback?.call(result.advertisementData.advName,
//                 result.advertisementData.manufacturerData);
//           }
//           return;
//         }

//         for (var result in results) {
//           if (!deviceName.contains(result.advertisementData.advName)) {
//             continue;
//           }
//           callback?.call(result.advertisementData.advName,
//               result.advertisementData.manufacturerData);
//         }
//       },
//       onError: (e) => print(e),
//     );
//   }

//   //实时扫描结果和以前的结果流
//   void scanResults({
//     Function(List<ScanResult>)? callbackList,
//   }) {
//     _sacnSubscription?.cancel();
//     _sacnSubscription = FlutterBluePlus.scanResults.listen(
//       (results) {
//         if (results.isNotEmpty) {
//           callbackList?.call(results);
//         }
//       },
//       onError: (e) => print(e),
//     );
//   }

//   //最后的扫描结果
//   List<ScanResult> get lastScanResults => FlutterBluePlus.lastScanResults;

//   //现在是否正在扫描
//   bool get isScanningNow => FlutterBluePlus.isScanningNow;
//   //是否正在扫描
//   isScaning(Function(bool)? callback) {
//     _sacningSubscription?.cancel();
//     _sacningSubscription = FlutterBluePlus.isScanning.listen((result) {
//       print("是否正在扫描:$result");
//       callback?.call(result);
//     }, onError: (Object e) {
//       print('是否正在扫描监听失败: $e');
//     });
//   }

//   //连接设备
//   ///蓝牙连接,为了防止第一次连接不上的问题,因此做了一次重新连接
//   connect(
//     BluetoothDevice device, {
//     String? serviceUUID,
//     String? readCharacteristicUUID,
//     String? writeCharacteristicUUID,
//     bool reConnect = false,
//     VoidCallback? notifyCallBcak,
//     Function(BluetoothConnectionState)? callbackConnectionState,
//     // Function(BluetoothConnectionState)? callback
//   }) async {
//     if (isConnect(device)) {
//       connectDevice = device;
//       bluetoothConnectStatus = BluetoothConnectionState.connected;
//       EasyLoading.dismiss();
//       return;
//     }
//     serviceUUID ??= this.serviceUUID;
//     readCharacteristicUUID ??= this.readCharacteristicUUID;
//     writeCharacteristicUUID ??= this.writeCharacteristicUUID;

//     stopScan();
//     _connection?.cancel();
//     _connection = device.connectionState.listen((result) async {
//       bluetoothConnectStatus = result;
//       if (result == BluetoothConnectionState.connected) {
//         if (connectDevice != null) {
//           //当前连接设备不为空 是否要等待 todo
//           await disconnect();
//         }
//         connectDevice = device;
//         getUUID(
//           serviceUUID,
//           readCharacteristicUUID,
//           writeCharacteristicUUID,
//           notifyCallBcak: notifyCallBcak,
//         );
//         // notifyCallBcak?.call();
//       } else if (result == BluetoothConnectionState.disconnected) {
//         //因为每次连接的时候会连接成功,断开连接交替出现,所以做一个延迟判断,而断开连接时就只会出现一次
//         Timer(const Duration(milliseconds: 800), () {
//           print("了解到状态:定时器");
//           if (bluetoothConnectStatus == BluetoothConnectionState.disconnected) {
//             connectDevice = null;
//           }
//         });
//       }
//       _connectController.sink.add(result);
//       callbackConnectionState?.call(result);
//     }, onError: (Object e) {
//       print('扫描失败，出现了错误: $e');
//     });
//     try {
//       print("设备开始连接");
//       await device.connect(
//           autoConnect: false, timeout: const Duration(seconds: 10));
//       print("设备连接结束");
//     } catch (onError) {
//       print("错误1111:$onError");
//       device.disconnect();
//       await Future.delayed(Duration(seconds: 2));
//       if (!reConnect) {
//         print("重新连接");
//         connect(
//           device,
//           serviceUUID: serviceUUID,
//           readCharacteristicUUID: readCharacteristicUUID,
//           writeCharacteristicUUID: writeCharacteristicUUID,
//           reConnect: true,
//           notifyCallBcak: notifyCallBcak,
//         );
//       }
//     } finally {
//       EasyLoading.dismiss();
//     }
//   }

//   //断开连接
//   disconnect() async {
//     if (connectDevice != null && isConnect(connectDevice!)) {
//       await connectDevice!.disconnect();
//       connectDevice = null;
//       clearSubscriptions();
//     }
//   }

//   dispose() {
//     stopScan();
//     disconnect();
//     _sacningSubscription?.cancel();
//     _sacnSubscription?.cancel();
//   }

//   //这个设备是否连接
//   bool isConnect(BluetoothDevice device) {
//     return device.isConnected;
//   }

//   //获取所有的的服务列表
//   void getUUID(
//     serviceUUID1,
//     readCharacteristicUUID1,
//     writeCharacteristicUUID1, {
//     VoidCallback? notifyCallBcak,
//   }) async {
//     serviceUUID = serviceUUID1;
//     readCharacteristicUUID = readCharacteristicUUID1;
//     writeCharacteristicUUID = writeCharacteristicUUID1;

//     List<BluetoothService> services = [];
//     try {
//       print("开始获取服务列表");
//       Timer timer = Timer(Duration(seconds: 5), () async {
//         if (services.isEmpty) {
//           print("再次获取服务列表");
//           services = await connectDevice?.discoverServices() ?? [];
//         }
//       });
//       services = await connectDevice?.discoverServices() ?? [];
//       timer.cancel();
//     } catch (e) {
//       print("获取服务信息列表错误:$e");
//     }
//     try {
//       // 读取MTU并请求更大的大小#
//       if (Platform.isAndroid) {
//         var mtu = await connectDevice?.mtu.first;

//         await connectDevice?.requestMtu(185);
//         var mtu1 = await connectDevice?.mtu.first;
//         if (mtu1 == null) {
//           EasyLoading.dismiss();
//           disconnect();
//         }
//       }
//     } catch (e) {
//       print('------------------------------mtumtu------------:${e}');
//     }

//     if (services.isEmpty) {
//       disconnect();
//       return;
//     }
//     _handlerServices(
//       services,
//       notifyCallBcak: notifyCallBcak,
//     );
//   }

//   //从所有的服务列表中找到读\写的UUID
//   void _handlerServices(
//     List<BluetoothService> services, {
//     VoidCallback? notifyCallBcak,
//   }) async {
//     clearSubscriptions();
//     for (var i = 0; i < services.length; i++) {
//       BluetoothService sItem = services[i];
//       String sUuid = sItem.uuid.toString().toLowerCase();
//       if (sUuid == '1800' || sUuid == '1801') {
//         continue;
//       }
//       _readCharacteristics(
//         sItem,
//       );
//     }
//     notifyCallBcak?.call();
//   }

//   // 清除所有订阅
//   void clearSubscriptions() {
//     for (var subscription in _notifysubscriptions) {
//       subscription.cancel();
//     }
//     _writeCharacteristics.clear();
//     _notifyServices.clear();
//     _notifysubscriptions.clear(); // 清空列表
//   }

//   //4.读取特征值(读出设置模式与写数据的特征值)
//   Future<void> _readCharacteristics(BluetoothService service) async {
//     _characteristics = service.characteristics;
//     for (BluetoothCharacteristic cItem in _characteristics) {
//       String cUuid = cItem.uuid.toString();

//       //------------_新的测试内容-----------
//       CharacteristicProperties characteristic = cItem.properties;

//       if (characteristic.notify) {
//         // await cItem.setNotifyValue(true); //为指定特征的值设置通知
//         print(
//             "cUuid:${cUuid}-==:${cItem.serviceUuid.toString()}}  ${_notifyServices.length}");

//         if (!containsCharacteristic(_notifyServices, cItem)) {
//           _notifyServices.add(cItem);
//           await cItem.setNotifyValue(true); //为指定特征的值设置通知
//           StreamSubscription subscription =
//               cItem.lastValueStream.listen((value) {
//             print("接收数据: $value ${cItem.uuid.toString()}");
//             // EasyLoading.showInfo("接收数据 $value");
//             _getBleDateController.sink.add(value);
//           });
//           _notifysubscriptions.add(subscription); // 添加订阅到列表
//         }
//       }
//       if (characteristic.write || characteristic.writeWithoutResponse) {
//         //判断_writeCharacteristic中是否存在cItem,没有则添加
//         if (!containsCharacteristic(_writeCharacteristics, cItem)) {
//           _writeCharacteristics.add(cItem);
//         }
//       }

//       //------------_新的测试内容结束-----------

//       // if (cUuid.toLowerCase().contains(readCharacteristicUUID.toLowerCase())) {
//       //   bool openSuccess = await cItem.setNotifyValue(true); //为指定特征的值设置通知
//       //   // print("打开了----${openSuccess}----${readCharacteristicUUID}");
//       //   // if (openSuccess) {
//       //   successRead = true;
//       // _getBleDate?.cancel();
//       // _getBleDate = cItem.lastValueStream.listen((value) {
//       //   print("接收数据:$value ${cItem.uuid.toString()}");
//       //   EasyLoading.showInfo("接收数据 $value");
//       //   _getBleDateController.sink.add(value);
//       // });
//       //   // }
//       // }

//       // if (cUuid.toLowerCase().contains(writeCharacteristicUUID.toLowerCase())) {
//       //   _writeCharacteristic = cItem;
//       //   successWrite = true;
//       // }
//     }
//     // print("${successRead}-----$successWrite");
//     // if (successRead && successWrite) {
//     // if (true) {
//     //   print("读写都拿到后,开始进行回调内容");
//     //   //读写都拿到后,开始进行回调内容
//     //   if (notifyCallBcak != null) {
//     //     notifyCallBcak();
//     //   }
//     // }
//   }

//   bool containsCharacteristic(List<BluetoothCharacteristic> characteristics,
//       BluetoothCharacteristic cItem) {
//     return characteristics.any((characteristic) =>
//         characteristic.uuid.toString() == cItem.uuid.toString() &&
//         characteristic.serviceUuid.toString() == cItem.serviceUuid.toString());
//   }

//   //无返回写数据
//   Future<void> writeWithOut(List<int> data,
//       {bool isRe = false,
//       String? serverUuid,
//       String? writeUuid,
//       bool allowLongWrite = false}) async {
//     // print(" 写数据:${
//     // })}  ");
//     List<String> writeData =
//         data.map((e) => e.toRadixString(16).padLeft(2, '0')).toList();
//     try {
//       if (serverUuid == null && writeUuid == null) {
//         for (var i = 0; i < _writeCharacteristics.length; i++) {
//           print(
//               "serverUUid:${_writeCharacteristics[i].serviceUuid.toString()}写uuid:${_writeCharacteristics[i].uuid.toString()}  写数据:${writeData}");
//           await _writeCharacteristics[i].write(data,
//               allowLongWrite: allowLongWrite,
//               withoutResponse:
//                   _writeCharacteristics[i].properties.writeWithoutResponse);
//         }
//       } else {
//         print("characteristic ${_writeCharacteristics.length}");
//         for (var characteristic in _writeCharacteristics) {
//           print(
//               "characteristic ${characteristic.serviceUuid.toString()}  ${serverUuid}  ${characteristic.uuid.toString()} ${writeUuid}");
//           if (serverUuid != null && writeUuid != null) {
//             if (characteristic.serviceUuid.toString() == serverUuid &&
//                 characteristic.uuid.toString() == writeUuid) {
//               print(
//                   "serverUUidlll:${characteristic.serviceUuid.toString()}写uuid:${characteristic.uuid.toString()}  写数据:${writeData}");

//               await characteristic.write(data,
//                   allowLongWrite: allowLongWrite,
//                   withoutResponse:
//                       characteristic.properties.writeWithoutResponse);
//             }
//           } else {
//             print("else ====${characteristic.uuid}");

//             if (characteristic.serviceUuid.toString() == serverUuid ||
//                 characteristic.uuid.toString() == writeUuid) {
//               print(
//                   "serverUUid:${characteristic.serviceUuid.toString()}写uuid:${characteristic.uuid.toString()}  写数据:${writeData}");

//               await characteristic.write(data,
//                   allowLongWrite: allowLongWrite,
//                   withoutResponse:
//                       characteristic.properties.writeWithoutResponse);
//             }
//           }
//         }
//       }
//     } catch (e) {
//       print("捕捉到了写错误信息:$e");
//       if (!isRe) {
//         //不是再次发生
//         writeWithOut(data, isRe: true);
//       }
//     }
//   }

//   //获取蓝牙的权限
//   getBluetoothPermission() async {
//     print("开始获取权限");
//     await getPermission(Permission.locationWhenInUse);

//     await getPermission(Permission.bluetoothConnect);
//     await getPermission(Permission.bluetoothScan);
//     await getPermission(Permission.bluetooth);
//   }

//   Future<bool> getPermission(Permission permission, {bool show = true}) async {
//     var flog = false;
//     try {
//       await permission.onDeniedCallback(() {
//         print("用户拒绝了权限");
//         flog = false;
//       }).onGrantedCallback(() {
//         print("用户授予了权限");
//         flog = true;
//       }).onPermanentlyDeniedCallback(() {
//         print("用户永久拒绝了权限");
//         dioLog();
//         flog = false;
//       }).request();
//     } catch (e) {
//       print("获取权限出现了错误");
//     }

//     ///获取权限的状态，android只有运行和拒绝，ios则还包括拒绝不在询问
//     var status = await permission.status;
//     // PermissionStatus
//     //如果没有同意则需要再次获取
//     if (!status.isGranted) {
//       // Here you can open app settings so that the user can give permission
//       // openAppSettings();
//       /// 获取权限有多个结果返回、允许、拒绝、拒绝且不再询问
//       var permissionStatus = await permission.request();
//       switch (permissionStatus) {
//         case PermissionStatus.granted:

//           ///允许权限
//           return true;
//         case PermissionStatus.permanentlyDenied:
//           //拒绝且不在询问，需要跳出弹窗提示用户前往设置修改权限
//           if (show) {
//             dioLog();
//           }

//           return false;

//         default:
//           return false;
//       }
//     } else {
//       ///允许权限
//       return true;
//     }
//   }

//   //提示跳转到设置打开定位权限
//   void dioLog() {
//     Get.defaultDialog(
//       titlePadding: EdgeInsets.only(top: 60.h, bottom: 15.h),
//       radius: 10,
//       title: "警告".tr,
//       middleTextStyle: const TextStyle(
//         color: Color.fromARGB(255, 135, 135, 133),
//       ),
//       content: Container(
//         margin: const EdgeInsets.only(bottom: 20),
//         child: Text("如果不提供定位权限将无法搜索到硬件。是否前往设置打开定位权限？".tr,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color: Color.fromARGB(255, 135, 135, 133),
//             )),
//       ),
//       cancel: SizedBox(
//         width: 110,
//         child: TextButton(
//           onPressed: () {
//             Get.back();
//           },
//           child: Text(
//             "取消".tr,
//             style: const TextStyle(
//               color: Colors.black,
//               fontWeight: FontWeight.w600,
//               fontSize: 16,
//             ),
//           ),
//         ),
//       ),
//       confirm: SizedBox(
//         width: 110,
//         child: TextButton(
//           onPressed: () {
//             openAppSettings();
//             Get.back();
//           },
//           child: Text(
//             "跳转到设置".tr,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 16,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   //打开蓝牙
//   void openBlu() {
//     tipModal();
//   }

//   Future<dynamic> tipModal({
//     String? title, //标题内容
//     String? content, //文本内容
//     Function()? confirmFun, //确认按钮
//     Function()? cancelFun, //取消按钮
//   }) {
//     return Get.defaultDialog(
//       titlePadding: EdgeInsets.only(top: 60.h, bottom: 15.h),
//       radius: 10,
//       title: title ?? "提示".tr,
//       middleTextStyle: const TextStyle(
//         color: Color.fromARGB(255, 135, 135, 133),
//       ),
//       content: Container(
//         margin: const EdgeInsets.only(bottom: 20),
//         child: Text(content ?? "需要打开蓝牙才能搜索硬件".tr,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color: Color.fromARGB(255, 135, 135, 133),
//             )),
//       ),
//       cancel: SizedBox(
//         width: 110,
//         child: TextButton(
//           onPressed: () {
//             if (cancelFun != null) {
//               cancelFun();
//             } else {
//               Get.back();
//             }
//           },
//           child: Text(
//             "取消".tr,
//             style: const TextStyle(
//               color: Colors.black,
//               fontWeight: FontWeight.w600,
//               fontSize: 16,
//             ),
//           ),
//         ),
//       ),
//       confirm: SizedBox(
//         width: 110,
//         child: TextButton(
//           onPressed: () async {
//             if (confirmFun != null) {
//               confirmFun();
//             } else {
//               Get.back();
//               if (Platform.isAndroid) {
//                 await FlutterBluePlus.turnOn();
//               } else {
//                 await AppSettings.openAppSettings(
//                     type: AppSettingsType.bluetooth);
//               }
//             }
//           },
//           child: Text(
//             "打开".tr,
//             style: const TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: 16,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   //---------------函数区域结束-------------------
// }

// enum NetworkSendDataType {
//   SETWIFITYPE, //设置wifi的类型,
//   GETWIFIINFO, //获取已连接wifi的信息
//   GETWIFILIST, //获取wifi列表
//   SENDWIFINAME, //发送wifi的名称
//   SENDWIFIPASSWORD, //发送wifi的密码
//   CONNECTWIFI, //发送链接wifiAP的指令
//   REGETWIFIINFO, //发送链接指令后再次获取已连接的wifi信息,
//   NONE, //无操作
//   DISCONNECDBYGETLISTLIGHT, //断开连接在获取列表之前
//   DISCONNECDBYCONNECTLIGHT, //断开连接在连接之前
// }
