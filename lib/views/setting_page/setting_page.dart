import 'package:flutter/material.dart';
import 'package:fzu_qrcode/views/setting_page/login_widget.dart';
import 'package:fzu_qrcode/views/setting_page/info_widget.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '登录',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const LoginYMTwigit(),
              const SizedBox(height: 32),
              const Text(
                '关于',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const InfoWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
