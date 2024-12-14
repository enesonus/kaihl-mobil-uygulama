import 'package:flutter/material.dart';

class MyStatelessWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stateless Widget Example'),
        backgroundColor: Colors.blueAccent, // AppBar color
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Hello, this is a simple Stateless Widget! Hello, this is a simple Stateless Widget!Hello, this is a simple Stateless Widget!Hello, this is a simple Stateless Widget!',
              style: TextStyle(
                fontSize: 18, // Text size
                color: Colors.blueAccent, // Text color
              ),
              textAlign: TextAlign.center, // Center the text
            ),
          )
        ],
      ),
    );
  }
}
