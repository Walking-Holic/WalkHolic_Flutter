import 'package:flutter/material.dart';

class GuideFocusScreen extends StatelessWidget {
  const GuideFocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDDB),
      body: SizedBox(
        height: 570,
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(
                right: 150,
              ),
              child: Text(
                "커뮤니티",
                style: TextStyle(
                  color: Color(0xFFE7626C),
                  fontSize: 35,
                ),
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            const Text(
              '사용자끼리 산책로를 공유하고',
              style: TextStyle(
                color: Color(
                  0xFF232B55,
                ),
                fontSize: 25,
              ),
            ),
            const Text(
              '후기를 작성해보세요',
              style: TextStyle(
                color: Color(
                  0xFF232B55,
                ),
                fontSize: 25,
              ),
            ),
            const SizedBox(
              height: 90,
            ),
            Image.asset(
              'assets/icons/main2.png',
            ),
          ],
        ),
      ),
    );
  }
}