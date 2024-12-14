import 'package:flutter/material.dart';

Color parseColor(String color) {
  switch (color.toLowerCase()) {
    case 'black':
      return Colors.black;
    case 'green':
      return Colors.green;
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'white':
      return Colors.white;
    default:
      return Colors.black; // 默认颜色
  }
}
