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

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('加载中...'),
            ],
          ),
        );
      },
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    if (mounted) {
      Navigator.of(context).pop();
    }
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '欢迎, ${userData.name}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
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
                    _showLoadingDialog(context);
                    final currentContext = context;
                    try {
                      bool success = await userData.loginAndSaveToken();
                      if (success) {
                        await userData.getPayId();
                        if (mounted) {
                          _hideLoadingDialog(currentContext);
                          DialogUtils.showAlertDialog(
                              currentContext, '成功', '登录成功');
                        }
                      } else {
                        if (mounted) {
                          _hideLoadingDialog(currentContext);
                          DialogUtils.showAlertDialog(
                              currentContext, '错误', '登录失败');
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        _hideLoadingDialog(currentContext);
                        DialogUtils.showAlertDialog(currentContext, '错误',
                            '发生错误：\n${e.toString()}\n请重试或联系管理员');
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
              subtitle: const Text("https://github.com/weijianxian/fzu_qrcode"),
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
    );
  }
}
