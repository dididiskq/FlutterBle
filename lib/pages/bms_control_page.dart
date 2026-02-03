import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/common_app_bar.dart';
import '../components/operation_confirm_dialog.dart';
import '../managers/battery_data_manager.dart';
import '../managers/language_manager.dart';

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
    return Consumer<LanguageManager>(
      builder: (context, languageManager, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A1128),
          appBar: CommonAppBar(title: languageManager.deviceControlPageTitle),
          body: Container(
            color: const Color(0xFF0A1128),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 系统控制按钮组
                  _buildControlButton(languageManager.systemShutdownText, () async {
                    final confirmed = await OperationConfirmDialog.show(
                      context,
                      title: languageManager.isChinese ? '确认系统关机' : 'Confirm System Shutdown',
                      operationName: languageManager.systemShutdownText,
                    );
                    
                    if (confirmed && mounted) {
                      final success = await _batteryDataManager.writeParameters(0x0001, [0]);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(languageManager.isChinese 
                              ? (success ? '系统关机成功' : '系统关机失败') 
                              : (success ? 'System shutdown success' : 'System shutdown failed')),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  }),
                  _buildControlButton(languageManager.restoreFactoryText, () async {
                    final confirmed = await OperationConfirmDialog.show(
                      context,
                      title: languageManager.isChinese ? '确认恢复出厂' : 'Confirm Restore Factory',
                      operationName: languageManager.isChinese ? '恢复出厂设置' : 'Restore Factory Settings',
                    );
                    
                    if (confirmed && mounted) {
                      final success = await _batteryDataManager.writeParameters(0x0002, [0]);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(languageManager.isChinese 
                              ? (success ? '恢复出厂成功' : '恢复出厂失败') 
                              : (success ? 'Restore factory success' : 'Restore factory failed')),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  }),
                  _buildControlButton(languageManager.restartSystemText, () async {
                    final confirmed = await OperationConfirmDialog.show(
                      context,
                      title: languageManager.isChinese ? '确认重启系统' : 'Confirm Restart System',
                      operationName: languageManager.restartSystemText,
                    );
                    
                    if (confirmed && mounted) {
                      final success = await _batteryDataManager.writeParameters(0x0000, [0]);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(languageManager.isChinese 
                              ? (success ? '重启系统成功' : '重启系统失败') 
                              : (success ? 'Restart system success' : 'Restart system failed')),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  }),
                  _buildControlButton(languageManager.toggleLanguageButtonText, () {
                    languageManager.toggleLanguage();
                  }),
                  const SizedBox(height: 20.0),
                  
                  // 弱电开关
                  _buildSwitchRow(languageManager.weakPowerSwitchText, _weakPowerSwitch, (value) async {
                    final confirmed = await OperationConfirmDialog.show(
                      context,
                      title: languageManager.isChinese ? '确认切换弱电开关' : 'Confirm Toggle Weak Power Switch',
                      operationName: languageManager.isChinese 
                        ? (value ? '开启弱电开关' : '关闭弱电开关') 
                        : (value ? 'Turn on weak power switch' : 'Turn off weak power switch'),
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
                            content: Text(languageManager.isChinese 
                              ? (value ? '弱电开关已开启' : '弱电开关已关闭') 
                              : (value ? 'Weak power switch on' : 'Weak power switch off')),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(languageManager.isChinese ? '操作失败' : 'Operation failed'),
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
                                languageManager.forceChargeControlText,
                                style: const TextStyle(color: Colors.white, fontSize: 16.0),
                              ),
                            ),
                            Switch(
                              value: _forceChargeSwitch,
                              onChanged: (value) async {
                                final confirmed = await OperationConfirmDialog.show(
                                  context,
                                  title: languageManager.isChinese ? '确认切换强制充电控制' : 'Confirm Toggle Force Charge Control',
                                  operationName: languageManager.isChinese 
                                    ? (value ? '开启强制充电控制' : '关闭强制充电控制') 
                                    : (value ? 'Turn on force charge control' : 'Turn off force charge control'),
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
                                        content: Text(languageManager.isChinese 
                                          ? (value ? '强制充电控制已开启' : '强制充电控制已关闭') 
                                          : (value ? 'Force charge control on' : 'Force charge control off')),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(languageManager.isChinese ? '操作失败' : 'Operation failed'),
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
                      _buildControlButton(languageManager.cancelForceChargeText, () async {
                        final confirmed = await OperationConfirmDialog.show(
                          context,
                          title: languageManager.isChinese ? '确认取消强制充电' : 'Confirm Cancel Force Charge',
                          operationName: languageManager.cancelForceChargeText,
                        );
                        
                        if (confirmed && mounted) {
                          final success = await _batteryDataManager.writeParameters(0x0008, [0]);
                          
                          if (success && mounted) {
                            await _readControlFlags();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(languageManager.isChinese ? '已取消强制充电' : 'Force charge canceled'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(languageManager.isChinese ? '操作失败' : 'Operation failed'),
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
                                languageManager.forceDischargeControlText,
                                style: const TextStyle(color: Colors.white, fontSize: 16.0),
                              ),
                            ),
                            Switch(
                              value: _forceDischargeSwitch,
                              onChanged: (value) async {
                                final confirmed = await OperationConfirmDialog.show(
                                  context,
                                  title: languageManager.isChinese ? '确认切换强制放电控制' : 'Confirm Toggle Force Discharge Control',
                                  operationName: languageManager.isChinese 
                                    ? (value ? '开启强制放电控制' : '关闭强制放电控制') 
                                    : (value ? 'Turn on force discharge control' : 'Turn off force discharge control'),
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
                                        content: Text(languageManager.isChinese 
                                          ? (value ? '强制放电控制已开启' : '强制放电控制已关闭') 
                                          : (value ? 'Force discharge control on' : 'Force discharge control off')),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(languageManager.isChinese ? '操作失败' : 'Operation failed'),
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
                      _buildControlButton(languageManager.cancelForceDischargeText, () async {
                        final confirmed = await OperationConfirmDialog.show(
                          context,
                          title: languageManager.isChinese ? '确认取消强制放电' : 'Confirm Cancel Force Discharge',
                          operationName: languageManager.cancelForceDischargeText,
                        );
                        
                        if (confirmed && mounted) {
                          final success = await _batteryDataManager.writeParameters(0x0005, [0]);
                          
                          if (success && mounted) {
                            await _readControlFlags();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(languageManager.isChinese ? '已取消强制放电' : 'Force discharge canceled'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(languageManager.isChinese ? '操作失败' : 'Operation failed'),
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