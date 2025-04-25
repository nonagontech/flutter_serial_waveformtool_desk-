import 'package:flutter/material.dart';

/// 测试store
class TestStore extends ChangeNotifier {
  String _id = "";

  String get id => _id;
  set id(String value) {
    notifyListeners();
    _id = value;
  }
}
