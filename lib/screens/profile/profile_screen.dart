import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/Source/LoginUser/login.dart';
import 'package:fresh_store_ui/screens/profile/header.dart';
import 'package:fresh_store_ui/login/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fresh_store_ui/constants.dart';

import '../../login/update_profile.dart';

typedef ProfileOptionTap = void Function();

class ProfileOption {
  Widget title;
  Widget icon;
  Color? titleColor;
  ProfileOptionTap? onClick;
  Widget? trailing;

  ProfileOption({
    required this.title,
    required this.icon,
    this.onClick,
    this.titleColor,
    this.trailing,
  });

  ProfileOption.arrow({
    required this.title,
    required this.icon,
    this.onClick,
    this.titleColor = const Color(0xFF212121),
    this.trailing = const Image(image: AssetImage('assets/icons/profile/arrow_right@2x.png'), width: 24, height: 24),
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static String route() => '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchAndSetProfileData();
  }

  void _fetchAndSetProfileData() async {
    profileData = await fetchProfile();
    if (mounted) {
      setState(() {});
    }
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      String? accessToken = await storage.read(key: 'accessToken');

      var Url = Uri.parse("$IP_address/api/member/me");
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

  Future<Map<String, dynamic>?> DeleteProfile() async {
    try {
      String? accessToken = await storage.read(key: 'accessToken');

      var Url = Uri.parse("$IP_address/auth/delete");
      var response = await http.delete(Url, // 서버의 프로필 정보 API
        headers: <String, String>{
          'Authorization': 'Bearer $accessToken'},
      );
      print(accessToken);

      var decodedResponse = utf8.decode(response.bodyBytes);
      print('서버 응답: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        print("성공");
        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
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

  get datas => profileData != null ? <ProfileOption>[
        ProfileOption(title: Text('내 정보 확인'),
            icon: Icon(Icons.account_circle, color: Colors.black87),
            onClick: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => getUserInfo()),
        );},
        ),
        ProfileOption(title: Text('프로필 수정'),
          icon: Icon(Icons.edit, color: Colors.black87),
          onClick: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileEditScreen()),
            );
        }),
        ProfileOption(title: Text('알람 설정'), icon: Icon(Icons.alarm, color: Colors.black87)),
        ProfileOption(title: Text('북마크 한 글보기'), icon: Icon(Icons.bookmark, color: Colors.black87)),
        ProfileOption(
          title: Text('로그아웃'),
          icon: Icon(Icons.logout, color: Colors.red),
          titleColor: const Color(0xFFF75555),
          onClick:() {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        ),
    ProfileOption(
      title: Text(
          '회원 탈퇴',
          style: TextStyle(color: Colors.black87.withOpacity(0.3)),
        ),
      icon: Icon(Icons.delete_forever, color: Colors.black87.withOpacity(0.3)), // 회원 탈퇴에 알맞은 아이콘
      onClick: () async {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('회원 탈퇴'),
              content: Text('정말 탈퇴 하시겠습니까?'),
              actions: <Widget>[
                TextButton(
                  child: Text('예'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // '예'를 선택하면 true 반환
                  },
                ),
                TextButton(
                  child: Text('아니요'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // '아니요'를 선택하면 false 반환
                  },
                ),
              ],
            );
          },
        );
        if (confirmed ?? false) {
          await DeleteProfile(); // 회원 탈퇴 처리 함수 호출
        }
      },
    ),
  ] : [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
           SliverList(
            delegate: SliverChildListDelegate([
              ProfileHeader(),
            ]),
          ),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 1),
      sliver: profileData != null ? SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final data = datas[index];
            return _buildOption(context, index, data);
          },
          childCount: datas.length,
        ),
      ): const SliverToBoxAdapter(child: CircularProgressIndicator()),
    );
  }

  Widget _buildOption(BuildContext context, int index, ProfileOption data) {
    return ListTile(
      leading: data.icon,
      title:
        data.title,

      trailing: data.trailing,
      onTap: data.onClick,
    );
  }
}


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

      var Url = Uri.parse("$IP_address/api/member/me");
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
              ],
            ),
          );
        },
      ),
    );
  }
}