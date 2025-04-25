//约束TestApi中的testPost的入参类型
class TestPostReq {
  String name;
  int? age;
  TestPostReq({
    required this.name,
    this.age,
  });
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
    };
  }
}

class TestPostResp {
  //约束TestApi中的testPost的出参类型
  String? name;
  int? age;
  TestPostResp({
    this.name,
    this.age,
  });
  factory TestPostResp.fromJson(Map<String, dynamic> json) {
    return TestPostResp(
      name: json['name'],
      age: json['age'],
    );
  }
}
