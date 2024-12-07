import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeDataNotifier with ChangeNotifier {
  bool _isDarkMode = false;

  get isDarkMode => _isDarkMode;

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, // 去除状态栏遮罩
            statusBarIconBrightness: Brightness.dark, // 状态栏图标字体颜色
            systemNavigationBarColor:
                Color.fromARGB(255, 242, 247, 251), // 底部导航栏颜色
          ),
        ),
        primarySwatch: Colors.blue,
        fontFamily: "JetBrainsMono", // 设置全局字体
        splashFactory: NoSplash.splashFactory, // 禁用水波纹效果
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent, // 去除状态栏遮罩
            statusBarIconBrightness: Brightness.light, // 状态栏图标字体颜色
            systemNavigationBarColor: Colors.black, // 底部导航栏颜色
          ),
        ),
        primarySwatch: Colors.blue,
        fontFamily: "JetBrainsMono", // 设置全局字体
        splashFactory: NoSplash.splashFactory, // 禁用水波纹效果
      );

  ThemeData get themeData => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void updateSystemTheme(Brightness brightness) {
    _isDarkMode = brightness == Brightness.dark;
    notifyListeners();
  }
}
