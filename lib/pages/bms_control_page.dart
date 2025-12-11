import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';

class BmsControlPage extends StatefulWidget {
  const BmsControlPage({super.key});

  @override
  State<BmsControlPage> createState() => _BmsControlPageState();
}

class _BmsControlPageState extends State<BmsControlPage> {
  // 开关状态
  bool _weakPowerSwitch = false;
  bool _forceChargeSwitch = false;
  bool _forceDischargeSwitch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      appBar: CommonAppBar(title: '设备控制'),
      body: Container(
        color: const Color(0xFF0A1128),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 系统控制按钮组
              _buildControlButton('系统关机'),
              _buildControlButton('恢复出厂'),
              _buildControlButton('重启系统'),
              _buildControlButton('切换为英文'),
              const SizedBox(height: 20.0),
              
              // 弱电开关
              _buildSwitchRow('弱电开关', _weakPowerSwitch, (value) {
                setState(() {
                  _weakPowerSwitch = value;
                });
              }),
              const SizedBox(height: 20.0),
              
              // 充电放电控制
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: const Color(0xFF3A475E), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '强制充电控制',
                              style: const TextStyle(color: Colors.white, fontSize: 13.0),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Switch(
                            value: _forceChargeSwitch,
                            onChanged: (value) {
                              setState(() {
                                _forceChargeSwitch = value;
                              });
                            },
                            activeColor: Colors.blue,
                            inactiveTrackColor: const Color(0xFF3A475E),
                            inactiveThumbColor: Colors.grey,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: const Color(0xFF3A475E), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '强制放电控制',
                              style: const TextStyle(color: Colors.white, fontSize: 13.0),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Switch(
                            value: _forceDischargeSwitch,
                            onChanged: (value) {
                              setState(() {
                                _forceDischargeSwitch = value;
                              });
                            },
                            activeColor: Colors.blue,
                            inactiveTrackColor: const Color(0xFF3A475E),
                            inactiveThumbColor: Colors.grey,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
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

  // 构建控制按钮
  Widget _buildControlButton(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // 实现按钮功能
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(fontSize: 16.0, color: Colors.white),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 0,
          ),
          child: Text(title),
        ),
      ),
    );
  }

  // 构建带开关的行
  Widget _buildSwitchRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16.0)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
            inactiveTrackColor: const Color(0xFF3A475E),
            inactiveThumbColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}