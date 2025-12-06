import 'package:flutter/material.dart';
import 'package:ultra_bms/pages/device_list_page.dart';
import 'package:ultra_bms/pages/scan_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          color: Colors.blue.withOpacity(0.9), // 设置背景色带透明度
          padding: const EdgeInsets.fromLTRB(10.0, 44.0, 10.0, 10.0), // 调整padding避开状态栏
          alignment: Alignment.bottomCenter, // 垂直对齐到底部
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 设备列表按钮
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeviceListPage()),
                  );
                },
                child: const Text('设备列表'),
              ),
              // ultra bms标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: const Text(
                  'Ultra Bms',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 扫一扫按钮
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanPage()),
                  );
                },
                child: const Text('扫一扫'),
              ),
            ],
          ),
        ),
      ),
      body: const Center(
        child: Text('主页'),
      ),
    );
  }
}