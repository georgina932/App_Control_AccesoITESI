import 'dart:async';

import 'package:attendancewithqr/model/attendance.dart';
import 'package:attendancewithqr/utils/strings.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:trust_location/trust_location.dart';

import '../database/db_helper.dart';
import '../model/settings.dart';
import '../utils/utils.dart';

class AttendancePage extends StatefulWidget {
  final String query;
  final String title;

  AttendancePage({this.query, this.title});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Progress dialog
  ProgressDialog pr;

  // Database
  DbHelper dbHelper = DbHelper();

  // Utils
  Utils utils = Utils();

  // Model settings
  Settings settings;

  // Global key scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // String
  String getUrl,
      getKey,
      _barcode = "",
      getQuery,
      getPath = 'api/attendance/apiSaveAttendance',
      mAccuracy;

  var getQrId;
  bool _isMockLocation, clickButton = false;

  // Geolocation
  Position _currentPosition;
  String _currentAddress;
  final Geolocator geoLocator = Geolocator();
  var subscription;
  double setAccuracy = 200.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    getSettings();
    TrustLocation.start(5);
    checkMockInfo();
  }

  @override
  void dispose() {
    TrustLocation.stop();
    super.dispose();
  }

  // Get latitude longitude
  _getCurrentLocation() {
    subscription = Geolocator.getPositionStream().listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });

        _getAddressFromLatLng(_currentPosition.accuracy);
      }
    });
  }

  // Checking Mock (fake GPS)
  checkMockInfo() async {
    try {
      TrustLocation.onChange
          .listen((values) => _isMockLocation = values.isMockLocation);
    } on PlatformException catch (e) {
      print('PlatformException $e');
    }
  }

  // Get address
  _getAddressFromLatLng(double accuracy) async {
    String strAccuracy = accuracy.toStringAsFixed(1);
    if (accuracy > setAccuracy) {
      mAccuracy = '$strAccuracy $attendance_not_accurate';
    } else {
      mAccuracy = '$strAccuracy $attendance_accurate';
    }
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark placeMark = p[0];
      if (mounted) {
        setState(() {
          _currentAddress =
              "$mAccuracy ${placeMark.name}, ${placeMark.subLocality}, ${placeMark.subAdministrativeArea} - ${placeMark.administrativeArea}.";
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // Get settings data
  void getSettings() async {
    var getSettings = await dbHelper.getSettings(1);
    setState(() {
      getUrl = getSettings.url;
      getKey = getSettings.key;
    });
  }

  // Send data post via http
  sendData() async {
    // Add data to map
    Map<String, dynamic> body = {
      'location': _currentAddress,
      'key': getKey,
      'qr_id': getQrId,
      'q': getQuery,
    };

    // Sending the data to server
    final uri = utils.getRealUrl(getUrl, getPath);
    Dio dio = new Dio();
    FormData formData = new FormData.fromMap(body);
    final response = await dio.post(uri, data: formData);

    var data = response.data;

    print(data);

    // Show response from server
    if (data['message'] == 'Success!') {
      // Set the url and key
      Attendance attendance = Attendance(
          date: data['date'],
          time: data['time'],
          location: data['location'],
          type: data['query']);

      // Insert the settings
      insertAttendance(attendance);

      // Hide the loading
      Future.delayed(Duration(seconds: 2)).then((value) {
        if (mounted) {
          setState(() {
            subscription.cancel();

            pr.hide();

            utils.showAlertDialog(
                "$attendance_show_alert-$getQuery $attendance_success_ms",
                "Success",
                AlertType.success,
                _scaffoldKey,
                true);
          });
        }
      });
    } else if (data['message'] == 'already check-in') {
      setState(() {
        pr.hide();

        utils.showAlertDialog(
            already_check_in, "warning", AlertType.warning, _scaffoldKey, true);
      });
    } else if (data['message'] == 'check-in first') {
      setState(() {
        pr.hide();

        utils.showAlertDialog(
            check_in_first, "warning", AlertType.warning, _scaffoldKey, true);
      });
    } else if (data['message'] == 'Error Qr!') {
      setState(() {
        pr.hide();

        utils.showAlertDialog(
            format_barcode_wrong, "Error", AlertType.error, _scaffoldKey, true);
      });
    } else if (data['message'] == 'Error! Something Went Wrong!') {
      setState(() {
        pr.hide();

        utils.showAlertDialog(attendance_error_server, "Error", AlertType.error,
            _scaffoldKey, true);
      });
    } else {
      setState(() {
        pr.hide();

        utils.showAlertDialog(response.data.toString(), "Error",
            AlertType.error, _scaffoldKey, true);
      });
    }
  }

  insertAttendance(Attendance object) async {
    await dbHelper.newAttendances(object);
  }

  // Scan the QR name of user
  Future scan() async {
    try {
      var barcode = await BarcodeScanner.scan();
      // The value of Qr Code

      if (barcode != null && barcode.rawContent != '') {
        setState(() {
          // Show dialog
          pr.show();

          // Get name from QR
          getQrId = barcode.rawContent;
          // Sending the data
          sendData();
        });
      }
      //-- Optional if you want to show message when user click back button or cancel button, then uncomment this code --
      // else {
      //   utils.showAlertDialog(
      //       '$barcode_empty', "Error", AlertType.error, _scaffoldKey, true);
      // }
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        _barcode = '$camera_permission';
        utils.showAlertDialog(
            _barcode, "Warning", AlertType.warning, _scaffoldKey, true);
      } else {
        _barcode = '$barcode_unknown_error $e';
        utils.showAlertDialog(
            _barcode, "Error", AlertType.error, _scaffoldKey, true);
      }
    } catch (e) {
      _barcode = '$barcode_unknown_error : $e';
      print(_barcode);
    }
  }

  // This function is about checking if the user uses Mock (Fake GPS) to make attendance
  checkMockIsNull() async {
    // Check if user click button attendance
    if (clickButton) {
      // Check mock is already get status
      if (_isMockLocation == null) {
        Future.delayed(Duration(seconds: 0)).then((value) {
          // Check if pr is showing or not
          if (!pr.isShowing()) {
            pr.show();
            pr.update(
              progress: 50.0,
              message: check_mock,
              progressWidget: Container(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator()),
              maxProgress: 100.0,
              progressTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w400),
              messageTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 19.0,
                  fontWeight: FontWeight.w600),
            );
          }
        });
      } else if (_isMockLocation == true) {
        // If there user use mock location means uses fake gps
        // Will show warning alert
        Future.delayed(Duration(seconds: 0)).then((value) {
          // Detect mock is true, mean user use fake gps
          setState(() {
            clickButton = false;
            if (pr.isShowing()) {
              pr.hide();
            }
          });

          utils.showAlertDialog(
              fake_gps, "warning", AlertType.warning, _scaffoldKey, true);
        });
      } else {
        // If user not use fake gps
        Future.delayed(Duration(seconds: 0)).then((value) async {
          setState(() {
            clickButton = false;
            if (pr.isShowing()) {
              pr.hide();
            }
          });

          // If already get mock will continue show camera for scan the QR code
          scan();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show progress
    pr = new ProgressDialog(context,
        isDismissible: false, type: ProgressDialogType.Normal);
    // Style progress
    pr.style(
        message: attendance_sending,
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        padding: EdgeInsets.all(10.0),
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));

    // Init the query
    getQuery = widget.query;

    // Check if user use fake gps
    checkMockIsNull();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$attendance_accurate_info $mAccuracy $attendance_on_gps',
              style: GoogleFonts.quicksand(
                  color: Colors.grey[800], fontSize: 14.0),
              textAlign: TextAlign.center,
            ),
            Container(
              margin: EdgeInsets.all(20.0),
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton(
                child: Text(
                  button_scan,
                  style: GoogleFonts.quicksand(
                      color: Colors.white, fontSize: 12.0),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Color(0xFF003D84),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                onPressed: () {
                  clickButton = true;
                },
              ),
            ),
            Text(
              '$attendance_button_info-$getQuery.',
              style: GoogleFonts.quicksand(color: Colors.grey, fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }
}
