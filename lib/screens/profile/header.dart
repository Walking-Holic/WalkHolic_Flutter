import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/model/rank_image.dart';
import '../../constants.dart';
import 'dart:core';

class ProfileHeader extends StatefulWidget {

  const ProfileHeader({super.key});

  @override
  State<StatefulWidget> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  Uint8List? profileImage;
  String? nickname;
  String? rank;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final storage = FlutterSecureStorage();

    try {// 로딩 시작
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
          nickname = responseData['nickname'];
          rank = responseData['rank'];
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

    @override
    Widget build(BuildContext context) {

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 50),
          child: Row(
            children: [
              Image.asset('assets/icons/profile/logo@2x.png', scale: 2),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('프로필', style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Stack(
          children: [
            InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              // onTap: () => Navigator.pushNamed(context, ProfileScreen.route()),
              child: profileImage != null
                  ? CircleAvatar(
                backgroundImage: MemoryImage(profileImage!),
                radius: 60,
              )
                  : const CircleAvatar(
                backgroundImage: AssetImage('$kIconPath/board1.png'), // 기본 이미지
                radius: 60,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nickname ?? '',
                style: TextStyle(
                  color: Color(0xFF212121),
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              SizedBox(width: 8),
              rank != null // rank 값이 있는 경우에만 RankImage를 보여줌
                  ? RankImage.getRankImage(rank!, width: 50.0, height: 50.0)
                  : SizedBox(),
            ],
          ),
        const SizedBox(height: 8),
        Container(
          color: const Color(0xFFEEEEEE),
          height: 10,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        )
      ],
    );
  }
}