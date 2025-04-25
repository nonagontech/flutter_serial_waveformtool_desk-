import 'dart:math';

import 'package:flutter/material.dart';

/// 定制switch
class MySwitch extends StatefulWidget {
  const MySwitch({
    super.key,
    required this.value,
    this.bgColor,
    this.bgBorderColor,
    this.bgOpenBorderColor,
    this.bgBorderWidth,
    this.openBgColor,
    this.color,
    this.openColor,
    this.width,
    this.height,
    this.borderColor,
    this.openBorderColor,
    this.borderWidth,
    required this.onChanged,
  });

  final bool value; // 开关的状态
  final ValueChanged<bool>? onChanged; //状态改变的回调

  final double? width; //开关的宽度
  final double? height; //开关的高度

  final Color? bgBorderColor; //关闭时的边框的颜色
  final Color? bgOpenBorderColor; //打开时的边框的颜色
  final double? bgBorderWidth; //边框的宽度

  final Color? bgColor; //关闭时的背景颜色
  final Color? openBgColor; //打开时的背景颜色

  final Color? color; //关闭时的中间按钮的颜色
  final Color? openColor; //打开时的中间按钮的颜色

  final Color? borderColor; //关闭时的中间边框颜色
  final Color? openBorderColor; //打开时中间按钮边框颜色
  final double? borderWidth; //中间按钮的边框宽度

  @override
  State<MySwitch> createState() => _MySwitchState();
}

class _MySwitchState extends State<MySwitch> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<Color?> _bgColorAnimation;
  late Animation<Color?> _bgBorderColorAnimation;
  late Animation<Color?> _borderColorAnimation;

  bool _switchOpen = false;

  // Color _bgColor = Colors.grey;
  // Color _openBgColor = Colors.lightGreen;
  // Color _color = Colors.grey;
  // Color _openColor = Colors.lightGreen;

  // Color _bgBorderColor = Colors.grey;
  // Color _bgOpenBorderColor = Colors.lightGreen;

  // Color _borderColor = Colors.grey;
  // Color _openBorderColor = Colors.lightGreen;

  double _width = 55.0;
  double _height = 26.0;
  double _minSize = 30.0;

  bool _isAnimating = false; // 动画中

  final double _space = 2.0;

  bool _isStartAnimating = false;

  @override
  void initState() {
    _switchOpen = widget.value;

    // _bgColor = widget.bgColor ?? Colors.grey;
    // _openBgColor = widget.openBgColor ?? Colors.lightGreen;
    // _color = widget.color ?? Colors.white;
    // _openColor = widget.openColor ?? Colors.white;

    // _bgBorderColor = widget.bgBorderColor ?? Colors.black12;
    // _bgOpenBorderColor = widget.bgOpenBorderColor ?? Colors.lightBlueAccent;

    // _borderColor = widget.borderColor ?? Colors.black12;
    // _openBorderColor = widget.openBorderColor ?? Colors.white;

    if (widget.width != null) {
      _width = widget.width!;
    }
    if (widget.height != null) {
      _height = widget.height!;
    }

    _minSize = min(_width, _height) - _space;

    super.initState();

    runAnimation();
  }

  void runAnimation() {
    Color bgBeginColor;
    Color bgEndColor;

    Color beginColor;
    Color endColor;

    double beginP;
    double endP;

    Color bgBorderBeginColor;
    Color bgBorderEndColor;

    Color borderBeginColor;
    Color borderEndColor;

    Color _bgColor = widget.bgColor ?? Colors.grey;
    Color _openBgColor = widget.openBgColor ?? Colors.lightGreen;
    Color _color = widget.color ?? Colors.white;
    Color _openColor = widget.openColor ?? Colors.white;

    Color _bgBorderColor = widget.bgBorderColor ?? Colors.black12;
    Color _bgOpenBorderColor =
        widget.bgOpenBorderColor ?? Colors.lightBlueAccent;

    Color _borderColor = widget.borderColor ?? Colors.black12;
    Color _openBorderColor = widget.openBorderColor ?? Colors.white;

    if (_switchOpen) {
      bgBeginColor = _openBgColor;
      bgEndColor = _bgColor;

      beginColor = _openColor;
      endColor = _color;

      bgBorderBeginColor = _bgOpenBorderColor;
      bgBorderEndColor = _bgBorderColor;

      borderBeginColor = _openBorderColor;
      borderEndColor = _borderColor;

      beginP = _width - _minSize - _space;
      endP = _space;
    } else {
      bgBeginColor = _bgColor;
      bgEndColor = _openBgColor;

      beginColor = _color;
      endColor = _openColor;

      bgBorderBeginColor = _bgBorderColor;
      bgBorderEndColor = _bgOpenBorderColor;

      borderBeginColor = _borderColor;
      borderEndColor = _openBorderColor;

      beginP = _space;
      endP = _width - _minSize - _space;
    }

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    // 移动位置
    _positionAnimation = Tween<double>(
      begin: beginP,
      end: endP,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0, 1.0, //间隔，后20%的动画时间
          curve: Curves.ease,
        ),
      ),
    );

    _colorAnimation = ColorTween(
      begin: beginColor,
      end: endColor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0, 1.0, //间隔，前60%的动画时间
          curve: Curves.ease,
        ),
      ),
    );

    _bgColorAnimation = ColorTween(
      begin: bgBeginColor,
      end: bgEndColor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0, 1.0, //间隔，前60%的动画时间
          curve: Curves.ease,
        ),
      ),
    );

    _bgBorderColorAnimation = ColorTween(
      begin: bgBorderBeginColor,
      end: bgBorderEndColor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0, 1.0, //间隔，前60%的动画时间
          curve: Curves.ease,
        ),
      ),
    );

    _borderColorAnimation = ColorTween(
      begin: borderBeginColor,
      end: borderEndColor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0, 1.0, //间隔，前60%的动画时间
          curve: Curves.ease,
        ),
      ),
    );

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimating = false;
        _isStartAnimating = true;
      }
    });
  }

  void animationDispose() {
    _controller.dispose();
  }

  void onSwitchPressed() {
    if (_isAnimating) {
      return;
    }

    _isAnimating = true;

    if (_isStartAnimating) {
      _switchOpen = !_switchOpen;
    }
    runAnimation();
    _controller.forward();
  }

  @override
  void dispose() {
    animationDispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MySwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 检查 id 是否变化
    if (widget.value != oldWidget.value) {
      onSwitchPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    double radius = _minSize / 2.0;
    double bgRadius = _height / 2.0;
    return GestureDetector(
      onTap: () {
        if (_isAnimating) {
          return;
        }
        widget.onChanged!(!widget.value);
      },
      child: SizedBox(
        width: _width,
        height: _height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _width,
              height: _height,
              decoration: BoxDecoration(
                color: _bgColorAnimation.value,
                borderRadius: BorderRadius.circular(bgRadius),
                border: Border.all(
                  color: _bgBorderColorAnimation.value ?? Colors.transparent,
                  width: widget.bgBorderWidth ?? 0,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            Positioned(
              left: _positionAnimation.value,
              child: Container(
                width: _minSize,
                height: _minSize,
                decoration: BoxDecoration(
                  color: _colorAnimation.value,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: _borderColorAnimation.value ?? Colors.transparent,
                    width: widget.borderWidth ?? 0,
                    style: widget.borderWidth == null || widget.borderWidth == 0
                        ? BorderStyle.none
                        : BorderStyle.solid,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
