import 'package:flutter/material.dart';
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

  final List<Widget> _pages = const [
    SetPage(),
    MainPage(),
    MinePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
        selectedItemColor: Colors.red, // 选中项颜色
        unselectedItemColor: Colors.grey, // 未选中项颜色
        backgroundColor: Colors.black, // 导航栏背景色
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}