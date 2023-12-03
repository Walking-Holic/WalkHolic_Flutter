import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuideBreakScreen extends StatelessWidget {
  const GuideBreakScreen({super.key});

  void finishiTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isFirstRun', false);
  }

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
                "랭크 시스템",
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
              '열심히 걸음 수를 채워서',
              style: TextStyle(
                color: Color(
                  0xFF232B55,
                ),
                fontSize: 25,
              ),
            ),
            const Text(
              '높은 등급을 달성보세요',
              style: TextStyle(
                color: Color(
                  0xFF232B55,
                ),
                fontSize: 25,
              ),
            ),
            const SizedBox(
              height: 44,
            ),
            Image.asset(
              'assets/icons/main3.png',
            ),
          ],
        ),
      ),
    );
  }
}