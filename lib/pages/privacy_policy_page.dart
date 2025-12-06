import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigator.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10.0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              const Text(
                '隐私政策',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20.0),
              
              // 隐私政策内容
              SizedBox(
                height: 200.0,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '欢迎使用Ultra BMS应用！',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Text(
                        '我们非常重视您的隐私保护和个人信息安全。为了更好地向您提供服务，请您仔细阅读并理解本隐私政策。',
                        style: TextStyle(fontSize: 14.0),
                      ),
                      SizedBox(height: 10.0),
                      Text(
                        '1. 我们收集的信息：',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '   - 设备信息：如设备型号、操作系统版本等',
                        style: TextStyle(fontSize: 14.0),
                      ),
                      Text(
                        '   - BMS数据：如电池电压、电流、温度等',
                        style: TextStyle(fontSize: 14.0),
                      ),
                      SizedBox(height: 10.0),
                      Text(
                        '2. 信息使用：',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '   - 用于提供BMS监控和管理功能',
                        style: TextStyle(fontSize: 14.0),
                      ),
                      Text(
                        '   - 用于改进产品性能和用户体验',
                        style: TextStyle(fontSize: 14.0),
                      ),
                      SizedBox(height: 10.0),
                      Text(
                        '3. 信息安全：',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '   - 我们采取严格的安全措施保护您的信息',
                        style: TextStyle(fontSize: 14.0),
                      ),
                      Text(
                        '   - 不会将您的信息泄露给第三方',
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              
              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 不同意按钮
                  ElevatedButton(
                    onPressed: () {
                      // 退出应用
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
                    ),
                    child: const Text(
                      '不同意',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  
                  // 同意按钮
                  ElevatedButton(
                    onPressed: () {
                      // 进入应用主界面
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainNavigator()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
                    ),
                    child: const Text(
                      '同意',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}