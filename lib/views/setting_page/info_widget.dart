import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class InfoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text("项目地址"),
          subtitle: const Text("https://github.com/weijianxian/fzu_qrcode"),
          onTap: () => launchUrlString(
              "https://github.com/weijianxian/fzu_qrcode",
              mode: LaunchMode.externalApplication),
          trailing: const Icon(Icons.arrow_right),
        ),
        ListTile(
          leading: const Icon(Icons.bug_report),
          title: const Text("报告问题"),
          subtitle:
              const Text("https://github.com/weijianxian/fzu_qrcode/issues"),
          onTap: () => launchUrlString(
              "https://github.com/weijianxian/fzu_qrcode/issues"),
          trailing: const Icon(Icons.arrow_right),
        ),
      ],
    );
  }
}
