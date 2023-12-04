import 'package:flutter/material.dart';
import 'package:fresh_store_ui/constants.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/model/rank_image.dart';

class HomeAppBar extends StatefulWidget {
  const HomeAppBar({super.key});

  @override
  State<StatefulWidget> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  Future<Map<String, dynamic>?>? _userProfileFuture;

  Uint8List? profileImage;
  String? nickname;
  String? rank;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _loadUserProfile();
  }

  Future<Map<String, dynamic>?> _loadUserProfile() async {
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
        return response.data;
      } else {
        // 에러 처리
        print('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      // 예외 처리
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 50.0,  // 원하는 너비 설정
              height: 50.0, // 원하는 높이 설정
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Text("데이터 로드 실패");
        }
        var data = snapshot.data!;
        Uint8List imageBytes = base64.decode(data['profileImage']);
        String nickname = data['nickname'] ?? 'walkholic';
        String rank = data['rank'] ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: MemoryImage(imageBytes),
                radius: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nickname,
                      style: TextStyle(
                        color: Color(0xFF212121),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(width: 8), // 닉네임과 랭크 이미지 사이 간격
                    RankImage.getRankImage(rank, width:40.0, height: 40.0),
                  ],
                ),
              ),
              SizedBox(width: 16),
              IconButton(
                iconSize: 28,
                icon: Image.asset('$kIconPath/notification.png'),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}


