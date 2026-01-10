import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';
import '../components/write_confirm_dialog.dart';
import '../managers/battery_data_manager.dart';

// 快速设置页面
class QuickSettingsPage extends StatefulWidget {
  const QuickSettingsPage({super.key});

  @override
  State<QuickSettingsPage> createState() => _QuickSettingsPageState();
}

class _QuickSettingsPageState extends State<QuickSettingsPage> {
  final BatteryDataManager _batteryDataManager = BatteryDataManager();
  
  // 控制器
  late TextEditingController _batterySeriesController;
  late TextEditingController _batteryCapacityController;
  
  // 写入状态
  bool _isWriting = false;
  String _writeStatus = '';
  Color _writeStatusColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    // 初始化控制器
    _batterySeriesController = TextEditingController(text: '0');
    _batteryCapacityController = TextEditingController(text: '0');
 
    // 页面加载时读取数据
    _readSettingsData();
 
  }

  Future<void> _readSettingsData() async {
    if (!_batteryDataManager.isConnected) {
      print('[QuickSettingsPage] 设备未连接，无法读取数据');
      return;
    }
    
    print('[QuickSettingsPage] 开始读取快速设置数据...');

    // 读取电池串数
    final seriesCount = await _batteryDataManager.readSetBatterySeriesCount();
    if (seriesCount != null && mounted) {
      setState(() {
        _batterySeriesController.text = seriesCount.toString();
      });
      print('[QuickSettingsPage] 电池串数: $seriesCount');
    }
    await Future.delayed(const Duration(milliseconds: 100));
    // 读取电池容量
    final capacityMah = await _batteryDataManager.readSetBatteryCapacity();
    if (capacityMah != null && mounted) {
      final capacityAh = (capacityMah / 1000).round();
      setState(() {
        _batteryCapacityController.text = capacityAh.toString();
      });
      print('[QuickSettingsPage] 电池容量: $capacityMah mAh ($capacityAh AH)');
    }
  }

  @override
  void dispose() {
    // 释放控制器
    _batterySeriesController.dispose();
    _batteryCapacityController.dispose();
    super.dispose();
  }
  
  Future<void> _writeBatterySeriesCount() async {
    final text = _batterySeriesController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _writeStatus = '请输入电池串数';
        _writeStatusColor = Colors.orange;
      });
      return;
    }
    
    final count = int.tryParse(text);
    if (count == null || count <= 0) {
      setState(() {
        _writeStatus = '请输入有效的电池串数';
        _writeStatusColor = Colors.orange;
      });
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      setState(() {
        _writeStatus = '设备未连接，无法写入';
        _writeStatusColor = Colors.red;
      });
      return;
    }
    
    final oldValue = _batteryDataManager.currentData.cellNumber;
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '电池实际串数',
      oldValue: oldValue,
      newValue: count,
    );
    
    if (!confirmed) {
      return;
    }
    
    setState(() {
      _isWriting = true;
      _writeStatus = '正在写入...';
      _writeStatusColor = Colors.blue;
    });
    
    try {
      final success = await _batteryDataManager.writeBatterySeriesCount(count);
      setState(() {
        _isWriting = false;
        if (success) {
          _writeStatus = '电池串数写入成功';
          _writeStatusColor = Colors.green;
        } else {
          _writeStatus = '电池串数写入失败';
          _writeStatusColor = Colors.red;
        }
      });
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _writeStatus = '';
            _writeStatusColor = Colors.transparent;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isWriting = false;
        _writeStatus = '写入出错: $e';
        _writeStatusColor = Colors.red;
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
  }

  Future<void> _writeBatteryCapacity() async {
    final text = _batteryCapacityController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _writeStatus = '请输入电池容量';
        _writeStatusColor = Colors.orange;
      });
      return;
    }
    
    final capacityAh = int.tryParse(text);
    if (capacityAh == null || capacityAh <= 0) {
      setState(() {
        _writeStatus = '请输入有效的电池容量';
        _writeStatusColor = Colors.orange;
      });
      return;
    }
    
    if (!_batteryDataManager.isConnected) {
      setState(() {
        _writeStatus = '设备未连接，无法写入';
        _writeStatusColor = Colors.red;
      });
      return;
    }
    
    final oldValue = _batteryDataManager.currentData.capacity;
    
    final confirmed = await WriteConfirmDialog.show(
      context,
      title: '确认写入',
      parameterName: '电池物理容量',
      oldValue: oldValue,
      newValue: capacityAh,
    );
    
    if (!confirmed) {
      return;
    }
    
    setState(() {
      _isWriting = true;
      _writeStatus = '正在写入...';
      _writeStatusColor = Colors.blue;
    });
    
    try {
      final capacityMah = capacityAh * 1000;
      final success = await _batteryDataManager.writeBatteryCapacity(capacityMah);
      setState(() {
        _isWriting = false;
        if (success) {
          _writeStatus = '电池容量写入成功';
          _writeStatusColor = Colors.green;
        } else {
          _writeStatus = '电池容量写入失败';
          _writeStatusColor = Colors.red;
        }
      });
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _writeStatus = '';
            _writeStatusColor = Colors.transparent;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isWriting = false;
        _writeStatus = '写入出错: $e';
        _writeStatusColor = Colors.red;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  CommonAppBar(title: '快速设置'),
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
                    _buildParamRow('电池实际串数', _batterySeriesController, '串'),
                    _buildParamRow('电池物理容量', _batteryCapacityController, 'AH'),
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
                    if (name == '电池实际串数') {
                      _writeBatterySeriesCount();
                    } else if (name == '电池物理容量') {
                      _writeBatteryCapacity();
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
