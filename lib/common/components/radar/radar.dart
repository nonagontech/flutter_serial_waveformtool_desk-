import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart';

/// 水波纹
class WaterRipple extends StatefulWidget {
  const WaterRipple(
      {super.key,
      this.count = 3,
      this.color = const Color(0xFF0080ff),
      this.width = 300,
      this.controller,
      this.location = 0,
      this.isFill = true});
  final int count; //涟漪的个数
  final Color color; //涟漪的颜色
  final double? width; //两个组件合并在一起的宽高
  final AnimationController? controller; //涟漪动画控制器
  final int location; //圆心位置，1代表在右上角，0代表在中心
  final bool isFill; //是否填充

  @override
  State<WaterRipple> createState() => _WaterRippleState();
}

class _WaterRippleState extends State<WaterRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    _controller = widget.controller != null
        ? widget.controller!
        : AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 2000),
          )
      ..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.width,
      // decoration: BoxDecoration(
      //   // color: ui.Color.fromARGB(64, 166, 240, 211),
      //   gradient: RadialGradient(
      //     center: Alignment.center,
      //     colors: [
      //       // ui.Color.fromARGB(203, 64, 250, 176),
      //       ui.Color.fromARGB(64, 32, 235, 153),
      //       Colors.white,
      //     ],
      //     radius: 0.5,
      //   ),
      //   borderRadius: BorderRadius.circular(2000),
      // ),
      child: ClipRRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: WaterRipplePainter(
                  _controller.value, widget.location, widget.isFill,
                  count: widget.count, color: widget.color),
            );
          },
        ),
      ),
    );
  }
}

class WaterRipplePainter extends CustomPainter {
  final double progress;
  final int count;
  final Color color;
  final Paint _paint = Paint();
  final int location; //圆心位置，1代表在右上角，0代表在中心
  final bool isFill; //是否填充

  WaterRipplePainter(this.progress, this.location, this.isFill,
      {this.count = 3, this.color = const Color(0xFF0080ff)});
  @override
  void paint(Canvas canvas, Size size) {
    _paint.style = isFill ? PaintingStyle.fill : PaintingStyle.stroke;
    double radius = location == 0
        ? max(size.width, size.height)
        : size.width + size.height; // 是否让用户自定义半径长度
    for (int i = count; i >= 0; i--) {
      final double opacity = (1.0 - ((i + progress) / (count + 1)));

      double _radius = radius * ((i + progress) / (count + 1));
      if (location == 0) {
        final Color _color = color.withOpacity(opacity);
        _paint.color = _color;
        canvas.drawCircle(
            Offset(size.width / 2, size.height / 2), _radius, _paint);
      } else {
        _paint.color = color;
        _paint.strokeWidth = 1;
        canvas.drawCircle(Offset(size.width, 0), _radius, _paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

/// 雷达扫描
class RadarView extends StatefulWidget {
  const RadarView({
    super.key,
    this.radarViewController,
    this.radarViewColor = Colors.white,
    this.count = 3,
  });

  final AnimationController? radarViewController; //雷达扫描动画控制器
  final Color radarViewColor; //雷达扫描指针的颜色
  final int count; //环的个数
  @override
  State<RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<RadarView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    _controller = widget.radarViewController != null
        ? widget.radarViewController!
        : AnimationController(
            vsync: this, duration: const Duration(seconds: 5));
    _animation = Tween(begin: .0, end: pi * 2).animate(_controller);
    _controller.repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: RadarPainter(
            angle: _animation.value,
            radarViewColor: widget.radarViewColor,
            circleCount: widget.count,
          ),
        );
      },
    );
  }
}

class RadarPainter extends CustomPainter {
  RadarPainter({
    required this.angle,
    this.radarViewColor = Colors.white,
    this.circleCount = 3,
  });
  final double angle;
  final Color radarViewColor; //雷达扫描指针的颜色
  final int circleCount; //雷达扫描添加瞄准的环数,暂时注销了

  final Paint _paint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    var radius = min(size.width / 2, size.height / 2);
    Paint _bgPaint = Paint()
      ..color = ui.Color.fromARGB(97, 183, 183, 183)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width / 2, size.height / 2 - radius),
        Offset(size.width / 2, size.height / 2 + radius), _bgPaint);
    canvas.drawLine(Offset(size.width / 2 - radius, size.height / 2),
        Offset(size.width / 2 + radius, size.height / 2), _bgPaint);
    for (var i = 1; i <= circleCount - 1; ++i) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2),
          radius * i / circleCount, _bgPaint);
    }
    _paint.shader = ui.Gradient.sweep(
        Offset(size.width / 2, size.height / 2),
        [radarViewColor.withOpacity(.01), radarViewColor.withOpacity(.5)],
        [.0, 1.0],
        TileMode.clamp,
        .0,
        pi / 180 * 270);
    canvas.save();
    double r = sqrt(pow(size.width, 2) + pow(size.height, 2));
    double startAngle = atan(size.height / size.width);
    Point p0 = Point(r * cos(startAngle), r * sin(startAngle));
    Point px = Point(r * cos(angle + startAngle), r * sin(angle + startAngle));
    canvas.translate((p0.x - px.x) / 2, (p0.y - px.y) / 2);
    canvas.rotate(angle);
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2), radius: radius),
        0,
        pi / 180 * 70,
        true,
        _paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class RadarPage extends StatefulWidget {
  const RadarPage({
    super.key,
    this.width = 300,
    this.count = 3,
    this.waterRippleColor = const Color(0xFF0080ff),
    this.waterRippleController,
    this.radarViewColor = Colors.white,
    this.radarViewController,
    this.gradient,
    this.radar = true,
    this.isFill = true,
  });
  final double? width; //两个组件合并在一起的宽高

  final int count; //涟漪的个数
  final Color waterRippleColor; //涟漪的颜色
  final AnimationController? waterRippleController; //涟漪动画控制器

  final Color radarViewColor; //雷达扫描指针的颜色
  final AnimationController? radarViewController; //雷达扫描动画控制器
  final Gradient? gradient; //雷达背景渐变色
  final bool radar; //是否开启雷达扫描
  final bool isFill; //是否填充扫描区域

  @override
  State<RadarPage> createState() => _RadarPageState();
}

class _RadarPageState extends State<RadarPage> {
  final List<Offset> blockPositions = [];

  @override
  void dispose() {
    // widget.waterRippleController?.dispose();
    // widget.radarViewController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.radar
        ? Stack(
            children: [
              Positioned(
                child: Container(
                  // color: Colors.black,
                  width: widget.width,
                  height: widget.width,
                  child: RadarView(
                    count: widget.count,
                    radarViewColor: widget.radarViewColor,
                    radarViewController: widget.radarViewController,
                  ),
                ),
              ),
              // 背景
              Positioned(
                child: Container(
                  width: widget.width,
                  height: widget.width,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(2000),
                  ),
                ),
              ),
            ],
          )
        : WaterRipple(
            isFill: widget.isFill,
            width: widget.width,
            color: widget.waterRippleColor,
            count: widget.count,
            controller: widget.waterRippleController,
          );
  }
}

class RadarPoint extends StatefulWidget {
  const RadarPoint(
      {super.key,
      required this.devices,
      this.width = 300,
      this.size = 15,
      this.image,
      this.onTap,
      required this.pointColor});

  final List devices;
  final double width; //两个组件合并在一起的宽高
  final double size; //点的大小
  final ImageProvider? image; //两个组件合并在一起的宽高
  final Color pointColor; //两个组件合并在一起的宽高
  final void Function(dynamic)? onTap; //两个组件合并在一起的宽高

  @override
  State<RadarPoint> createState() => _RadarPointState();
}

class _RadarPointState extends State<RadarPoint> {
  final List<Offset> blockPositions = [];

  // 一个圆形区域内随机生成一个点，但这个点不能与给定的blockPositions列表中的任何点过于接近（距离小于等于size）
  void generateRandomBlockPosition() {
    // 圆形区域半径
    double radius = widget.width / 2;
    final random = Random();
    Offset position;
    do {
      double angle = random.nextDouble() * 2 * pi;
      double distance = random.nextDouble() * radius;
      double x = radius + distance * cos(angle);
      double y = radius + distance * sin(angle);

      position = Offset(x, y);
    } while (blockPositions
        .any((offset) => (offset - position).distance <= widget.size));

    blockPositions.add(position);
  }

  void removeLastBlockPosition() {
    if (blockPositions.isNotEmpty) {
      blockPositions.removeLast();
    }
  }

  @override
  Widget build(BuildContext context) {
    print("-----------------:${widget.devices.length}");
    if (widget.devices.length > blockPositions.length &&
        widget.devices.length < 20) {
      for (var i = 0; i < widget.devices.length - blockPositions.length; i++) {
        generateRandomBlockPosition();
      }
    } else if (widget.devices.length < blockPositions.length &&
        widget.devices.length < 20) {
      for (var i = 0; i < blockPositions.length - widget.devices.length; i++) {
        removeLastBlockPosition();
      }
    }

    List<Widget> children = [];
    for (int i = 0; i < blockPositions.length; i++) {
      children.add(Positioned(
        left: blockPositions[i].dx,
        top: blockPositions[i].dy,
        child: InkWell(
          onTap: () {
            print(
                "widget.onTap?.${widget.devices}  i====${i}   ====================${widget.devices[i]["address"]}");
            widget.onTap?.call(widget.devices[i]);
          },
          child: widget.image == null
              ? Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.pointColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Center(
                    child: Container(
                      width: widget.size / 2,
                      height: widget.size / 2,
                      decoration: BoxDecoration(
                        color: widget.pointColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                )
              : Container(
                  width: widget.size,
                  // height: widget.size,
                  child: Column(
                    children: [
                      Image(
                        image: widget.image!,
                      ),
                      Text(
                        widget.devices[i]["name"] ?? "null",
                        style: TextStyle(fontSize: 12),
                      )
                    ],
                  ),
                ),
        ),
      ));
    }
    return Stack(children: children);
  }
}

//测试使用
class RadarTest11 extends StatefulWidget {
  const RadarTest11({super.key});

  @override
  State<RadarTest11> createState() => _RadarTest11State();
}

class _RadarTest11State extends State<RadarTest11>
    with TickerProviderStateMixin {
  late AnimationController waterRippleController;
  late AnimationController radarViewController;
  int num = 3;
  @override
  void initState() {
    super.initState();
    waterRippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    radarViewController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    super.dispose();
    waterRippleController.dispose();
    radarViewController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RadarPoint(
          pointColor: Color.fromARGB(255, 59, 53, 183),
          devices: [],
        ),
        RadarPage(
          width: double.infinity,
          waterRippleController: waterRippleController,
          radarViewController: radarViewController,
          waterRippleColor: Color.fromARGB(66, 209, 208, 208),
          radarViewColor: const Color(0xFF0080ff),
          count: 2,
        ),
      ],
    );

    // Column(
    //   mainAxisSize: MainAxisSize.min,
    //   children: [
    //     Container(
    //       child:
    //     ),
    // TextButton(
    //     onPressed: () {
    //       waterRippleController.stop();
    //       radarViewController.stop();
    //     },
    //     child: Text("停止动画")),
    // TextButton(
    //     onPressed: () {
    //       waterRippleController.repeat();
    //       radarViewController.repeat();
    //     },
    //     child: Text("开始动画")),
    // TextButton(
    //     onPressed: () {
    //       setState(() {
    //         num = num + 1;
    //       });
    //     },
    //     child: Text("添加"))
    // ],
    // );
  }
}

/// 喇叭样式
class TrumpetPage extends StatefulWidget {
  const TrumpetPage({
    super.key,
    this.width = 300,
    this.count = 3,
    this.waterRippleColor = const Color(0xFF0080ff),
    this.waterRippleController,
    this.radarViewColor = Colors.white,
    this.radarViewController,
  });
  final double? width; //两个组件合并在一起的宽高

  final int count; //涟漪的个数
  final Color waterRippleColor; //涟漪的颜色
  final AnimationController? waterRippleController; //涟漪动画控制器

  final Color radarViewColor; //雷达扫描指针的颜色
  final AnimationController? radarViewController; //雷达扫描动画控制器

  @override
  State<TrumpetPage> createState() => _TrumpetPageState();
}

class _TrumpetPageState extends State<TrumpetPage> {
  final List<Offset> blockPositions = [];
  String image = "assets/images/小喇叭.png";
  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();

  //   Future.delayed(Duration(seconds: 1)).then((value) => {
  //         widget.radarViewController?.addStatusListener((status) {
  //           // if (image == "assets/images/喇叭关闭.png") {
  //           //   setState(() {
  //           //     image = "assets/images/小喇叭.png";
  //           //   });
  //           // } else {
  //           //   setState(() {
  //           //     image = "assets/images/喇叭关闭.png";
  //           //   });
  //           // }
  //           print(status);
  //           if (status == AnimationStatus.completed) {
  //             setState(() {
  //               image = "assets/images/喇叭关闭.png";
  //             });
  //           } else {
  //             setState(() {
  //               image = "assets/images/小喇叭.png";
  //             });
  //           }
  //         })
  //       });
  // }

  @override
  Widget build(BuildContext context) {
    Color color = ui.Color.fromARGB(255, 160, 156, 243);

    double height = (widget.width! * 0.8);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Stack(children: [
          Positioned(
            child: SizedBox(
              width: widget.width,
              height: height,
              child: WaterRipple(
                count: widget.count,
                isFill: false,
                location: 1,
                color: ui.Color.fromARGB(64, 189, 189, 189),
                controller: widget.radarViewController,
                width: widget.width,
              ),
            ),
          ),
        ]),
        Positioned(
          top: -10,
          // left: 4,
          right: -10,
          child: Transform.rotate(
            // angle: 30* (pi / 180), // 旋转30度
            angle: 131 * (pi / 180), // 旋转30度
            child: Image.asset(
              image,
              color: Colors.blue, // ui.Color.fromARGB(64, 32, 235, 153),
              width: 30,
            ),
          ),
        ),
        Positioned(
          child: Container(
            width: widget.width,
            height: height,
            decoration: BoxDecoration(
                color: ui.Color.fromARGB(64, 166, 240, 211),
                borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }
}

/// 气泡式的招呼用语
class CallPoint extends StatefulWidget {
  const CallPoint({
    super.key,
    this.devicesNum = 0,
    this.width = 300,
  });

  final int devicesNum;
  final double width; //两个组件合并在一起的宽高

  @override
  State<CallPoint> createState() => _CallPointState();
}

class _CallPointState extends State<CallPoint> {
  final List<Offset> blockPositions = [];
  final int maxDevicesNum = 10;
  late double height;

  @override
  void initState() {
    super.initState();
    height = widget.width * 0.8;
  }

  void generateRandomBlockPosition() {
    double radius = (widget.width!) / 2 / 4 * 3;
    print(radius);
    final random = Random();
    Offset position;
    do {
      double angle = random.nextDouble() * 2 * pi;
      double distance = random.nextDouble() * radius;
      double x = radius + distance * cos(angle);
      double y = radius + distance * sin(angle);
      position = Offset(x, y);
    } while (
        blockPositions.any((offset) => (offset - position).distance <= 60) ||
            position.dy + 50 > height);

    blockPositions.add(position);
  }

  void removeLastBlockPosition() {
    if (blockPositions.isNotEmpty) {
      blockPositions.removeLast();
    }
  }

  @override
  Widget build(BuildContext context) {
    print("-----------------:${widget.devicesNum}");

    if (widget.devicesNum > blockPositions.length &&
        widget.devicesNum < maxDevicesNum) {
      for (var i = 0; i < widget.devicesNum - blockPositions.length; i++) {
        generateRandomBlockPosition();
      }
    } else if (widget.devicesNum < blockPositions.length &&
        widget.devicesNum < maxDevicesNum) {
      for (var i = 0; i < blockPositions.length - widget.devicesNum; i++) {
        removeLastBlockPosition();
      }
    }
    Color color = ui.Color.fromARGB(255, 59, 53, 183);
    double wid = 50;
    return Stack(
      children: blockPositions.map((offset) {
        return Positioned(
          left: offset.dx,
          top: offset.dy,
          child: Container(
            width: wid,
            height: wid * 0.6,
            child: Stack(
              children: [
                Image.asset(
                  "assets/images/group574.png",
                  color: Colors.blue,
                  width: 30,
                ),
                Positioned(
                  top: 6,
                  left: 10,
                  child: Text(
                    "Hi",
                    style: TextStyle(color: Colors.black, fontSize: 10),
                  ),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
