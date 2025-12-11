import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/privacy_policy_dialog.dart';
import '../navigator.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // 显示隐私政策弹窗
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPrivacyPolicyDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 可以在这里添加应用logo
            const Icon(
              Icons.battery_charging_full,
              size: 80.0,
              color: Colors.white,
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Ultra BMS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 显示隐私政策弹窗
  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 必须用户操作才能关闭
      builder: (context) => const PrivacyPolicyDialog(),
    ).then((value) {
      if (value == true) {
        // 用户同意隐私政策，进入主页面
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigator(),
          ),
        );
      } else {
        // 用户不同意隐私政策，退出应用
        SystemNavigator.pop();
      }
    });
  }
}
