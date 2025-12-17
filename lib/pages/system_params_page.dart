import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';

// 系统参数页面
class SystemParamsPage extends StatefulWidget {
  const SystemParamsPage({super.key});

  @override
  State<SystemParamsPage> createState() => _SystemParamsPageState();
}

class _SystemParamsPageState extends State<SystemParamsPage> {
  // 控制器
  late TextEditingController _ratedChargeVoltageController;
  late TextEditingController _ratedChargeCurrentController;
  late TextEditingController _sleepDelayController;
  late TextEditingController _shutdownDelayController;
  late TextEditingController _fullChargeDelayController;
  late TextEditingController _fullChargeVoltageController;
  late TextEditingController _fullChargeCurrentController;
  late TextEditingController _zeroCurrentThresholdController;

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    _ratedChargeVoltageController = TextEditingController(text: '0');
    _ratedChargeCurrentController = TextEditingController(text: '0');
    _sleepDelayController = TextEditingController(text: '0');
    _shutdownDelayController = TextEditingController(text: '0');
    _fullChargeDelayController = TextEditingController(text: '0');
    _fullChargeVoltageController = TextEditingController(text: '0');
    _fullChargeCurrentController = TextEditingController(text: '0');
    _zeroCurrentThresholdController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    // 释放控制器
    _ratedChargeVoltageController.dispose();
    _ratedChargeCurrentController.dispose();
    _sleepDelayController.dispose();
    _shutdownDelayController.dispose();
    _fullChargeDelayController.dispose();
    _fullChargeVoltageController.dispose();
    _fullChargeCurrentController.dispose();
    _zeroCurrentThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '系统参数'),
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
                      _buildParamRow('额定充电电压', _ratedChargeVoltageController, '0.1V'),
                      _buildParamRow('额定充电电流', _ratedChargeCurrentController, '0.1A'),
                      _buildParamRow('休眠延时', _sleepDelayController, 's'),
                      _buildParamRow('关机延时', _shutdownDelayController, 's'),
                      _buildParamRow('充满延时', _fullChargeDelayController, 's'),
                      _buildParamRow('充满电压', _fullChargeVoltageController, 'mV'),
                      _buildParamRow('充满电流', _fullChargeCurrentController, 'mA'),
                      _buildParamRow('零电流显示阈值', _zeroCurrentThresholdController, 'mA'),
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
                    Flexible(
                      child: SizedBox(
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
                    ),
                    SizedBox(width: 8),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    minimumSize: Size(60, 36),
                  ),
                  child: Text(
                    '设置',
                    style: TextStyle(
                      fontSize: 14,
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
