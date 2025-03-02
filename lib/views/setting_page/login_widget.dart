// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fzu_qrcode/models/user_data.dart';
import 'package:fzu_qrcode/utils/dialog_utils.dart';

class LoginYMTwigit extends StatefulWidget {
  const LoginYMTwigit({super.key});

  @override
  State<LoginYMTwigit> createState() => _LoginYMTwigitState();
}

class _LoginYMTwigitState extends State<LoginYMTwigit> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final FocusNode studentIdFocusNode;
  late final FocusNode passwordFocusNode;

  @override
  void initState() {
    super.initState();
    final userData = Provider.of<UserData>(context, listen: false);
    _studentIdController.text = userData.studentId;
    _passwordController.text = userData.password;
    studentIdFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    studentIdFocusNode.dispose();
    passwordFocusNode.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

    return Column(
      children: [
        TextField(
          controller: _studentIdController,
          decoration: const InputDecoration(
            labelText: '学号',
            border: OutlineInputBorder(),
          ),
          focusNode: studentIdFocusNode,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: '密码',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
          focusNode: passwordFocusNode,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                userData.setStudentId(_studentIdController.text);
                userData.setPassword(_passwordController.text);

                DialogUtils.showLoadingDialog(context); // 显示加载对话框
                final currentContext = context;
                try {
                  await userData.loginAndSaveToken();
                  await userData.getPayId();
                  if (mounted) {
                    Navigator.of(context).pop();
                    DialogUtils.showTipsDialog(currentContext, '成功', '登录成功');
                    // 隐藏键盘
                    studentIdFocusNode.unfocus();
                    passwordFocusNode.unfocus();
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();

                    DialogUtils.showAlertDialog(
                        currentContext, const Text('错误'), [Text(e.toString())]);
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
      ],
    );
  }
}
