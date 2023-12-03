import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.8,  // 이미지의 너비를 화면 너비의 80%로 설정
      height: size.height * 0.2,
      child: Image.asset('assets/icons/headForm.png',),
    );
  }
}
