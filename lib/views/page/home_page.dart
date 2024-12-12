import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_data.dart';
import '../../utils/dialog_utils.dart';
import '../../models/theme_data.dart';

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
          backgroundColor: Theme.of(context).colorScheme.primary,
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: userData.payIdList.first.prePayId,
                  backgroundColor: Colors.white,
                  size: MediaQuery.of(context).size.width >=
                          MediaQuery.of(context).size.height
                      ? MediaQuery.of(context).size.height * 0.4
                      : MediaQuery.of(context).size.width * 0.7,
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
          child: Text("请先登录", style: TextStyle(fontSize: 30)),
        ),
      );
    }
  }
}
