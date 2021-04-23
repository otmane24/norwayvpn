import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:norwayvpn/Screen/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        floatingActionButtonTheme:
            FloatingActionButtonThemeData(backgroundColor: Colors.deepOrange),
        //  primaryColor: Colors.orangeAccent[200],
        primarySwatch: Colors.deepOrange,
        brightness: Brightness.dark,
        cupertinoOverrideTheme: CupertinoThemeData(
          primaryContrastingColor: Colors.deepOrange,
          primaryColor: Colors.deepOrange,
        ),
        bottomSheetTheme: BottomSheetThemeData(
            shape: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            modalElevation: 10),
      ),
      debugShowCheckedModeBanner: false,
      title: 'NorwayVPN',
      home: Home(title: 'NorwayVPN'),
    );
  }
}
