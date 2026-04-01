// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fzu_qrcode/utils/dialog_utils.dart';
import 'package:fzu_qrcode/models/user_data.dart';

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

  Future<String?> _showTwoFactorDialog(
    String phone,
    String tip,
    Future<void> Function() sendSms,
  ) async {
    final codeController = TextEditingController();
    bool sending = false;

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          Future<void> onSendPressed() async {
            try {
              setState(() => sending = true);
              await sendSms();
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('验证码已发送')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('发送失败: $e')),
                );
              }
            } finally {
              if (mounted) {
                setState(() => sending = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('两步验证'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip),
                const SizedBox(height: 8),
                Text('手机号: $phone'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: sending ? null : onSendPressed,
                    child: Text(sending ? '发送中...' : '发送验证码'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '短信验证码',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(null),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(codeController.text.trim());
                },
                child: const Text('确认'),
              ),
            ],
          );
        });
      },
    );

    codeController.dispose();
    return result;
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

                var loadingShown = true;
                DialogUtils.showLoadingDialog(context);
                final currentContext = context;
                try {
                  Future<String?> twoFactorCallback(
                    String phone,
                    String tip,
                    Future<void> Function() sendSms,
                  ) async {
                    if (mounted && loadingShown) {
                      Navigator.of(currentContext).pop();
                      loadingShown = false;
                    }

                    final code = await _showTwoFactorDialog(phone, tip, sendSms);

                    if (mounted && !loadingShown) {
                      DialogUtils.showLoadingDialog(currentContext);
                      loadingShown = true;
                    }
                    return code;
                  }

                  await userData.loginAndSaveToken(twoFactorCallback);
                  await userData.getPayId();
                  if (mounted && loadingShown) {
                    Navigator.of(context).pop();
                    DialogUtils.showTipsDialog(currentContext, '成功', '登录成功');
                    // 隐藏键盘
                    studentIdFocusNode.unfocus();
                    passwordFocusNode.unfocus();
                  }
                } catch (e) {
                  if (mounted && loadingShown) {
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
