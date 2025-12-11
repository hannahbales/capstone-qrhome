// import 'package:app/home.dart';
import 'package:app/signin.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(qrHomeApp());
}

Widget qrHomeApp({Widget? startPage}) {
  return MaterialApp(
    title: 'Main',
    home: startPage ?? SignIn(),
  );
}
