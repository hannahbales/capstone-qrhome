import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Loadable extends StatefulWidget {
  final bool isLoading;
  final Widget Function(BuildContext context) widgetBuilder;

  const Loadable({
    super.key,
    required this.isLoading,
    required this.widgetBuilder,
  });

  @override
  LoadableState createState() => LoadableState();
}

class LoadableState extends State<Loadable> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return LoadingAnimationWidget.waveDots(
        color: Colors.blue,
        size: 100.0,
      );
    } else {
      return widget.widgetBuilder(context);
    }
  }
}
