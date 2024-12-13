import 'package:flutter/material.dart';
import 'package:fzu_qrcode/models/user_data.dart';
import 'package:fzu_qrcode/models/theme_data.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.title});
  final String title;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

    if (userData.isLoggedIn && userData.payIdList.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(widget.title),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '图书馆电子证件',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: userData.studentId,
                  backgroundColor: Colors.white,
                  size: MediaQuery.of(context).size.width >=
                          MediaQuery.of(context).size.height
                      ? MediaQuery.of(context).size.height * 0.4
                      : MediaQuery.of(context).size.width * 0.7,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Text(widget.title),
        ),
        body: const Center(
          child: Text("请先登录", style: TextStyle(fontSize: 30)),
        ),
      );
    }
  }
}
