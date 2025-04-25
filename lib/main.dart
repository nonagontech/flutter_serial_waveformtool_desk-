import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'common/locale/translation_server.dart';
import 'common/routes/names.dart';
import 'common/routes/pages.dart';
import 'common/store/test_store.dart';
import 'common/style/theme.dart';
import 'common/utils/storage.dart';
import 'pages/tabs.dart';
import 'package:flutter/services.dart';

void main() async {
//初始化本地存储
  await GetStorage.init();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
//设置状态栏颜色
    statusBarColor: Colors.transparent,
//状态栏图标颜色
    statusBarIconBrightness: Brightness.light,
  ));

//用于确保Flutter的Widgets绑定已经初始化。
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData? theme;
    var local = Storages.getTheme() ?? "";
    switch (local) {
      case '': //light主题
      case 'light': //light主题
        theme = AppTheme.light;
        break;
      case 'dark': //暗系统主题
        theme = AppTheme.dark;
        break;
      default:
    }
//屏幕自适应
    return ScreenUtilInit(
        designSize: const Size(750, 1624), // 初始化设计尺寸 750是高度
        builder: (context, chider) {
          return MultiProvider(
// 动态管理
            providers: [
              ChangeNotifierProvider(
                create: (ctx) => TestStore(), //这里是一个全局的provider,根据需求替换
              ),
            ],
            child: GetMaterialApp(
              title: 'FlutterFlow',
              translations: TranslationServer(), //多语言字典
              locale: TranslationServer().getLocal(), //当前使用的语言
              fallbackLocale:
                  const Locale("zh", "Hans"), //在选择无效区域设置的情况下指定回退区域设置。
              supportedLocales: TranslationServer.locales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations
                    .delegate, //是Flutter的一个本地化委托，用于提供Material组件库的本地化支持
                GlobalWidgetsLocalizations.delegate, //用于提供通用部件（Widgets）的本地化支持
                GlobalCupertinoLocalizations
                    .delegate, //用于提供Cupertino风格的组件的本地化支持
              ],
              debugShowCheckedModeBanner: false, //删除调试横幅
//主题
              theme: theme,
// theme: AppTheme.dark,
              themeMode: ThemeMode.light,
              enableLog: true,
              getPages: AppPages.routes,
              navigatorObservers: [AppPages.observer],
              initialRoute: '/',
              builder: EasyLoading.init(),
              home: null,
            ),
          );
        });
  }
}
