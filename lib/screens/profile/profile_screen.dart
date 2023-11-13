import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/screens/profile/header.dart';
import 'package:fresh_store_ui/login/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fresh_store_ui/Source/LoginUser/userInfo.dart';

typedef ProfileOptionTap = void Function();

class ProfileOption {
  String title;
  String icon;
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
  static _profileIcon(String last) => 'assets/icons/profile/$last';
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

  bool _isDark = false;

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
  get datas => profileData != null ? <ProfileOption>[
        ProfileOption(title: '이메일: ${profileData?['email']}' , icon: _profileIcon('shield_done@2x.png')),
        ProfileOption(title:'닉네임: ${profileData?['nickname']}',icon: _profileIcon('user@2x.png')),
        ProfileOption(title: '랭크: ${profileData?['rank']}', icon:_profileIcon('show@2x.png')),
        ProfileOption(title: '걸음 수: ${profileData?['walk']}', icon:_profileIcon('location@2x.png')),
        ProfileOption(
          title: 'Logout',
          icon: _profileIcon('logout@2x.png'),
          titleColor: const Color(0xFFF75555),
          onClick:() {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        ),
      ] : [];

  void _viewProfile() {
    print("눌림");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => getUserInfo()),
    );
  }


  /*_languageOption() => ProfileOption(
      title: 'Language',
      icon: _profileIcon('more_circle@2x.png'),
      trailing: SizedBox(
        width: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'English (US)',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: Color(0xFF212121)),
            ),
            const SizedBox(width: 16),
            Image.asset('assets/icons/profile/arrow_right@2x.png', scale: 2)
          ],
        ),
      ));

  _darkModel() => ProfileOption(
      title: 'Dark Mode',
      icon: _profileIcon('show@2x.png'),
      trailing: Switch(
        value: _isDark,
        activeColor: const Color(0xFF212121),
        onChanged: (value) {
          setState(() {
            _isDark = !_isDark;
          });
        },
      ));*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverList(
            delegate: SliverChildListDelegate.fixed([
              Padding(
                padding: EdgeInsets.only(top: 30),
                child: ProfileHeader(),
              ),
            ]),
          ),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 10.0),
      sliver: profileData != null ? SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final data = datas[index];
            return _buildOption(context, index, data);
          },
          childCount: datas.length,
        ),
      ): SliverToBoxAdapter(child: CircularProgressIndicator()),
    );
  }

  Widget _buildOption(BuildContext context, int index, ProfileOption data) {
    return ListTile(
      leading: Image.asset(data.icon, scale: 2),
      title: Text(
        data.title,
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: data.titleColor),
      ),
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