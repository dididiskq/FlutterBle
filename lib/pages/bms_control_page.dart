import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';
import '../components/operation_confirm_dialog.dart';
import '../managers/battery_data_manager.dart';

class BmsControlPage extends StatefulWidget {
  const BmsControlPage({super.key});

  @override
  State<BmsControlPage> createState() => _BmsControlPageState();
}

class _BmsControlPageState extends State<BmsControlPage> {
  final BatteryDataManager _batteryDataManager = BatteryDataManager();
  
  // 开关状态
  bool _weakPowerSwitch = false;
  bool _forceChargeSwitch = false;
  bool _forceDischargeSwitch = false;
  
  // 开关配置寄存器值
  int _switchConfigValue = 0;
  
  // 控制标志寄存器值
  int _controlFlagsValue = 0;

  @override
  void initState() {
    super.initState();
    _readAllSwitchStates();
  }
  
  Future<void> _readAllSwitchStates() async {
    await _readSwitchConfig();
    await _readControlFlags();
  }
  
  Future<void> _readSwitchConfig() async {
    final value = await _batteryDataManager.readSwitchConfig();
    if (value != null && mounted) {
      setState(() {
        _switchConfigValue = value;
        _weakPowerSwitch = (value & 0x01) != 0;
      });
    }
  }
  
  Future<void> _readControlFlags() async {
    final value = await _batteryDataManager.readControlFlags();
    if (value != null && mounted) {
      setState(() {
        _controlFlagsValue = value;
        
        // bit2: 强制开启放电标志
        // bit3: 强制关闭放电标志
        // bit4: 强制开启充电标志
        // bit5: 强制关闭充电标志
        
        final forceDischargeOn = (value & 0x04) != 0;
        final forceDischargeOff = (value & 0x08) != 0;
        final forceChargeOn = (value & 0x10) != 0;
        final forceChargeOff = (value & 0x20) != 0;
        
        // 如果强制开启标志为1，则开关为开
        // 如果强制关闭标志为1，则开关为关
        _forceDischargeSwitch = forceDischargeOn && !forceDischargeOff;
        _forceChargeSwitch = forceChargeOn && !forceChargeOff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      appBar: CommonAppBar(title: '设备控制'),
      body: Container(
        color: const Color(0xFF0A1128),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 系统控制按钮组
              _buildControlButton('系统关机', () async {
                final confirmed = await OperationConfirmDialog.show(
                  context,
                  title: '确认系统关机',
                  operationName: '系统关机',
                );
                
                if (confirmed && mounted) {
                  final success = await _batteryDataManager.writeParameters(0x0001, [0]);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? '系统关机成功' : '系统关机失败'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              }),
              _buildControlButton('恢复出厂', () async {
                final confirmed = await OperationConfirmDialog.show(
                  context,
                  title: '确认恢复出厂',
                  operationName: '恢复出厂设置',
                );
                
                if (confirmed && mounted) {
                  final success = await _batteryDataManager.writeParameters(0x0002, [0]);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? '恢复出厂成功' : '恢复出厂失败'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              }),
              _buildControlButton('重启系统', () async {
                final confirmed = await OperationConfirmDialog.show(
                  context,
                  title: '确认重启系统',
                  operationName: '重启系统',
                );
                
                if (confirmed && mounted) {
                  final success = await _batteryDataManager.writeParameters(0x0000, [0]);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? '重启系统成功' : '重启系统失败'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              }),
              _buildControlButton('切换为英文', () async {
                // TODO: 实现语言切换逻辑
              }),
              const SizedBox(height: 20.0),
              
              // 弱电开关
              _buildSwitchRow('弱电开关', _weakPowerSwitch, (value) async {
                final confirmed = await OperationConfirmDialog.show(
                  context,
                  title: '确认切换弱电开关',
                  operationName: value ? '开启弱电开关' : '关闭弱电开关',
                );
                
                if (confirmed && mounted) {
                  int newValue;
                  if (value) {
                    newValue = _switchConfigValue | 0x01;
                  } else {
                    newValue = _switchConfigValue & ~0x01;
                  }
                  
                  final success = await _batteryDataManager.writeParameters(0x205, [newValue]);
                  
                  if (success && mounted) {
                    setState(() {
                      _switchConfigValue = newValue;
                      _weakPowerSwitch = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? '弱电开关已开启' : '弱电开关已关闭'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('操作失败'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }),
              const SizedBox(height: 20.0),
              
              // 充电放电控制
              Column(
                children: [
                  // 强制充电控制
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2332),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: const Color(0xFF3A475E), width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '强制充电控制',
                            style: const TextStyle(color: Colors.white, fontSize: 16.0),
                          ),
                        ),
                        Switch(
                          value: _forceChargeSwitch,
                          onChanged: (value) async {
                            final confirmed = await OperationConfirmDialog.show(
                              context,
                              title: '确认切换强制充电控制',
                              operationName: value ? '开启强制充电控制' : '关闭强制充电控制',
                            );
                            
                            if (confirmed && mounted) {
                              final address = value ? 0x0006 : 0x0007;
                              final success = await _batteryDataManager.writeParameters(address, [0]);
                              
                              if (success && mounted) {
                                setState(() {
                                  _forceChargeSwitch = value;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(value ? '强制充电控制已开启' : '强制充电控制已关闭'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('操作失败'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          activeColor: Colors.blue,
                          inactiveTrackColor: const Color(0xFF3A475E),
                          inactiveThumbColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  
                  // 取消强制充电按钮
                  _buildControlButton('取消强制充电', () async {
                    final confirmed = await OperationConfirmDialog.show(
                      context,
                      title: '确认取消强制充电',
                      operationName: '取消强制充电',
                    );
                    
                    if (confirmed && mounted) {
                      final success = await _batteryDataManager.writeParameters(0x0008, [0]);
                      
                      if (success && mounted) {
                        await _readControlFlags();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已取消强制充电'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('操作失败'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }),
                  const SizedBox(height: 20.0),
                  
                  // 强制放电控制
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2332),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: const Color(0xFF3A475E), width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '强制放电控制',
                            style: const TextStyle(color: Colors.white, fontSize: 16.0),
                          ),
                        ),
                        Switch(
                          value: _forceDischargeSwitch,
                          onChanged: (value) async {
                            final confirmed = await OperationConfirmDialog.show(
                              context,
                              title: '确认切换强制放电控制',
                              operationName: value ? '开启强制放电控制' : '关闭强制放电控制',
                            );
                            
                            if (confirmed && mounted) {
                              final address = value ? 0x0003 : 0x0004;
                              final success = await _batteryDataManager.writeParameters(address, [0]);
                              
                              if (success && mounted) {
                                setState(() {
                                  _forceDischargeSwitch = value;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(value ? '强制放电控制已开启' : '强制放电控制已关闭'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('操作失败'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          activeColor: Colors.blue,
                          inactiveTrackColor: const Color(0xFF3A475E),
                          inactiveThumbColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  
                  // 取消强制放电按钮
                  _buildControlButton('取消强制放电', () async {
                    final confirmed = await OperationConfirmDialog.show(
                      context,
                      title: '确认取消强制放电',
                      operationName: '取消强制放电',
                    );
                    
                    if (confirmed && mounted) {
                      final success = await _batteryDataManager.writeParameters(0x0005, [0]);
                      
                      if (success && mounted) {
                        await _readControlFlags();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('已取消强制放电'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('操作失败'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建控制按钮
  Widget _buildControlButton(String title, VoidCallback? onPressed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(fontSize: 16.0, color: Colors.white),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 0,
          ),
          child: Text(title),
        ),
      ),
    );
  }

  // 构建带开关的行
  Widget _buildSwitchRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16.0)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
            inactiveTrackColor: const Color(0xFF3A475E),
            inactiveThumbColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}