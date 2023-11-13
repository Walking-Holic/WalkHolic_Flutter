import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/login/signup_page.dart'; // 필요한 경우 적절한 경로로 수정하세요




class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _signupFormKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nicknameController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  final storage = FlutterSecureStorage();

  Future<bool> registerUsers(String email, String password, String nickname, String name, BuildContext context) async {
    try {
      var Url = Uri.parse("http://192.168.56.1:8080/auth/register");
      var response = await http.post(Url,
          headers: <String, String>{"Content-Type": "application/json"},
          body: jsonEncode(<String, String>{
            "email": email,
            "password": password,
            "nickname": nickname,
            "name": name,
          }));

      if (response.statusCode == 200) {
        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return MyAlertDialog(title: '처리 메시지', content: '회원가입이 완료되었습니다');
            });
        return true;
      } else {
        final Map<String, dynamic> errorResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = errorResponse["message"];
        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return MyAlertDialog(title: '오류 메시지', content: errorMessage);
            });
        return false;
      }
    } catch (e) {
      print('서버 연결 오류: $e');
      throw Exception('서버 연결 오류: $e');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("회원가입"),
      ),
      body: Form(
        key: _signupFormKey,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              // 이메일 입력 필드
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요.';
                  }
                  return null;
                },
              ),
              // 비밀번호 입력 필드
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요.';
                  }
                  return null;
                },
              ),
              // 닉네임 입력 필드
              TextFormField(
                controller: nicknameController,
                decoration: InputDecoration(labelText: 'Nickname'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요.';
                  }
                  return null;
                },
              ),
              // 이름 입력 필드
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요.';
                  }
                  return null;
                },
              ),
              // 회원가입 버튼
              ElevatedButton(
                onPressed: () {
                  if (_signupFormKey.currentState!.validate()) {
                    registerUsers(
                        emailController.text,
                        passwordController.text,
                        nicknameController.text,
                        nameController.text,
                        context
                    );
                  }
                },
                child: Text('회원가입'),
              ),
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

  const MyAlertDialog({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK'),
        ),
      ],
    );
  }
}
