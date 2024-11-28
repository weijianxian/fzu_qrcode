import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widgets/barcode_flutter.dart';
import '../utils/user_data.dart';
import '../utils/dialog_utils.dart';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (userData.isLoggedIn) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '欢迎, ${userData.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const Text('消费码:', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  if (userData.payIdList.isNotEmpty)
                    Center(
                      child: QrImageView(
                        data: userData.payIdList.first.prePayId,
                        version: QrVersions.auto,
                        size: constraints.maxWidth * 0.6,
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (userData.payIdList.isNotEmpty)
                    Center(
                      child: BarCodeImage(
                        params: Code128BarCodeParams(
                          userData.payIdList.first.prePayId,
                          withText: true,
                          lineWidth: 1,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshPayId,
                    child: const Text('刷新消费码'),
                  ),
                ],
              );
            } else {
              return const Text('请先登录');
            }
          },
        ),
      ),
    );
  }
}
