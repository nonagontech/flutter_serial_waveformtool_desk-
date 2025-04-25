import 'package:flutter/material.dart';
import 'dart:math';

class CicularProgress extends StatelessWidget {
  const CicularProgress({
    super.key,
    required this.size,
    required this.strokeWidth,
    this.isRounded = false,
    this.gapAngle = 0,
    this.startAngle = 0,
    this.clockwise = true,
    required this.color,
    this.gradient,
    this.child,
    this.showText = false,
    this.textGapAngle = 0,
    this.text,
    this.tickCount = 12,
    this.tickLongLength = 10,
    this.tickLongInterval = 1,
    this.tickInterval = 1,
    this.tickLowLength = 5,
    this.showTicks = false,
    this.tickLongColor = Colors.black,
    this.tickLongWidth = 2,
    this.tickLowColor = Colors.black,
    this.tickLowWidth = 2,
    this.overlapEndCaps = false,
    this.showTopWidget = false,
    required this.tickStartNum,
    required this.tickIntervalNum,
  });
  final double size;
  final double strokeWidth;
  final bool isRounded;
  final bool overlapEndCaps; // 是否重叠结束端点
  final double gapAngle;
  final double startAngle;
  final bool clockwise;
  final Color color;
  final Gradient? gradient;
  final Widget? child;
  final bool showText;
  final double textGapAngle;
  final String? text;
  final bool showTicks; // 是否显示刻度线
  final int tickCount; // 刻度线数量
  final int tickInterval; // 刻度线间隔

  final double tickLongLength; // 长刻度线长度
  final Color tickLongColor; // 长刻度线颜色
  final double tickLongWidth; //长刻度线宽度
  final double tickLongInterval; // 长刻度线间隔

  final double tickLowLength; // 短刻度线长度
  final Color tickLowColor; // 短刻度线颜色
  final double tickLowWidth; // 短刻度线宽度
  final bool showTopWidget; // 是否显示顶部组件

  final double tickStartNum; // 刻度线的起始值 默认值为0
  final double tickIntervalNum; // 刻度线的间隔代表的数值 默认值为1

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          child: CustomPaint(
            painter: RingPainter(
              strokeWidth: strokeWidth,
              isRounded: isRounded,
              overlapEndCaps: overlapEndCaps,
              gapAngle: gapAngle,
              startAngle: startAngle,
              clockwise: clockwise,
              color: color,
              gradient: gradient,
              showText: showText,
              textGapAngle: textGapAngle,
              text: text,
              tickCount: tickCount,
              tickLongLength: tickLongLength,
              tickLowLength: tickLowLength,
              tickLongColor: tickLongColor,
              tickLongWidth: tickLongWidth,
              tickLongInterval: tickLongInterval,
              showTicks: showTicks,
              tickInterval: tickInterval,
              tickLowColor: tickLowColor,
              tickLowWidth: tickLowWidth,
              showTopWidget: showTopWidget,
              tickIntervalNum: tickIntervalNum,
              tickStartNum: tickStartNum,
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

class RingPainter extends CustomPainter {
  final double strokeWidth;
  final bool isRounded;
  final bool overlapEndCaps; // 是否重叠结束端点
  final double gapAngle;
  final double startAngle;
  final bool clockwise;
  final Color color;
  final Gradient? gradient;
  final bool? showText;
  final double? textGapAngle;
  final String? text;
  final int tickCount;

  final int tickInterval; // 刻度线间隔
  final bool showTicks; //是否显示刻度线
  final double tickLongLength; // 长刻度线长度
  final Color tickLongColor; // 长刻度线颜色
  final double tickLongWidth; //长刻度线宽度
  final double tickLongInterval; // 长刻度线间隔

  final double tickLowLength; // 短刻度线长度
  final Color tickLowColor; // 短刻度线颜色
  final double tickLowWidth; // 短刻度线宽度

  final bool showTopWidget; // 是否显示顶部控件
  final double tickStartNum; // 刻度线的起始值
  final double tickIntervalNum; // 刻度线的间隔代表的数值

  RingPainter({
    required this.strokeWidth,
    required this.isRounded,
    required this.overlapEndCaps,
    required this.gapAngle,
    required this.startAngle,
    required this.clockwise,
    required this.color,
    required this.tickStartNum,
    required this.tickIntervalNum,
    this.showTopWidget = false,
    this.textGapAngle,
    this.gradient,
    this.showText,
    this.text,
    this.showTicks = false,
    this.tickCount = 12,
    this.tickLongLength = 10,
    this.tickLowLength = 5,
    this.tickLongInterval = 1,
    this.tickInterval = 1,
    this.tickLongColor = Colors.black,
    this.tickLongWidth = 2,
    this.tickLowColor = Colors.black,
    this.tickLowWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double radius = (size.width / 2) - strokeWidth / 2;
    Rect rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2), radius: radius);

    double asinData = asin(strokeWidth / (size.width - strokeWidth));
    double asinOffset = asinData * pi / 180;

    // 计算起始角度的偏移量，使圆帽左边缘对齐
    double angleOffset = (strokeWidth / 2) / radius;

    double startRadians1 = ((startAngle - 90) * pi / 180) + angleOffset;

    double startRadians = (startAngle - 90) * pi / 180;
    double sweepRadians = gapAngle * pi / 180;
    double textSweepRadians = (textGapAngle ?? 0) * pi / 180;

    if (!clockwise) {
      sweepRadians = (360 - gapAngle) * pi / 180;
      textSweepRadians = (360 - (textGapAngle ?? 0)) * pi / 180;
    }

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = isRounded ? StrokeCap.round : StrokeCap.butt
      ..color = color;

    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    }
    double angleStep = sweepRadians;
    if (!overlapEndCaps && isRounded) {
      angleStep = sweepRadians - angleOffset * 2;
      if (angleStep < 0 && gapAngle > 0) {
        angleStep = 0.001;
      }
    }
    if (!(isRounded && !overlapEndCaps)) {
      startRadians1 = startRadians;
    }
    if (gapAngle == 0) {
      startRadians1 = 0;
      angleStep = 0;
    }

    canvas.drawArc(rect, startRadians1, angleStep, false, paint);
    if (showTicks) {
      // 长刻度线
      Paint tickLongPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tickLongWidth
        ..color = tickLongColor;
      //短刻度线
      Paint tickLowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tickLowWidth
        ..color = tickLowColor;
      double angleStep = sweepRadians / tickCount;

      for (int i = 0; i <= tickCount;) {
        double tickRadius = radius - strokeWidth / 2;

        // double tickAngle = (i * 360 / tickCount) * pi / 180;
        double tickAngle = startRadians + i * angleStep;

        double innerX;
        double innerY;
        if (i % tickLongInterval == 0) {
          innerX =
              size.width / 2 + (tickRadius - tickLongLength) * cos(tickAngle);
          innerY =
              size.height / 2 + (tickRadius - tickLongLength) * sin(tickAngle);
        } else {
          innerX =
              size.width / 2 + (tickRadius - tickLowLength) * cos(tickAngle);
          innerY =
              size.height / 2 + (tickRadius - tickLowLength) * sin(tickAngle);
        }

        double outerX = size.width / 2 + tickRadius * cos(tickAngle);
        double outerY = size.height / 2 + tickRadius * sin(tickAngle);
        if (i % tickLongInterval == 0) {
          canvas.drawLine(
              Offset(innerX, innerY), Offset(outerX, outerY), tickLongPaint);
        } else {
          canvas.drawLine(
              Offset(innerX, innerY), Offset(outerX, outerY), tickLowPaint);
        }

        // 在刻度线上方添加文字
        if (i % tickLongInterval == 0) {
          // 这里的
          double textNum = i * tickIntervalNum + tickStartNum;
          int decimalPlaces = 0;
          //判断tickIntervalNum的小数是几位,textNum的小数就是几位
          List<String> tickIntervalArr = tickIntervalNum.toString().split('.');
          if (tickIntervalArr.length > 1) {
            String lastdata = tickIntervalArr[tickIntervalArr.length - 1];
            decimalPlaces = lastdata.length;
            if (decimalPlaces == 1 && lastdata == "0") {
              decimalPlaces = 0;
            }
          }

          String formattedTextNum = textNum.toStringAsFixed(decimalPlaces);
          List<String> formattedArr = formattedTextNum.split('.');
          if (formattedArr.length > 1) {
            String lastdata = formattedArr[tickIntervalArr.length - 1];
            int decimalPlaces = lastdata.length;
            if (decimalPlaces == 1 && lastdata == "0") {
              formattedTextNum = formattedArr[0];
            }
          }

          TextPainter textPainter = TextPainter(
            text: TextSpan(
              text: formattedTextNum, // 显示刻度编号
              style: TextStyle(color: Colors.black, fontSize: 12.0),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          double textX = size.width / 2 +
              (radius - strokeWidth / 2 - tickLongLength - 15) * cos(tickAngle);
          double textY = size.height / 2 +
              (radius - strokeWidth / 2 - tickLongLength - 15) * sin(tickAngle);
          Offset textOffset = Offset(
              textX - textPainter.width / 2, textY - textPainter.height / 2);
          textPainter.paint(canvas, textOffset);
        }
        i = i + tickInterval;
      }
    }

    if (showText == true) {
      double endAngle = textSweepRadians;

      double endX =
          size.width / 2 + (size.width / 2) * cos(endAngle - startRadians);
      double endY =
          size.width / 2 + (size.width / 2) * sin(endAngle - startRadians);
      double radius1 = (size.width / 2) - strokeWidth;

      double endX1 = size.width / 2 + radius1 * cos(endAngle - startRadians);
      double endY1 = size.width / 2 + radius1 * sin(endAngle - startRadians);
      Paint paint1 = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.butt
        ..color = Colors.black;
      // 绘制从圆心到圆环最后一点的连线
      canvas.drawLine(
        // Offset(size.width / 2, size.height / 2),
        Offset(endX, endY),
        Offset(endX1, endY1),

        paint1,
      );
      // 在线的顶端写文字
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: text ?? "",
          style: TextStyle(color: Colors.black, fontSize: 12.0),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(); // 进行布局
      Offset textOffset = Offset(endX - textPainter.width / 2 - 5,
          endY - textPainter.height - 5); // 确定文字位置
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
