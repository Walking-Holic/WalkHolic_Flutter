import 'package:flutter/material.dart';
import 'package:fresh_store_ui/routes.dart';
import 'package:fresh_store_ui/screens/tabbar/tabbar.dart';
import 'package:fresh_store_ui/theme.dart';
import 'package:fresh_store_ui/login/login_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:fresh_store_ui/map.dart';

const String kakaoMapKey = 'c7f0222c04ff0b7bb1656cf815b683d2';


void main() async {
  await dotenv.load(fileName: 'assets/env/.env');
  AuthRepository.initialize(appKey: kakaoMapKey);
  runApp(const FreshBuyerApp());
  // runApp(const MyApp());
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
