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

/// BLE蓝牙控制类（单例模式）
class BleController {
  static BleController? _instance;
  
  factory BleController() {
    _instance ??= BleController._internal();
    return _instance!;
  }
  
  BleController._internal() {
    print('[BleController] 创建单例实例');
  }
  
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final BmsProtocol _protocol = BmsProtocol();
  
  // 蓝牙UUID常量 - 正常业务功能
  static const String SERVICE_UUID = "00002760-08C2-11E1-9073-0E8AC72E1001";
  static const String WRITE_UUID = "00002760-08C2-11E1-9073-0E8AC72E0001";
  static const String NOTIFY_UUID = "00002760-08C2-11E1-9073-0E8AC72E0002";
  
  // 蓝牙UUID常量 - OTA升级功能
  static const String OTA_SERVICE_UUID = "11110001-1111-1111-1111-111111111111";
  static const String OTA_WRITE_UUID = "11110002-1111-1111-1111-111111111111";
  static const String OTA_NOTIFY_UUID = "11110003-1111-1111-1111-111111111111";
  
  // 使用Uuid.parse创建Uuid对象（flutter_reactive_ble库的Uuid）
  static final Uuid _serviceUuid = Uuid.parse(SERVICE_UUID);
  static final Uuid _writeUuid = Uuid.parse(WRITE_UUID);
  static final Uuid _notifyUuid = Uuid.parse(NOTIFY_UUID);
  
  static final Uuid _otaServiceUuid = Uuid.parse(OTA_SERVICE_UUID);
  static final Uuid _otaWriteUuid = Uuid.parse(OTA_WRITE_UUID);
  static final Uuid _otaNotifyUuid = Uuid.parse(OTA_NOTIFY_UUID);
  
  // 当前使用的UUID（默认使用正常业务UUID）
  Uuid _currentServiceUuid = _serviceUuid;
  Uuid _currentWriteUuid = _writeUuid;
  Uuid _currentNotifyUuid = _notifyUuid;
  
  // 公开访问方法
  Uuid get serviceUuid => _currentServiceUuid;
  Uuid get writeUuid => _currentWriteUuid;
  Uuid get notifyUuid => _currentNotifyUuid;
  
  /// 切换到OTA模式（使用OTA升级专用UUID）
  Future<void> enableOtaMode() async {
    print('[BLE] 切换到OTA模式');
    
    // 先检查设备是否已连接
    if (_connectedDevice == null) {
      print('[BLE] 警告：尝试切换到OTA模式，但设备未连接');
      // 仅切换UUID，不执行服务发现
      _currentServiceUuid = _otaServiceUuid;
      _currentWriteUuid = _otaWriteUuid;
      _currentNotifyUuid = _otaNotifyUuid;
      return;
    }
    
    // 权限应该在连接设备之前就已经获取，不再重复请求
    // 避免权限请求导致的连接中断问题
    
    // 取消当前通知订阅
    if (_notificationSubscription != null) {
      print('[BLE] 取消当前通知订阅');
      await _notificationSubscription!.cancel();
      _notificationSubscription = null;
    }
    
    // 切换到OTA专用UUID
    print('[BLE] 切换到OTA专用UUID');
    _currentServiceUuid = _otaServiceUuid;
    _currentWriteUuid = _otaWriteUuid;
    _currentNotifyUuid = _otaNotifyUuid;
    
    // 重置服务和特征状态
    print('[BLE] 重置服务和特征状态');
    _discoveredService = null;
    _commandCharacteristic = null;
    _dataCharacteristic = null;
    
    // OTA模式切换重试次数
    const maxRetries = 3;
    // 重试间隔
    const retryDelay = Duration(milliseconds: 800);
    
    for (int retry = 0; retry < maxRetries; retry++) {
      try {
        print('[BLE] 开始重新发现OTA服务和特征 (重试 $retry/$maxRetries)');
        
  
        // 重新发现服务和特征
        await discoverCharacteristics(_connectedDevice!.id);
        
        // 启用通知
        await enableNotification();
        
        // 👇 新增：重新协商 MTU（关键！）
        try {
          final mtu = await _ble.requestMtu(deviceId: _connectedDevice!.id, mtu: 512);
          print('[BLE] OTA 模式下 MTU 协商成功! MTU = $mtu');
        } catch (e) {
          print('[BLE] ⚠️ OTA 模式下 MTU 协商失败: $e');
 
        }
        print('[BLE] OTA模式切换成功');
        print('[BLE] 当前服务UUID: $_currentServiceUuid');
        print('[BLE] 当前写入特征UUID: $_currentWriteUuid');
        print('[BLE] 当前通知特征UUID: $_currentNotifyUuid');
        return; // 成功，退出方法
      } catch (e) {
        print('[BLE] OTA模式切换失败 (重试 $retry/$maxRetries): $e');
        
        // 检查是否是权限错误
        if (e.toString().contains('GATTINSUF_AUTHORIZATION') || 
            e.toString().contains('PERMISSION') || 
            e.toString().contains('authorization')) {
          print('[BLE] 权限认证失败，尝试重新请求权限...');
          await requestPermissions();
        }
        
        // 清理资源
        _notificationSubscription?.cancel();
        _notificationSubscription = null;
        
        // 重置服务和特征状态
        _discoveredService = null;
        _commandCharacteristic = null;
        _dataCharacteristic = null;
        
        // 如果不是最后一次重试，等待一段时间后重试
        if (retry < maxRetries - 1) {
          print('[BLE] 等待 $retryDelay 后重试OTA模式切换...');
          await Future.delayed(retryDelay);
          
          // 重新设置UUID，确保模式正确
          _currentServiceUuid = _otaServiceUuid;
          _currentWriteUuid = _otaWriteUuid;
          _currentNotifyUuid = _otaNotifyUuid;
        }
      }
    }
    
    // 如果所有重试都失败，抛出异常
    throw Exception('OTA模式切换失败，已重试 $maxRetries 次');
  }
  
  /// 切换到正常模式（使用正常业务UUID）
  Future<void> disableOtaMode() async {
    print('[BLE] 切换到正常模式');
    
    // 如果已连接设备，先断开通知订阅
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    
    // 切换UUID
    _currentServiceUuid = _serviceUuid;
    _currentWriteUuid = _writeUuid;
    _currentNotifyUuid = _notifyUuid;
    
    // 如果已连接设备，重新发现服务和特征
    if (_connectedDevice != null) {
      print('[BLE] 重新发现正常业务服务和特征');
      _discoveredService = null;
      _commandCharacteristic = null;
      _dataCharacteristic = null;
      
      try {
        await discoverCharacteristics(_connectedDevice!.id);
        await enableNotification();
        print('[BLE] 正常业务服务和特征发现完成');
      } catch (e) {
        print('[BLE] 重新发现正常业务服务失败: $e');
        rethrow;
      }
    }
  }
  
  // 蓝牙状态流
  Stream<BleStatus> get bleStatusStream => _ble.statusStream;
  
  // 扫描结果流
  Stream<DiscoveredDevice> get scanResultsStream => _ble.scanForDevices(
        withServices: [], // 扫描所有蓝牙设备
        scanMode: ScanMode.lowLatency,
      );
  
  // 当前连接的设备
  DiscoveredDevice? _connectedDevice;
  DiscoveredDevice? get connectedDevice {
    print('[BleController] connectedDevice getter被调用: $_connectedDevice');
    return _connectedDevice;
  }
  
  ///// 连接状态流
  final StreamController<ConnectionStateUpdate> _connectionStateController = StreamController.broadcast();
  Stream<ConnectionStateUpdate> get connectionStateStream => _connectionStateController.stream;
  
  /// 当前连接状态
  DeviceConnectionState _currentConnectionState = DeviceConnectionState.disconnected;
  DeviceConnectionState get connectionState => _currentConnectionState;
  
  /// 检查设备是否已连接
  bool get isConnected => _connectedDevice != null && _currentConnectionState == DeviceConnectionState.connected;
  
  /// 确保设备已连接的辅助方法
  void ensureConnected() {
    if (!isConnected) {
      throw Exception('设备未连接，请先连接设备');
    }
    if (_commandCharacteristic == null) {
      throw Exception('未找到命令控制特征，请重新连接设备');
    }
  }
  
  // 发现的服务和特征
  DiscoveredService? _discoveredService;
  QualifiedCharacteristic? _commandCharacteristic;   // 命令控制特征 (ius_cc: 11110003) - 用于发送命令和接收响应
  QualifiedCharacteristic? _dataCharacteristic;      // 数据传输特征 (ius_rc: 11110002) - 用于传输大量数据
  
  // 通知数据流
  final StreamController<List<int>> _notificationStreamController = StreamController.broadcast();
  Stream<List<int>> get notificationStream => _notificationStreamController.stream;
  
  // 通知订阅
  StreamSubscription<List<int>>? _notificationSubscription;
  
  // 连接流订阅（用于断开连接）
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  
  // 连接结果流
  final StreamController<ConnectionResultData> _connectionResultController = StreamController.broadcast();
  Stream<ConnectionResultData> get connectionResultStream => _connectionResultController.stream;

  // 连接成功设备流
  final StreamController<BleDevice> _connectedDeviceController = StreamController.broadcast();
  Stream<BleDevice> get connectedDeviceStream => _connectedDeviceController.stream;

  /// 请求蓝牙和位置权限
  Future<bool> requestPermissions() async {
    print('[BLE] 开始请求权限...');
    
    // 请求Android 12+所需的蓝牙权限
    var bluetoothScanStatus = await Permission.bluetoothScan.request();
    if (bluetoothScanStatus.isDenied) {
      print('[BLE] 蓝牙扫描权限被拒绝');
      return false;
    }
    
    var bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    if (bluetoothConnectStatus.isDenied) {
      print('[BLE] 蓝牙连接权限被拒绝');
      return false;
    }
    

    
    // 请求传统蓝牙权限（针对旧版Android）
    var bluetoothStatus = await Permission.bluetooth.request();
    if (bluetoothStatus.isDenied) {
      print('[BLE] 传统蓝牙权限被拒绝');
      // 传统蓝牙权限不是必须的，继续尝试
    }
    
    // 请求位置权限（Android 11及以下需要位置权限才能扫描蓝牙）
    var locationStatus = await Permission.location.request();
    if (locationStatus.isDenied) {
      print('[BLE] 位置权限被拒绝');
      // 在Android 12+上，蓝牙扫描不再需要位置权限
      // 但为了兼容性，我们仍然尝试请求，但不强制要求
      print('[BLE] 继续执行，位置权限可能不是必须的');
    }
    
    print('[BLE] 权限请求完成');
    return true;
  }

  /// 开始扫描蓝牙设备
  Stream<DiscoveredDevice> startScan() {
    return _ble.scanForDevices(
      withServices: [], // 扫描所有设备
      scanMode: ScanMode.balanced, // 使用平衡模式，减少功耗问题
    );
  }

  /// 扫描并根据设备名称查找设备
  /// 返回匹配到的设备ID（uuid），超时时间5秒
  Future<String> scanAndFindDeviceByName(String expectedName, {Duration timeout = const Duration(seconds: 5)}) async {
    print('[BleController] 开始扫描设备，匹配名称: $expectedName，超时时间: ${timeout.inSeconds}秒');
    
    final Completer<String> completer = Completer<String>();
    StreamSubscription<DiscoveredDevice>? subscription;
    Timer? timeoutTimer;
    
    try {
      // 开始扫描
      subscription = _ble.scanForDevices(
        withServices: [], // 扫描所有设备
        scanMode: ScanMode.lowLatency, // 快速扫描
      ).listen((device) {
        print('[BleController] 扫描到设备: ${device.name}, ID: ${device.id}');
        
        // 匹配设备名称（忽略大小写）
        if (device.name.toLowerCase() == expectedName.toLowerCase()) {
          print('[BleController] 找到匹配设备: ${device.name}, ID: ${device.id}');
          
          // 取消超时计时器
          timeoutTimer?.cancel();
          
          // 完成并返回设备ID
          if (!completer.isCompleted) {
            completer.complete(device.id);
          }
        }
      }, onError: (error) {
        print('[BleController] 扫描设备时发生错误: $error');
        if (!completer.isCompleted) {
          completer.completeError(Exception('扫描设备失败: $error'));
        }
      });
      
      // 设置超时
      timeoutTimer = Timer(timeout, () {
        print('[BleController] 扫描设备超时，未找到匹配名称的设备: $expectedName');
        if (!completer.isCompleted) {
          completer.completeError(Exception('扫描设备超时，未找到匹配名称的设备'));
        }
      });
      
      // 等待结果
      return await completer.future;
    } finally {
      // 清理资源
      subscription?.cancel();
      timeoutTimer?.cancel();
      print('[BleController] 扫描设备流程结束');
    }
  }

  /// 停止扫描蓝牙设备
  Future<void> stopScan() async {
    // flutter_reactive_ble会自动管理扫描停止
    // 当不再监听scanResultsStream时，扫描会自动停止
  }

  /// 发现指定服务
  Future<DiscoveredService> discoverService(String deviceId, Uuid serviceId) async {
    print('[BLE] 开始发现服务...');
    print('[BLE] 目标服务UUID: $serviceId');
    
    // 服务发现重试次数
    const maxRetries = 3;
    // 重试间隔
    const retryDelay = Duration(milliseconds: 500);
    
    for (int retry = 0; retry < maxRetries; retry++) {
      try {
        // 权限应该在连接设备之前就已经获取，不再重复请求
        // 避免权限请求导致的连接中断问题
        // final permissionsGranted = await requestPermissions();
        // if (!permissionsGranted) {
        //   print('[BLE] 权限不足，无法发现服务');
        //   await Future.delayed(retryDelay);
        //   continue;
        // }
        
        final services = await _ble.discoverServices(deviceId);
        print('[BLE] 发现 ${services.length} 个服务');
        
        // 打印所有发现的服务
        for (int i = 0; i < services.length; i++) {
          print('[BLE]   服务[$i]: ${services[i].serviceId} (包含 ${services[i].characteristics.length} 个特征)');
        }
        
        // 先尝试查找目标服务
        if (serviceId != null) {
          try {
            final service = services.firstWhere(
              (service) => service.serviceId == serviceId,
              orElse: () => throw Exception('未找到指定服务: $serviceId'),
            );
            
            print('[BLE] ★★★ 找到目标服务: ${service.serviceId}');
            print('[BLE] 服务包含 ${service.characteristics.length} 个特征');
            _discoveredService = service;
            return service;
          } catch (serviceError) {
            print('[BLE] 未找到目标服务，尝试查找其他服务...');
          }
        }
        
        // 如果找不到目标服务或目标服务为null，尝试查找OTA服务
        try {
          final otaService = services.firstWhere(
            (service) => service.serviceId == _otaServiceUuid,
            orElse: () => throw Exception('未找到OTA服务'),
          );
          
          // 如果找到OTA服务，自动切换到OTA模式
          print('[BLE] ★★★ 找到OTA服务，自动切换到OTA模式');
          _currentServiceUuid = _otaServiceUuid;
          _currentWriteUuid = _otaWriteUuid;
          _currentNotifyUuid = _otaNotifyUuid;
          
          _discoveredService = otaService;
          print('[BLE] ★★★ 使用OTA服务: ${otaService.serviceId}');
          print('[BLE] 服务包含 ${otaService.characteristics.length} 个特征');
          return otaService;
        } catch (otaError) {
          print('[BLE] 未找到OTA服务，尝试查找普通服务...');
        }
        
        // 如果找不到OTA服务，尝试查找普通服务
        try {
          final normalService = services.firstWhere(
            (service) => service.serviceId == _serviceUuid,
            orElse: () => throw Exception('未找到普通服务'),
          );
          
          // 如果找到普通服务，切换到普通模式
          print('[BLE] ★★★ 找到普通服务，切换到普通模式');
          _currentServiceUuid = _serviceUuid;
          _currentWriteUuid = _writeUuid;
          _currentNotifyUuid = _notifyUuid;
          
          _discoveredService = normalService;
          print('[BLE] ★★★ 使用普通服务: ${normalService.serviceId}');
          print('[BLE] 服务包含 ${normalService.characteristics.length} 个特征');
          return normalService;
        } catch (normalError) {
          print('[BLE] 未找到任何已知服务');
        }
        
        // 如果找不到任何已知服务，尝试使用第一个服务
        if (services.isNotEmpty) {
          final firstService = services.first;
          print('[BLE] ★★★ 找到第一个服务: ${firstService.serviceId}');
          print('[BLE] 服务包含 ${firstService.characteristics.length} 个特征');
          _discoveredService = firstService;
          return firstService;
        }
        
        // 如果没有找到任何服务，抛出异常
        throw Exception('未找到任何服务');
      } catch (e) {
        print('[BLE] ★★★ 发现服务失败 (重试 $retry/$maxRetries): $e');
        
        // 检查是否是权限错误
        if (e.toString().contains('GATTINSUF_AUTHORIZATION') || 
            e.toString().contains('PERMISSION') || 
            e.toString().contains('authorization')) {
          print('[BLE] 权限认证失败，尝试重新请求权限...');
          await requestPermissions();
        }
        
        // 如果不是最后一次重试，等待一段时间后重试
        if (retry < maxRetries - 1) {
          print('[BLE] 等待 $retryDelay 后重试服务发现...');
          await Future.delayed(retryDelay);
        }
      }
    }
    
    // 如果所有重试都失败，抛出异常
    throw Exception('服务发现失败，已重试 $maxRetries 次');
  }

  /// 发现指定特征
  Future<void> discoverCharacteristics(String deviceId) async {
    if (_discoveredService == null) {
      await discoverService(deviceId, _currentServiceUuid);
    }

    try {
      // 打印所有特征
      print('[BLE] 服务中的所有特征:');
      for (int i = 0; i < _discoveredService!.characteristics.length; i++) {
        final char = _discoveredService!.characteristics[i];
        print('[BLE]   特征[$i]: ${char.characteristicId}');
      }
      
      // 查找数据传输特征 (ius_rc: 11110002) - 用于传输大量数据
      final dataChar = _discoveredService!.characteristics.firstWhere(
        (char) => char.characteristicId == _currentWriteUuid,
        orElse: () => throw Exception('未找到数据传输特征: $_currentWriteUuid'),
      );
      
      print('[BLE] 数据传输特征: ${dataChar.characteristicId}');
      
      _dataCharacteristic = QualifiedCharacteristic(
        serviceId: _currentServiceUuid,
        characteristicId: _currentWriteUuid,
        deviceId: deviceId,
      );

      // 查找命令控制特征 (ius_cc: 11110003) - 用于发送命令和接收响应
      final commandChar = _discoveredService!.characteristics.firstWhere(
        (char) => char.characteristicId == _currentNotifyUuid,
        orElse: () => throw Exception('未找到命令控制特征: $_currentNotifyUuid'),
      );
      
      print('[BLE] 命令控制特征: ${commandChar.characteristicId}');
      
      _commandCharacteristic = QualifiedCharacteristic(
        serviceId: _currentServiceUuid,
        characteristicId: _currentNotifyUuid,
        deviceId: deviceId,
      );
    } catch (e) {
      print('发现特征失败: $e');
      rethrow;
    }
  }

  /// 启用通知
  Future<void> enableNotification() async {
    if (_commandCharacteristic == null) {
      throw Exception('未找到通知特征，请先调用discoverCharacteristics');
    }

    try {
      print('[BLE] 开始订阅通知特征: ${_commandCharacteristic!.characteristicId}');
      
      // 取消之前的订阅
      _notificationSubscription?.cancel();
      _notificationSubscription = null;
      
      // 订阅通知
      _notificationSubscription = _ble
          .subscribeToCharacteristic(_commandCharacteristic!)
          .listen((data) {
        print('[BLE] 收到通知数据: $data');
        _notificationStreamController.add(data);
      }, onError: (error) {
        print('[BLE] 通知订阅失败: $error');
      }, onDone: () {
        print('[BLE] 通知订阅流已关闭');
      });
      
      print('[BLE] 通知订阅已建立');
      
      // 等待一小段时间确保订阅生效
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('[BLE] 启用通知失败: $e');
      rethrow;
    }
  }

  /// 连接蓝牙设备
  Future<void> connectToDevice(String deviceId, {String? deviceName}) async {
    print('[BLE] ==================== 开始连接设备 ====================');
    print('[BLE] 设备ID: $deviceId');
    if (deviceName != null) {
      print('[BLE] 设备名称: $deviceName');
    }
    
    try {
      // 重置状态
      _discoveredService = null;
      _commandCharacteristic = null;
      _dataCharacteristic = null;
      _notificationSubscription?.cancel();
      _notificationSubscription = null;
      _connectionSubscription?.cancel();
      _connectionSubscription = null;
      
      print('[BLE] 调用flutter_reactive_ble库connectToDevice方法...');
      
      // 调用flutter_reactive_ble库的connectToDevice方法
      final connectionStream = _ble.connectToDevice(
        id: deviceId,
        connectionTimeout: Duration(seconds: 10),
      );
      
      // 保存连接流订阅，用于后续断开连接
      _connectionSubscription = connectionStream.listen((connectionState) {
        // 更新当前连接状态
        _currentConnectionState = connectionState.connectionState;
        
        _connectionStateController.add(connectionState);
        
        print('[BLE] 连接状态变化: ${connectionState.connectionState}');
        
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          print('[BLE] ★★★ 连接成功! 设备ID: ${connectionState.deviceId}');
          print('[BLE] 开始发现服务...');
          
          // 连接成功，请求MTU协商
          _ble.requestMtu(deviceId: deviceId, mtu: 512).then((mtu) {
            print('[BLE] ★★★ MTU协商成功! MTU大小: $mtu 字节');
            print('[BLE] 最大可传输数据: ${mtu - 3} 字节 (减去3字节L2CAP开销)');
          }).catchError((error) {
            print('[BLE] ⚠️ MTU协商失败: $error');
            print('[BLE] 使用默认MTU (23字节，实际数据20字节)');
          });
          
          // 连接成功，等待MTU协商完成（flutter_reactive_ble会自动请求MTU为512字节）
          Future.delayed(const Duration(milliseconds: 500), () {
            print('[BLE] MTU协商延迟完成，开始发现服务...');
            
            // 连接成功，自动发现服务和特征
            discoverCharacteristics(deviceId)
              .then((_) {
                print('[BLE] ★★★ 特征发现完成');
                print('[BLE] 写入特征: $_currentWriteUuid');
                print('[BLE] 通知特征: $_currentNotifyUuid');
                
                // 启用通知
                return enableNotification();
              })
              .then((_) {
                print('[BLE] ★★★ 通知订阅成功! 开始监听设备数据...');
                // 保存连接的设备信息
                if (deviceName != null) {
                  _connectedDevice = DiscoveredDevice(
                    id: deviceId,
                    name: deviceName,
                    serviceUuids: [],
                    serviceData: {},
                    manufacturerData: Uint8List(0),
                    rssi: 0,
                  );
                  print('[BLE] ★★★ 已保存设备信息: $deviceName');
                  // 发送连接成功设备事件
                  _connectedDeviceController.add(BleDevice(
                    id: deviceId,
                    name: deviceName,
                    rssi: 0,
                    isConnected: true,
                  ));
                }
                // 连接流程完全成功
                _connectionResultController.add(ConnectionResultData(ConnectionResult.success, null));
                print('[BLE] ==================== 连接流程全部完成 ====================');
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
                
                print('[BLE] ★★★ 连接失败: $errorMessage');
                _connectionResultController.add(ConnectionResultData(result, errorMessage));
              });
          });
        } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
          // 断开连接，清理资源
          print('[BLE] ★★★ 连接断开');
          _connectedDevice = null;
          _discoveredService = null;
          _commandCharacteristic = null;
          _dataCharacteristic = null;
          _notificationSubscription?.cancel();
          _notificationSubscription = null;
        } else if (connectionState.connectionState == DeviceConnectionState.connecting) {
          print('[BLE] 正在连接...');
        } else if (connectionState.connectionState == DeviceConnectionState.disconnecting) {
          print('[BLE] 正在断开连接...');
        }
        
        if (connectionState.failure != null) {
          // 连接过程中发生错误
          final error = connectionState.failure;
          print('[BLE] ★★★ 连接错误: ${error?.message ?? '未知错误'}');
          _connectionResultController.add(ConnectionResultData(
            ConnectionResult.connectionFailed,
            '连接失败: ${error?.message ?? '未知错误'}'
          ));
        }
      });
    } catch (e) {
      print('[BLE] ★★★ 连接初始化失败: $e');
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
      print('[BLE] ==================== 开始断开设备 ====================');
      print('[BLE] 设备ID: $deviceId');
      
      // 先取消连接流订阅
      _connectionSubscription?.cancel();
      _connectionSubscription = null;
      print('[BLE] ★★★ 已取消连接流订阅');
      
      // 调用flutter_reactive_ble库的disconnect方法主动断开连接
      // flutter_reactive_ble 没有提供直接的 disconnectDevice 方法，取消连接流订阅即可触发底层断开
      // 已在上面调用 _connectionSubscription?.cancel(); 完成断开，无需额外调用
      print('[BLE] ★★★ 已调用库的disconnect方法');
      
      // 清理通知订阅
      _notificationSubscription?.cancel();
      _notificationSubscription = null;
      
      // 重置状态
      _connectedDevice = null;
      _discoveredService = null;
      _commandCharacteristic = null;
      _dataCharacteristic = null;
      
      // 发送断开连接设备事件
      _connectedDeviceController.add(BleDevice(
        id: deviceId,
        name: '已断开',
        rssi: 0,
        isConnected: false,
      ));
      
      // 发送断开连接状态更新
      _connectionStateController.add(ConnectionStateUpdate(
        deviceId: deviceId,
        connectionState: DeviceConnectionState.disconnected,
        failure: null,
      ));
      
      print('[BLE] ==================== 断开连接完成 ====================');
    } catch (e) {
      print('[BLE] ★★★ 断开连接失败: $e');
      rethrow;
    }
  }

  /// 主动读取通知特征值
  Future<Uint8List> readNotifyCharacteristic() async {
    if (_commandCharacteristic == null) {
      throw Exception('未找到通知特征，请先连接设备');
    }
    
    try {
      final data = await _ble.readCharacteristic(_commandCharacteristic!);
      return Uint8List.fromList(data);
    } catch (e) {
      print('读取通知特征值失败: $e');
      rethrow;
    }
  }

  /// 读取写入特征值
  Future<Uint8List> readWriteCharacteristic() async {
    if (_dataCharacteristic == null) {
      throw Exception('未找到写入特征，请先连接设备');
    }
    
    try {
      final data = await _ble.readCharacteristic(_dataCharacteristic!);
      return Uint8List.fromList(data);
    } catch (e) {
      print('读取写入特征值失败: $e');
      rethrow;
    }
  }

  /// 写入数据到特征值
  Future<void> writeData(Uint8List value, {bool? withResponse}) async {
    if (_dataCharacteristic == null) {
      throw Exception('未找到写入特征，请先连接设备');
    }
    
    try {
 
      // print('[BLE] 尝试使用writeWithoutResponse写入数据...');
      // print('[BLE] 数据: ${value.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
      
      try {
        await _ble.writeCharacteristicWithoutResponse(
          _dataCharacteristic!,
          value: value,
        );
        // print('[BLE] writeWithoutResponse写入成功');
      } catch (e) {
        // print('[BLE] writeWithoutResponse写入失败: $e');
        // print('[BLE] 尝试使用writeWithResponse...');
        
        // 如果writeWithoutResponse失败，尝试使用writeWithResponse
        await _ble.writeCharacteristicWithResponse(
          _dataCharacteristic!,
          value: value,
        );
        print('[BLE] writeWithResponse写入成功');
      }
    } catch (e) {
      // print('[BLE] writeWithResponse写入失败: $e');
      print('写入数据失败: $e');
      rethrow;
    }
  }

  /// 写入OTA命令到命令控制特征 (ius_cc: 11110003)
  Future<void> writeOtaCommand(Uint8List value, {bool? withResponse}) async {
    // 确保设备已连接且命令特征可用
    ensureConnected();
    
    try {
      print('[BLE] 写入OTA命令到命令控制特征: ${_commandCharacteristic!.characteristicId}');
      print('[BLE] 命令数据: ${value.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
      
      // OTA命令必须使用writeWithResponse确保可靠性和获取响应
      // 忽略withResponse参数，强制使用可靠写入
      await _ble.writeCharacteristicWithResponse(
        _commandCharacteristic!,
        value: value,
      );
      print('[BLE] OTA命令写入成功 (writeWithResponse)');
    } catch (e) {
      print('[BLE] 写入OTA命令失败: $e');
      rethrow;
    }
  }

  /// 写入OTA数据到数据传输特征 (ius_rc: 11110002)
  /// 数据传输使用writeWithoutResponse提高效率
  Future<void> writeOtaData(Uint8List data) async {
    ensureConnected();
    
    if (_dataCharacteristic == null) {
      throw Exception('未找到数据传输特征，请先连接设备');
    }

    try {
      print('[BLE] 写入OTA数据到数据传输特征: ${_dataCharacteristic!.characteristicId}');
      print('[BLE] 数据长度: ${data.length} bytes');
      
      // 数据传输使用writeWithoutResponse提高效率
      await _ble.writeCharacteristicWithoutResponse(
        _dataCharacteristic!,
        value: data,
      );
      print('[BLE] OTA数据写入成功 (writeWithoutResponse)');
    } catch (e) {
      print('[BLE] 写入OTA数据失败: $e');
      rethrow;
    }
  }
  
  /// 发送OTA命令并等待响应（参考Java代码的实现方式）
  /// 使用直接订阅特征通知的方式，确保响应的准确性
  Future<List<int>> sendOtaCommandAndWaitResponse(
    Uint8List command, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // 确保设备已连接且命令特征可用
    ensureConnected();

    final commandId = command[0];
    print('[BLE] 发送OTA命令并等待响应: 命令ID=0x${commandId.toRadixString(16)}');
    
    final Completer<List<int>> completer = Completer<List<int>>();
    
    // 直接订阅命令特征的通知流，确保只接收当前命令的响应
    // 避免使用全局通知流导致的响应混乱问题
    StreamSubscription<List<int>>? subscription;
    
    // 检查是否已经有全局订阅，如果有，先保存它
    final existingSubscription = _notificationSubscription;
    
    try {
        
        // 直接订阅命令特征的通知
        subscription = _ble.subscribeToCharacteristic(_commandCharacteristic!).listen(
          (data) {
            // 确保设备仍处于连接状态
            if (!isConnected) {
              print('[BLE] 设备已断开连接，忽略响应');
              if (!completer.isCompleted) {
                completer.completeError(Exception('设备已断开连接'));
              }
              return;
            }
            
            print('[BLE] 收到OTA响应数据: $data');
            
            // 检查响应是否匹配当前命令
            if (data.isNotEmpty && data[0] == commandId) {
              print('[BLE] 响应匹配命令ID=0x${commandId.toRadixString(16)}');
              if (!completer.isCompleted) {
                completer.complete(data);
              }
            } else if (data.isNotEmpty) {
              print('[BLE] 收到不匹配的响应，命令ID=0x${commandId.toRadixString(16)}，响应ID=0x${data[0].toRadixString(16)}');
              // 对于不匹配的响应，我们不应该完成completer，而是继续等待正确的响应
            } else {
              print('[BLE] 收到空响应，忽略');
            }
          },
          onError: (error) {
            print('[BLE] OTA命令响应监听错误: $error');
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
          onDone: () {
            print('[BLE] OTA命令响应流已关闭');
            if (!completer.isCompleted) {
              completer.completeError(Exception('响应流已关闭'));
            }
          },
        );
        
        // 等待一小段时间确保订阅生效
        await Future.delayed(const Duration(milliseconds: 200));
        
        // 发送命令 - 所有OTA命令都必须使用writeWithResponse确保可靠性
        // 不允许回退到writeWithoutResponse，因为OTA命令需要确保设备确认
        await _ble.writeCharacteristicWithResponse(
          _commandCharacteristic!,
          value: command,
        );
        print('[BLE] OTA命令写入成功 (writeWithResponse)');
        
        // 等待响应或超时
        final response = await completer.future.timeout(timeout);
        print('[BLE] OTA命令响应接收成功');
        
        return response;
      } catch (e) {
        print('[BLE] OTA命令执行失败: $e');
        rethrow;
      } finally {
        // 取消临时订阅
        await subscription?.cancel();
        
        // 如果之前有全局订阅，恢复它
        if (existingSubscription != null) {
          print('[BLE] 恢复全局通知订阅');
          _notificationSubscription = existingSubscription;
        }
      }
  }

  /// 便捷方法：发送命令
  Future<void> sendCommand(int commandId, Map<String, dynamic> data, {bool? withResponse}) async {
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

  /// 获取当前MTU值
  int? get getMtu {
    if (_connectedDevice != null) {
      try {
        // 从flutter_reactive_ble获取MTU值
        // 注意：flutter_reactive_ble库可能不直接提供获取MTU的方法
        // 这里可能需要根据库的API进行调整
        return null; // 暂时返回null，因为flutter_reactive_ble可能不直接支持获取MTU
      } catch (e) {
        print('[BLE] 获取MTU失败: $e');
        return null;
      }
    }
    return null;
  }

  /// 设置MTU值（如果支持）
  Future<void> setMtu(int mtu) async {
    if (_connectedDevice != null) {
      try {
        // flutter_reactive_ble库可能不直接支持设置MTU
        // 在实际实现中，可能需要使用其他方式或库来设置MTU
        print('[BLE] 设置MTU为: $mtu');
        // 注意：flutter_reactive_ble库通常不提供直接的setMtu方法
        // MTU协商通常在连接过程中自动完成
      } catch (e) {
        print('[BLE] 设置MTU失败: $e');
        rethrow;
      }
    }
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
    _connectedDeviceController.close();
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
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