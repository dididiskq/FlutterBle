import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';
import '../components/write_confirm_dialog.dart';
import '../managers/battery_data_manager.dart';

// 温度参数页面
class TemperatureParamsPage extends StatefulWidget {
  const TemperatureParamsPage({super.key});

  @override
  State<TemperatureParamsPage> createState() => _TemperatureParamsPageState();
}

class _TemperatureParamsPageState extends State<TemperatureParamsPage> {
  final BatteryDataManager _batteryDataManager = BatteryDataManager();
  
  // 控制器
  late TextEditingController _chargeHighTempProtectController;
  late TextEditingController _chargeHighTempRecoverController;
  late TextEditingController _chargeLowTempProtectController;
  late TextEditingController _chargeLowTempRecoverController;
  late TextEditingController _dischargeHighTempProtectController;
  late TextEditingController _dischargeHighTempRecoverController;
  late TextEditingController _dischargeLowTempProtectController;
  late TextEditingController _dischargeLowTempRecoverController;
  
  // 写入状态
  bool _isWriting = false;
  String _writeStatus = '';
  Color _writeStatusColor = Colors.transparent;

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
    
    // 页面加载时读取数据
    _readSettingsData();
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

  Future<void> _readSettingsData() async {
    if (!_batteryDataManager.isConnected) {
      print('[TemperatureParamsPage] 设备未连接，无法读取数据');
      return;
    }

    print('[TemperatureParamsPage] 开始读取温度参数数据...');

    // 读取充电高温保护
    final chargeHighTempProtect = await _batteryDataManager.readChargeHighTempProtect();
    if (chargeHighTempProtect != null && mounted) {
      setState(() {
        _chargeHighTempProtectController.text = chargeHighTempProtect.toString();
      });
      print('[TemperatureParamsPage] 充电高温保护: $chargeHighTempProtect °C');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取充电高温恢复
    final chargeHighTempRecover = await _batteryDataManager.readChargeHighTempRecover();
    if (chargeHighTempRecover != null && mounted) {
      setState(() {
        _chargeHighTempRecoverController.text = chargeHighTempRecover.toString();
      });
      print('[TemperatureParamsPage] 充电高温恢复: $chargeHighTempRecover °C');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取充电低温保护
    final chargeLowTempProtect = await _batteryDataManager.readChargeLowTempProtect();
    if (chargeLowTempProtect != null && mounted) {
      setState(() {
        _chargeLowTempProtectController.text = chargeLowTempProtect.toString();
      });
      print('[TemperatureParamsPage] 充电低温保护: $chargeLowTempProtect °C');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取充电低温恢复
    final chargeLowTempRecover = await _batteryDataManager.readChargeLowTempRecover();
    if (chargeLowTempRecover != null && mounted) {
      setState(() {
        _chargeLowTempRecoverController.text = chargeLowTempRecover.toString();
      });
      print('[TemperatureParamsPage] 充电低温恢复: $chargeLowTempRecover °C');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取放电高温保护
    final dischargeHighTempProtect = await _batteryDataManager.readDischargeHighTempProtect();
    if (dischargeHighTempProtect != null && mounted) {
      setState(() {
        _dischargeHighTempProtectController.text = dischargeHighTempProtect.toString();
      });
      print('[TemperatureParamsPage] 放电高温保护: $dischargeHighTempProtect °C');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取放电高温恢复
    final dischargeHighTempRecover = await _batteryDataManager.readDischargeHighTempRecover();
    if (dischargeHighTempRecover != null && mounted) {
      setState(() {
        _dischargeHighTempRecoverController.text = dischargeHighTempRecover.toString();
      });
      print('[TemperatureParamsPage] 放电高温恢复: $dischargeHighTempRecover °C');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取放电低温保护
    final dischargeLowTempProtect = await _batteryDataManager.readDischargeLowTempProtect();
    if (dischargeLowTempProtect != null && mounted) {
      setState(() {
        _dischargeLowTempProtectController.text = dischargeLowTempProtect.toString();
      });
      print('[TemperatureParamsPage] 放电低温保护: $dischargeLowTempProtect °C');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取放电低温恢复
    final dischargeLowTempRecover = await _batteryDataManager.readDischargeLowTempRecover();
    if (dischargeLowTempRecover != null && mounted) {
      setState(() {
        _dischargeLowTempRecoverController.text = dischargeLowTempRecover.toString();
      });
      print('[TemperatureParamsPage] 放电低温恢复: $dischargeLowTempRecover °C');
    }
  }

  Future<void> _writeChargeHighTempProtect() async {
    final text = _chargeHighTempProtectController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入充电高温保护温度', Colors.orange);
      return;
    }
    
    final temperature = int.tryParse(text);
    if (temperature == null) {
      _showStatus('请输入有效的充电高温保护温度', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    final currentValue = await _batteryDataManager.readChargeHighTempProtect();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '充电高温保护',
      oldValue: currentValue ?? 0,
      newValue: temperature,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeChargeHighTempProtect(temperature), '充电高温保护');
  }

  Future<void> _writeChargeHighTempRecover() async {
    final text = _chargeHighTempRecoverController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入充电高温恢复温度', Colors.orange);
      return;
    }
    
    final temperature = int.tryParse(text);
    if (temperature == null) {
      _showStatus('请输入有效的充电高温恢复温度', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    final currentValue = await _batteryDataManager.readChargeHighTempRecover();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '充电高温恢复',
      oldValue: currentValue ?? 0,
      newValue: temperature,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeChargeHighTempRecover(temperature), '充电高温恢复');
  }

  Future<void> _writeChargeLowTempProtect() async {
    final text = _chargeLowTempProtectController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入充电低温保护温度', Colors.orange);
      return;
    }
    
    final temperature = int.tryParse(text);
    if (temperature == null) {
      _showStatus('请输入有效的充电低温保护温度', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '充电低温保护',
      oldValue: 0,
      newValue: temperature,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeChargeLowTempProtect(temperature), '充电低温保护');
  }

  Future<void> _writeChargeLowTempRecover() async {
    final text = _chargeLowTempRecoverController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入充电低温恢复温度', Colors.orange);
      return;
    }
    
    final temperature = int.tryParse(text);
    if (temperature == null) {
      _showStatus('请输入有效的充电低温恢复温度', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '充电低温恢复',
      oldValue: 0,
      newValue: temperature,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeChargeLowTempRecover(temperature), '充电低温恢复');
  }

  Future<void> _writeDischargeHighTempProtect() async {
    final text = _dischargeHighTempProtectController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入放电高温保护温度', Colors.orange);
      return;
    }
    
    final temperature = int.tryParse(text);
    if (temperature == null) {
      _showStatus('请输入有效的放电高温保护温度', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '放电高温保护',
      oldValue: 0,
      newValue: temperature,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeDischargeHighTempProtect(temperature), '放电高温保护');
  }

  Future<void> _writeDischargeHighTempRecover() async {
    final text = _dischargeHighTempRecoverController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入放电高温恢复温度', Colors.orange);
      return;
    }
    
    final temperature = int.tryParse(text);
    if (temperature == null) {
      _showStatus('请输入有效的放电高温恢复温度', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '放电高温恢复',
      oldValue: 0,
      newValue: temperature,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeDischargeHighTempRecover(temperature), '放电高温恢复');
  }

  Future<void> _writeDischargeLowTempProtect() async {
    final text = _dischargeLowTempProtectController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入放电低温保护温度', Colors.orange);
      return;
    }
    
    final temperature = int.tryParse(text);
    if (temperature == null) {
      _showStatus('请输入有效的放电低温保护温度', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '放电低温保护',
      oldValue: 0,
      newValue: temperature,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeDischargeLowTempProtect(temperature), '放电低温保护');
  }

  Future<void> _writeDischargeLowTempRecover() async {
    final text = _dischargeLowTempRecoverController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入放电低温恢复温度', Colors.orange);
      return;
    }
    
    final temperature = int.tryParse(text);
    if (temperature == null) {
      _showStatus('请输入有效的放电低温恢复温度', Colors.orange);
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }
    
    final currentValue = await _batteryDataManager.readDischargeLowTempRecover();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '放电低温恢复',
      oldValue: currentValue ?? 0,
      newValue: temperature,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeDischargeLowTempRecover(temperature), '放电低温恢复');
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
                  onPressed: _isWriting ? null : () {
                    if (name == '充电高温保护') {
                      _writeChargeHighTempProtect();
                    } else if (name == '充电高温恢复') {
                      _writeChargeHighTempRecover();
                    } else if (name == '充电低温保护') {
                      _writeChargeLowTempProtect();
                    } else if (name == '充电低温恢复') {
                      _writeChargeLowTempRecover();
                    } else if (name == '放电高温保护') {
                      _writeDischargeHighTempProtect();
                    } else if (name == '放电高温恢复') {
                      _writeDischargeHighTempRecover();
                    } else if (name == '放电低温保护') {
                      _writeDischargeLowTempProtect();
                    } else if (name == '放电低温恢复') {
                      _writeDischargeLowTempRecover();
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
