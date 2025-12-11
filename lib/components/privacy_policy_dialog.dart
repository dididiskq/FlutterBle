import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/privacy_policy_page.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A1128),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            const Text(
              '隐私政策确认',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20.0),
            
            // 简短说明
            const Text(
              '在使用我们的BMS电池管理系统应用前，请您仔细阅读并同意我们的隐私政策。',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 15.0),
            
            // 查看完整协议按钮
            GestureDetector(
              onTap: () {
                // 关闭对话框
                Navigator.of(context).pop();
                // 打开完整隐私政策页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage(),
                  ),
                );
              },
              child: const Text(
                '查看完整隐私政策',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14.0,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            
            // 按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 不同意按钮
                ElevatedButton(
                  onPressed: () {
                    // 退出应用
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A475E),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF5A677E)),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('不同意'),
                ),
                const SizedBox(width: 15.0),
                
                // 同意按钮
                ElevatedButton(
                  onPressed: () {
                    // 同意隐私政策，关闭对话框
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('同意'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
