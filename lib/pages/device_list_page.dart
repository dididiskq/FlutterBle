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
  
  @override
  void initState() {
    super.initState();
    
    // 初始化时请求权限
    _requestPermissions();
    
    // 监听连接状态变化
    _bleController.connectionStateStream.listen((connectionState) {
      setState(() {
        final deviceId = connectionState.deviceId;
        final deviceIndex = _devices.indexWhere(
          (device) => device.id == deviceId,
        );
        
        if (deviceIndex != -1) {
          _devices[deviceIndex].isConnected = 
              connectionState.connectionState == DeviceConnectionState.connected;
        }
      });
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
    setState(() {
      _isScanning = false;
    });
  }

  /// 连接或断开设备
  Future<void> _toggleConnection(BleDevice device) async {
    try {
      if (device.isConnected) {
        // 断开连接
        await _bleController.disconnectFromDevice(device.id);
      } else {
        // 连接设备
        await _bleController.connectToDevice(device.id);
      }
    } catch (error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $error')),
        );
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
      appBar: AppBar(
        title: const Text('蓝牙设备列表'),
        actions: [
          IconButton(
            icon: _isScanning
                ? CircularProgressIndicator(color: Colors.white)
                : Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
            tooltip: _isScanning ? '扫描中...' : '重新扫描',
          ),
        ],
      ),
      body: Column(
        children: [
          // 扫描状态提示
          if (_isScanning)
            Container(
              padding: EdgeInsets.all(12),
              color: Colors.blue[50],
              child: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 12),
                  Text('正在扫描蓝牙设备...'),
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
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 2,
                        child: ListTile(
                          leading: Icon(
                            _getRssiIcon(device.rssi),
                            color: Colors.blue,
                          ),
                          title: Text(
                            device.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(device.id),
                              const SizedBox(height: 4),
                              Text(
                                '信号强度: ${device.rssi} dBm',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _toggleConnection(device),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: device.isConnected ? Colors.grey : Colors.blue,
                            ),
                            child: Text(device.isConnected ? '断开' : '连接'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
