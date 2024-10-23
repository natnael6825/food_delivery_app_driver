import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'splashscreen.dart';
import 'video_streaming_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is ready before anything else

  // Initialize WebRTC plugin (no changes needed here)
  await WebRTC.initialize();

  // Run the Flutter app
  runApp(MyApp());
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
      home: SplashScreen(), // Initial screen
    );
  }
}
