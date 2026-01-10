import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';
import '../components/write_confirm_dialog.dart';
import '../managers/battery_data_manager.dart';

// 电压参数页面
class VoltageParamsPage extends StatefulWidget {
  const VoltageParamsPage({super.key});

  @override
  State<VoltageParamsPage> createState() => _VoltageParamsPageState();
}

class _VoltageParamsPageState extends State<VoltageParamsPage> {
  final BatteryDataManager _batteryDataManager = BatteryDataManager();
  
  // 控制器
  late TextEditingController _overchargeProtectController;
  late TextEditingController _overchargeRecoverController;
  late TextEditingController _overdischargeProtectController;
  late TextEditingController _overdischargeRecoverController;
  
  // 写入状态
  bool _isWriting = false;
  String _writeStatus = '';
  Color _writeStatusColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    _overchargeProtectController = TextEditingController(text: '0');
    _overchargeRecoverController = TextEditingController(text: '0');
    _overdischargeProtectController = TextEditingController(text: '0');
    _overdischargeRecoverController = TextEditingController(text: '0');
   
    // 页面加载时读取数据
    _readSettingsData();
   
  }

  Future<void> _readSettingsData() async {
    if (!_batteryDataManager.isConnected) {
      print('[VoltageParamsPage] 设备未连接，无法读取数据');
      return;
    }

    print('[VoltageParamsPage] 开始读取电压参数数据...');

    // 读取过充保护电压
    final overchargeProtect = await _batteryDataManager.readOverchargeProtectVoltage();
    if (overchargeProtect != null && mounted) {
      setState(() {
        _overchargeProtectController.text = overchargeProtect.toString();
      });
      print('[VoltageParamsPage] 过充保护电压: $overchargeProtect mV');
    }
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 读取过充恢复电压
    final overchargeRecover = await _batteryDataManager.readOverchargeRecoverVoltage();
    if (overchargeRecover != null && mounted) {
      setState(() {
        _overchargeRecoverController.text = overchargeRecover.toString();
      });
      print('[VoltageParamsPage] 过充恢复电压: $overchargeRecover mV');
    }
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 读取过放保护电压
    final overdischargeProtect = await _batteryDataManager.readOverdischargeProtectVoltage();
    if (overdischargeProtect != null && mounted) {
      setState(() {
        _overdischargeProtectController.text = overdischargeProtect.toString();
      });
      print('[VoltageParamsPage] 过放保护电压: $overdischargeProtect mV');
    }
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 读取过放恢复电压
    final overdischargeRecover = await _batteryDataManager.readOverdischargeRecoverVoltage();
    if (overdischargeRecover != null && mounted) {
      setState(() {
        _overdischargeRecoverController.text = overdischargeRecover.toString();
      });
      print('[VoltageParamsPage] 过放恢复电压: $overdischargeRecover mV');
    }
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

  Future<void> _writeOverchargeProtectVoltage() async {
    final text = _overchargeProtectController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入过充保护电压', Colors.orange);
      return;
    }
    
    final voltage = int.tryParse(text);
    if (voltage == null || voltage <= 0) {
      _showStatus('请输入有效的过充保护电压', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    // 读取当前值作为旧值
    final oldValue = await _batteryDataManager.readOverchargeProtectVoltage() ?? 0;
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '过充保护电压',
      oldValue: oldValue,
      newValue: voltage,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeOverchargeProtectVoltage(voltage), '过充保护电压');
  }

  Future<void> _writeOverchargeRecoverVoltage() async {
    final text = _overchargeRecoverController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入过充恢复电压', Colors.orange);
      return;
    }
    
    final voltage = int.tryParse(text);
    if (voltage == null || voltage <= 0) {
      _showStatus('请输入有效的过充恢复电压', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    // 读取当前值作为旧值
    final oldValue = await _batteryDataManager.readOverchargeRecoverVoltage() ?? 0;
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '过充恢复电压',
      oldValue: oldValue,
      newValue: voltage,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeOverchargeRecoverVoltage(voltage), '过充恢复电压');
  }

  Future<void> _writeOverdischargeProtectVoltage() async {
    final text = _overdischargeProtectController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入过放保护电压', Colors.orange);
      return;
    }
    
    final voltage = int.tryParse(text);
    if (voltage == null || voltage <= 0) {
      _showStatus('请输入有效的过放保护电压', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    // 读取当前值作为旧值
    final oldValue = await _batteryDataManager.readOverdischargeProtectVoltage() ?? 0;
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '过放保护电压',
      oldValue: oldValue,
      newValue: voltage,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeOverdischargeProtectVoltage(voltage), '过放保护电压');
  }

  Future<void> _writeOverdischargeRecoverVoltage() async {
    final text = _overdischargeRecoverController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入过放恢复电压', Colors.orange);
      return;
    }
    
    final voltage = int.tryParse(text);
    if (voltage == null || voltage <= 0) {
      _showStatus('请输入有效的过放恢复电压', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    // 读取当前值作为旧值
    final oldValue = await _batteryDataManager.readOverdischargeRecoverVoltage() ?? 0;
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '过放恢复电压',
      oldValue: oldValue,
      newValue: voltage,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeOverdischargeRecoverVoltage(voltage), '过放恢复电压');
  }

  Future<void> _executeWrite(Future<bool> Function() writeFunc, String paramName) async {
    setState(() {
      _isWriting = true;
      _writeStatus = '正在写入...';
      _writeStatusColor = Colors.blue;
    });
    
    try {
      final success = await writeFunc();
      setState(() {
        _isWriting = false;
        if (success) {
          _showStatus('$paramName写入成功', Colors.green);
        } else {
          _showStatus('$paramName写入失败', Colors.red);
        }
      });
    } catch (e) {
      setState(() {
        _isWriting = false;
        _showStatus('写入出错: $e', Colors.red);
      });
    }
  }

  void _showStatus(String message, Color color) {
    setState(() {
      _writeStatus = message;
      _writeStatusColor = color;
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _writeStatus = '';
          _writeStatusColor = Colors.transparent;
        });
      }
    });
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
              // 写入状态显示
              if (_writeStatus.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: _writeStatusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: _writeStatusColor, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isWriting)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_writeStatusColor),
                          ),
                        ),
                      if (_isWriting) SizedBox(width: 10),
                      Text(
                        _writeStatus,
                        style: TextStyle(
                          fontSize: 16,
                          color: _writeStatusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_writeStatus.isNotEmpty) SizedBox(height: 20),
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
                  onPressed: _isWriting ? null : () {
                    if (name == '过充保护电压') {
                      _writeOverchargeProtectVoltage();
                    } else if (name == '过充恢复电压') {
                      _writeOverchargeRecoverVoltage();
                    } else if (name == '过放保护电压') {
                      _writeOverdischargeProtectVoltage();
                    } else if (name == '过放恢复电压') {
                      _writeOverdischargeRecoverVoltage();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isWriting ? Colors.grey : Colors.blue,
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
