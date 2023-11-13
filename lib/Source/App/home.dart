import 'package:flutter/material.dart';
import 'package:fresh_store_ui/screens/profile/profile_screen.dart';
import 'package:fresh_store_ui/image_loader.dart';
import 'package:fresh_store_ui/size_config.dart';
import 'package:fresh_store_ui/screens/test/test_screen.dart';

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

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _select = 0; // 선택된 메뉴의 인덱스

  // 각 메뉴에 해당하는 화면을 저장할 리스트
  final screens = [
    const TestScreen(
      title: '메인',
    ),
    const TestScreen(title: '게시판'),
    const ProfileScreen(),
  ];

  static Image generateIcon(String path) {
    return Image.asset(
      '${ImageLoader.rootPaht}tabbar/$path',
      width: 20,
      height: 20,
    );
  }

  final List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(
      icon: generateIcon('light/Home@2x.png'),
      activeIcon: generateIcon('bold/Home@2x.png'),
      label: '홈',
    ),
    BottomNavigationBarItem(
      icon: generateIcon('light/Wallet@2x.png'),
      activeIcon: generateIcon('bold/Wallet@2x.png'),
      label: '게시판',
    ),
    BottomNavigationBarItem(
      icon: generateIcon('light/Profile@2x.png'),
      activeIcon: generateIcon('bold/Profile@2x.png'),
      label: '내정보',
    ),
  ];
  // 메뉴를 선택했을 때 실행되는 콜백 함수
  void _onItemTapped(int index) {
    setState(() {
      _select = index;
    });
  }

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
        onTap: ((value) => setState(() => _select = value)),
        currentIndex: _select,
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

