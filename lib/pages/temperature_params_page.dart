import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';

// 温度参数页面
class TemperatureParamsPage extends StatefulWidget {
  const TemperatureParamsPage({super.key});

  @override
  State<TemperatureParamsPage> createState() => _TemperatureParamsPageState();
}

class _TemperatureParamsPageState extends State<TemperatureParamsPage> {
  // 控制器
  late TextEditingController _chargeHighTempProtectController;
  late TextEditingController _chargeHighTempRecoverController;
  late TextEditingController _chargeLowTempProtectController;
  late TextEditingController _chargeLowTempRecoverController;
  late TextEditingController _dischargeHighTempProtectController;
  late TextEditingController _dischargeHighTempRecoverController;
  late TextEditingController _dischargeLowTempProtectController;
  late TextEditingController _dischargeLowTempRecoverController;

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    _chargeHighTempProtectController = TextEditingController(text: '0');
    _chargeHighTempRecoverController = TextEditingController(text: '0');
    _chargeLowTempProtectController = TextEditingController(text: '0');
    _chargeLowTempRecoverController = TextEditingController(text: '0');
    _dischargeHighTempProtectController = TextEditingController(text: '0');
    _dischargeHighTempRecoverController = TextEditingController(text: '0');
    _dischargeLowTempProtectController = TextEditingController(text: '0');
    _dischargeLowTempRecoverController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    // 释放控制器
    _chargeHighTempProtectController.dispose();
    _chargeHighTempRecoverController.dispose();
    _chargeLowTempProtectController.dispose();
    _chargeLowTempRecoverController.dispose();
    _dischargeHighTempProtectController.dispose();
    _dischargeHighTempRecoverController.dispose();
    _dischargeLowTempProtectController.dispose();
    _dischargeLowTempRecoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '温度参数'),
      body: Container(
        color: const Color(0xFF0A1128),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 表头
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '项目',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '参数',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '设定',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // 参数列表
              Expanded(
                child: ListView(
                  children: [
                    _buildParamRow('充电高温保护', _chargeHighTempProtectController, '°C'),
                    _buildParamRow('充电高温恢复', _chargeHighTempRecoverController, '°C'),
                    _buildParamRow('充电低温保护', _chargeLowTempProtectController, '°C'),
                    _buildParamRow('充电低温恢复', _chargeLowTempRecoverController, '°C'),
                    _buildParamRow('放电高温保护', _dischargeHighTempProtectController, '°C'),
                    _buildParamRow('放电高温恢复', _dischargeHighTempRecoverController, '°C'),
                    _buildParamRow('放电低温保护', _dischargeLowTempProtectController, '°C'),
                    _buildParamRow('放电低温恢复', _dischargeLowTempRecoverController, '°C'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建参数行
  Widget _buildParamRow(String name, TextEditingController controller, String unit) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: const Color(0xFF3A475E), width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 36,
                      child: TextField(
                        controller: controller,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () {
                    // 设置按钮点击事件
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  child: Text(
                    '设置',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
