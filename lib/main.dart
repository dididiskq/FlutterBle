import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'navigator.dart';
import 'pages/privacy_policy_page.dart';

void main() {
  // 设置系统UI样式，将状态栏和导航栏颜色设置为透明
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    // 状态栏颜色透明
    statusBarColor: Colors.transparent,
    // 导航栏颜色透明
    systemNavigationBarColor: Colors.transparent,
    // 状态栏图标颜色（Android）
    statusBarIconBrightness: Brightness.light,
    // 导航栏图标颜色
    systemNavigationBarIconBrightness: Brightness.dark,
    // 导航栏分割线颜色
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultra bms',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PrivacyPolicyPage(),
    );
  }
}
