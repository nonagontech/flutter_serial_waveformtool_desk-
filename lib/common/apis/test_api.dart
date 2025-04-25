// 这是一个样例API，可以根据实际需求进行修改。
import '../entities/test_entities.dart';
import '../utils/http.dart';

class TestApi {
  // 设置API的基本URL
  static String baseUrl = "test";
  //这是一个样例接口
  static Future<DioResponse> testPost(TestPostReq params) async {
    var response = await HttpUtil().post(
      "$baseUrl/test",
      data: params.toJson(),
    );
    return response;
  }
}
