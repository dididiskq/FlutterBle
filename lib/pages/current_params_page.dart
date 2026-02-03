import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/common_app_bar.dart';
import '../components/write_confirm_dialog.dart';
import '../managers/battery_data_manager.dart';
import '../managers/language_manager.dart';

// 电流参数页面
class CurrentParamsPage extends StatefulWidget {
  const CurrentParamsPage({super.key});

  @override
  State<CurrentParamsPage> createState() => _CurrentParamsPageState();
}

class _CurrentParamsPageState extends State<CurrentParamsPage> {
  final BatteryDataManager _batteryDataManager = BatteryDataManager();
  
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

  // 写入状态
  bool _isWriting = false;
  String _writeStatus = '';
  Color _writeStatusColor = Colors.transparent;

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
    
   
    // 页面加载时读取数据
    _readSettingsData();
 
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

  Future<void> _readSettingsData() async {
    if (!_batteryDataManager.isConnected) {
      print('[CurrentParamsPage] 设备未连接，无法读取数据');
      return;
    }

    print('[CurrentParamsPage] 开始读取电流参数数据...');

    // 读取充电过流1保护电流
    final chargeOvercurrent1Protect = await _batteryDataManager.readChargeOvercurrent1Protect();
    if (chargeOvercurrent1Protect != null && mounted) {
      setState(() {
        _chargeOvercurrent1ProtectController.text = chargeOvercurrent1Protect.toString();
      });
      print('[CurrentParamsPage] 充电过流1保护电流: $chargeOvercurrent1Protect A');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取充电过流1延时
    final chargeOvercurrent1Delay = await _batteryDataManager.readChargeOvercurrent1Delay();
    if (chargeOvercurrent1Delay != null && mounted) {
      setState(() {
        _chargeOvercurrent1DelayController.text = chargeOvercurrent1Delay.toString();
      });
      print('[CurrentParamsPage] 充电过流1延时: $chargeOvercurrent1Delay ms');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取放电过流1保护电流
    final dischargeOvercurrent1Protect = await _batteryDataManager.readDischargeOvercurrent1Protect();
    if (dischargeOvercurrent1Protect != null && mounted) {
      setState(() {
        _dischargeOvercurrent1ProtectController.text = dischargeOvercurrent1Protect.toString();
      });
      print('[CurrentParamsPage] 放电过流1保护电流: $dischargeOvercurrent1Protect A');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取放电过流1延时
    final dischargeOvercurrent1Delay = await _batteryDataManager.readDischargeOvercurrent1Delay();
    if (dischargeOvercurrent1Delay != null && mounted) {
      setState(() {
        _dischargeOvercurrent1DelayController.text = dischargeOvercurrent1Delay.toString();
      });
      print('[CurrentParamsPage] 放电过流1延时: $dischargeOvercurrent1Delay ms');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取放电过流2保护电流
    final dischargeOvercurrent2Protect = await _batteryDataManager.readDischargeOvercurrent2Protect();
    if (dischargeOvercurrent2Protect != null && mounted) {
      setState(() {
        _dischargeOvercurrent2ProtectController.text = dischargeOvercurrent2Protect.toString();
      });
      print('[CurrentParamsPage] 放电过流2保护电流: $dischargeOvercurrent2Protect A');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取放电过流2延时
    final dischargeOvercurrent2Delay = await _batteryDataManager.readDischargeOvercurrent2Delay();
    if (dischargeOvercurrent2Delay != null && mounted) {
      setState(() {
        _dischargeOvercurrent2DelayController.text = dischargeOvercurrent2Delay.toString();
      });
      print('[CurrentParamsPage] 放电过流2延时: $dischargeOvercurrent2Delay ms');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取短路保护电流
    final shortCircuitProtect = await _batteryDataManager.readShortCircuitProtect();
    if (shortCircuitProtect != null && mounted) {
      setState(() {
        _shortCircuitProtectController.text = shortCircuitProtect.toString();
      });
      print('[CurrentParamsPage] 短路保护电流: $shortCircuitProtect A');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取短路保护延时
    final shortCircuitDelay = await _batteryDataManager.readShortCircuitDelay();
    if (shortCircuitDelay != null && mounted) {
      setState(() {
        _shortCircuitDelayController.text = shortCircuitDelay.toString();
      });
      print('[CurrentParamsPage] 短路保护延时: $shortCircuitDelay us');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    // 读取采样电阻值
    final samplingResistance = await _batteryDataManager.readSamplingResistance();
    if (samplingResistance != null && mounted) {
      setState(() {
        _samplingResistanceController.text = samplingResistance.toString();
      });
      print('[CurrentParamsPage] 采样电阻值: $samplingResistance mΩ');
    }
  }

  Future<void> _writeChargeOvercurrent1Protect() async {
    final languageManager = Provider.of<LanguageManager>(context, listen: false);
    final text = _chargeOvercurrent1ProtectController.text.trim();
    if (text.isEmpty) {
      _showStatus(
        languageManager.isChinese ? '请输入充电过流1保护电流' : 'Please enter Charge Overcurrent 1 Protect', 
        Colors.orange
      );
      return;
    }
    
    final current = int.tryParse(text);
    if (current == null || current <= 0) {
      _showStatus(
        languageManager.isChinese ? '请输入有效的充电过流1保护电流' : 'Please enter valid Charge Overcurrent 1 Protect', 
        Colors.orange
      );
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus(
        languageManager.isChinese ? '设备未连接，无法写入' : 'Device not connected, cannot write', 
        Colors.red
      );
      return;
    }
    
    final currentValue = await _batteryDataManager.readChargeOvercurrent1Protect();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: languageManager.isChinese ? '确认写入' : 'Confirm Write',
      parameterName: '充电过流1保护电流',
      oldValue: currentValue ?? 0,
      newValue: current,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeChargeOvercurrent1Protect(current), '充电过流1保护电流');
  }

  Future<void> _writeChargeOvercurrent1Delay() async {
    final languageManager = Provider.of<LanguageManager>(context, listen: false);
    final text = _chargeOvercurrent1DelayController.text.trim();
    if (text.isEmpty) {
      _showStatus(
        languageManager.isChinese ? '请输入充电过流1延时' : 'Please enter Charge Overcurrent 1 Delay', 
        Colors.orange
      );
      return;
    }
    
    final delay = int.tryParse(text);
    if (delay == null || delay < 0) {
      _showStatus(
        languageManager.isChinese ? '请输入有效的充电过流1延时' : 'Please enter valid Charge Overcurrent 1 Delay', 
        Colors.orange
      );
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus(
        languageManager.isChinese ? '设备未连接，无法写入' : 'Device not connected, cannot write', 
        Colors.red
      );
      return;
    }
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: languageManager.isChinese ? '确认写入' : 'Confirm Write',
      parameterName: '充电过流1延时',
      oldValue: 0,
      newValue: delay,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeChargeOvercurrent1Delay(delay), '充电过流1延时');
  }

  Future<void> _writeDischargeOvercurrent1Protect() async {
    final languageManager = Provider.of<LanguageManager>(context, listen: false);
    final text = _dischargeOvercurrent1ProtectController.text.trim();
    if (text.isEmpty) {
      _showStatus(
        languageManager.isChinese ? '请输入放电过流1保护电流' : 'Please enter Discharge Overcurrent 1 Protect', 
        Colors.orange
      );
      return;
    }
    
    final current = int.tryParse(text);
    if (current == null || current <= 0) {
      _showStatus(
        languageManager.isChinese ? '请输入有效的放电过流1保护电流' : 'Please enter valid Discharge Overcurrent 1 Protect', 
        Colors.orange
      );
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus(
        languageManager.isChinese ? '设备未连接，无法写入' : 'Device not connected, cannot write', 
        Colors.red
      );
      return;
    }
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: languageManager.isChinese ? '确认写入' : 'Confirm Write',
      parameterName: '放电过流1保护电流',
      oldValue: 0,
      newValue: current,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeDischargeOvercurrent1Protect(current), '放电过流1保护电流');
  }

  Future<void> _writeDischargeOvercurrent1Delay() async {
    final languageManager = Provider.of<LanguageManager>(context, listen: false);
    final text = _dischargeOvercurrent1DelayController.text.trim();
    if (text.isEmpty) {
      _showStatus(
        languageManager.isChinese ? '请输入放电过流1延时' : 'Please enter Discharge Overcurrent 1 Delay', 
        Colors.orange
      );
      return;
    }
    
    final delay = int.tryParse(text);
    if (delay == null || delay < 0) {
      _showStatus(
        languageManager.isChinese ? '请输入有效的放电过流1延时' : 'Please enter valid Discharge Overcurrent 1 Delay', 
        Colors.orange
      );
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus(
        languageManager.isChinese ? '设备未连接，无法写入' : 'Device not connected, cannot write', 
        Colors.red
      );
      return;
    }
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: languageManager.isChinese ? '确认写入' : 'Confirm Write',
      parameterName: '放电过流1延时',
      oldValue: 0,
      newValue: delay,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeDischargeOvercurrent1Delay(delay), '放电过流1延时');
  }

  Future<void> _writeDischargeOvercurrent2Protect() async {
    final languageManager = Provider.of<LanguageManager>(context, listen: false);
    final text = _dischargeOvercurrent2ProtectController.text.trim();
    if (text.isEmpty) {
      _showStatus(
        languageManager.isChinese ? '请输入放电过流2保护电流' : 'Please enter Discharge Overcurrent 2 Protect', 
        Colors.orange
      );
      return;
    }
    
    final current = int.tryParse(text);
    if (current == null || current <= 0) {
      _showStatus(
        languageManager.isChinese ? '请输入有效的放电过流2保护电流' : 'Please enter valid Discharge Overcurrent 2 Protect', 
        Colors.orange
      );
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus(
        languageManager.isChinese ? '设备未连接，无法写入' : 'Device not connected, cannot write', 
        Colors.red
      );
      return;
    }
    
    final currentValue = await _batteryDataManager.readDischargeOvercurrent2Protect();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: languageManager.isChinese ? '确认写入' : 'Confirm Write',
      parameterName: '放电过流2保护电流',
      oldValue: currentValue ?? 0,
      newValue: current,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeDischargeOvercurrent2Protect(current), '放电过流2保护电流');
  }

  Future<void> _writeDischargeOvercurrent2Delay() async {
    final languageManager = Provider.of<LanguageManager>(context, listen: false);
    final text = _dischargeOvercurrent2DelayController.text.trim();
    if (text.isEmpty) {
      _showStatus(
        languageManager.isChinese ? '请输入放电过流2延时' : 'Please enter Discharge Overcurrent 2 Delay', 
        Colors.orange
      );
      return;
    }
    
    final delay = int.tryParse(text);
    if (delay == null || delay < 0) {
      _showStatus(
        languageManager.isChinese ? '请输入有效的放电过流2延时' : 'Please enter valid Discharge Overcurrent 2 Delay', 
        Colors.orange
      );
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus(
        languageManager.isChinese ? '设备未连接，无法写入' : 'Device not connected, cannot write', 
        Colors.red
      );
      return;
    }
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: languageManager.isChinese ? '确认写入' : 'Confirm Write',
      parameterName: '放电过流2延时',
      oldValue: 0,
      newValue: delay,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeDischargeOvercurrent2Delay(delay), '放电过流2延时');
  }

  Future<void> _writeShortCircuitProtect() async {
    final languageManager = Provider.of<LanguageManager>(context, listen: false);
    final text = _shortCircuitProtectController.text.trim();
    if (text.isEmpty) {
      _showStatus(
        languageManager.isChinese ? '请输入短路保护电流' : 'Please enter Short Circuit Protect', 
        Colors.orange
      );
      return;
    }
    
    final current = int.tryParse(text);
    if (current == null || current <= 0) {
      _showStatus(
        languageManager.isChinese ? '请输入有效的短路保护电流' : 'Please enter valid Short Circuit Protect', 
        Colors.orange
      );
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus(
        languageManager.isChinese ? '设备未连接，无法写入' : 'Device not connected, cannot write', 
        Colors.red
      );
      return;
    }
    
    final currentValue = await _batteryDataManager.readShortCircuitProtect();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: languageManager.isChinese ? '确认写入' : 'Confirm Write',
      parameterName: '短路保护电流',
      oldValue: currentValue ?? 0,
      newValue: current,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeShortCircuitProtect(current), '短路保护电流');
  }

  Future<void> _writeShortCircuitDelay() async {
    final languageManager = Provider.of<LanguageManager>(context, listen: false);
    final text = _shortCircuitDelayController.text.trim();
    if (text.isEmpty) {
      _showStatus(
        languageManager.isChinese ? '请输入短路保护延时' : 'Please enter Short Circuit Delay', 
        Colors.orange
      );
      return;
    }
    
    final delay = int.tryParse(text);
    if (delay == null || delay < 0) {
      _showStatus(
        languageManager.isChinese ? '请输入有效的短路保护延时' : 'Please enter valid Short Circuit Delay', 
        Colors.orange
      );
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus(
        languageManager.isChinese ? '设备未连接，无法写入' : 'Device not connected, cannot write', 
        Colors.red
      );
      return;
    }
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: languageManager.isChinese ? '确认写入' : 'Confirm Write',
      parameterName: '短路保护延时',
      oldValue: 0,
      newValue: delay,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeShortCircuitDelay(delay), '短路保护延时');
  }

  Future<void> _writeSamplingResistance() async {
    final languageManager = Provider.of<LanguageManager>(context, listen: false);
    final text = _samplingResistanceController.text.trim();
    if (text.isEmpty) {
      _showStatus(
        languageManager.isChinese ? '请输入采样电阻值' : 'Please enter Sampling Resistance', 
        Colors.orange
      );
      return;
    }
    
    final resistance = double.tryParse(text);
    if (resistance == null || resistance <= 0) {
      _showStatus(
        languageManager.isChinese ? '请输入有效的采样电阻值' : 'Please enter valid Sampling Resistance', 
        Colors.orange
      );
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      _showStatus(
        languageManager.isChinese ? '设备未连接，无法写入' : 'Device not connected, cannot write', 
        Colors.red
      );
      return;
    }
    
    final currentValue = await _batteryDataManager.readSamplingResistance();
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: languageManager.isChinese ? '确认写入' : 'Confirm Write',
      parameterName: '采样电阻值',
      oldValue: currentValue ?? 0.0,
      newValue: resistance,
    );
    
    if (!confirmed) return;
    
    await _executeWrite(() => _batteryDataManager.writeSamplingResistance(resistance), '采样电阻值');
  }

  Future<void> _executeWrite(Future<bool> Function() writeFunc, String paramName) async {
    final languageManager = Provider.of<LanguageManager>(context, listen: false);
    
    setState(() {
      _isWriting = true;
      _writeStatus = languageManager.isChinese ? '正在写入...' : 'Writing...';
      _writeStatusColor = Colors.blue;
    });
    
    try {
      final success = await writeFunc();
      setState(() {
        _isWriting = false;
        if (success) {
          _showStatus(
            languageManager.isChinese ? '$paramName写入成功' : '$paramName Write Success', 
            Colors.green
          );
        } else {
          _showStatus(
            languageManager.isChinese ? '$paramName写入失败' : '$paramName Write Failed', 
            Colors.red
          );
        }
      });
    } catch (e) {
      setState(() {
        _isWriting = false;
        _showStatus(
          languageManager.isChinese ? '写入出错: $e' : 'Write Error: $e', 
          Colors.red
        );
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
    return Consumer<LanguageManager>(
      builder: (context, languageManager, child) {
        return Scaffold(
          appBar:  CommonAppBar(title: languageManager.currentParamsTitle),
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
                          languageManager.item,
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
                          languageManager.parameter,
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
                          languageManager.setting,
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
                        _buildParamRow('充电过流1保护电流', _chargeOvercurrent1ProtectController, 'A', languageManager),
                        _buildParamRow('充电过流1延时', _chargeOvercurrent1DelayController, 'ms', languageManager),
                        _buildParamRow('放电过流1保护电流', _dischargeOvercurrent1ProtectController, 'A', languageManager),
                        _buildParamRow('放电过流1延时', _dischargeOvercurrent1DelayController, 'ms', languageManager),
                        _buildParamRow('放电过流2保护电流', _dischargeOvercurrent2ProtectController, 'A', languageManager),
                        _buildParamRow('放电过流2延时', _dischargeOvercurrent2DelayController, 'ms', languageManager),
                        _buildParamRow('短路保护电流', _shortCircuitProtectController, 'A', languageManager),
                        _buildParamRow('短路保护延时', _shortCircuitDelayController, 'us', languageManager),
                        _buildParamRow('采样电阻值', _samplingResistanceController, 'mΩ', languageManager),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 构建参数行
  Widget _buildParamRow(String name, TextEditingController controller, String unit, LanguageManager languageManager) {
    String displayName = name;
    if (!languageManager.isChinese) {
      switch (name) {
        case '充电过流1保护电流':
          displayName = 'Charge Overcurrent 1 Protect';
          break;
        case '充电过流1延时':
          displayName = 'Charge Overcurrent 1 Delay';
          break;
        case '放电过流1保护电流':
          displayName = 'Discharge Overcurrent 1 Protect';
          break;
        case '放电过流1延时':
          displayName = 'Discharge Overcurrent 1 Delay';
          break;
        case '放电过流2保护电流':
          displayName = 'Discharge Overcurrent 2 Protect';
          break;
        case '放电过流2延时':
          displayName = 'Discharge Overcurrent 2 Delay';
          break;
        case '短路保护电流':
          displayName = 'Short Circuit Protect';
          break;
        case '短路保护延时':
          displayName = 'Short Circuit Delay';
          break;
        case '采样电阻值':
          displayName = 'Sampling Resistance';
          break;
      }
    }
    
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
                  displayName,
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
                  onPressed: _isWriting ? null : () {
                    if (name == '充电过流1保护电流') {
                      _writeChargeOvercurrent1Protect();
                    } else if (name == '充电过流1延时') {
                      _writeChargeOvercurrent1Delay();
                    } else if (name == '放电过流1保护电流') {
                      _writeDischargeOvercurrent1Protect();
                    } else if (name == '放电过流1延时') {
                      _writeDischargeOvercurrent1Delay();
                    } else if (name == '放电过流2保护电流') {
                      _writeDischargeOvercurrent2Protect();
                    } else if (name == '放电过流2延时') {
                      _writeDischargeOvercurrent2Delay();
                    } else if (name == '短路保护电流') {
                      _writeShortCircuitProtect();
                    } else if (name == '短路保护延时') {
                      _writeShortCircuitDelay();
                    } else if (name == '采样电阻值') {
                      _writeSamplingResistance();
                    }
                  },
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
                    languageManager.setting,
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
