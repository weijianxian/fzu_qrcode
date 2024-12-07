import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/user_data.dart';
import '../utils/dialog_utils.dart';
import '../utils/theme_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _refreshPayId() async {
    final userData = Provider.of<UserData>(context, listen: false);
    try {
      await userData.getPayId();
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
    if (userData.payIdList.isEmpty) {
      _refreshPayId();
    }
    if (userData.isLoggedIn && userData.payIdList.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: [
            IconButton(
              onPressed: () {
                DialogUtils.showAlertDialog(context, "关于", "FZUQrCode");
              },
              icon: const Icon(Icons.info),
            ),
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: () {
                Provider.of<ThemeDataNotifier>(context, listen: false)
                    .toggleTheme();
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '欢迎, ${userData.name}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const Text('消费码:', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Center(
                child: QrImageView(
                  data: userData.payIdList.first.prePayId,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                  size: MediaQuery.of(context).size.width >=
                          MediaQuery.of(context).size.height
                      ? MediaQuery.of(context).size.height * 0.4
                      : MediaQuery.of(context).size.width * 0.8,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _refreshPayId,
          child: const Icon(Icons.refresh),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: const Center(
          child: Text("请先登录"),
        ),
      );
    }
  }
}
