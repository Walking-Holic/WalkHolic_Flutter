import 'package:flutter/material.dart';
import 'package:fresh_store_ui/constants.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/model/rank_image.dart';
import 'package:fresh_store_ui/screens/track/track_search.dart';

import '../track/pomodoros.dart';

class HomeAppBar extends StatefulWidget {
  const HomeAppBar({super.key});

  @override
  State<StatefulWidget> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  Future<Map<String, dynamic>?>? _userProfileFuture;

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

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userProfileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Text("데이터 로드 실패");
        }
        var data = snapshot.data!;
        Uint8List imageBytes = base64.decode(data['profileImage']);
        String nickname = data['nickname'] ?? 'walkholic';
        String rank = data['rank'] ?? '';

        return Container(
          padding: EdgeInsets.only(
              top: 50.0, left: 16.0, right: 16.0, bottom: 16.0),
          color: Colors.white, // 배경색 지정
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
                    SizedBox(width: 8),
                    RankImage.getRankImage(rank, width: 40.0, height: 40.0),
                  ],
                ),
              ),
              IconButton(
                iconSize: 28,
                icon: Image.asset('$kIconPath/board1.png'),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PedometerAndStopwatchUI())
                  );
                },
              ),
              SizedBox(width: 16),
              IconButton(
                iconSize: 28,
                icon: Image.asset('$kIconPath/notification.png'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchTrack())
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}