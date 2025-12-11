import 'package:flutter/material.dart';

class QScaffold extends Scaffold {
  final String title;
  final Icon? icon;

  QScaffold({
    super.key,
    required this.title,
    this.icon,
    super.body,
  }) : super(appBar: _constuctAppBar(title, icon));

  static AppBar _constuctAppBar(String title, Icon? icon) {
    List<Widget> children = [
      Text(
        'QRHome',
        style: TextStyle(
          fontSize: 36.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
    if (icon != null) {
      children.insert(0, icon);
    }
    return AppBar(
      backgroundColor: Color(0xFF4169E1),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8.0,
        children: children,
      ),
      centerTitle: true,
      toolbarHeight: 80,
    );
  }
}
