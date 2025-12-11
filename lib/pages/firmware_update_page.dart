import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';

class FirmwareUpdatePage extends StatelessWidget {
  const FirmwareUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      appBar: CommonAppBar(title: '固件升级'),
      body: Container(
        color: const Color(0xFF0A1128),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 固件版本信息
              _buildVersionCard('固件版本', 'V1.0.0'),
              const SizedBox(height: 20.0),
              
              // 软件版本信息
              _buildVersionCard('软件版本', 'V2.1.5'),
              const SizedBox(height: 30.0),
              
              // 检查更新按钮
              _buildCheckUpdateButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 构建版本信息卡片
  Widget _buildVersionCard(String title, String version) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16.0)),
          Text(version, style: const TextStyle(color: Colors.blue, fontSize: 16.0, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 构建检查更新按钮
  Widget _buildCheckUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // 实现检查更新功能
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A2332),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          textStyle: const TextStyle(fontSize: 18.0, color: Colors.white),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: const BorderSide(color: const Color(0xFF3A475E), width: 1),
          ),
          elevation: 0,
        ),
        child: const Text('检查更新'),
      ),
    );
  }
}