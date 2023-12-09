import 'package:flutter/material.dart';

class GuideHowScreen extends StatelessWidget {
  const GuideHowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDDB),
      body: SizedBox(
        height: 570,
        child: SingleChildScrollView(
          child:Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(
                right: 150,
              ),
              child: Text(
                "1. 주변 산책로 확인",
                style: TextStyle(
                  color: Color(0xFFE7626C),
                  fontWeight: FontWeight.w900,
                  fontSize: 35,
                ),
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            const Text(
              '현재 위치를 기반으로',
              style: TextStyle(
                color: Color(
                  0xFF232B55,
                ),
                fontWeight: FontWeight.w900,
                fontSize: 25,
              ),
            ),
            const Text(
              '주변 산책로를 확인해보세요',
              style: TextStyle(
                color: Color(
                  0xFF232B55,
                ),
                fontWeight: FontWeight.w900,
                fontSize: 25,
              ),
            ),
            const SizedBox(
              height: 45,
            ),
            Image.asset(
              'assets/icons/main1.png',
            ),
          ],
        ),
        ),
      ),
    );
  }
}