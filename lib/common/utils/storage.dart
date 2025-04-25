import 'package:get_storage/get_storage.dart';

// 封装本地存储的增删改查
class StorageUtil {
  static final StorageUtil _storage = StorageUtil._internal();
  final GetStorage _box = GetStorage();
  GetStorage get box => _box;
  StorageUtil._internal();
  factory StorageUtil() => _storage;

  write(String key, value) => _box.write(key, value); //写入
  read(String key) => _box.read(key); //读取
  remove(String key) => _box.remove(key); //删除
  cleanAll() => _box.erase(); //清空所有
}

// 包装本地存储的变量
class Storages {
  //---------语言---------
  static setLanguage(String value) {
    StorageUtil().write("language", value);
  }

  static getLanguage() {
    return StorageUtil().read("language");
  }

  static clearLanguage() {
    StorageUtil().remove("language");
  }

  //---------主题---------
  static setTheme(bool value) {
    StorageUtil().write("theme", value);
  }

  static getTheme() {
    return StorageUtil().read("theme");
  }

  static clearTheme() {
    StorageUtil().remove("theme");
  }

  //----------用户token---------------
  static setToken(String value) {
    StorageUtil().write("token", value);
  }

  static getToken() {
    return StorageUtil().read("token");
  }

  static clearToken() {
    StorageUtil().remove("token");
  }
}
