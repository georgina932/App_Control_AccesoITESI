import 'package:attendancewithqr/screen/scan_qr_page.dart';
import 'package:attendancewithqr/utils/strings.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: main_title,
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          // change the appbar color
          primary: Color(0xFF0E67B4),
        ),
      ),
      home: ScanQrPage(),
    );
  }
}
