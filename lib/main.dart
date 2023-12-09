import 'package:flutter/material.dart';
import 'package:fresh_store_ui/routes.dart';
import 'package:fresh_store_ui/theme.dart';
import 'package:fresh_store_ui/login/login_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main/guide_main_screen.dart';

const String kakaoMapKey = 'c7f0222c04ff0b7bb1656cf815b683d2';


void main() async {
  // await dotenv.load(fileName: 'assets/env/.env');
  AuthRepository.initialize(appKey: kakaoMapKey);

  // WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);


  runApp(const FreshBuyerApp());
  // runApp(const MyApp());

}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SharedPreferences prefs; // added
  bool firstRun = true; // added

  // added
  void initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun');
    if (isFirstRun == false) {
      setState(
            () {
          firstRun = false;
        },
      );
    }
  }

  // added
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPrefs();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE7626C),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFF232B55),
          ),
        ),
        cardColor: const Color(0xFFF4EDDB),
      ),
      home: firstRun ? const GuideMainScreen() : const GuideMainScreen(), // added
    );
  }
}


class FreshBuyerApp extends StatelessWidget {
  const FreshBuyerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '잠깐 시간 될까',
      theme: appTheme(),
      routes: routes,
      home: const LoginPage(),
    );
  }
}
