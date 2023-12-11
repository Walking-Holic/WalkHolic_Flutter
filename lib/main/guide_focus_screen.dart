import 'package:flutter/material.dart';

class GuideFocusScreen extends StatelessWidget {
  const GuideFocusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDDB),
      body: Center(
        child: SizedBox(
          height: 570,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 세로 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center, // 가로 중앙 정렬
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  right: 220,
                ),
                child: Text(
                  "2. 커뮤니티 ",
                  style: TextStyle(
                    color: Color(0xFFE7626C),
                    fontWeight: FontWeight.w900,
                    fontSize: 35,
                  ),
                ),
              ),
              const SizedBox(
                height: 80,
              ),
              Text(
                '사용자끼리 산책로를 공유하고',
                style: TextStyle(
                  color: Color(
                    0xFF232B55,
                  ),
                  fontWeight: FontWeight.w900,
                  fontSize: 25,
                ),
              ),
              Text(
                '후기를 작성해보세요',
                style: TextStyle(
                  color: Color(
                    0xFF232B55,
                  ),
                  fontWeight: FontWeight.w900,
                  fontSize: 25,
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              Image.asset(
                'assets/icons/main2.png',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
