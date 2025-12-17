import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import 'protocol.dart';

// 连接结果状态枚举
enum ConnectionResult {
  success,
  serviceNotFound,
  characteristicNotFound,
  connectionFailed,
  unknownError,
}

// 连接结果类
class ConnectionResultData {
  final ConnectionResult result;
  final String? message;
  
  ConnectionResultData(this.result, this.message);
}

/// BLE蓝牙控制类
class BleController {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final BmsProtocol _protocol = BmsProtocol();
  
  // 蓝牙UUID常量
  static const String SERVICE_UUID = "00002760-08C2-11E1-9073-0E8AC72E1001";
  static const String WRITE_UUID = "00002760-08C2-11E1-9073-0E8AC72E0001";
  static const String NOTIFY_UUID = "00002760-08C2-11E1-9073-0E8AC72E0002";
  
  // 使用Uuid.parse创建Uuid对象（flutter_reactive_ble库的Uuid）
  static final Uuid _serviceUuid = Uuid.parse(SERVICE_UUID);
  static final Uuid _writeUuid = Uuid.parse(WRITE_UUID);
  static final Uuid _notifyUuid = Uuid.parse(NOTIFY_UUID);
  
  // 公开访问方法
  Uuid get serviceUuid => _serviceUuid;
  Uuid get writeUuid => _writeUuid;
  Uuid get notifyUuid => _notifyUuid;
  
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
  
  // 连接状态流
  final StreamController<ConnectionStateUpdate> _connectionStateController = StreamController.broadcast();
  Stream<ConnectionStateUpdate> get connectionStateStream => _connectionStateController.stream;
  
  // 发现的服务和特征
  DiscoveredService? _discoveredService;
  QualifiedCharacteristic? _writeCharacteristic;
  QualifiedCharacteristic? _notifyCharacteristic;
  
  // 通知数据流
  final StreamController<List<int>> _notificationStreamController = StreamController.broadcast();
  Stream<List<int>> get notificationStream => _notificationStreamController.stream;
  
  // 通知订阅
  StreamSubscription<List<int>>? _notificationSubscription;
  
  // 连接结果流
  final StreamController<ConnectionResultData> _connectionResultController = StreamController.broadcast();
  Stream<ConnectionResultData> get connectionResultStream => _connectionResultController.stream;

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

  /// 发现指定服务
  Future<DiscoveredService> discoverService(String deviceId, Uuid serviceId) async {
    try {
      final services = await _ble.discoverServices(deviceId);
      final service = services.firstWhere(
        (service) => service.serviceId == serviceId,
        orElse: () => throw Exception('未找到指定服务: $serviceId'),
      );
      _discoveredService = service;
      return service;
    } catch (e) {
      print('发现服务失败: $e');
      rethrow;
    }
  }

  /// 发现指定特征
  Future<void> discoverCharacteristics(String deviceId) async {
    if (_discoveredService == null) {
      await discoverService(deviceId, _serviceUuid);
    }

    try {
      // 查找写入特征
      final writeChar = _discoveredService!.characteristics.firstWhere(
        (char) => char.characteristicId == _writeUuid,
        orElse: () => throw Exception('未找到写入特征: $_writeUuid'),
      );
      _writeCharacteristic = QualifiedCharacteristic(
        serviceId: _serviceUuid,
        characteristicId: _writeUuid,
        deviceId: deviceId,
      );

      // 查找通知特征
      final notifyChar = _discoveredService!.characteristics.firstWhere(
        (char) => char.characteristicId == _notifyUuid,
        orElse: () => throw Exception('未找到通知特征: $_notifyUuid'),
      );
      _notifyCharacteristic = QualifiedCharacteristic(
        serviceId: _serviceUuid,
        characteristicId: _notifyUuid,
        deviceId: deviceId,
      );
    } catch (e) {
      print('发现特征失败: $e');
      rethrow;
    }
  }

  /// 启用通知
  Future<void> enableNotification() async {
    if (_notifyCharacteristic == null) {
      throw Exception('未找到通知特征，请先调用discoverCharacteristics');
    }

    try {
      // 订阅通知
      _notificationSubscription = _ble
          .subscribeToCharacteristic(_notifyCharacteristic!)
          .listen((data) {
        _notificationStreamController.add(data);
      }, onError: (error) {
        print('通知订阅失败: $error');
      });
    } catch (e) {
      print('启用通知失败: $e');
      rethrow;
    }
  }

  /// 连接蓝牙设备
  Future<void> connectToDevice(String deviceId) async {
    try {
      // 重置状态
      _discoveredService = null;
      _writeCharacteristic = null;
      _notifyCharacteristic = null;
      _notificationSubscription?.cancel();
      
      // 调用flutter_reactive_ble库的connectToDevice方法
      final connectionStream = _ble.connectToDevice(
        id: deviceId,
        connectionTimeout: Duration(seconds: 10),
      );
      
      // 监听连接状态变化
      connectionStream.listen((connectionState) {
        _connectionStateController.add(connectionState);
        
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          // 连接成功，自动发现服务和特征
          discoverCharacteristics(deviceId)
              .then((_) {
                // 启用通知
                return enableNotification();
              })
              .then((_) {
                // 连接流程完全成功
                _connectionResultController.add(ConnectionResultData(ConnectionResult.success, null));
              })
              .catchError((error) {
                // 处理发现服务和特征或启用通知失败的情况
                String errorMessage = '连接失败: $error';
                ConnectionResult result = ConnectionResult.unknownError;
                
                if (error.toString().contains('未找到指定服务')) {
                  result = ConnectionResult.serviceNotFound;
                  errorMessage = '未找到指定服务，设备类型不匹配';
                } else if (error.toString().contains('未找到写入特征') || 
                           error.toString().contains('未找到通知特征')) {
                  result = ConnectionResult.characteristicNotFound;
                  errorMessage = '未找到指定特征，设备类型不匹配';
                }
                
                print(errorMessage);
                _connectionResultController.add(ConnectionResultData(result, errorMessage));
              });
        } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
          // 断开连接，清理资源
          _connectedDevice = null;
          _discoveredService = null;
          _writeCharacteristic = null;
          _notifyCharacteristic = null;
          _notificationSubscription?.cancel();
          _notificationSubscription = null;
        } else if (connectionState.failure != null) {
          // 连接过程中发生错误
          final error = connectionState.failure;
          print('连接失败: $error');
          _connectionResultController.add(ConnectionResultData(
            ConnectionResult.connectionFailed,
            '连接失败: ${error?.message ?? '未知错误'}'
          ));
        }
      });
    } catch (e) {
      print('连接初始化失败: $e');
      _connectionResultController.add(ConnectionResultData(
        ConnectionResult.connectionFailed,
        '连接初始化失败: $e'
      ));
      rethrow;
    }
  }

  /// 断开蓝牙设备连接
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      // 清理资源
      _notificationSubscription?.cancel();
      _notificationSubscription = null;
      
      // 重置状态
      _connectedDevice = null;
      _discoveredService = null;
      _writeCharacteristic = null;
      _notifyCharacteristic = null;
      
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

  /// 主动读取通知特征值
  Future<Uint8List> readNotifyCharacteristic() async {
    if (_notifyCharacteristic == null) {
      throw Exception('未找到通知特征，请先连接设备');
    }
    
    try {
      final data = await _ble.readCharacteristic(_notifyCharacteristic!);
      return Uint8List.fromList(data);
    } catch (e) {
      print('读取通知特征值失败: $e');
      rethrow;
    }
  }

  /// 读取写入特征值
  Future<Uint8List> readWriteCharacteristic() async {
    if (_writeCharacteristic == null) {
      throw Exception('未找到写入特征，请先连接设备');
    }
    
    try {
      final data = await _ble.readCharacteristic(_writeCharacteristic!);
      return Uint8List.fromList(data);
    } catch (e) {
      print('读取写入特征值失败: $e');
      rethrow;
    }
  }

  /// 写入数据到特征值
  Future<void> writeData(Uint8List value, {bool withResponse = true}) async {
    if (_writeCharacteristic == null) {
      throw Exception('未找到写入特征，请先连接设备');
    }
    
    try {
      if (withResponse) {
        await _ble.writeCharacteristicWithResponse(
          _writeCharacteristic!,
          value: value,
        );
      } else {
        await _ble.writeCharacteristicWithoutResponse(
          _writeCharacteristic!,
          value: value,
        );
      }
    } catch (e) {
      print('写入数据失败: $e');
      rethrow;
    }
  }

  /// 便捷方法：发送命令
  Future<void> sendCommand(int commandId, Map<String, dynamic> data, {bool withResponse = true}) async {
    final command = buildCommand(commandId, data);
    await writeData(command, withResponse: withResponse);
  }

  /// 通过通知接收数据（便捷方法，使用内部流）
  Stream<List<int>> receiveNotificationData() {
    return notificationStream;
  }

  /// 监听特征值变化（原始方法，需要传入特征）
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
    // 兼容旧的API调用方式
    return _protocol.buildCommand(commandId, {'rawData': data});
  }

  /// 构建发送命令（新API）
  Uint8List buildCommand(int commandId, Map<String, dynamic> data) {
    return _protocol.buildCommand(commandId, data);
  }

  /// 检查蓝牙状态
  Future<BleStatus> getBleStatus() async {
    return _ble.status;
  }

  /// 销毁资源
  void dispose() {
    _connectionStateController.close();
    _notificationStreamController.close();
    _connectionResultController.close();
    _notificationSubscription?.cancel();
  }
}

/// 设备信息类（用于UI显示）
class BleDevice {
  final String id;
  final String name;
  final int rssi;
  bool isConnected;
  bool isConnecting;
  
  BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.isConnected = false,
    this.isConnecting = false,
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