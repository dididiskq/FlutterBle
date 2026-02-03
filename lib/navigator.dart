import 'package:flutter/material.dart';
import 'package:ultra_bms/managers/battery_data_manager.dart';
import 'package:ultra_bms/pages/main_page.dart';
import 'package:ultra_bms/pages/mine_page.dart';
import 'package:ultra_bms/pages/set_page.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 1; // 默认选中主页
  
  // 电池数据管理器（单例）
  final BatteryDataManager _batteryDataManager = BatteryDataManager();

  final List<Widget> _pages = const [
    SetPage(),
    MainPage(),
    MinePage(),
  ];

  @override
  void initState() {
    super.initState();
    // 根据初始页面类型控制数据读取
    _controlDataReading(_currentIndex);
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      // 根据新页面类型控制数据读取
      _controlDataReading(index);
    });
  }
  
  // 根据页面索引控制数据读取
  void _controlDataReading(int index) {
    // 更新 BatteryDataManager 中的当前页面索引
    _batteryDataManager.setCurrentIndex(index);
    
    if (index == 0 || index == 1) {
      // 首页或设置页，启动自动读取
      _batteryDataManager.startAutoRead();
    } else {
      // 其他页面，停止自动读取
      _batteryDataManager.stopAutoRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 让内容延伸到AppBar下方
      extendBodyBehindAppBar: true,
      // 让内容延伸到底部导航栏下方
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '主页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        selectedItemColor: Colors.blue, // 选中项颜色
        unselectedItemColor: Colors.grey, // 未选中项颜色
        backgroundColor: Colors.black, // 导航栏背景色
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}