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

import '../common/style/color.dart';
import '../common/routes/pages.dart';
import '../common/utils/storage.dart';

/// @file  help
/// @author https://aiflutter.com/
/// @description
/// @createDate 2025-04-25 15:10:54
class help extends StatefulWidget {
  const help({super.key});

  @override
  State<help> createState() => _helpState();
}

class _helpState extends State<help> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前主题的亮度
    Brightness brightness = Theme.of(context).brightness;
    bool isDark = brightness == Brightness.dark;

    return SingleChildScrollView(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
//关闭键盘
          hideKeyboard(context);
        },
        child: Container(
          clipBehavior: Clip.none,
          width: 442.252197265625,
          height: 432.251953125,
          alignment: Alignment(-1, -1),
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.transparent,
            gradient: null,
            border: Border.all(
              color: Colors.black,
              width: 0,
              style: BorderStyle.none,
            ),
          ),
          child: Container(
            clipBehavior: Clip.none,
            width: 400,
            height: 400,
            alignment: Alignment(-1, -1),
            padding: EdgeInsets.only(
              top: 20,
              right: 10,
              bottom: 0,
              left: 10,
            ),
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Color(4294967295),
              gradient: null,
              border: Border.all(
                color: Colors.black,
                width: 0,
                style: BorderStyle.none,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              verticalDirection: VerticalDirection.down,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  verticalDirection: VerticalDirection.down,
                  children: [
                    Text(
                      "帮助".tr,
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? DarkAppColor.primaryText
                            : AppColor.primaryText,
                        height: null,
                        fontStyle: FontStyle.normal,
                      ),
                    ),
                  ],
                ), //Row
                Text(
                  "规则".tr,
                  textAlign: TextAlign.left,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? DarkAppColor.primaryText
                        : AppColor.primaryText,
                    height: null,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                Text(
                  " <计数戳>{窗口名称}数据\n".tr,
                  textAlign: TextAlign.left,
                  maxLines: 10,
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
                Text(
                  "备注".tr,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? DarkAppColor.primaryText
                        : AppColor.primaryText,
                    height: null,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                Text(
                  "1.任意数据都可以分窗".tr,
                  textAlign: TextAlign.left,
                  maxLines: 10,
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
                Text(
                  "2.当数据为逗号分隔数字时可以绘图".tr,
                  textAlign: TextAlign.left,
                  maxLines: 10,
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
                Text(
                  "3.不支持中文，花括号、尖括号、换行符\n不可省略".tr,
                  textAlign: TextAlign.left,
                  maxLines: 10,
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
                Text(
                  "4.计数戳为纯数字，作为X轴数据，不可带单位".tr,
                  textAlign: TextAlign.left,
                  maxLines: 10,
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
                Text(
                  "数据示例".tr,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? DarkAppColor.primaryText
                        : AppColor.primaryText,
                    height: null,
                    fontStyle: FontStyle.normal,
                  ),
                ),
                Text(
                  "<0.0>{plotter}1,2,3,4".tr,
                  textAlign: TextAlign.left,
                  maxLines: 10,
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
                Text(
                  "<1.0>{plotter}1,2,3,4".tr,
                  textAlign: TextAlign.left,
                  maxLines: 10,
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
                Text(
                  "<2.5>{plotter}1,2,3,4".tr,
                  textAlign: TextAlign.left,
                  maxLines: 10,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  verticalDirection: VerticalDirection.down,
                  children: [
                    Container(
                      margin: EdgeInsets.zero,
                      width: 240,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (AppPages.currentIsPop()) {
                            Get.back();
                          }
                        },
                        style: ButtonStyle(
                          minimumSize: WidgetStateProperty.all(Size.zero),
                          backgroundColor: WidgetStateProperty.all(
                              Color.fromARGB(255, 200, 200, 200)),
                          padding: WidgetStateProperty.all(EdgeInsets.only(
                              left: 0, right: 0, top: 0, bottom: 0)),
                          elevation: WidgetStateProperty.all(4),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(),
                          ),
                          side: WidgetStateProperty.all(BorderSide.none),
                        ),
                        child: Text(
                          "确认".tr,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w500,
                            color: Color(4278190080),
                            height: null,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ), //Row
              ],
            ), //Column
          ), //Container
        ), //Container
      ),
    );
  }

  /// 点击任意位置关闭键盘
  void hideKeyboard(BuildContext context) {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus!.unfocus();
    }
  }
}
