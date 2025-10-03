import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inviso/controllers/screenshot_controller.dart';
import 'package:inviso/screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Inviso',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
      initialBinding: BindingsBuilder(() {
        Get.put(ScreenshotController());
      }),
    );
  }
}
