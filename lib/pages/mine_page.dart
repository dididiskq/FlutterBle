import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ultra_bms/pages/battery_info_page.dart';
import 'package:ultra_bms/pages/firmware_update_page.dart';
import 'package:ultra_bms/pages/production_panel_page.dart';
import 'package:ultra_bms/pages/bms_control_page.dart';
import 'package:ultra_bms/pages/privacy_policy_page.dart';
import 'package:ultra_bms/managers/language_manager.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageManager>(
      builder: (context, languageManager, child) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(55.0),
            child: Container(
              color: Colors.black, // 设置背景色为黑色，与底部导航栏一致
              padding: const EdgeInsets.fromLTRB(10.0, 44.0, 10.0, 10.0),
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧空白占位 - 完全模拟设置页面的结构
                  SizedBox(
                    width: 80.0,
                    child: IconButton(
                      icon: const Icon(Icons.menu, color: Colors.transparent), // 透明图标
                      onPressed: () {}, // 空点击事件
                    ),
                  ),
                  // ultra bms标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      // border: Border.all(color: Colors.red, width: 1),
                      // borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: const Text(
                      'Ultra Bms',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 右侧空白占位 - 与设置页面完全相同
                  const SizedBox(width: 80.0),
                ],
              ),
            ),
          ),
          body: Container(
            color: const Color(0xFF0A1128),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BatteryInfoPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2332),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 16.0, color: Colors.white),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(color: Color(0xFF3A475E), width: 1),
                      ),
                    ),
                    child: Text(languageManager.batteryInfoButtonText),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FirmwareUpdatePage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2332),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 16.0, color: Colors.white),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(color: Color(0xFF3A475E), width: 1),
                      ),
                    ),
                    child: Text(languageManager.firmwareUpdateButtonText),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductionPanelPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2332),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 16.0, color: Colors.white),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(color: Color(0xFF3A475E), width: 1),
                      ),
                    ),
                    child: Text(languageManager.productionPanelButtonText),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BmsControlPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2332),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 16.0, color: Colors.white),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(color: Color(0xFF3A475E), width: 1),
                      ),
                    ),
                    child: Text(languageManager.bmsControlButtonText),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2332),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 16.0, color: Colors.white),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: const BorderSide(color: Color(0xFF3A475E), width: 1),
                      ),
                    ),
                    child: Text(languageManager.protocolPolicyButtonText),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}