import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:get/get.dart';

import '../utils/storage.dart';
// import 'en_us.dart';
// import 'zh_Hans.dart';

class TranslationServer extends Translations {
  static List<Locale> locales = const [
    Locale('zh', 'CN'), // 支持的语言和地区
    Locale('en', 'US'),
  ];

  Locale getLocal() {
    var local = Storages.getLanguage();
    if (local == null) {
      String temp = Get.deviceLocale?.toString() ?? "zh_Hans";
      if (temp.contains("zh_")) {
        Storages.setLanguage("zh");
        return const Locale("zh", "Hans");
      } else {
        Storages.setLanguage("en");
        return const Locale("en", "en_US");
      }
    } else {
      if (local == 'zh') {
        return const Locale("zh", "Hans");
      } else {
        return const Locale("en", "en_US");
      }
    }
  }

  @override
  Map<String, Map<String, String>> get keys => {
        // "en_US": enUS,
        // "zh_Hans": zhHans,
      };
}
