import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:fzu_qrcode/models/user_data.dart';
import 'package:fzu_qrcode/utils/dialog_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _didAutoRefreshOnStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleAutoRefreshOnStart();
    });
  }

  void _scheduleAutoRefreshOnStart() {
    if (!mounted || _didAutoRefreshOnStart) {
      return;
    }

    final userData = Provider.of<UserData>(context, listen: false);
    if (userData.isInitialized) {
      _didAutoRefreshOnStart = true;
      _autoRefreshOnStart();
      return;
    }

    late VoidCallback listener;
    listener = () {
      if (!mounted) {
        userData.removeListener(listener);
        return;
      }

      if (!userData.isInitialized || _didAutoRefreshOnStart) {
        return;
      }

      _didAutoRefreshOnStart = true;
      userData.removeListener(listener);
      _autoRefreshOnStart();
    };

    userData.addListener(listener);
  }

  Future<void> _autoRefreshOnStart() async {
    if (!mounted) return;
    final userData = Provider.of<UserData>(context, listen: false);
    if (!userData.isLoggedIn) {
      return;
    }

    try {
      await userData.getPayId();
    } catch (e) {
      debugPrint('[HomePage] 启动自动刷新失败: $e');
    }
  }

  Future<void> _refreshQrCode() async {
    final userData = Provider.of<UserData>(context, listen: false);
    if (!userData.isLoggedIn) {
      if (!mounted) return;
      await DialogUtils.showTipsDialog(context, '提示', '请先在设置页完成登录');
      return;
    }

    if (!mounted) return;

    try {
      await userData.getPayId();
    } catch (e) {
      debugPrint('[HomePage] 获取失败: $e');

      if (!mounted) {
        return;
      }

      await DialogUtils.showAlertDialog(
          context, const Text('刷新失败'), [Text('错误: ${e.toString()}')]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserData>(
      builder: (context, userData, _) {
        final qrText = userData.identifyID.content;
        // 确保 qrText 不为空且有效
        final hasValidQr = qrText.isNotEmpty && qrText.length > 10;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: Text(widget.title),
          ),
          body: Center(
            child:
                hasValidQr ? qrcodeWidget(context, qrText) : notLoginWidget(),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _refreshQrCode,
            tooltip: '刷新二维码',
            child: const Icon(Icons.refresh),
          ),
        );
      },
    );
  }
}

Widget qrcodeWidget(context, String qrText) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final nimiScreen = screenWidth < screenHeight ? screenWidth : screenHeight;

  return Center(
    child: Container(
      width: nimiScreen - 100,
      padding: EdgeInsets.all(nimiScreen * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: QrImageView(
          data: qrText,
          version: QrVersions.auto,
          errorStateBuilder: (context, error) {
            return Center(
              child: Text(
                '二维码加载失败\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

Widget notLoginWidget() {
  return const Center(
    child: Text(
      '请先登录并刷新',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.black54,
      ),
    ),
  );
}
