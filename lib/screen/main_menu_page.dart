import 'package:android_intent_plus/android_intent.dart';
import 'package:attendancewithqr/screen/attendance_page.dart';
import 'package:attendancewithqr/screen/report_page.dart';
import 'package:attendancewithqr/screen/setting_page.dart';
import 'package:attendancewithqr/utils/single_menu.dart';
import 'package:attendancewithqr/utils/strings.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'about_page.dart';

class MainMenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Menu();
  }
}

class Menu extends StatefulWidget {
  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  @override
  void initState() {
    _getPermission();
    super.initState();
  }

  void _getPermission() async {
    getPermissionAttendance();
    _checkGps();
  }

  void getPermissionAttendance() async {
    await [
      Permission.camera,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
  }

  final ButtonStyle flatButtonStyle = TextButton.styleFrom(
    foregroundColor: Colors.black87,
    minimumSize: Size(88, 36),
    padding: EdgeInsets.symmetric(horizontal: 16.0),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2.0)),
    ),
  );

  // Check the GPS is on
  Future _checkGps() async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(main_menu_popup_gps_title),
              content: const Text(main_menu_popup_gps_desc),
              actions: <Widget>[
                // ignore: deprecated_member_use
                TextButton(
                  style: flatButtonStyle,
                  child: Text(main_menu_popup_gps_button),
                  onPressed: () async {
                    final AndroidIntent intent = AndroidIntent(
                        action: 'android.settings.LOCATION_SOURCE_SETTINGS');

                    await intent.launch();
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            margin: EdgeInsets.only(bottom: 40.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 250.0,
                  color: Color(0xFF0E67B4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image(
                        image: AssetImage('images/logo.png'),
                      ),
                      SizedBox(
                        width: 10.0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AutoSizeText(
                            main_menu_hi,
                            style: GoogleFonts.quicksand(
                                fontSize: 20.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          AutoSizeText(
                            main_menu_title,
                            style: GoogleFonts.quicksand(
                                fontSize: 15.0,
                                color: Color(0xB4FFFFFF),
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SingleMenu(
                  icon: FontAwesomeIcons.clock,
                  menuName: main_menu_check_in,
                  textDesc: main_menu_check_in_dec,
                  color: Colors.blue,
                  action: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AttendancePage(
                        query: 'in',
                        title: main_menu_check_in_title,
                      ),
                    ),
                  ),
                ),
                SingleMenu(
                  icon: FontAwesomeIcons.rightFromBracket,
                  menuName: main_menu_check_out,
                  textDesc: main_menu_check_out_dec,
                  color: Colors.teal,
                  action: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AttendancePage(
                        query: 'out',
                        title: main_menu_check_out_title,
                      ),
                    ),
                  ),
                ),
                SingleMenu(
                  icon: FontAwesomeIcons.gears,
                  menuName: main_menu_settings,
                  textDesc: main_menu_settings_dec,
                  color: Colors.green,
                  action: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SettingPage()),
                  ),
                ),
                SingleMenu(
                  icon: FontAwesomeIcons.calendar,
                  menuName: main_menu_report,
                  textDesc: main_menu_report_dec,
                  color: Colors.pinkAccent[700],
                  action: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ReportPage()),
                  ),
                ),
                SingleMenu(
                  icon: FontAwesomeIcons.userLarge,
                  menuName: main_menu_about,
                  textDesc: main_menu_about_dec,
                  color: Colors.purple,
                  action: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => AboutPage()),
                  ),
                ),
                SingleMenu(
                    icon: FontAwesomeIcons.info,
                    menuName: 'v 1.0',
                    textDesc: main_menu_version_dec,
                    color: Colors.red[300]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
