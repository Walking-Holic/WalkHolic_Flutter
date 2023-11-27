import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/screens/board/kakao_map.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../constants.dart';
import '../tabbar/tabbar.dart';
import 'board_screen.dart';

class NewPostScreen extends StatefulWidget {
  @override
  _NewPostScreenState createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _titleController = TextEditingController(); // 게시글 제목을 위한 컨트롤러
  final _contentController = TextEditingController(); // 게시글 내용을 위한 컨트롤러
  final _distanceController = TextEditingController(); // 게시글 거리를 위한 컨트롤러
  final _estimatedTimeController = TextEditingController(); // 예상 소요시간을 위한 컨트롤러

  String? _difficulty; // 경로의 난이도 설정을 위한 컨트롤러

  File? _image; // 선택한 이미지를 저장하기 위한 변수

  final List<String> _difficultyOptions = ['상', '중', '하']; // 난이도 옵션
  List<Map<String, dynamic>> coordinates =
      []; // 카카오맵 사용자 경로 설정에서 받아올 경로 정보 들의 배열

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 300, // 최대 너비
        maxHeight: 200, // 최대 높이
        imageQuality: 85, // 이미지 품질 (0 ~ 100)
      );
      if (image == null) return;

      final imageTemporary = File(image.path);
      setState(() => _image = imageTemporary);
    } on PlatformException catch (e) {
      debugPrint('Failed to pick image error: $e');
    }
  }

  Map<String, dynamic> _collectUserData() {
    // 사용자의 입력값을 모아서 백으로 보내기 위해 정렬
    return {
      "title": _titleController.text,
      "content": _contentController.text,
      "totalDistance": double.tryParse(_distanceController.text) ?? 0.0,
      "difficulty": _mapDifficultyToBackendFormat(_difficulty),
      "estimatedTime": _estimatedTimeController.text
    };
  }

  @override
  void dispose() {
    //컨트롤러 정리
    _titleController.dispose();
    _contentController.dispose();
    _estimatedTimeController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  String _mapDifficultyToBackendFormat(String? difficulty) {
    // 입력받은 난이도는 상,중,하 중 1개 이지만 백으로 보낼때 형식 바꿔주기
    switch (difficulty) {
      case '상':
        return 'UPPER';
      case '중':
        return 'MIDDLE';
      case '하':
        return 'LOWER';
      default:
        return 'UNKNOWN'; // 기본값 처리
    }
  }

  Future<File> _getLocalImageFile() async {
    // _profileImage가 존재하면 그 경로를 사용합니다.
    if (_image != null) return _image!;

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

  void _submitPost() async {
    // 사용자 입력 데이터 수집
    Map<String, dynamic> userData = _collectUserData(); //데이타 받아오기
    // 모든 필드가 채워졌는지 확인
    bool isDataComplete = userData['title']?.isNotEmpty == true &&
        userData['content']?.isNotEmpty == true &&
        userData['totalDistance'] != 0.0 &&
        userData['difficulty']?.isNotEmpty == true &&
        userData['estimatedTime']?.isNotEmpty == true;

    if (!isDataComplete) {
      // Flutter에서는 ScaffoldMessenger.of(context).showSnackBar() 등을 사용할 수 있습니다.
      ScaffoldMessenger.of(context as BuildContext)
          .showSnackBar(SnackBar(content: Text('모든 필드를 채워 주세요')));
      return;
    } // KakaoMapTest에서 반환된 데이터로 대체

    final storage = FlutterSecureStorage();
    String? accessToken = await storage.read(key: 'accessToken');

    var uri = Uri.parse('http://$IP_address:8080/api/path/save');

    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $accessToken';

    var jsonDto = jsonEncode({
      "title": userData['title'],
      "content": userData['content'],
      "totalDistance": userData['totalDistance'],
      "difficulty": userData['difficulty'],
      "estimatedTime": userData['estimatedTime'],
      "coordinates": coordinates
    });

    File Image = await _getLocalImageFile();

    var stream = http.ByteStream(Image.openRead());
    var length = await Image.length();

    request.files.add(http.MultipartFile.fromString(
      'dto', // 서버에서 기대하는 필드 이름
      jsonDto,
      contentType: MediaType('application', 'json'),
    ));

    request.files.add(http.MultipartFile('pathImage',
        stream,
        length,
        filename: path.basename(Image.path),
        contentType: MediaType('image', 'png') // 여기서 적절한 MIME 타입을 설정합니다.
        ));

    print(jsonDto);

    var response = await request.send();
    // 누락된 데이터가 있는 경우 경고 메시지 표시
    if (response.statusCode == 200) {
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return MyAlertDialog(title: '처리 메시지', content: '게시물 등록이 완료되었습니다');
          }).then((_) {
        // 대화 상자가 닫힌 후에 실행될 코드
        Navigator.push(context, MaterialPageRoute(builder: (context) => FRTabbarScreen()));
      });   // 성공적으로 요청을 보냈을 때의 처리
      print('게시글 업로드 성공');
    } else {
      // 에러 처리
      print(response);
      ScaffoldMessenger.of(context as BuildContext)
          .showSnackBar(SnackBar(content: Text('경로를 설정 해주세요')));
      print('게시글 업로드 실패: ${response.statusCode}');
    }
    // 데이터 전송 로직 (네트워크 요청, 파일 저장 등)
    // ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글 작성'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목',
              ),
              maxLength: 15, // 제목의 최대 길이를 15자로 제한합니다.
              inputFormatters: [
                LengthLimitingTextInputFormatter(15), // 여기에도 같은 제한을 적용합니다.
              ],
            ),
            SizedBox(height: 10),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '내용',
              ),
              maxLength: 100,
              // 내용의 최대 길이를 100자로 제한합니다.
              maxLines: 6,
              inputFormatters: [
                LengthLimitingTextInputFormatter(100), // 여기에도 같은 제한을 적용합니다.
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => KakaoMapTest()),
                  );
                  if (result != null) {
                    setState(() {
                      // KakaoMapTest에서 반환된 데이터를 coordinates에 저장
                      coordinates = result as List<Map<String, dynamic>>;
                    });
                  }
                },
                child: Text('내 경로 찍어보기')),
            SizedBox(height: 20),
            TextField(
              controller: _distanceController,
              decoration: InputDecoration(
                labelText: '경로 길이(km)',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              // 숫자 키패드와 소수점 입력 허용
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                // 숫자와 소수점 한 자리만 허용
              ],
            ),
            SizedBox(height: 10),
            TextField(
              controller: _estimatedTimeController,
              decoration: InputDecoration(
                labelText: '예상 소요시간 (분 단위로 작성)',
              ),
              keyboardType: TextInputType.text, // 텍스트 입력 키보드
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: _difficulty,
              hint: Text('난이도 선택'),
              isExpanded: true,
              items: _difficultyOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _difficulty = newValue;
                });
              },
            ),
            _image != null ? Image.file(File(_image!.path)) : Container(),
            // 선택한 이미지를 보여줌
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('사진 추가'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitPost,
              child: Text('게시글 올리기'),
            ),
          ],
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

