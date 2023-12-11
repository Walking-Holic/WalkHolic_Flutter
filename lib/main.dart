import 'package:flutter/material.dart';
import 'package:fresh_store_ui/routes.dart';
import 'package:fresh_store_ui/theme.dart';
import 'package:fresh_store_ui/login/login_page.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:fresh_store_ui/model/notification_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main/guide_main_screen.dart';

const String kakaoMapKey = 'c7f0222c04ff0b7bb1656cf815b683d2';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  // await dotenv.load(fileName: 'assets/env/.env');
  AuthRepository.initialize(appKey: kakaoMapKey);
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  final notificationService = NotificationService();
  WidgetsFlutterBinding.ensureInitialized();
  await notificationService.init();
  tz.initializeTimeZones();

  //runApp(const FreshBuyerApp());
  runApp(const MyApp());
  FlutterNativeSplash.remove();

  // WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // runApp(const MyApp());

}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SharedPreferences prefs; // added
  bool firstRun = true; // 초기에 null로 설정

  // added
  void initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun');
    if (isFirstRun != null) {
      // 값이 null이 아닌 경우에만 업데이트
      setState(() {
        firstRun = !isFirstRun;
      });
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
      title: '잠깐 시간 될까',
      theme: firstRun ? ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE7626C),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFF232B55),
          ),
        ),
        cardColor: const Color(0xFFF4EDDB),
      ): ThemeData(
        // 그 외 경우 사용할 테마
        scaffoldBackgroundColor: Colors.white,
        // ...
      ),
      home: firstRun! ? const GuideMainScreen() : const LoginPage(), // added
    );
  }
}
