import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';
import '../components/write_confirm_dialog.dart';
import '../managers/battery_data_manager.dart';

// 均衡参数页面
class BalanceParamsPage extends StatefulWidget {
  const BalanceParamsPage({super.key});

  @override
  State<BalanceParamsPage> createState() => _BalanceParamsPageState();
}

class _BalanceParamsPageState extends State<BalanceParamsPage> {
  final BatteryDataManager _batteryDataManager = BatteryDataManager();

  // 控制器
  late TextEditingController _balanceStartVoltageController;
  late TextEditingController _balanceStartThresholdController;
  late TextEditingController _balanceDelayController;

  // 写入状态
  bool _isWriting = false;
  String _writeStatus = '';
  Color _writeStatusColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    _balanceStartVoltageController = TextEditingController(text: '0');
    _balanceStartThresholdController = TextEditingController(text: '0');
    _balanceDelayController = TextEditingController(text: '0');
   
    // 页面加载时读取数据
    _readSettingsData();
 
  }

  @override
  void dispose() {
    // 释放控制器
    _balanceStartVoltageController.dispose();
    _balanceStartThresholdController.dispose();
    _balanceDelayController.dispose();
    super.dispose();
  }

  Future<void> _readSettingsData() async {
    if (!_batteryDataManager.isConnected) {
      print('[BalanceParamsPage] 设备未连接，无法读取数据');
      return;
    }

    print('[BalanceParamsPage] 开始读取均衡参数数据...');

    // 读取均衡启动电压
    final balanceStartVoltage = await _batteryDataManager.readBalanceStartVoltage();
    if (balanceStartVoltage != null && mounted) {
      setState(() {
        _balanceStartVoltageController.text = balanceStartVoltage.toString();
      });
      print('[BalanceParamsPage] 均衡启动电压: $balanceStartVoltage mV');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取均衡启动阈值
    final balanceStartThreshold = await _batteryDataManager.readBalanceStartThreshold();
    if (balanceStartThreshold != null && mounted) {
      setState(() {
        _balanceStartThresholdController.text = balanceStartThreshold.toString();
      });
      print('[BalanceParamsPage] 均衡启动阈值: $balanceStartThreshold mV');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取均衡延时
    final balanceDelay = await _batteryDataManager.readBalanceDelay();
    if (balanceDelay != null && mounted) {
      setState(() {
        _balanceDelayController.text = balanceDelay.toString();
      });
      print('[BalanceParamsPage] 均衡延时: $balanceDelay ms');
    }
  }

  Future<void> _writeBalanceStartVoltage() async {
    final text = _balanceStartVoltageController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入均衡启动电压', Colors.orange);
      return;
    }

    final voltage = int.tryParse(text);
    if (voltage == null || voltage <= 0) {
      _showStatus('请输入有效的均衡启动电压', Colors.orange);
      return;
    }

    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }

    final currentValue = await _batteryDataManager.readBalanceStartVoltage();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '均衡启动电压',
      oldValue: currentValue ?? 0,
      newValue: voltage,
    );

    if (!confirmed) return;

    await _executeWrite(() => _batteryDataManager.writeBalanceStartVoltage(voltage), '均衡启动电压');
  }

  Future<void> _writeBalanceStartThreshold() async {
    final text = _balanceStartThresholdController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入均衡启动阈值', Colors.orange);
      return;
    }

    final threshold = int.tryParse(text);
    if (threshold == null || threshold <= 0) {
      _showStatus('请输入有效的均衡启动阈值', Colors.orange);
      return;
    }

    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }

    final currentValue = await _batteryDataManager.readBalanceStartThreshold();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '均衡启动阈值',
      oldValue: currentValue ?? 0,
      newValue: threshold,
    );

    if (!confirmed) return;

    await _executeWrite(() => _batteryDataManager.writeBalanceStartThreshold(threshold), '均衡启动阈值');
  }

  Future<void> _writeBalanceDelay() async {
    final text = _balanceDelayController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入均衡延时', Colors.orange);
      return;
    }

    final delay = int.tryParse(text);
    if (delay == null || delay <= 0) {
      _showStatus('请输入有效的均衡延时', Colors.orange);
      return;
    }

    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }

    final currentValue = await _batteryDataManager.readBalanceDelay();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '均衡延时',
      oldValue: currentValue ?? 0,
      newValue: delay,
    );

    if (!confirmed) return;

    await _executeWrite(() => _batteryDataManager.writeBalanceDelay(delay), '均衡延时');
  }

  Future<void> _executeWrite(Future<bool> Function() writeFunction, String paramName) async {
    setState(() {
      _isWriting = true;
      _writeStatus = '正在写入${paramName}...';
      _writeStatusColor = Colors.blue;
    });

    try {
      final success = await writeFunction();
      setState(() {
        if (success) {
          _writeStatus = '${paramName}写入成功';
          _writeStatusColor = Colors.green;
        } else {
          _writeStatus = '${paramName}写入失败';
          _writeStatusColor = Colors.red;
        }
      });
    } catch (e) {
      setState(() {
        _writeStatus = '${paramName}写入异常: $e';
        _writeStatusColor = Colors.red;
      });
    } finally {
      setState(() {
        _isWriting = false;
      });
    }
  }

  void _showStatus(String message, Color color) {
    setState(() {
      _writeStatus = message;
      _writeStatusColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  CommonAppBar(title: '均衡参数'),
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
                    _buildParamRow('均衡启动电压', _balanceStartVoltageController, 'mV', _writeBalanceStartVoltage),
                    _buildParamRow('均衡启动阈值', _balanceStartThresholdController, 'mV', _writeBalanceStartThreshold),
                    _buildParamRow('均衡延时', _balanceDelayController, 'ms', _writeBalanceDelay),
                  ],
                ),
              ),
              // 写入状态显示
              if (_writeStatus.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: _writeStatusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: _writeStatusColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _writeStatusColor == Colors.green ? Icons.check_circle : 
                          _writeStatusColor == Colors.red ? Icons.error : 
                          Icons.info,
                          color: _writeStatusColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _writeStatus,
                            style: TextStyle(
                              fontSize: 16,
                              color: _writeStatusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建参数行
  Widget _buildParamRow(String name, TextEditingController controller, String unit, VoidCallback onWrite) {
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
                  onPressed: _isWriting ? null : onWrite,
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
                    _isWriting ? '写入中...' : '设置',
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
