import 'dart:convert';
import 'package:fresh_store_ui/screens/home/home.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/login/common/custom_input_field.dart';
import 'package:fresh_store_ui/login/common/page_header.dart';
import 'package:fresh_store_ui/login/forget_password_page.dart';
import 'package:fresh_store_ui/login/signup_page.dart';
import 'package:fresh_store_ui/login/common/page_heading.dart';
import 'package:fresh_store_ui/screens/tabbar/tabbar.dart';
import 'package:fresh_store_ui/Source/LoginUser/user.dart';
import 'package:fresh_store_ui/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

final storage = FlutterSecureStorage();

Future<bool> loginUsers(
    String email, String password, BuildContext context) async {
  try {
    var Url = Uri.parse("$IP_address/auth/login"); //본인 IP 주소를  localhost 대신 넣기
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => FRTabbarScreen()));
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

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffEEF1F3),
        body: Column(
          children: [
            const PageHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20),),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _loginFormKey,
                    child: Column(
                      children: [
                        const PageHeading(title: 'Log-in',),
                        CustomInputField(controller: emailController,
                            labelText: '이메일',
                            hintText: '이메일을 작성해주세요',
                            validator: (textValue) {
                              if(textValue == null || textValue.isEmpty) {
                                return '작성해주세요!!';
                              }
                              // if(!EmailValidator.validate(textValue)) {
                              //   return 'Please enter a valid email';
                              // }
                              return null;
                            }
                        ),
                        const SizedBox(height: 16,),
                        CustomInputField(
                          controller: passwordController,
                          labelText: '비밀번호',
                          hintText: '비밀번호를 작성해주세요',
                          obscureText: true,
                          suffixIcon: true,
                          validator: (textValue) {
                            if(textValue == null || textValue.isEmpty) {
                              return '작성해주세요!!';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16,),
                        Container(
                          width: size.width * 0.80,
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgetPasswordPage()))
                            },
                            child: const Text(
                              'Forget password?',
                              style: TextStyle(
                                color: Color(0xff939393),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20,),
                        SizedBox(
                          width: 650,
                          height: 45,

                          child: ElevatedButton(
                            child: Text('로그인'),
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
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)
                                )
                            ),
                          ),
                        ),

                        const SizedBox(height: 20,),
                        SizedBox(
                          width: 650,
                          height: 45,
                          child: ElevatedButton(
                            child: Text('카카오 로그인', style: TextStyle(color: Colors.black),),
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
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.yellow,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(10)
                             )
                           ),

                          ),
                        ),
                        const SizedBox(height: 18,),
                        SizedBox(
                          width: size.width * 0.8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Don\'t have an account ? ', style: TextStyle(fontSize: 13, color: Color(0xff939393), fontWeight: FontWeight.bold),),
                              GestureDetector(
                                onTap: () => {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupPage()))
                                },
                                child: const Text('Sign-up', style: TextStyle(fontSize: 15, color: Color(0xff748288), fontWeight: FontWeight.bold),),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLoginUser() {
    // login user
    if (_loginFormKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitting data..')),
      );
    }
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
