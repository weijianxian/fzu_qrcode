// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:fzu_qrcode/models/user_data.dart';
import 'package:fzu_qrcode/models/theme_data.dart';
import 'package:fzu_qrcode/utils/dialog_utils.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key, required this.title});
  final String title;

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final userData = Provider.of<UserData>(context, listen: false);
    _studentIdController.text = userData.studentId;
    _passwordController.text = userData.password;
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '欢迎, ${userData.name}',
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: '学号',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  userData.setStudentId(value);
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) {
                  userData.setPassword(value);
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      userData.setStudentId(_studentIdController.text);
                      userData.setPassword(_passwordController.text);
                      if (userData.studentId.isEmpty ||
                          userData.password.isEmpty) {
                        DialogUtils.showAlertDialog(context, '错误', '学号和密码不能为空');
                        return;
                      }
                      DialogUtils.showLoadingDialog(context); // 显示加载对话框
                      final currentContext = context;
                      try {
                        await userData.loginAndSaveToken();
                        await userData.getPayId();
                        if (mounted) {
                          Navigator.of(context).pop();

                          DialogUtils.showTipsDialog(
                              currentContext, '成功', '登录成功');
                        }
                        FocusScope.of(context).unfocus(); // 隐藏键盘
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(context).pop();

                          DialogUtils.showAlertDialog(
                              currentContext, '错误', '错误信息如下：\n${e.toString()}');
                        }
                      }
                    },
                    child: const Text("登录"),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      userData.logout();
                      _studentIdController.text = '';
                      _passwordController.text = '';
                    },
                    child: const Text("登出"),
                  ),
                ],
              ),
              const Divider(height: 40, thickness: 2),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text("项目地址"),
                subtitle:
                    const Text("https://github.com/weijianxian/fzu_qrcode"),
                onTap: () => launchUrlString(
                    "https://github.com/weijianxian/fzu_qrcode",
                    mode: LaunchMode.externalApplication),
                trailing: const Icon(Icons.arrow_right),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text("报告问题"),
                subtitle: const Text(
                    "https://github.com/weijianxian/fzu_qrcode/issues"),
                onTap: () => launchUrlString(
                    "https://github.com/weijianxian/fzu_qrcode/issues"),
                trailing: const Icon(Icons.arrow_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
