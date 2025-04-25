import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'routes.dart';

class RouteObservers extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // 如果为空则默认是弹窗跳转
    var name = route.settings.name ?? 'popUp';
    if (name.isNotEmpty) AppPages.history.add(name);
    Log.print("didPush:${AppPages.history.toString()}");
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    AppPages.history.remove(route.settings.name ?? 'popUp');
    Log.print("didPop:${AppPages.history.toString()}");
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      var index = AppPages.history.indexWhere((element) {
        return element == oldRoute?.settings.name;
      });
      var name = newRoute.settings.name ?? 'popUp';
      if (name.isNotEmpty) {
        if (index > 0) {
          AppPages.history[index] = name;
        } else {
          AppPages.history.add(name);
        }
      }
    }
    Log.print("didReplace:${AppPages.history.toString()}");
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    AppPages.history.remove(route.settings.name ?? 'popUp');
    Log.print("didRemove:${AppPages.history.toString()}");
  }
}
