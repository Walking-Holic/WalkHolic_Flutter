import 'package:flutter/material.dart';
import 'package:fresh_store_ui/screens/tabbar/tabbar.dart';

class CustomFormButton extends StatelessWidget {
  final String innerText;
  final void Function()? onPressed;
  const CustomFormButton({Key? key, required this.innerText, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      width: size.width * 0.8,
      decoration: BoxDecoration(
        color: const Color(0xff233743),
        borderRadius: BorderRadius.circular(26),
      ),
      child: TextButton(
        onPressed: (){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FRTabbarScreen()),
          );
        },
        child: Text(innerText, style: const TextStyle(color: Colors.white, fontSize: 20),),
      ),
    );
  }
}
