import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.white,
      title: 'Flutter Demo',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Stateless Widget Example'),
          backgroundColor: Colors.blueAccent, // AppBar color
        ),
        body: MyStatefulWidget(),
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({super.key});

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  String myText = "Kartal AIHL Mobil STATEFUL uygulama geliştirme dersleri";
  Color textColor = Colors.blue;
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          myText,
          style: TextStyle(color: textColor),
        ),
        ElevatedButton(
            onPressed: () {
              setState(() {
                myText = myText + " Tiklandi";
                textColor = Colors.red;
              });

              print("Tiklandi");
            },
            child: Text("Tikla"))
      ]),
    );
  }
}

class MyStatelessWidget extends StatelessWidget {
  String text = "Kartal AIHL Mobil STATEFUL uygulama geliştirme dersleri";
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(text),
        ElevatedButton(
            onPressed: () {
              print("Tiklandi");
            },
            child: Text("Tikla"))
      ]),
    );
  }
}
