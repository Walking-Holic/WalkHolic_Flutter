import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/screens/tabbar/tabbar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import '../Source/LoginUser/register.dart';
import '../constants.dart';
import 'common/custom_input_field.dart';
import 'common/page_header.dart';
import 'common/page_heading.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEditScreen extends StatefulWidget {
  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _editProfileFormKey = GlobalKey<FormState>();
  final storage = FlutterSecureStorage();
  Uint8List? profileImage;
  String? name;
  String ? nickname;

  TextEditingController nicknameController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  File? _profileImage;

  Future<void> _loadUserProfile() async {
    final storage = FlutterSecureStorage();

    try {
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get(
        '$IP_address/api/member/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print("실행");
      print(response.statusCode);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = response.data;
        // 이미지 바이트 배열 추출
        String base64String = responseData['profileImage'];
        Uint8List imageBytes = base64.decode(base64String);

        setState(() {
          profileImage = imageBytes;
          name = responseData['name'];
          nickname = responseData['nickname'];

          nameController.text = name ?? '';
          nicknameController.text = nickname ?? '';
        });
      } else {
        // 에러 처리
        print('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      // 예외 처리
      print('Error: $e');
    }
  }

  Future<bool> updateProfile(
      String nickname,
      String name,
      File? profileImage, // 프로필 이미지 파일
      BuildContext context
      ) async {
    var url = Uri.parse("$IP_address/auth/update");
    var dto = jsonEncode({
      "nickname": nickname,
      "name": name
    });
    var request = http.MultipartRequest('PATCH', url);
    // accessToken 헤더 추가
    String? accessToken = await storage.read(key: 'accessToken');
    request.headers['Authorization'] = 'Bearer $accessToken';

    request.files.add(http.MultipartFile.fromString(
      'dto',
      dto,
      contentType: MediaType('application', 'json'),
    ));

    // 프로필 이미지 처리
    if (profileImage != null) {
      var stream = http.ByteStream(profileImage.openRead());
      var length = await profileImage.length();

      request.files.add(http.MultipartFile(
          'profileImage',
          stream,
          length,
          filename: basename(profileImage.path),
          contentType: MediaType('image', 'png') // 적절한 MIME 타입 설정
      ));
    } else {
      // profileImage가 null인 경우 기본 이미지 사용
      var defaultImage = await rootBundle.load('assets/icons/board1.png');
      var buffer = defaultImage.buffer;
      var bytes = buffer.asUint8List(defaultImage.offsetInBytes, defaultImage.lengthInBytes);

      request.files.add(http.MultipartFile.fromBytes(
          'profileImage',
          bytes,
          filename: 'board1.png',
          contentType: MediaType('image', 'png') // 적절한 MIME 타입 설정
      ));
    }
    try{
    var response = await http.Response.fromStream(await request.send());

    print('상태 코드: ${response.statusCode}');
    print('Response: ${response.body}');

    if (response.statusCode == 200) {
      // 성공적인 응답 처리
      showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return MyAlertDialog(
                title: '처리 메시지',
                content: '프로필 수정이 완료되었습니다'
            );
          }
      ).then((_) => Navigator.push(context, MaterialPageRoute(builder: (context) => FRTabbarScreen(initialTabIndex: 4))));
      return true;
    } else if (response.statusCode == 400) {
      // 이메일 형식 오류 처리
      showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return MyAlertDialog(
                title: '오류 메시지',
                content: '이메일 형식이 맞지 않습니다.'
            );
          }
      );
      return false;
    } else if (response.statusCode == 409) {
      // 이미 가입한 이메일 존재 처리
      showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return MyAlertDialog(
                title: '오류 메시지',
                content: '이미 가입한 이메일이 존재합니다.'
            );
          }
      );
      return false;
    } else {
      // 기타 오류 처리
      showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return MyAlertDialog(
                title: '오류 메시지',
                content: '알 수 없는 오류가 발생했습니다.'
            );
          }
      );
      return false;
    }
  } catch (e) {
  print('서버 연결 오류: $e');
  throw Exception('서버 연결 오류: $e');
  }
}


// 프로필 이미지 선택 로직
  Future<void> _pickProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final imageTemporary = File(image.path);
      setState(() {
        _profileImage = imageTemporary;
        // 선택한 이미지를 profileImage 상태 변수에도 반영합니다.
        profileImage = File(image.path).readAsBytesSync();
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to pick image error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFF4EDDB),
        body: SingleChildScrollView(
          child: Form(
            key: _editProfileFormKey,
            child: Column(
              children: [
                const PageHeader(),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),),
                  ),
                  child: Column(
                    children: [
                      const PageHeading(title: '프로필 수정'),
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: profileImage != null ? MemoryImage(profileImage!) : null,
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
                                      border: Border.all(
                                          color: Colors.white, width: 3),
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
                      const SizedBox(height: 20),
                      CustomInputField(
                          controller: nicknameController,
                          labelText: '별명',
                          hintText: '새로운 별명을 작성해주세요',
                          isDense: true,
                          validator: (textValue) {
                            if (textValue == null || textValue.isEmpty) {
                              return '작성해주세요!!';
                            }
                            return null;
                          }
                      ),
                      const SizedBox(height: 20),
                      CustomInputField(
                        controller: nameController,
                        labelText: '이름',
                        hintText: '이름을 작성해주세요',
                        isDense: true,
                        validator: (textValue) {
                          if (textValue == null || textValue.isEmpty) {
                            return '작성해주세요!!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8, // 화면 너비의 80%
                        child: ElevatedButton(
                          onPressed: () {
                            if (_editProfileFormKey.currentState!.validate()) {
                              updateProfile(
                                  nicknameController.text,
                                  nameController.text,
                                  _profileImage,
                                  context
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            textStyle: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15.0,
                            ),
                          ),
                          child: Text('프로필 수정'),
                        ),
                      ),
                      const SizedBox(height: 39),
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