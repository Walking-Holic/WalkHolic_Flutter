import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:fresh_store_ui/Source/Loginuser/register.dart';
import 'package:fresh_store_ui/Source/App/home.dart';
import 'package:fresh_store_ui/screens/tabbar/tabbar.dart';
import 'login.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/constants.dart';

class KakaoLoginScreen extends StatefulWidget {
  @override
  _KakaoLoginScreenState createState() => _KakaoLoginScreenState();
}

class MyLoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MyLoginPageState();
  }
}

final storage = FlutterSecureStorage();

Future<bool> kakaoLogingUsers(String code, BuildContext context) async {
  try {
    var Url = Uri.parse(
        "$IP_address/auth/kakao"); //본인 IP 주소를  localhost 대신 넣기
    var response = await http.post(Url,
        headers: <String, String>{"Content-Type": "application/json"},
        body: jsonEncode(<String, String>{
          "authorizationCode" : code,
        }));
    print("code:"+code);
    print(response.statusCode);
    if (response.statusCode == 200) {
      // 로그인 성공 시
      final Map<String, dynamic> responseData =
      jsonDecode(utf8.decode(response.bodyBytes));
      final String accessToken = responseData['accessToken'];


      await storage.write(key: 'accessToken', value: accessToken);

      print(accessToken);
      showDialog(
        context: context,
        barrierDismissible: true, // 사용자가 대화 상자 외부를 터치하여 닫을 수 있도록 설정
        builder: (BuildContext dialogContext) {
          return MyAlertDialog(
            title: '처리 메시지',
            content: '로그인에 성공하였습니다',
          );
        },
      ).then((_) {
        // 대화 상자가 닫힌 후에 실행될 코드
        Navigator.push(context, MaterialPageRoute(builder: (context) => FRTabbarScreen()));
      });
      return true;
    } else if (response.statusCode == 400) {
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return MyAlertDialog(title: '오류 메시지', content: '로그인 실패');
          });
      print("실패");
      return false;
    }
  } catch (e) {
    print('서버 연결 오류: $e');
    // 서버 연결 오류를 처리할 수 있는 코드를 추가하십시오.
    throw Exception('서버 연결 오류: $e');
  }
  print('여기');
  // 실패 로직
  return false;
}

class MyLoginPageState extends State<MyLoginPage> {
  late String authCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '잠깐 시간 될까',
          style: TextStyle(
            fontFamily: 'Dongle-Bold',
            fontSize: 40,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background1.jpeg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupPage()),
                  );
                },
                child: Text("회원가입"),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => loginUser()),
                  );
                },
                child: Text("로그인"),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  onPrimary: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('카카오톡으로 로그인'),
                onPressed: () async {
                  final code = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => KakaoLoginScreen()),
                  );
                  if (code != null) {
                    try {
                      bool kakakLoginResult = await kakaoLogingUsers(code, context);

                      if (kakakLoginResult) {
                        // 회원 등록 성공
                        print('카카오톡 로그인 성공');
                        // 이후 사용자 정보를 가져오는 요청 또는 다른 작업을 수행
                        // UserModel userModel = await fetchUserInfo(email);
                      } else {
                        // 회원 등록 실패
                        print('카카오톡 로그인 실패');
                        // 다른 처리 수행
                      }
                    } catch (e) {
                      print('서버 연결 오류: $e');
                      // 서버 연결 오류를 처리
                    }
                  }
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class MyAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget> actions;

  MyAlertDialog({
    required this.title,
    required this.content,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        this.title,
        style: TextStyle(
          // 제목 텍스트 스타일을 직접 지정
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: this.actions,
      content: Text(
        this.content,
        style: TextStyle(
          // 내용 텍스트 스타일을 직접 지정
          fontSize: 16.0,
        ),
      ),
    );
  }
}

class _KakaoLoginScreenState extends State<KakaoLoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("카카오 로그인"),
      ),
      body: Builder(
        builder: (BuildContext context) {
          // Builder 내에서 WebViewController를 생성하고 사용
          WebViewController controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onProgress: (int progress) {
                  // Update loading bar.
                },
                onPageStarted: (String url) {},
                onPageFinished: (String url) {},
                onWebResourceError: (WebResourceError error) {},
                onNavigationRequest: (NavigationRequest request) {
                  if (request.url.startsWith("http://localhost:8080/kakao/callback")) {
                    Uri uri = Uri.parse(request.url);
                    final code = uri.queryParameters["code"];
                    if (code != null) {
                      // 인가 코드를 사용하여 서버에 액세스 토큰 요청
                      Navigator.pop(context, code);
                    }
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ),
            )
            ..loadRequest(Uri.parse(("https://kauth.kakao.com/oauth/authorize?client_id=a0120cb04bb109d4e2a6ad0a2ea8f24d&redirect_uri=http://localhost:8080/kakao/callback&response_type=code")));

          return WebViewWidget(controller: controller);
        },
      ),
    );
  }
}