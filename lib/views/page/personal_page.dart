// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_data.dart';
import '../../utils/dialog_utils.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key, required this.title});
  final String title;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
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
            )
          ],
        ),
      ),
    );
  }
}
