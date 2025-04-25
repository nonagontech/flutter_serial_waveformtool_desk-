import 'package:dio/dio.dart';
import 'package:get/get.dart' as tr;
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../value/cache.dart';
// import '../value/serve.dart';
import 'logger.dart';
import 'storage.dart';

class HttpUtil {
  static final HttpUtil _instance = HttpUtil.internal();
  factory HttpUtil() => _instance;

  bool _isRefreshing = false;

  Future? requestFunction;

  late Dio dio;
  //可以通过 CancelToken 来取消发起的请求
  CancelToken cancelToken = CancelToken();

  HttpUtil.internal() {
    // BaseOptions、Options、RequestOptions 都可以配置参数，优先级别依次递增，且可以根据优先级别覆盖参数
    BaseOptions options = BaseOptions(
      //请求基地址
      // baseUrl: SERVER_API_URL,

      //连接服务器超时时间
      connectTimeout: const Duration(seconds: 20),
      // 响应流上前后两次接受到数据的间隔
      receiveTimeout: const Duration(seconds: 20),
      // Http请求头.
      headers: {},

      /// 请求的Content-Type，默认值是"application/json; charset=utf-8".
      /// 如果您想以"application/x-www-form-urlencoded"格式编码请求数据,
      /// 可以设置此选项为 `Headers.formUrlEncodedContentType`,  这样[Dio]
      /// 就会自动编码请求体.
      contentType: 'application/json; charset=utf-8',

      /// [responseType] 表示期望以那种格式(方式)接受响应数据。
      /// 目前 [ResponseType] 接受三种类型 `JSON`, `STREAM`, `PLAIN`.
      ///
      /// 默认值是 `JSON`, 当响应头中content-type为"application/json"时，dio 会自动将响应内容转化为json对象。
      /// 如果想以二进制方式接受响应数据，如下载一个二进制文件，那么可以使用 `STREAM`.
      ///
      /// 如果想以文本(字符串)格式接收响应数据，请使用 `PLAIN`.
      responseType: ResponseType.json,
    );
    dio = Dio(options);
    // CookieJar   Dart 中用于 http 请求的 cookie 管理器，您可以通过它轻松处理复杂的 cookie 策略并持久化 cookie。
    // CookieJar cookieJar = CookieJar();
    // dio.interceptors.add(CookieManager(cookieJar));

    // 添加拦截器
    // dio.interceptors.add(
    //   InterceptorsWrapper(
    //     onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
    //       /// 如果你想完成请求并返回一些自定义数据，你可以使用 `handler.resolve(response)`。
    //       ///这样请求将会被终止，上层then会被调用，then中返回的数据将是你的自定义response.

    //       /// 如果你想终止请求并触发一个错误,你可以使用 `handler.reject(error)`。
    //       /// 这样请求将被中止并触发异常，上层catchError会被调用。
    //       ///
    //       return handler.next(options);
    //     },
    //     onResponse: (response, handler) {
    //       // 如果你想终止请求并触发一个错误,你可以使用 `handler.reject(error)`。
    //       //这样请求将被中止并触发异常，上层catchError会被调用。
    //       // 请求成功是对数据做基本处理

    //       if (response.statusCode == 200) {
    //         response.data = DioResponse(
    //             code: 200,
    //             message: "请求成功啦",
    //             data: response.data == '' ? null : response.data);
    //       } else {
    //         response.data = DioResponse(
    //             code: response.statusCode,
    //             message: "请求失败啦",
    //             data: response.data);
    //       }
    //       // 对某些单独的url返回数据做特殊处理
    //       // if (response.requestOptions.baseUrl.contains("???????")) {
    //       //   //....
    //       // }

    //       return handler.next(response);
    //     },
    //     onError: (e, handler) async {
    //       //停止加载
    //       // Loading.dismiss();

    //       EasyLoading.instance.userInteractions = true;
    //       EasyLoading.dismiss();
    //       DioResponse? eInfo;
    //       if ("$e".contains("The request connection took longer")) {
    //         eInfo = DioResponse(code: -1, message: "连接超时".tr, data: "");
    //       } else {
    //         eInfo = createErrorEntity(e);
    //       }
    //       onError(eInfo);
    //       Response response =
    //           Response(data: eInfo, requestOptions: RequestOptions());

    //       if (eInfo.code == 401 &&
    //           (eInfo.message == "Token has expired" ||
    //               eInfo.message == "Authentication failed" ||
    //               eInfo.message == "JWT Token expired" ||
    //               eInfo.message == "Invalid JWT token")) {
    //         if (!_isRefreshing) {
    //           _isRefreshing = true;
    //           // String refreshToken =  StorageUtil().read("refreshToken") ?? ''; //获取当前的refreshToken
    //           String refreshToken = "";
    //           Dio tokenDio = Dio(); //创建新的Dio实例
    //           if (refreshToken == '') {
    //             return;
    //           }

    //           try {
    //             var error = e;
    //             String url =
    //                 "${SERVER_API_URL}api/auth/token"; //refreshToken url
    //             var response = await tokenDio.post(url, data: {
    //               "refreshToken": refreshToken,
    //             }); //请求refreshToken刷新的接口
    //             _isRefreshing = false; // 刷新完成，释放刷新锁
    //             Log.print("response.statusCode:${response.statusCode}");
    //             if (response.statusCode == 200) {
    //               var res = response.data;
    //               String? token = res["token"] ?? "";

    //               RequestOptions requestOptions =
    //                   error.response!.requestOptions;
    //               Options option = Options(
    //                 method: requestOptions.method,
    //                 headers: {"X-Authorization": 'Bearer ${token!}'},
    //                 responseType: requestOptions.responseType,
    //               );

    //               Response newResponse = await dio.request(
    //                 requestOptions.path,
    //                 data: requestOptions.data,
    //                 queryParameters: requestOptions.queryParameters,
    //                 options: option,
    //               );
    //               return handler.resolve(newResponse); // 返回重新发送的响应
    //             } else {
    //               Log.print("获取新的token过期了");
    //               String errText = "账号登录已过期，请重新登陆".tr;
    //               EasyLoading.showError(errText);
    //               //返回首页中
    //             }
    //           } on DioError catch (e) {
    //             _isRefreshing = false; // 刷新完成，释放刷新锁
    //             if (e.response?.statusCode == 401) {
    //               //401代表refresh_token过期
    //               String errText = "账号登录已过期，请重新登陆".tr;
    //               EasyLoading.showError(errText);
    //               //返回首页中
    //             }
    //           }
    //         }
    //       } else {
    //         return handler.resolve(response); //continue
    //       }

    //       // 如果你想完成请求并返回一些自定义数据，可以resolve 一个`Response`,如`handler.resolve(response)`。
    //       // 这样请求将会被终止，上层then会被调用，then中返回的数据将是你的自定义response.
    //     },
    //   ),
    // );
  }

  //error进行统一处理
  onError(DioResponse eInfo) {
    String errText = '';
    switch (eInfo.code) {
      case 401: //401提示什么错误或者做些什么操作，比如token过期退出登录

        switch (eInfo.message) {
          case "Token has expired":
          case "Authentication failed":
            // errText = "账号登录已过期，请重新登陆".tr;

            break;
          case "Invalid password":
          case "Authentication Failed. Username or Password not valid.":
            EasyLoading.showError("密码错误".tr);
            // Get.offNamed(AppRoutes.SIGN_IN);
            break;
          case "Invalid username":
            EasyLoading.showError("账号错误".tr);
            break;
          case "Invalid username or password":
            EasyLoading.showError("账号或密码不正确".tr);
            break;
          case "User account is not active":
          case "User account is locked due to security policy":
            break;
        }

        break;
      case 501:
        switch (eInfo.message) {
          case "The user does not exist, please register!":
            errText = "该账号不存在".tr;
            EasyLoading.showError(errText);
            break;
          case "User already exists!":
            errText = "用户已存在".tr;
            EasyLoading.showError(errText);
            break;
        }

        break;
      case 509:
        errText = "验证码有误，请重新获取".tr;
        EasyLoading.showError(errText);
        break;

      case 511:
        errText = "验证码以过期，请重新输入".tr;
        EasyLoading.showError(errText);
        break;
      case -1:
        EasyLoading.showError(eInfo.message);

        break;

      default:
    }
  }

//错误信息
  DioResponse createErrorEntity(DioError error) {
    var data = error.response?.data;
    Log.print(
        "进入了错误信息：error.type:${error.type},错误的码：￥「${error.response!.statusCode},,data:$data");
    switch (error.type) {
      case DioExceptionType.cancel:
        return DioResponse(code: -1, message: "请求取消".tr, data: data);
      case DioExceptionType.connectionTimeout:
        return DioResponse(code: -1, message: "连接超时".tr, data: data);
      case DioExceptionType.sendTimeout:
        return DioResponse(code: -1, message: "请求超时".tr, data: data);
      case DioExceptionType.receiveTimeout:
        return DioResponse(code: -1, message: "响应超时".tr, data: data);
      case DioExceptionType.badResponse:
        {
          try {
            int errCode =
                error.response != null ? error.response!.statusCode! : -1;
            String message = '';
            if (data != null && data is Map) {
              if (data["message"] != null) {
                message = data["message"];
              } else {
                if (error.response != null &&
                    error.response?.data is Map<String, dynamic>) {
                  message = error.response?.data["message"] ??
                      error.response?.data["msg"] ??
                      '';
                }
              }
            }

            return DioResponse(code: errCode, message: '$message', data: data);
          } catch (e) {
            return DioResponse(
                code: -1, message: "${data["message"]}", data: e);
          }
        }

      case DioExceptionType.unknown:
        {
          try {
            int errCode =
                error.response != null ? error.response!.statusCode! : -1;

            switch (errCode) {
              case 400:
                return DioResponse(
                    code: errCode, message: "请求语法错误", data: data);
              case 401:
                return DioResponse(code: errCode, message: "没有权限", data: data);
              case 403:
                return DioResponse(
                    code: errCode, message: "服务器拒绝执行", data: data);
              case 404:
                return DioResponse(
                    code: errCode, message: "无法连接服务器", data: data);
              case 405:
                return DioResponse(
                    code: errCode, message: "请求方法被禁止", data: data);
              case 500:
                return DioResponse(
                    code: errCode, message: "服务器内部错误", data: data);
              case 502:
                return DioResponse(code: errCode, message: "无效的请求", data: data);
              case 503:
                return DioResponse(code: errCode, message: "服务器挂了", data: data);
              case 505:
                return DioResponse(
                    code: errCode, message: "不支持HTTP协议请求", data: data);
              default:
                {
                  // return ErrorEntity(code: errCode, message: "未知错误");
                  return DioResponse(
                      code: errCode,
                      message: error.response != null
                          ? error.response!.statusMessage!
                          : "其他状态字异常",
                      data: data);
                }
            }
          } on Exception catch (_) {
            return DioResponse(code: -1, message: "unknown抛出了异常", data: data);
          }
        }
      default:
        {
          return DioResponse(
              code: -1, message: error.message.toString(), data: data);
        }
    }
  }

  /// 取消请求
  /// 同一个cancel token 可以用于多个请求，当一个cancel token取消时，所有使用该cancel token的请求都会被取消。
  /// 所以参数可选
  void cancelRequests(CancelToken token) {
    token.cancel("cancelled");
  }

  /// 读取本地配置
  Map<String, dynamic>? getAuthorizationHeader() {
    // var headers = <String, dynamic>{};
    // var token = Storages.getToken();
    // if (token != null) {
    //   headers['X-Authorization'] = 'Bearer $token';
    // }
    // return headers;
    return null;
  }

  /// restful get 操作
  /// refresh 是否下拉刷新 默认 false
  /// noCache 是否不缓存 默认 true
  /// list 是否列表 默认 false
  /// cacheKey 缓存key
  /// cacheDisk 是否磁盘缓存
  Future get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool refresh = false,
    bool noCache = !CACHE_ENABLE,
    bool list = false,
    String cacheKey = '',
    bool cacheDisk = false,
    CancelToken? canceltoken,
    Map<String, dynamic>? data,
  }) async {
    Options requestOptions = options ?? Options();
    requestOptions.headers = requestOptions.headers ?? {};
    Map<String, dynamic>? authorization = getAuthorizationHeader();
    if (authorization != null) {
      requestOptions.headers!.addAll(authorization);
    }

    try {
      var response = await dio.get(
        path,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: canceltoken ?? cancelToken,
        data: data,
      );
      return response;
    } catch (e) {
      Log.print("get接口出现了错误$e");
    }
  }

  /// restful post 操作
  Future post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? canceltoken,
  }) async {
    Options requestOptions = options ?? Options();
    requestOptions.headers = requestOptions.headers ?? {};
    Map<String, dynamic>? authorization = getAuthorizationHeader();

    if (authorization != null) {
      requestOptions.headers!.addAll(authorization);
    }
    try {
      var response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: canceltoken ?? cancelToken,
      );
      return response;
    } catch (e) {
      Log.print("post接口出现了错误：$e");
    }
  }

  /// restful put 操作
  Future put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    Options requestOptions = options ?? Options();
    requestOptions.headers = requestOptions.headers ?? {};
    Map<String, dynamic>? authorization = getAuthorizationHeader();
    if (authorization != null) {
      requestOptions.headers!.addAll(authorization);
    }
    var response = await dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: requestOptions,
      cancelToken: cancelToken,
    );
    return response;
  }

  /// restful patch 操作
  Future patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    Options requestOptions = options ?? Options();
    requestOptions.headers = requestOptions.headers ?? {};
    Map<String, dynamic>? authorization = getAuthorizationHeader();
    if (authorization != null) {
      requestOptions.headers!.addAll(authorization);
    }
    var response = await dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: requestOptions,
      cancelToken: cancelToken,
    );
    return response;
  }

  /// restful delete 操作
  Future delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    Options requestOptions = options ?? Options();
    requestOptions.headers = requestOptions.headers ?? {};
    Map<String, dynamic>? authorization = getAuthorizationHeader();
    if (authorization != null) {
      requestOptions.headers!.addAll(authorization);
    }
    var response = await dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: requestOptions,
      cancelToken: cancelToken,
    );
    return response;
  }

  /// restful post form 表单提交操作
  Future postForm(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    Options requestOptions = options ?? Options();
    requestOptions.headers = requestOptions.headers ?? {};
    Map<String, dynamic>? authorization = getAuthorizationHeader();
    if (authorization != null) {
      requestOptions.headers!.addAll(authorization);
    }
    var response = await dio.post(
      path,
      data: FormData.fromMap(data),
      queryParameters: queryParameters,
      options: requestOptions,
      cancelToken: cancelToken,
    );
    return response.data;
  }

  /// restful post Stream 流数据
  Future postStream(
    String path, {
    dynamic data,
    int dataLength = 0,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    Options requestOptions = options ?? Options();
    requestOptions.headers = requestOptions.headers ?? {};
    Map<String, dynamic>? authorization = getAuthorizationHeader();
    if (authorization != null) {
      requestOptions.headers!.addAll(authorization);
    }
    requestOptions.headers!.addAll({
      Headers.contentLengthHeader: dataLength.toString(),
    });
    var response = await dio.post(
      path,
      data: Stream.fromIterable(data.map((e) => [e])),
      queryParameters: queryParameters,
      options: requestOptions,
      cancelToken: cancelToken,
    );
    return response.data;
  }
}

class DioResponse<T> {
  /// 消息(例如成功消息文字/错误消息文字)
  final String message;

  /// 自定义code(可根据内部定义方式)
  final int? code;

  /// 接口返回的数据
  final T data;

  /// 需要添加更多
  /// .........

  DioResponse({
    required this.message,
    required this.data,
    required this.code,
  });
  factory DioResponse.fromJson(Map<String, dynamic> json) => DioResponse(
        code: json["code"],
        message: json["message"],
        data: json["data"],
      );
  Map<String, dynamic> toJson() => {
        "message": message,
        "data": data,
        "code": code,
      };
}
