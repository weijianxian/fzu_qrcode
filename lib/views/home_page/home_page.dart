import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:fzu_qrcode/models/user_data.dart';
import 'package:fzu_qrcode/models/theme_data.dart';
import 'package:fzu_qrcode/utils/dialog_utils.dart';
import 'package:fzu_qrcode/utils/parse_color.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _refresh() async {
    final userData = Provider.of<UserData>(context, listen: false);
    try {
      await userData.getPayId();
      await userData.getIdentifyCode();
    } catch (e) {
      if (mounted) {
        DialogUtils.showAlertDialog(
            context, "Error", "发生错误：\n${e.toString()}\n请重试或联系管理员");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);
    bool isLandscape =
        MediaQuery.of(context).size.width >= MediaQuery.of(context).size.height;
    if (userData.payIdList.isEmpty || userData.identifyID.content.isEmpty) {
      _refresh();
    }
    if (userData.isLoggedIn && userData.payIdList.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: () {
                Provider.of<ThemeDataNotifier>(context, listen: false)
                    .toggleTheme();
              },
            ),
          ],
        ),
        body: isLandscape
            ? SingleChildScrollView(
                child: Row(
                  children: [
                    SizedBox(
                        width: MediaQuery.of(context).size.width / 2,
                        child: genPage(
                            "消费码", userData.payIdList.first.prePayId, "black")),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2,
                      child: genPage("认证码", userData.identifyID.content,
                          userData.identifyID.color),
                    ),
                  ],
                ),
              )
            : PageView(
                scrollDirection: Axis.vertical,
                children: [
                  genPage("消费码", userData.payIdList.first.prePayId, "black"),
                  genPage("认证码", userData.identifyID.content,
                      userData.identifyID.color),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _refresh,
          child: const Icon(Icons.refresh),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(widget.title),
        ),
        body: const Center(
          child: Text("请先登录", style: TextStyle(fontSize: 30)),
        ),
      );
    }
  }

  Widget genPage(
    String codeTitle,
    String codeData,
    String color,
  ) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool isLandscape = screenWidth >= screenHeight;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            codeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.5 * 255).toInt()),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: QrImageView(
              data: codeData,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: parseColor(color),
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: parseColor(color),
              ),
              backgroundColor: Colors.white,
              size: isLandscape ? screenHeight * 0.45 : screenWidth * 0.8,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
