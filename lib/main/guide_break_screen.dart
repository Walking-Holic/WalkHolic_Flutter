import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuideBreakScreen extends StatelessWidget {
  const GuideBreakScreen({Key? key}) : super(key: key);

  void finishiTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isFirstRun', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDDB),
      body: Center(
        child: SizedBox(
          height: 570,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  right: 300,
                ),
                child: Text(
                  "3. 랭크",
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
              Text(
                '열심히 걸음 수를 채워서',
                style: TextStyle(
                  color: Color(
                    0xFF232B55,
                  ),
                  fontWeight: FontWeight.w900,
                  fontSize: 25,
                ),
              ),
              Text(
                '높은 등급을 달성보세요',
                style: TextStyle(
                  color: Color(
                    0xFF232B55,
                  ),
                  fontWeight: FontWeight.w900,
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
      ),
    );
  }
}
