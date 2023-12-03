import 'package:flutter/material.dart';

class RankImage {
  static Widget getRankImage(String rank,{double width = 24.0, double height = 24.0}) {
    String imagePath;
    switch (rank.toLowerCase()) {
      case 'bronze':
        imagePath = 'assets/ranks/bronze.png';
        break;
      case 'silver':
        imagePath = 'assets/ranks/silver.png';
        break;
      case 'gold':
        imagePath = 'assets/ranks/gold.png';
        break;
      case 'platinum':
        imagePath = 'assets/ranks/platinum.png';
        break;
      case 'diamond':
        imagePath = 'assets/ranks/diamond.png';
        break;
      default:
        imagePath = 'assets/icons/board1.png'; // 기본 랭크 이미지
    }

    return Image.asset(imagePath, width: width, height: height);
  }
}