import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../App/home.dart';



class loginUser extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return loginUserState();
  }
}
final storage = FlutterSecureStorage();

Future<bool> loginUsers(
    String email, String password, BuildContext context) async {
  try {
    var Url = Uri.parse("http://192.168.56.1:8080/auth/login"); //본인 IP 주소를  localhost 대신 넣기
    var response = await http.post(Url,
        headers: <String, String>{"Content-Type": "application/json"},
        body: jsonEncode(<String, String>{
          "email": email,
          "password": password,
        }));

    print(response);

    if (response.statusCode == 200) {
      // 로그인 성공
      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
      final String accessToken = responseData['accessToken'];
      // accessToken을 안전하게 저장
      await storage.write(key: 'accessToken', value: accessToken);


      // 이제 accessToken을 가져올 수 있습니다.
      // final storedAccessToken = await storage.read(key: 'loginAccessToken')
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
      });
      return true;
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> errorResponse = jsonDecode(utf8.decode(response.bodyBytes));
      final String errorCode = errorResponse['code'];
      final String errorMessage = errorResponse['message'];

      if (errorCode == 'INVALID_INPUT_VALUE') {
        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return MyAlertDialog(title: '오류 메시지',
                  content: errorMessage);
            });
      } else if (errorCode == 'MISMATCH_USERNAME_OR_PASSWORD') {
        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return MyAlertDialog(title: '오류 메시지',
                  content: errorMessage);
            });
      } else {
        // 기타 오류 상황에 대한 처리
      }
    }
    // 모든 경우에 대한 반환값을 추가
    return false;
  } catch (e) {
    print('서버 연결 오류: $e');
    // 서버 연결 오류를 처리할 수 있는 코드를 추가하십시오.
    throw Exception('서버 연결 오류: $e');
  }
}

class loginUserState extends State<loginUser> {
  final minimumPadding = 5.0;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = TextStyle(
      fontSize: 16.0, // 원하는 폰트 크기로 설정
      fontWeight: FontWeight.normal, // 원하는 폰트 두께로 설정
    );
    return Scaffold(
      appBar: AppBar(
        title: Text("로그인"),
      ),
      body: Form(
        child: Padding(
          padding: EdgeInsets.all(minimumPadding * 2),
          child: ListView(
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.only(
                      top: minimumPadding, bottom: minimumPadding),
                  child: TextFormField(
                    style: textStyle,
                    controller: emailController,
                    decoration: InputDecoration(
                        labelText: 'email',
                        hintText: '작성해주세요',
                        labelStyle: textStyle,
                        border: OutlineInputBorder (
                            borderRadius: BorderRadius.circular(5.0))),
                  )),
              Padding(
                  padding: EdgeInsets.only(
                      top: minimumPadding, bottom: minimumPadding),
                  child: TextFormField(
                    style: textStyle,
                    controller: passwordController,
                    decoration: InputDecoration(
                        labelText: '비밀번호',
                        hintText: '작성해주세요',
                        labelStyle: textStyle,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0))),
                  )),
              ElevatedButton(
                child: Text('작성'),
                onPressed: () async {
                  String email = emailController.text;
                  String password = passwordController.text;
                  try {
                    bool loginResult = await loginUsers(email, password, context);

                    if (loginResult) {
                      // 회원 등록 성공
                      print('로그인 성공');
                      // 이후 사용자 정보를 가져오는 요청 또는 다른 작업을 수행
                      // UserModel userModel = await fetchUserInfo(email);
                    } else {
                      // 회원 등록 실패
                      print('로그인 실패');
                      // 다른 처리 수행
                    }
                  } catch (e) {
                    print('서버 연결 오류: $e');
                    // 서버 연결 오류를 처리
                  }
                },
              )
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
