import 'package:flutter/material.dart';
import 'package:sharile/screens/home_screen.dart';
import 'package:sharile/screens/receive_screen.dart';
import 'package:sharile/screens/send_screen.dart';

void main() => runApp(SharileApp());

class SharileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: HomeScreen.id,
      routes: {
        HomeScreen.id: (context) => HomeScreen(),
        SendScreen.id: (context) => SendScreen(),
        ReceiveScreen.id: (context) => ReceiveScreen(),
      },
    );
  }
}
