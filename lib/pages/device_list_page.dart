import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ultra_bms/bluetooth/ble_controller.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final BleController _bleController = BleController();
  
  // 设备列表
  final List<BleDevice> _devices = [];
  
  // 扫描状态
  bool _isScanning = false;
  
  // 订阅流
  StreamSubscription? _scanSubscription;
  
  // 已连接设备
  BleDevice? _connectedDevice;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化时请求权限
    _requestPermissions();
    
    // 从 BleController 恢复已连接设备
    _restoreConnectedDevice();
    
    // 监听连接状态变化
    _bleController.connectionStateStream.listen((connectionState) {
      print('[DeviceListPage] 连接状态变化: ${connectionState.deviceId} -> ${connectionState.connectionState}');
      
      if (!mounted) return;
      
      setState(() {
        final deviceId = connectionState.deviceId;
        final deviceIndex = _devices.indexWhere(
          (device) => device.id == deviceId,
        );
        
        if (deviceIndex != -1) {
          final isConnected = connectionState.connectionState == DeviceConnectionState.connected;
          print('[DeviceListPage] 更新设备状态: ${_devices[deviceIndex].name} -> $isConnected');
          _devices[deviceIndex].isConnected = isConnected;
          _devices[deviceIndex].isConnecting = false;
          
          // 更新已连接设备
          if (isConnected) {
            _connectedDevice = _devices[deviceIndex];
          } else if (_connectedDevice?.id == deviceId) {
            _connectedDevice = null;
          }
        }
      });
    });

    // 监听连接结果
    _bleController.connectionResultStream.listen((result) {
      final connectionResult = result.result;
      final message = result.message;
      if (connectionResult != ConnectionResult.success && message != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        });
      }
    });

    // 监听连接成功设备事件
    _bleController.connectedDeviceStream.listen((device) {
      if (device.isConnected) {
        // 连接成功，返回主页并传递设备名称
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pop(context, device.name);
        });
      } else {
        // 断开连接，更新UI
        setState(() {
          if (_connectedDevice?.id == device.id) {
            _connectedDevice = null;
          }
          final deviceIndex = _devices.indexWhere((d) => d.id == device.id);
          if (deviceIndex != -1) {
            _devices[deviceIndex].isConnected = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _stopScan();
    _bleController.dispose();
    super.dispose();
  }

  /// 请求蓝牙和位置权限
  Future<void> _requestPermissions() async {
    final granted = await _bleController.requestPermissions();
    if (!granted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请授予蓝牙和位置权限')),
        );
      });
    }
  }

  /// 从 BleController 恢复已连接设备
  void _restoreConnectedDevice() {
    final connectedDevice = _bleController.connectedDevice;
    if (connectedDevice != null) {
      print('[DeviceListPage] 恢复已连接设备: ${connectedDevice.name}');
      
      setState(() {
        // 检查设备是否已在列表中
        final existingIndex = _devices.indexWhere((d) => d.id == connectedDevice.id);
        
        if (existingIndex != -1) {
          // 更新已存在设备的状态
          _devices[existingIndex].isConnected = true;
          _connectedDevice = _devices[existingIndex];
        } else {
          // 添加已连接设备到列表
          final bleDevice = BleDevice(
            id: connectedDevice.id,
            name: connectedDevice.name,
            rssi: connectedDevice.rssi,
            isConnected: true,
          );
          _devices.add(bleDevice);
          _connectedDevice = bleDevice;
        }
      });
    }
  }

  /// 开始扫描设备
  Future<void> _startScan() async {
    // 检查蓝牙状态
    final status = await _bleController.getBleStatus();
    if (status != BleStatus.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('蓝牙未启用')),
        );
      });
      return;
    }

    setState(() {
      _devices.clear();
      _isScanning = true;
    });

    // 开始扫描
    try {
      _scanSubscription = _bleController.startScan().listen((device) {
        setState(() {
          // 避免重复添加设备
          final existingIndex = _devices.indexWhere((d) => d.id == device.id);
          if (existingIndex != -1) {
            // 更新已存在设备的信息
            _devices[existingIndex] = BleDevice.fromDiscoveredDevice(device);
          } else {
            // 添加新设备
            _devices.add(BleDevice.fromDiscoveredDevice(device));
          }
        });
      }, onError: (error) {
        setState(() {
          _isScanning = false;
        });
        print('扫描错误详情: $error, 类型: ${error.runtimeType}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('扫描失败: $error')),
          );
        });
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      print('扫描初始化错误: $e, 类型: ${e.runtimeType}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描初始化失败: $e')),
        );
      });
    }

    // 扫描10秒后自动停止
    Future.delayed(const Duration(seconds: 10), () {
      _stopScan();
    });
  }

  /// 停止扫描设备
  void _stopScan() {
    _scanSubscription?.cancel();
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  /// 连接或断开设备
  Future<void> _toggleConnection(int deviceIndex) async {
    try {
      setState(() {
        // 更新列表中实际的设备对象，确保UI能正确显示状态
        _devices[deviceIndex].isConnecting = true;
      });
      
      final device = _devices[deviceIndex];
      
      if (device.isConnected) {
        // 断开连接
        await _bleController.disconnectFromDevice(device.id);
      } else {
        // 连接设备，传递设备名称
        await _bleController.connectToDevice(device.id, deviceName: device.name);
      }
    } catch (error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $error')),
        );
      });
    } finally {
      setState(() {
        // 无论成功失败，都结束连接中状态
        _devices[deviceIndex].isConnecting = false;
      });
    }
  }

  /// 断开已连接设备
  Future<void> _disconnectConnectedDevice() async {
    if (_connectedDevice == null) return;
    
    final deviceId = _connectedDevice!.id;
    final deviceName = _connectedDevice!.name;
    
    try {
      // 显示断开连接中状态
      setState(() {
        _connectedDevice!.isConnecting = true;
      });
      
      // 断开连接
      await _bleController.disconnectFromDevice(deviceId);
      
      // 显示断开成功反馈
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已成功断开 $deviceName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    } catch (error) {
      print('[DeviceListPage] 断开失败: $error');
      
      // 显示断开失败反馈
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('断开失败: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    } finally {
      // 更新UI状态
      setState(() {
        if (_connectedDevice != null) {
          _connectedDevice!.isConnecting = false;
        }
      });
    }
  }

  /// 获取信号强度图标
  IconData _getRssiIcon(int rssi) {
    if (rssi > -50) {
      return Icons.bluetooth_connected;
    } else if (rssi > -70) {
      return Icons.bluetooth_searching;
    } else if (rssi > -90) {
      return Icons.bluetooth_disabled;
    } else {
      return Icons.bluetooth_disabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          color: Colors.black, // 设置背景色为黑色，与底部导航栏一致
          padding: const EdgeInsets.fromLTRB(10.0, 44.0, 10.0, 10.0),
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 返回按钮
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('返回'),
              ),
              // 页面标题
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: const Text(
                  '蓝牙设备列表',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 扫描按钮
              IconButton(
                icon: _isScanning
                    ? CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isScanning ? null : _startScan,
                tooltip: _isScanning ? '扫描中...' : '重新扫描',
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFF0A1128),
        child: Column(
          children: [
            // 扫描状态提示
            if (_isScanning)
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1A2332),
                child: Row(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text('正在扫描蓝牙设备...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            
            // 已连接设备区域
            if (_connectedDevice != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bluetooth_connected, color: Colors.green, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          '已连接设备',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _connectedDevice!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _connectedDevice!.id,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _disconnectConnectedDevice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.red, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child: const Text('断开'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            // 设备列表
            Expanded(
              child: _devices.isEmpty
                  ? const Center(
                      child: Text(
                        '点击右上角扫描按钮开始扫描',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2332),
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: const Color(0xFF3A475E), width: 1),
                          ),
                          child: ListTile(
                            leading: Icon(
                              _getRssiIcon(device.rssi),
                              color: Colors.blue,
                            ),
                            title: Text(
                              device.name,
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(device.id, style: const TextStyle(color: Colors.white70)),
                                const SizedBox(height: 4),
                                Text(
                                  '信号强度: ${device.rssi} dBm',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
              onPressed: device.isConnecting ? null : () => _toggleConnection(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: device.isConnected 
                    ? const Color(0xFF3A475E) 
                    : device.isConnecting 
                        ? Colors.grey 
                        : Colors.blue,
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.red, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              child: device.isConnecting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(device.isConnected ? '断开' : '连接'),
            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
