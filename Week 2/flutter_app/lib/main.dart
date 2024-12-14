import 'package:flutter/material.dart';
import 'package:flutter_app/stateful_widget_sample.dart';
import 'package:flutter_app/stateless_widget_sample.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home:  MyStatefulWidget(),
    );
  }
}