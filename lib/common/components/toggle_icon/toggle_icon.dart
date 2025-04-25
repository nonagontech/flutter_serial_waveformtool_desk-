import 'package:flutter/material.dart';

class ToggleIcon extends StatefulWidget {
  const ToggleIcon(
      {super.key,
      this.padding,
      this.margin,
      required this.onIcon,
      required this.offIcon});
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Icon onIcon;
  final Icon offIcon;

  @override
  State<ToggleIcon> createState() => _ToggleIconState();
}

class _ToggleIconState extends State<ToggleIcon> {
  late Icon currentIcon;

  @override
  void initState() {
    super.initState();
    currentIcon = widget.offIcon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      margin: widget.margin,
      child: GestureDetector(
        child: currentIcon,
        onTap: () {
          setState(() {
            currentIcon = currentIcon.icon == widget.onIcon.icon
                ? widget.offIcon
                : widget.onIcon;
          });
        },
        // onTapCancel: () {
        //   Log.i("onTapCancel");
        //   setState(() {
        //     iconData = offIcon;
        //   });
        // },
      ),
    );
  }
}
