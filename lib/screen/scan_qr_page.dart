import 'dart:async';
import 'dart:convert';

import 'package:attendancewithqr/database/db_helper.dart';
import 'package:attendancewithqr/model/settings.dart';
import 'package:attendancewithqr/screen/main_menu_page.dart';
import 'package:attendancewithqr/utils/strings.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

import '../utils/utils.dart';

class ScanQrPage extends StatefulWidget {
  @override
  _ScanQrPageState createState() => new _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  DbHelper dbHelper = DbHelper();
  Utils utils = Utils();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String _barcode = "";
  Settings settings;
  String _isAlreadyDoSettings = 'loading';

  Future scan() async {
    try {
      var barcode = await BarcodeScanner.scan();
      // The value of Qr Code
      // Return the json data
      // We need replaceAll because Json from web use single-quote ({' '}) not double-quote ({" "})
      final newJsonData = barcode.rawContent.replaceAll("'", '"');
      var data = jsonDecode(newJsonData);
      // Check the type of barcode
      if (data['url'] != null && data['key'] != null) {
        // Decode the json data form QR
        String getUrl = data['url'];
        String getKey = data['key'];

        // Set the url and key
        settings = Settings(url: getUrl, key: getKey);
        // Insert the settings
        insertSettings(settings);
      } else {
        utils.showAlertDialog(format_barcode_wrong, "Error", AlertType.error,
            _scaffoldKey, false);
      }
    } on PlatformException catch (e) {
      setState(() {
        _isAlreadyDoSettings = 'no';
      });
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        _barcode = barcode_permission_cam_close;
        utils.showAlertDialog(
            _barcode, "Warning", AlertType.warning, _scaffoldKey, false);
      } else {
        _barcode = '$barcode_unknown_error $e';
        utils.showAlertDialog(
            _barcode, "Error", AlertType.error, _scaffoldKey, false);
      }
    } catch (e) {
      _barcode = '$barcode_unknown_error : $e';
      print(_barcode);
    }
  }

  // Insert the URL and KEY
  insertSettings(Settings object) async {
    await dbHelper.newSettings(object);
    setState(() {
      _isAlreadyDoSettings = 'yes';
      goToMainMenu();
    });
  }

  getSettings() async {
    var checking = await dbHelper.countSettings();
    setState(() {
      checking > 0 ? _isAlreadyDoSettings = 'yes' : _isAlreadyDoSettings = 'no';
      goToMainMenu();
    });
  }

  // Init for the first time
  @override
  void initState() {
    super.initState();
    splashScreen();
  }

  // Show splash scree with time duration
  splashScreen() async {
    var duration = const Duration(seconds: 5);
    return Timer(duration, () {
      getSettings();
    });
  }

  // Got to main menu after scanning the QR or if user scanned the QR.
  goToMainMenu() {
    if (_isAlreadyDoSettings == 'yes') {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainMenuPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user already do settings
    if (_isAlreadyDoSettings == 'no') {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0E67B4),
          key: _scaffoldKey,
          body: Container(
            margin: EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(
                  image: AssetImage('images/logo.png'),
                ),
                SizedBox(
                  height: 10.0,
                ),
                AutoSizeText(
                  setting_welcome_title,
                  style: GoogleFonts.quicksand(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 20.0,
                ),
                AutoSizeText(
                  setting_desc,
                  style: GoogleFonts.quicksand(
                      fontSize: 12.0, color: Colors.grey[300]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 40.0,
                ),
                // ignore: deprecated_member_use
                ElevatedButton(
                  onPressed: () => scan(),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Color(0xFF003D84),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                  ),
                  child: Text(button_scan,
                  style: GoogleFonts.quicksand(
                      color: Colors.white, fontSize: 12.0),
                ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Color(0xFF0E67B4),
      child: Center(
        child: Image(
          image: AssetImage('images/logo.png'),
        ),
      ),
    );
  }
}
