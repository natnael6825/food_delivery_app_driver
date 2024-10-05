import 'package:flutter/material.dart';

import 'home.dart';
import 'splashscreen.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() async{

   WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
    await WebRTC.initialize();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
