import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login/login_page.dart';



class AppbarSkip extends StatelessWidget implements PreferredSizeWidget {
  const AppbarSkip({super.key});

  void skipTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isFirstRun', false);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFF4EDDB),
      leading: InkWell(
        onTap: () {
          skipTutorial();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.only(
            left: 20,
            top: 10,
          ),
          child: Text(
            "SKIP",
            style: TextStyle(
              color: Color(0xFF232B55),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}