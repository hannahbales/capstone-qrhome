import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

Widget qLoadingWidget() {
  return Flex(
    direction: Axis.vertical,
    children: [
      Expanded(
        child: Center(
          child: LoadingAnimationWidget.waveDots(
            color: Colors.blue,
            size: 100.0,
          ),
        ),
      ),
    ],
  );
}
