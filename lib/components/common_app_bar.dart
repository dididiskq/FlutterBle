import 'package:flutter/material.dart';
import '../managers/battery_data_manager.dart';

// 通用AppBar组件
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final BatteryDataManager _batteryDataManager = BatteryDataManager();
  CommonAppBar({super.key, required this.title});

 
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(10.0, 44.0, 10.0, 10.0),
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 返回按钮
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.red, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            onPressed: () {
              // 开始自动读取
              _batteryDataManager.startAutoRead();
              Navigator.pop(context);
            },
            child: const Text('返回'),
          ),
          // 页面标题
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            decoration: BoxDecoration(
              // border: Border.all(color: Colors.red, width: 1),
              // borderRadius: BorderRadius.circular(5.0),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 占位符，保持按钮居中
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(55.0);
}