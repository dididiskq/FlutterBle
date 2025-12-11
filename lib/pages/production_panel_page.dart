import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';

class ProductionPanelPage extends StatelessWidget {
  const ProductionPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      appBar: CommonAppBar(title: '生产操作面板'),
      body: Container(
        color: const Color(0xFF0A1128),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 电流归零按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 实现电流归零功能
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2332),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(fontSize: 18.0, color: Colors.white),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(color: Color(0xFF3A475E), width: 1),
                    ),
                  ),
                  child: const Text('电流归零'),
                ),
              ),
              const SizedBox(height: 20.0),
              
              // 蓝牙名称输入框
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: const Color(0xFF3A475E), width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '请输入蓝牙名称',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              
              // 写入蓝牙名称按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 实现写入蓝牙名称功能
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
                  child: const Text('写入蓝牙名称'),
                ),
              ),
              const SizedBox(height: 20.0),
              
              // 扫一扫按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 实现扫一扫功能
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2332),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(fontSize: 18.0, color: Colors.white),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(color: Color(0xFF3A475E), width: 1),
                    ),
                  ),
                  child: const Text('扫一扫'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}