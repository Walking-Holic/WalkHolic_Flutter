import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../login/login_page.dart';
import 'appbar_skip_widget.dart';
import 'guide_break_screen.dart';
import 'guide_focus_screen.dart';
import 'guide_how_screen.dart';

class GuideMainScreen extends StatelessWidget {
  const GuideMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GuideScreen(),
    );
  }
}

class GuideScreen extends StatelessWidget {
  GuideScreen({super.key});

  final _controller = PageController();

  void skipTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isFirstRun', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EDDB),
      appBar: const AppbarSkip(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 570,
              child: PageView(
                controller: _controller,
                children: const [
                  GuideHowScreen(),
                  GuideFocusScreen(),
                  GuideBreakScreen(),
                ],
              ),
            ),
            Row(
              children: [
                const Padding(padding: EdgeInsets.only(left: 40)),
                SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: const ExpandingDotsEffect(
                    activeDotColor: Color(0xFFE7626C),
                    dotColor: Color(
                      0xFF232B55,
                    ),
                  ),
                ),
                const SizedBox()
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 45,
              ),
            ),
            SizedBox(
              width: 181,
              height: 49,
              child: ElevatedButton(
                onPressed: () {
                  skipTutorial();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF232B55,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w900,),
                ),
              ),
            ),
          ],
        ),
      )

    );
  }
}