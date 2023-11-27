import 'dart:convert';
import 'dart:io';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/login/common/page_header.dart';
import 'package:fresh_store_ui/login/common/page_heading.dart';
import 'package:fresh_store_ui/login/login_page.dart';
import 'package:fresh_store_ui/login/common/custom_input_field.dart';
import 'package:http/http.dart' as http;
import 'package:fresh_store_ui/constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
  File? _profileImage;
  final storage = FlutterSecureStorage();

  Future<File> _getLocalImageFile() async {
    // _profileImage가 존재하면 그 경로를 사용합니다.
    if (_profileImage != null) return _profileImage!;

    // 그렇지 않으면 기본 이미지를 임시 파일로 복사하고 그 경로를 사용합니다.
    final byteData = await rootBundle.load('assets/icons/walkholic1.png');
    final buffer = byteData.buffer;
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/default_profile.png';
    final file = await File(tempPath).writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );
    return file;
  }

  Future<bool> registerUsers(String email, String password, String nickname, String name, BuildContext context) async {
      var Url = Uri.parse("http://$IP_address:8080/auth/register");
      var dto = jsonEncode({
        "email": email,
        "password": password,
        "nickname": nickname,
        "name": name
      });

      File imageFile = await _getLocalImageFile();

      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();

      var request = http.MultipartRequest('POST', Url);

      request.files.add(http.MultipartFile.fromString(
        'dto',
        dto,
        contentType: MediaType('application', 'json'), // Set content-type to application/json
      ));

      request.files.add(http.MultipartFile(
          'profileImage',
          stream,
          length,
          filename: basename(imageFile.path),
          contentType: MediaType('image', 'png') // 여기서 적절한 MIME 타입을 설정합니다.
      ));

      print("1");
      print(imageFile.path);
        try{
        var response = await http.Response.fromStream(await request.send());

      print("2");
        print('상태 코드: ${response.statusCode}');
        print('Response: ${response.body}');

        if (response.statusCode == 200) {
        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return MyAlertDialog(
                  title: '처리 메시지',
                  content: '회원가입이 완료되었습니다'
              );
            }).then((_) {
          // 대화 상자가 닫힌 후에 실행될 코드
          Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
        });
        return true;
      } else {
        final Map<String, dynamic> errorResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = errorResponse["message"] ?? '알 수 없는 오류가 발생했습니다.';
        showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return MyAlertDialog(title: '오류 메시지', content: errorMessage);
            },
        ).then((_) {
    // 대화 상자가 닫힌 후에 실행될 코드
    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
    });
        return false;
      }
    } catch (e) {
      print('서버 연결 오류: $e');
      throw Exception('서버 연결 오류: $e');
    }
    return false;
  }



  Future<void> _pickProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageTemporary = File(image.path);
      setState(() => _profileImage = imageTemporary);
    } on PlatformException catch (e) {
      debugPrint('Failed to pick image error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffEEF1F3),
        body: SingleChildScrollView(
          child: Form(
            key: _signupFormKey,
            child: Column(
              children: [
                const PageHeader(),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20),),
                  ),
                  child: Column(
                    children: [
                      const PageHeading(title: 'Sign-up',),
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade400,
                                      border: Border.all(color: Colors.white, width: 3),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_sharp,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16,),
                      CustomInputField(
                          controller: emailController,
                          labelText: 'Email',
                          hintText: 'Email을 작성해주세요',
                          isDense: true,
                          validator: (textValue) {
                            if(textValue == null || textValue.isEmpty) {
                              return '작성해주세요!!';
                            }
                            return null;
                          }
                      ),
                      const SizedBox(height: 16,),
                      CustomInputField(
                          controller: passwordController,
                          labelText: '비밀번호',
                          hintText: '비밀번호를 작성해주세요',
                          isDense: true,
                          obscureText: true,
                          validator: (textValue) {
                            if(textValue == null || textValue.isEmpty) {
                              return '작성해주세요!!';
                            }
                            return null;
                          }
                      ),
                      const SizedBox(height: 16,),
                      CustomInputField(
                          controller: nicknameController,
                          labelText: '별명',
                          hintText: '사용할 별명을 작성해주세요',
                          isDense: true,
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
                        controller: nameController,
                        labelText: '이름',
                        hintText: '이름을 작성해주세요',
                        isDense: true,
                        validator: (textValue) {
                          if(textValue == null || textValue.isEmpty) {
                            return '작성해주세요!!';
                          }
                          return null;
                        },
                        suffixIcon: true,
                      ),
                      const SizedBox(height: 22,),
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
                      const SizedBox(height: 18,),
                      SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Already have an account ? ', style: TextStyle(fontSize: 13, color: Color(0xff939393), fontWeight: FontWeight.bold),),
                            GestureDetector(
                              onTap: () => {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()))
                              },
                              child: const Text('Log-in', style: TextStyle(fontSize: 15, color: Color(0xff748288), fontWeight: FontWeight.bold),),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30,),
                    ],
                  ),
                ),
              ],
            ),
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

