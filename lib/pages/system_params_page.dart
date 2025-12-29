import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';
import '../components/write_confirm_dialog.dart';
import '../managers/battery_data_manager.dart';

// 系统参数页面
class SystemParamsPage extends StatefulWidget {
  const SystemParamsPage({super.key});

  @override
  State<SystemParamsPage> createState() => _SystemParamsPageState();
}

class _SystemParamsPageState extends State<SystemParamsPage> {
  final BatteryDataManager _batteryDataManager = BatteryDataManager();

  // 控制器
  late TextEditingController _ratedChargeVoltageController;
  late TextEditingController _ratedChargeCurrentController;
  late TextEditingController _sleepDelayController;
  late TextEditingController _shutdownDelayController;
  late TextEditingController _fullChargeDelayController;
  late TextEditingController _fullChargeVoltageController;
  late TextEditingController _fullChargeCurrentController;
  late TextEditingController _zeroCurrentThresholdController;

  // 写入状态
  bool _isWriting = false;
  String _writeStatus = '';
  Color _writeStatusColor = Colors.transparent;

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
    
    // 页面加载时读取数据
    _readSettingsData();
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

  Future<void> _readSettingsData() async {
    if (!_batteryDataManager.isConnected) {
      print('[SystemParamsPage] 设备未连接，无法读取数据');
      return;
    }

    print('[SystemParamsPage] 开始读取系统参数数据...');

    // 读取休眠延时
    final sleepDelay = await _batteryDataManager.readSleepDelay();
    if (sleepDelay != null && mounted) {
      setState(() {
        _sleepDelayController.text = sleepDelay.toString();
      });
      print('[SystemParamsPage] 休眠延时: $sleepDelay s');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取关机延时
    final shutdownDelay = await _batteryDataManager.readShutdownDelay();
    if (shutdownDelay != null && mounted) {
      setState(() {
        _shutdownDelayController.text = shutdownDelay.toString();
      });
      print('[SystemParamsPage] 关机延时: $shutdownDelay s');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取额定充电电压
    final ratedChargeVoltage = await _batteryDataManager.readRatedChargeVoltage();
    if (ratedChargeVoltage != null && mounted) {
      setState(() {
        _ratedChargeVoltageController.text = ratedChargeVoltage.toString();
      });
      print('[SystemParamsPage] 额定充电电压: $ratedChargeVoltage 0.1V');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取额定充电电流
    final ratedChargeCurrent = await _batteryDataManager.readRatedChargeCurrent();
    if (ratedChargeCurrent != null && mounted) {
      setState(() {
        _ratedChargeCurrentController.text = ratedChargeCurrent.toString();
      });
      print('[SystemParamsPage] 额定充电电流: $ratedChargeCurrent 0.1A');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取满充电压
    final fullChargeVoltage = await _batteryDataManager.readFullChargeVoltage();
    if (fullChargeVoltage != null && mounted) {
      setState(() {
        _fullChargeVoltageController.text = fullChargeVoltage.toString();
      });
      print('[SystemParamsPage] 满充电压: $fullChargeVoltage mV');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取满充电流
    final fullChargeCurrent = await _batteryDataManager.readFullChargeCurrent();
    if (fullChargeCurrent != null && mounted) {
      setState(() {
        _fullChargeCurrentController.text = fullChargeCurrent.toString();
      });
      print('[SystemParamsPage] 满充电流: $fullChargeCurrent mA');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取满充延时
    final fullChargeDelay = await _batteryDataManager.readFullChargeDelay();
    if (fullChargeDelay != null && mounted) {
      setState(() {
        _fullChargeDelayController.text = fullChargeDelay.toString();
      });
      print('[SystemParamsPage] 满充延时: $fullChargeDelay s');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取零电流显示阈值
    final zeroCurrentThreshold = await _batteryDataManager.readZeroCurrentThreshold();
    if (zeroCurrentThreshold != null && mounted) {
      setState(() {
        _zeroCurrentThresholdController.text = zeroCurrentThreshold.toString();
      });
      print('[SystemParamsPage] 零电流显示阈值: $zeroCurrentThreshold mA');
    }
  }

  Future<void> _writeRatedChargeVoltage() async {
    final text = _ratedChargeVoltageController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入额定充电电压', Colors.orange);
      return;
    }

    final voltage = int.tryParse(text);
    if (voltage == null || voltage <= 0) {
      _showStatus('请输入有效的额定充电电压', Colors.orange);
      return;
    }

    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }

    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '额定充电电压',
      oldValue: 0,
      newValue: voltage,
    );

    if (!confirmed) return;

    await _executeWrite(() => _batteryDataManager.writeRatedChargeVoltage(voltage), '额定充电电压');
  }

  Future<void> _writeRatedChargeCurrent() async {
    final text = _ratedChargeCurrentController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入额定充电电流', Colors.orange);
      return;
    }

    final current = int.tryParse(text);
    if (current == null || current <= 0) {
      _showStatus('请输入有效的额定充电电流', Colors.orange);
      return;
    }

    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }

    final currentValue = await _batteryDataManager.readRatedChargeCurrent();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '额定充电电流',
      oldValue: currentValue ?? 0,
      newValue: current,
    );

    if (!confirmed) return;

    await _executeWrite(() => _batteryDataManager.writeRatedChargeCurrent(current), '额定充电电流');
  }

  Future<void> _writeSleepDelay() async {
    final text = _sleepDelayController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入休眠延时', Colors.orange);
      return;
    }

    final delay = int.tryParse(text);
    if (delay == null || delay <= 0) {
      _showStatus('请输入有效的休眠延时', Colors.orange);
      return;
    }

    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }

    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '休眠延时',
      oldValue: 0,
      newValue: delay,
    );

    if (!confirmed) return;

    await _executeWrite(() => _batteryDataManager.writeSleepDelay(delay), '休眠延时');
  }

  Future<void> _writeShutdownDelay() async {
    final text = _shutdownDelayController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入关机延时', Colors.orange);
      return;
    }

    final delay = int.tryParse(text);
    if (delay == null || delay <= 0) {
      _showStatus('请输入有效的关机延时', Colors.orange);
      return;
    }

    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }

    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '关机延时',
      oldValue: 0,
      newValue: delay,
    );

    if (!confirmed) return;

    await _executeWrite(() => _batteryDataManager.writeShutdownDelay(delay), '关机延时');
  }

  Future<void> _writeFullChargeVoltage() async {
    final text = _fullChargeVoltageController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入满充电压', Colors.orange);
      return;
    }

    final voltage = int.tryParse(text);
    if (voltage == null || voltage <= 0) {
      _showStatus('请输入有效的满充电压', Colors.orange);
      return;
    }

    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }

    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '满充电压',
      oldValue: 0,
      newValue: voltage,
    );

    if (!confirmed) return;

    await _executeWrite(() => _batteryDataManager.writeFullChargeVoltage(voltage), '满充电压');
  }

  Future<void> _writeFullChargeCurrent() async {
    final text = _fullChargeCurrentController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入满充电流', Colors.orange);
      return;
    }

    final current = int.tryParse(text);
    if (current == null || current <= 0) {
      _showStatus('请输入有效的满充电流', Colors.orange);
      return;
    }

    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }

    final currentValue = await _batteryDataManager.readFullChargeCurrent();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '满充电流',
      oldValue: currentValue ?? 0,
      newValue: current,
    );

    if (!confirmed) return;

    await _executeWrite(() => _batteryDataManager.writeFullChargeCurrent(current), '满充电流');
  }

  Future<void> _writeFullChargeDelay() async {
    final text = _fullChargeDelayController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入满充延时', Colors.orange);
      return;
    }

    final delay = int.tryParse(text);
    if (delay == null || delay <= 0) {
      _showStatus('请输入有效的满充延时', Colors.orange);
      return;
    }

    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }

    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '满充延时',
      oldValue: 0,
      newValue: delay,
    );

    if (!confirmed) return;

    await _executeWrite(() => _batteryDataManager.writeFullChargeDelay(delay), '满充延时');
  }

  Future<void> _writeZeroCurrentThreshold() async {
    final text = _zeroCurrentThresholdController.text.trim();
    if (text.isEmpty) {
      _showStatus('请输入零电流显示阈值', Colors.orange);
      return;
    }

    final threshold = int.tryParse(text);
    if (threshold == null || threshold <= 0) {
      _showStatus('请输入有效的零电流显示阈值', Colors.orange);
      return;
    }

    if (!_batteryDataManager.isConnected) {
      _showStatus('设备未连接，无法写入', Colors.red);
      return;
    }

    final currentValue = await _batteryDataManager.readZeroCurrentThreshold();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '零电流显示阈值',
      oldValue: currentValue ?? 0,
      newValue: threshold,
    );

    if (!confirmed) return;

    await _executeWrite(() => _batteryDataManager.writeZeroCurrentThreshold(threshold), '零电流显示阈值');
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
                    _buildParamRow('额定充电电压', _ratedChargeVoltageController, '0.1V', _writeRatedChargeVoltage),
                    _buildParamRow('额定充电电流', _ratedChargeCurrentController, '0.1A', _writeRatedChargeCurrent),
                    _buildParamRow('休眠延时', _sleepDelayController, 's', _writeSleepDelay),
                    _buildParamRow('关机延时', _shutdownDelayController, 's', _writeShutdownDelay),
                    _buildParamRow('满充延时', _fullChargeDelayController, 's', _writeFullChargeDelay),
                    _buildParamRow('满充电压', _fullChargeVoltageController, 'mV', _writeFullChargeVoltage),
                    _buildParamRow('满充电流', _fullChargeCurrentController, 'mA', _writeFullChargeCurrent),
                    _buildParamRow('零电流显示阈值', _zeroCurrentThresholdController, 'mA', _writeZeroCurrentThreshold),
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
                  onPressed: _isWriting ? null : onWrite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isWriting ? Colors.grey : Colors.blue,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    minimumSize: Size(60, 36),
                  ),
                  child: Text(
                    _isWriting ? '写入中...' : '设置',
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
