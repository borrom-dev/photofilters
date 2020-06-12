import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ContainerRectangle extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final MemoryImage memoryImage;

  const ContainerRectangle(
      {Key key,
      this.child,
      this.backgroundColor = Colors.white,
      this.memoryImage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: memoryImage == null
          ? null
          : BoxDecoration(
              image: new DecorationImage(fit: BoxFit.cover, image: memoryImage),
            ),
      child: ClipRect(child: child),
    );
  }
}
