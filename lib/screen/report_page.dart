import 'package:attendancewithqr/database/db_helper.dart';
import 'package:attendancewithqr/model/attendance.dart';
import 'package:attendancewithqr/utils/strings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../utils/utils.dart';

class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DbHelper dbHelper = DbHelper();
  Future<List<Attendance>> attendances;
  String dateFromVal, dateToVal;
  int totalData = 0;

  TextEditingController dateFrom = TextEditingController();
  TextEditingController dateTo = TextEditingController();

  @override
  void initState() {
    super.initState();
    getData();
  }

  // Init filter by date
  DateTime selectedDateFrom = DateTime.now();
  DateTime selectedDateTo = DateTime.now();

  _selectTheFrom(BuildContext context) async {
    var picked = await Utils().selectDate(context, DateTime(1980));
    if (picked != null && picked != selectedDateFrom) {
      setState(() {
        dateFrom.text = DateFormat('yyyy-MM-dd').format(picked);
        dateFromVal = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  _selectTheTo(BuildContext context) async {
    var picked = await Utils().selectDate(context, DateTime.parse(dateFromVal));
    if (picked != null && picked != selectedDateTo) {
      setState(() {
        dateTo.text = DateFormat('yyyy-MM-dd').format(picked);
        dateToVal = DateFormat('yyyy-MM-dd').format(picked);
        _getDataFilterByDate();
      });
    }
  }

  getData() async {
    if (mounted) {
      setState(() {
        attendances = dbHelper.getAttendances();
      });
    }
  }

  _getDataFilterByDate() async {
    setState(() {
      if (dateFromVal != null && dateToVal != null) {
        attendances = dbHelper.filterByDateAttendances(dateFromVal, dateToVal);
        _getTotalDataLength().then((value) {
          if (value != null)
            setState(() {
              totalData = value;
            });
        });
      }
    });
  }

  Future<int> _getTotalDataLength() async {
    return await attendances.then((value) {
      return value.length;
    });
  }

  // Text form for filter by date
  InkWell buildInkWellDate(
      BuildContext context, dynamic dateCtl, bool isDateFrom) {
    return InkWell(
      onTap: () {
        // Below line stops keyboard from appearing
        FocusScope.of(context).requestFocus(new FocusNode());
        // Show Date Picker Here
        isDateFrom ? _selectTheFrom(context) : _selectTheTo(context);
      },
      child: IgnorePointer(
        child: TextFormField(
          style: GoogleFonts.quicksand(color: Colors.white),
          controller: dateCtl,
          decoration: InputDecoration(
            labelText:
                isDateFrom ? report_filter_date_from : report_filter_date_to,
            labelStyle: TextStyle(color: Colors.white),
            prefixIcon: Icon(
              Icons.calendar_today,
              color: Colors.white,
            ),
            fillColor: Colors.white,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide(
                color: Colors.blue,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide(
                color: Colors.white,
                width: 2.0,
              ),
            ),
          ),
          // ignore: missing_return
          validator: (e) {
            var message;
            if (e.isEmpty) {
              message = report_filter_input_empty;
            }
            return message;
          },
          onSaved: (e) {
            if (isDateFrom) dateFromVal = e;
            if (!isDateFrom) dateToVal = e;
          },
        ),
      ),
    );
  }

  SingleChildScrollView dataTable(List<Attendance> attendances) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(
              label: Text(
                report_date,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                report_time,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                report_type,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                report_location,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: attendances
              .map(
                (attendance) => DataRow(cells: [
                  DataCell(
                    Text(attendance.date),
                  ),
                  DataCell(
                    Text(attendance.time),
                  ),
                  DataCell(
                    Text(attendance.type),
                  ),
                  DataCell(
                    Text(attendance.location),
                  ),
                ]),
              )
              .toList(),
        ),
      ),
    );
  }

  list() {
    return Expanded(
      child: FutureBuilder(
        future: attendances,
        builder: (context, snapshot) {
          if (null == snapshot.data || snapshot.data.length == 0) {
            return Center(child: Text(report_no_data));
          }

          if (snapshot.hasData) {
            totalData = 0;
            totalData = snapshot.data.length;
            _getTotalDataLength();
            return dataTable(snapshot.data);
          }

          return CircularProgressIndicator();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report_title),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          verticalDirection: VerticalDirection.down,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF0E67B4),
                borderRadius: BorderRadius.all(Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.6),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Text(
                      report_filter_by_title,
                      style: GoogleFonts.quicksand(
                          color: Colors.white, fontSize: 16.0),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    buildInkWellDate(context, dateFrom, true),
                    SizedBox(
                      height: 10,
                    ),
                    buildInkWellDate(context, dateTo, false),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Text(
                          report_filter_total,
                          style: GoogleFonts.quicksand(
                              color: Colors.white, fontSize: 16.0),
                        ),
                        FutureBuilder(
                          future: attendances,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                totalData.toString(),
                                style: GoogleFonts.quicksand(
                                    color: Colors.white, fontSize: 16.0),
                              );
                            }

                            return CircularProgressIndicator();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            list(),
          ],
        ),
      ),
    );
  }
}
