import 'package:attendancewithqr/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(about_title),
      ),
      body: Container(
        margin: EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image(
              image: AssetImage('images/logo.png'),
            ),
            SizedBox(
              height: 20.0,
            ),
            Center(
              child: Text(
                about_app_name,
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                    fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Text(
              about_developer,
              style: GoogleFonts.quicksand(fontSize: 13.0, color: Colors.grey),
            ),
            Text(
              about_url,
              style: GoogleFonts.quicksand(fontSize: 13.0, color: Colors.grey),
            ),
            SizedBox(
              height: 20.0,
            ),
            Text(
              about_desc,
              style: GoogleFonts.quicksand(fontSize: 15.0, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
