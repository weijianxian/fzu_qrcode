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
  @override
  void initState() {
    super.initState();
    _refreshPayId();
  }

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: PageView(
        scrollDirection: Axis.vertical,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '欢迎, ${userData.name}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const Text('消费码:', textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        if (userData.payIdList.isNotEmpty)
                          QrImageView(
                            data: userData.payIdList.first['prePayId'],
                            version: QrVersions.auto,
                            size: constraints.maxWidth * 0.6,
                          ),
                        const SizedBox(height: 20),
                        if (userData.payIdList.isNotEmpty)
                          BarCodeImage(
                            params: Code128BarCodeParams(
                              userData.payIdList.first['prePayId'],
                              withText: true,
                            ),
                          ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _refreshPayId,
                          child: const Text('刷新消费码'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                const Text(
                  '调试信息:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...userData.payIdList.map((payId) {
                  return ListTile(
                    title: Text('Pay ID: ${payId['prePayId']}'),
                    subtitle: Text('Expired Time: ${payId['expiredTime']}'),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
