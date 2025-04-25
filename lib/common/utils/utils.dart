import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// 全局函数和变量

//打开相机
Future<CroppedFile?> openCamera() async {
  XFile? pickedFile = await ImagePicker().pickImage(
    source: ImageSource.camera,
  );
  if (pickedFile != null) {
    return await croppedImg(pickedFile);
  }
  return null;
}

//图片进行剪切
Future<CroppedFile?> croppedImg(pickedFile) async {
  CroppedFile? croppFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      cropStyle: CropStyle.circle,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: "裁剪".tr,
          hideBottomControls: true,
          cropGridRowCount: 0,
          cropGridColumnCount: 0,
          cropFrameStrokeWidth: 0,
        ),
        IOSUiSettings(
          title: "裁剪".tr,
          doneButtonTitle: "确认".tr,
          cancelButtonTitle: "取消".tr,
        )
      ]);
  return croppFile;
}

Future<bool> getPermission(Permission permission, {bool show = true}) async {
  var flog = false;
  try {
    await permission.onDeniedCallback(() {
      print("用户拒绝了权限");
      flog = false;
    }).onGrantedCallback(() {
      print("用户授予了权限");
      flog = true;
    }).onPermanentlyDeniedCallback(() {
      print("用户永久拒绝了权限");
      dioLog();
      flog = false;
    }).request();
  } catch (e) {
    print("获取权限出现了错误");
  }

  ///获取权限的状态，android只有运行和拒绝，ios则还包括拒绝不在询问
  var status = await permission.status;
  // PermissionStatus
  //如果没有同意则需要再次获取
  if (!status.isGranted) {
    // Here you can open app settings so that the user can give permission
    // openAppSettings();
    /// 获取权限有多个结果返回、允许、拒绝、拒绝且不再询问
    var permissionStatus = await permission.request();
    switch (permissionStatus) {
      case PermissionStatus.granted:

        ///允许权限
        return true;
      case PermissionStatus.permanentlyDenied:
        //拒绝且不在询问，需要跳出弹窗提示用户前往设置修改权限
        if (show) {
          dioLog();
        }

        return false;

      default:
        return false;
    }
  } else {
    ///允许权限
    return true;
  }
}

//提示跳转到设置打开定位权限
void dioLog() {
  Get.defaultDialog(
    titlePadding: EdgeInsets.only(top: 60.h, bottom: 15.h),
    radius: 10,
    title: "警告".tr,
    middleTextStyle: const TextStyle(
      color: Color.fromARGB(255, 135, 135, 133),
    ),
    content: Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Text("如果不提供定位权限将无法搜索到硬件。是否前往设置打开定位权限？".tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color.fromARGB(255, 135, 135, 133),
          )),
    ),
    cancel: SizedBox(
      width: 110,
      child: TextButton(
        onPressed: () {
          Get.back();
        },
        child: Text(
          "取消".tr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    ),
    confirm: SizedBox(
      width: 110,
      child: TextButton(
        onPressed: () {
          openAppSettings();
          Get.back();
        },
        child: Text(
          "跳转到设置".tr,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    ),
  );
}

// 打开相册
Future<XFile?> openImg() async {
  bool isGranted = Platform.isAndroid
      ? await getPermission(Permission.camera)
      : await getPermission(Permission.photos);
  print("相册权限的值:$isGranted");
  if (!isGranted) {
    EasyLoading.showError("拒绝了访问相册的权限".tr);
    return null;
  }
  XFile? image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
  );
  return image;
}

/// 计算校验和
int calculateChecksum(List<int> data) {
  int checksum = 0;
  for (int i = 0; i < data.length; i++) {
    checksum += data[i];
  }
  // 取低八位
  return checksum & 0xFF;
}

/// 点击任意位置关闭键盘
void hideKeyboard(BuildContext context) {
  FocusScopeNode currentFocus = FocusScope.of(context);
  if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
    FocusManager.instance.primaryFocus!.unfocus();
  }
}

//command,ESP32的控制命令,必须是4个字节
List<int> sendDataESP32(String command, List<int> arr, int sequence) {
  List<int> sendArr = [];
  //帧长,如果帧长是一位,前面加0
  command = command.padLeft(4, "0");
  List<int> commandArr = [];
  for (int i = 0; i < command.length; i += 2) {
    int endIndex = i + 2;
    if (endIndex > command.length) {
      endIndex = command.length;
    }
    String subString = command.substring(i, endIndex);
    int subInt = int.parse(subString, radix: 16);
    commandArr.add(subInt);
  }
  int arrLength = arr.length;
  sendArr = commandArr + [sequence] + [arrLength] + arr;
  List<String> dataArr = [];
  return sendArr;
}

List<int> mellaDataFun(String zhiling, List<int> arr) {
  int length = arr.length + 3;
  int kongzhi = int.parse(zhiling, radix: 16);
  int comment = length ^ kongzhi;
  for (var i = 0; i < arr.length; i++) {
    comment = comment ^ arr[i];
  }
  List<int> newArr = [170, length, kongzhi];
  newArr.addAll(arr);
  newArr.addAll([comment, 85]);
  return newArr;
}

enum TakeStatus {
  /// 准备中
  preparing,

  /// 拍摄中
  taking,

  /// 待确认
  confirm,

  /// 已完成
  done
}
