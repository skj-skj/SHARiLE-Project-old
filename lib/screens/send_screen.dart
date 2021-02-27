import 'package:flutter/material.dart';
import 'package:sharile/components/next_screen_widget.dart';
import 'package:sharile/brain/server_brain.dart';

class SendScreen extends StatelessWidget {
  static const String id = 'Send_screen';
  static final sendServer = ServerBrain();

  @override
  Widget build(BuildContext context) {
//    sendServer.sendFilePick();
    sendServer.sendFile();
    return NextScreen(server: sendServer);
  }
}
