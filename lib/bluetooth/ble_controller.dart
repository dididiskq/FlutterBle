import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'protocol.dart';

/// BLE蓝牙控制类
class BleController {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final BmsProtocol _protocol = BmsProtocol();
  
  // 蓝牙状态流
  Stream<BleStatus> get bleStatusStream => _ble.statusStream;
  
  // 扫描结果流
  Stream<DiscoveredDevice> get scanResultsStream => _ble.scanForDevices(
        withServices: [], // 扫描所有蓝牙设备
        scanMode: ScanMode.lowLatency,
      );
  
  // 当前连接的设备
  DiscoveredDevice? _connectedDevice;
  DiscoveredDevice? get connectedDevice => _connectedDevice;
  
  // 连接状态流（简化实现）
  final StreamController<ConnectionStateUpdate> _connectionStateController = StreamController.broadcast();
  Stream<ConnectionStateUpdate> get connectionStateStream => _connectionStateController.stream;

  /// 请求蓝牙和位置权限
  Future<bool> requestPermissions() async {
    // 检查Android版本并请求相应的蓝牙权限
    if (await Permission.bluetoothScan.request().isDenied) {
      return false;
    }
    
    if (await Permission.bluetoothConnect.request().isDenied) {
      return false;
    }
    
    // 传统蓝牙权限（针对旧版Android）
    if (await Permission.bluetooth.request().isDenied) {
      return false;
    }
    
    // 请求位置权限（Android需要位置权限才能扫描蓝牙）
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      return false;
    }
    
    return true;
  }

  /// 开始扫描蓝牙设备
  Stream<DiscoveredDevice> startScan() {
    return _ble.scanForDevices(
      withServices: [], // 扫描所有设备
      scanMode: ScanMode.balanced, // 使用平衡模式，减少功耗问题
    );
  }

  /// 停止扫描蓝牙设备
  Future<void> stopScan() async {
    // flutter_reactive_ble会自动管理扫描停止
    // 当不再监听scanResultsStream时，扫描会自动停止
  }

  /// 连接蓝牙设备
  Future<void> connectToDevice(String deviceId) async {
    try {
      // 在flutter_reactive_ble 5.0.0中，connectToDevice返回连接状态流
      final connectionStream = _ble.connectToDevice(
        id: deviceId,
        connectionTimeout: Duration(seconds: 10),
      );
      
      // 监听连接状态变化
      connectionStream.listen((connectionState) {
        _connectionStateController.add(connectionState);
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          // 连接成功
        } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
          _connectedDevice = null;
        }
      });
    } catch (e) {
      print('连接失败: $e');
      rethrow;
    }
  }

  /// 断开蓝牙设备连接
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      // 在flutter_reactive_ble 5.4.0中，没有disconnectFromDevice方法
      // 连接会在订阅取消时自动断开
      // 我们只需要更新本地状态
      _connectedDevice = null;
      // 发送断开连接状态更新
      _connectionStateController.add(ConnectionStateUpdate(
        deviceId: deviceId,
        connectionState: DeviceConnectionState.disconnected,
        failure: null,
      ));
    } catch (e) {
      print('断开连接失败: $e');
      rethrow;
    }
  }

  /// 读取特征值
  Future<Uint8List> readCharacteristic(QualifiedCharacteristic characteristic) async {
    try {
      final data = await _ble.readCharacteristic(characteristic);
      return Uint8List.fromList(data);
    } catch (e) {
      print('读取特征值失败: $e');
      rethrow;
    }
  }

  /// 写入特征值
  Future<void> writeCharacteristic(
    QualifiedCharacteristic characteristic,
    Uint8List value,
  ) async {
    try {
      await _ble.writeCharacteristicWithResponse(
        characteristic,
        value: value,
      );
    } catch (e) {
      print('写入特征值失败: $e');
      rethrow;
    }
  }

  /// 监听特征值变化
  Stream<List<int>> subscribeToCharacteristic(
      QualifiedCharacteristic characteristic) {
    return _ble.subscribeToCharacteristic(characteristic);
  }

  /// 解析接收到的数据
  BatteryData parseBatteryData(List<int> data) {
    return _protocol.parseBatteryData(Uint8List.fromList(data));
  }

  /// 构建写入命令
  Uint8List buildWriteCommand(int commandId, List<int> data) {
    return _protocol.buildWriteCommand(commandId, Uint8List.fromList(data));
  }

  /// 检查蓝牙状态
  Future<BleStatus> getBleStatus() async {
    return _ble.status;
  }

  /// 销毁资源
  void dispose() {
    _connectionStateController.close();
  }
}

/// 设备信息类（用于UI显示）
class BleDevice {
  final String id;
  final String name;
  final int rssi;
  bool isConnected;
  
  BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.isConnected = false,
  });

  // 从扫描结果创建BleDevice
  factory BleDevice.fromDiscoveredDevice(DiscoveredDevice device) {
    return BleDevice(
      id: device.id,
      name: device.name.isNotEmpty ? device.name : '未知设备',
      rssi: device.rssi,
    );
  }
}