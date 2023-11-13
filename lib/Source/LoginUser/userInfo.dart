import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class getUserInfo extends StatefulWidget {
  const getUserInfo ({Key? key}) : super(key: key);
  @override
  _getUserInfoState createState() => _getUserInfoState();
}

class _getUserInfoState extends State<getUserInfo> {

  final storage = FlutterSecureStorage();

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
    String? accessToken = await storage.read(key: 'accessToken');

    var Url = Uri.parse("http://192.168.56.1:8080/api/member/me");
    var response = await http.get(Url, // 서버의 프로필 정보 API
        headers: <String, String>{
        'Authorization': 'Bearer $accessToken'},
    );
    print(accessToken);
    var decodedResponse = utf8.decode(response.bodyBytes);
    print('서버 응답: ${response.statusCode}, ${response.body}');
    if (response.statusCode == 200) {
      print("성공");

      return jsonDecode(decodedResponse);
    } else {
      print('Failed to fetch profile');
    }
  }catch (e) {
      print('서버 연결 오류: $e');
      // 서버 연결 오류를 처리할 수 있는 코드를 추가하십시오.
      throw Exception('서버 연결 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 정보'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('프로필 정보를 불러오는 데 실패했습니다.'));
          }

          if (snapshot.data == null) {
            return Center(child: Text('프로필 정보가 없습니다.'));
          }

          final profileData = snapshot.data!;

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('이메일: ${profileData['email']}', style: TextStyle(fontSize: 20)),
                Text('닉네임: ${profileData['nickname']}', style: TextStyle(fontSize: 20)),
                Text('랭크: ${profileData['rank']}', style: TextStyle(fontSize: 20)),
                Text('걸음 수: ${profileData['walk']}', style: TextStyle(fontSize: 20)),
                // 여기에 추가 프로필 정보를 표시
              ],
            ),
          );
        },
      ),
    );
  }
}