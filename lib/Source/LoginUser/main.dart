import 'package:flutter/material.dart';
import 'package:fresh_store_ui/Source/Loginuser/user.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

void main() {
  KakaoSdk.init(nativeAppKey: 'a0120cb04bb109d4e2a6ad0a2ea8f24d');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ㅎㅇ",
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
            home: MyLoginPage(), // MyLoginPage 위젯을 body에 추가
      );
  }
}
