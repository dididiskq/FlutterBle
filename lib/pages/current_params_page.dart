import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';

// 电流参数页面
class CurrentParamsPage extends StatefulWidget {
  const CurrentParamsPage({super.key});

  @override
  State<CurrentParamsPage> createState() => _CurrentParamsPageState();
}

class _CurrentParamsPageState extends State<CurrentParamsPage> {
  // 控制器
  late TextEditingController _chargeOvercurrent1ProtectController;
  late TextEditingController _chargeOvercurrent1DelayController;
  late TextEditingController _dischargeOvercurrent1ProtectController;
  late TextEditingController _dischargeOvercurrent1DelayController;
  late TextEditingController _dischargeOvercurrent2ProtectController;
  late TextEditingController _dischargeOvercurrent2DelayController;
  late TextEditingController _shortCircuitProtectController;
  late TextEditingController _shortCircuitDelayController;
  late TextEditingController _samplingResistanceController;

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    _chargeOvercurrent1ProtectController = TextEditingController(text: '0');
    _chargeOvercurrent1DelayController = TextEditingController(text: '0');
    _dischargeOvercurrent1ProtectController = TextEditingController(text: '0');
    _dischargeOvercurrent1DelayController = TextEditingController(text: '0');
    _dischargeOvercurrent2ProtectController = TextEditingController(text: '0');
    _dischargeOvercurrent2DelayController = TextEditingController(text: '0');
    _shortCircuitProtectController = TextEditingController(text: '0');
    _shortCircuitDelayController = TextEditingController(text: '0');
    _samplingResistanceController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    // 释放控制器
    _chargeOvercurrent1ProtectController.dispose();
    _chargeOvercurrent1DelayController.dispose();
    _dischargeOvercurrent1ProtectController.dispose();
    _dischargeOvercurrent1DelayController.dispose();
    _dischargeOvercurrent2ProtectController.dispose();
    _dischargeOvercurrent2DelayController.dispose();
    _shortCircuitProtectController.dispose();
    _shortCircuitDelayController.dispose();
    _samplingResistanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '电流参数'),
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
                    _buildParamRow('充电过流1保护电流', _chargeOvercurrent1ProtectController, 'A'),
                    _buildParamRow('充电过流1延时', _chargeOvercurrent1DelayController, 'ms'),
                    _buildParamRow('放电过流1保护电流', _dischargeOvercurrent1ProtectController, 'A'),
                    _buildParamRow('放电过流1延时', _dischargeOvercurrent1DelayController, 'ms'),
                    _buildParamRow('放电过流2保护电流', _dischargeOvercurrent2ProtectController, 'A'),
                    _buildParamRow('放电过流2延时', _dischargeOvercurrent2DelayController, 'ms'),
                    _buildParamRow('短路保护电流', _shortCircuitProtectController, 'A'),
                    _buildParamRow('短路保护延时', _shortCircuitDelayController, 'us'),
                    _buildParamRow('采样电阻值', _samplingResistanceController, 'mΩ'),
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
