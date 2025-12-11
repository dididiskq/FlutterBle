import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';

// 电压参数页面
class VoltageParamsPage extends StatefulWidget {
  const VoltageParamsPage({super.key});

  @override
  State<VoltageParamsPage> createState() => _VoltageParamsPageState();
}

class _VoltageParamsPageState extends State<VoltageParamsPage> {
  // 控制器
  late TextEditingController _overchargeProtectController;
  late TextEditingController _overchargeRecoverController;
  late TextEditingController _overdischargeProtectController;
  late TextEditingController _overdischargeRecoverController;

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    _overchargeProtectController = TextEditingController(text: '0');
    _overchargeRecoverController = TextEditingController(text: '0');
    _overdischargeProtectController = TextEditingController(text: '0');
    _overdischargeRecoverController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    // 释放控制器
    _overchargeProtectController.dispose();
    _overchargeRecoverController.dispose();
    _overdischargeProtectController.dispose();
    _overdischargeRecoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '电压参数'),
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
                    _buildParamRow('过充保护电压', _overchargeProtectController, 'mV'),
                    _buildParamRow('过充恢复电压', _overchargeRecoverController, 'mV'),
                    _buildParamRow('过放保护电压', _overdischargeProtectController, 'mV'),
                    _buildParamRow('过放恢复电压', _overdischargeRecoverController, 'mV'),
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
