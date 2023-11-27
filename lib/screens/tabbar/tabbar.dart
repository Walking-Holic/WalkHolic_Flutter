import 'package:flutter/material.dart';
import 'package:fresh_store_ui/image_loader.dart';
import 'package:fresh_store_ui/screens/board/board_screen.dart';
import 'package:fresh_store_ui/screens/home/home.dart';
import 'package:fresh_store_ui/screens/profile/profile_screen.dart';
import 'package:fresh_store_ui/screens/test/test_screen.dart';
import 'package:fresh_store_ui/size_config.dart';
import 'package:fresh_store_ui/screens/board/board_screen.dart';

class TabbarItem {
  final String lightIcon;
  final String boldIcon;
  final String label;

  TabbarItem({required this.lightIcon, required this.boldIcon, required this.label});

  BottomNavigationBarItem item(bool isbold) {
    return BottomNavigationBarItem(
      icon: ImageLoader.imageAsset(isbold ? boldIcon : lightIcon),
      label: label,
    );
  }

  BottomNavigationBarItem get light => item(false);
  BottomNavigationBarItem get bold => item(true);
}

class FRTabbarScreen extends StatefulWidget {
  final int initialTabIndex;

  const FRTabbarScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);
  @override
  State<FRTabbarScreen> createState() => _FRTabbarScreenState();
}

class _FRTabbarScreenState extends State<FRTabbarScreen> {
  late int _select;

  final screens = [
    const HomeScreen(
      title: '홈',
    ),
    FeedScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _select = widget.initialTabIndex;  // 초기 선택된 탭 설정
  }

  static Image generateIcon(String path) {
    return Image.asset(
      '${ImageLoader.rootPaht}/tabbar/$path',
      width: 24,
      height: 24,
    );
  }

  final List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(
      icon: generateIcon('light/Home@2x.png'),
      activeIcon: generateIcon('bold/Home@2x.png'),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: generateIcon('light/Wallet@2x.png'),
      activeIcon: generateIcon('bold/Wallet@2x.png'),
      label: 'Post',
    ),
    BottomNavigationBarItem(
      icon: generateIcon('light/Profile@2x.png'),
      activeIcon: generateIcon('bold/Profile@2x.png'),
      label: 'Profile',
    ),
  ];

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: screens[_select],
      bottomNavigationBar: BottomNavigationBar(
        items: items,
        currentIndex: _select,
        onTap: (index) {
          setState(() {
            _select = index; // 사용자가 선택한 화면으로 전환합니다.
          });
        },
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        showUnselectedLabels: true,
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 10,
        ),
        selectedItemColor: const Color(0xFF212121),
        unselectedItemColor: const Color(0xFF9E9E9E),
      ),
    );
  }
}
