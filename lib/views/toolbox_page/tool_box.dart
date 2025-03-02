import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fzu_qrcode/models/theme_data.dart';

class ToolBoxPage extends StatefulWidget {
  const ToolBoxPage({super.key, required this.title});
  final String title;

  @override
  State<ToolBoxPage> createState() => _ToolBoxPageState();
}

class _ToolBoxPageState extends State<ToolBoxPage> {
  Widget genCard(
    BuildContext context, {
    required String arguments,
    required String title,
    required String path,
    required Widget icon,
  }) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.5 * 255).toInt()),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: icon,
        title: Text(title),
        onTap: () => Navigator.pushNamed(context, path, arguments: arguments),
        trailing: const Icon(Icons.arrow_right),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          genCard(context,
              title: '淘宝我的驿站页面',
              icon: const Icon(Icons.delivery_dining),
              path: "/webview",
              arguments:
                  'https://pages-fast.m.taobao.com/wow/z/uniapp/1011717/last-mile-fe/end-collect-platform/school'),
          genCard(context,
              title: "淘宝身份码",
              icon: const Icon(Icons.code),
              path: "/webview",
              arguments:
                  'https://pages-fast.m.taobao.com/wow/z/uniapp/1011717/last-mile-fe/end-collect-platform/identity-code'),
          genCard(context,
              title: "菜鸟出库码",
              icon: const Icon(Icons.code),
              path: "/webview",
              arguments:
                  'https://market.m.taobao.com/app/cn-yz/multi-activity/authCode.html?bizEntry=ALIPAY_GUOGUO'),
        ],
      ),
    );
  }
}
