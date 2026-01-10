import 'dart:async';
import 'dart:typed_data';

import '../bluetooth/ble_controller.dart';
import '../bluetooth/modbus_protocol.dart';
import '../models/battery_data.dart';
import '../models/modbus_request.dart';

/// 电池数据管理器（单例模式）
/// 负责与 BMS 设备通信，管理数据读取和写入
class BatteryDataManager {
  static BatteryDataManager? _instance;
  
  factory BatteryDataManager() {
    _instance ??= BatteryDataManager._internal();
    return _instance!;
  }
  
  BatteryDataManager._internal() {
    print('[BatteryDataManager] 创建单例实例');
  }
  
  final BleController _bleController = BleController();
  final ModbusProtocol _protocol = ModbusProtocol();
  
  final StreamController<BatteryData> _batteryDataController = StreamController.broadcast();
  final StreamController<ModbusRequest> _requestStatusController = StreamController.broadcast();
  
  Stream<BatteryData> get batteryDataStream => _batteryDataController.stream;
  Stream<ModbusRequest> get requestStatusStream => _requestStatusController.stream;
  
  BatteryData _currentData = BatteryData.empty();
  BatteryData get currentData => _currentData;
  
  final Map<String, ModbusRequest> _pendingRequests = {};
  Timer? _readTimer;
  Timer? _timeoutCheckTimer;
  Timer? _batteryLevelReadTimer;
  bool _isReading = false;
  
  int _slaveId = 0x16;
  int _cellCount = 16;
  int _temperatureCount = 4;
  int _currentCellIndex = 0;
  List<double> _cellVoltages = [];
  Duration _readInterval = const Duration(seconds: 3);
  Duration _batteryLevelReadInterval = const Duration(milliseconds: 500);
  bool _isAutoReadingEnabled = true;
  
  int _currentIndex = 1; // 默认选中主页
  
  void setSlaveId(int slaveId) {
    _slaveId = slaveId;
  }
  
  void setCellCount(int count) {
    _cellCount = count;
  }
  
  void setTemperatureCount(int count) {
    _temperatureCount = count;
  }
  
  void setReadInterval(Duration interval) {
    _readInterval = interval;
    if (_readTimer != null && _readTimer!.isActive) {
      stopAutoRead();
      startAutoRead();
    }
  }
  
  void setCurrentIndex(int index) {
    _currentIndex = index;
    // 如果切换到我的页，停止自动读取
    if (index == 2) {
      stopAutoRead();
    }
  }
  
  bool get isConnected => _bleController.connectedDevice != null;
  
  void _logConnectionStatus() {
    final connectedDevice = _bleController.connectedDevice;
    print('[BatteryDataManager] 连接状态检查:');
    print('[BatteryDataManager]   connectedDevice: $connectedDevice');
    print('[BatteryDataManager]   isConnected: ${connectedDevice != null}');
    if (connectedDevice != null) {
      print('[BatteryDataManager]   设备ID: ${connectedDevice.id}');
      print('[BatteryDataManager]   设备名称: ${connectedDevice.name}');
    }
  }
  
  void startAutoRead() {
    if (_readTimer != null && _readTimer!.isActive) {
      return;
    }
    //如果导航页是我的页，不启动自动读取
    if (_currentIndex == 2) {
      return;
    }
    
    _isAutoReadingEnabled = true;
    
    _readTimer = Timer.periodic(_readInterval, (_) {
      readAllData();
    });
    
    _timeoutCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkTimeouts();
    });
    
    print('[BatteryDataManager] 自动读取已启动');
  }
  
  void stopAutoRead() {
    _isAutoReadingEnabled = false;
    _readTimer?.cancel();
    _readTimer = null;
    _timeoutCheckTimer?.cancel();
    _timeoutCheckTimer = null;
    print('[BatteryDataManager] 自动读取已停止');
  }
  
  void startBatteryLevelReading() {
    if (_batteryLevelReadTimer != null && _batteryLevelReadTimer!.isActive) {
      print('[BatteryDataManager] 电池电量实时读取已经在运行中');
      return;
    }
    
    _batteryLevelReadTimer = Timer.periodic(_batteryLevelReadInterval, (_) {
      readBatteryLevel();
    });
    
    print('[BatteryDataManager] 电池电量实时读取已启动，查询间隔: ${_batteryLevelReadInterval.inMilliseconds}ms');
  }
  
  void stopBatteryLevelReading() {
    _batteryLevelReadTimer?.cancel();
    _batteryLevelReadTimer = null;
    print('[BatteryDataManager] 电池电量实时读取已停止');
  }
  
  Future<void> readBatteryLevel() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readBatteryLevel(
      id: requestId,
      slaveId: _slaveId,
    );
    
    await _sendRequest(request);
  }
  
  Future<void> readAllData() async {
    if (!isConnected || _isReading || !_isAutoReadingEnabled) {
      return;
    }
    
    _isReading = true;
    
    try {
      await readBatteryLevel();                   // 读取电池电量(SOC/SOH)
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      await readBatteryDc();                  // 读取总容量
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      await readCellVoltages();                   // 读取总电压
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;

      //读取总电流
      await readCellCurrent();                   // 读取总电流
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      //读取充放电状态
      await readChargeDischargeStatus();                   // 读取充放电状态
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      await readTemperatures1();                   // 读取温度1数据
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      await readTemperatures2();                   // 读取温度2数据
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      await readTemperaturesMos();                   // 读取Mos温度数据
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      // 读取循环次数
      await readCycleCount();                   // 读取循环次数
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;

      //读取电池串数
      await readBatteryStringCount();                   // 读取电池串数
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      //读取单体电压
      await readCellAloneVoltages();                   // 读取单体电压
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      //读取异常信息
      await readWarningInfo();                   // 读取警告信息
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      await readProtectionInfo();                   // 读取保护信息
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      await readBatteryStatus();                   // 读取电池状态
      if (!_isAutoReadingEnabled) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isAutoReadingEnabled) return;
      
      // await readMainPageData();                   // 读取主页数据
    } catch (e) {
      print('[BatteryDataManager] 读取数据失败: $e');
    } finally {
      _isReading = false;
    }
  }
  
  Future<void> readMainPageData() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readMainPageData(
      id: requestId,
      slaveId: _slaveId,
    );
    
    await _sendRequest(request);
  }
  
  Future<void> readBatteryDc() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readBatteryDc(id: requestId, slaveId: _slaveId);
    
    await _sendRequest(request);
  }
  
  Future<void> readCellVoltages() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readCellVoltages(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x0004,
      quantity: 2,
    );
    
    await _sendRequest(request);
  }
  Future<void> readCellCurrent() async
  {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readCellCurrent(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x0006,
      quantity: 2,
    );
    
    await _sendRequest(request);
  }
  

  Future<void> readTemperatures1() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readTemperatures1(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x0001,
      quantity: 1,
    );
    
    await _sendRequest(request);
  }
  Future<void> readTemperatures2() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readTemperatures2(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x0002,
      quantity: 1,
    );
    
    await _sendRequest(request);
  }
  Future<void> readTemperaturesMos() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readTemperaturesMos(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x0000,
      quantity: 1,
    );
    
    await _sendRequest(request);
  }
  Future<void> readCycleCount() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readCycleCount(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x001A,
      quantity: 1,
    );
    
    await _sendRequest(request);
  }

  Future<void> readBatteryStringCount() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readBatteryStringCount(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x0018,
      quantity: 1,
    );
    
    await _sendRequest(request);
  }

  Future<void> readCellAloneVoltages() async {
    print('[BatteryDataManager] 开始读取单体电压，电池串数: $_cellCount');
    
    _cellVoltages = [];
    _currentCellIndex = 0;
    
    for (int i = 0; i < _cellCount; i++) {
      final requestId = _generateRequestId();
      final request = ModbusRequest.readCellAloneVoltage(
        id: requestId,
        slaveId: _slaveId,
        cellIndex: i,
      );
      
      await _sendRequest(request);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('[BatteryDataManager] 单体电压读取完成');
  }
  
  Future<void> readWarningInfo() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readWarningInfo(
      id: requestId,
      slaveId: _slaveId,
    );
    
    await _sendRequest(request);
  }

  Future<void> readProtectionInfo() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readProtectionInfo(
      id: requestId,
      slaveId: _slaveId,
    );
    
    await _sendRequest(request);
  }

  Future<void> readBatteryStatus() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readBatteryStatus(
      id: requestId,
      slaveId: _slaveId,
    );
    
    await _sendRequest(request);
  }
  
  Future<bool> writeParameters(int startAddress, List<int> values) async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.writeParameters(
      id: requestId,
      slaveId: _slaveId,
      startAddress: startAddress,
      values: values,
    );
    
    final sent = await _sendRequest(request);
    if (!sent) {
      return false;
    }
    
    // 等待写入响应
    final completer = Completer<bool>();
    StreamSubscription? subscription;
    
    subscription = _requestStatusController.stream.listen((statusRequest) {
      if (statusRequest.id == requestId) {
        subscription?.cancel();
        if (statusRequest.status == ModbusRequestStatus.completed) {
          completer.complete(true);
        } else if (statusRequest.status == ModbusRequestStatus.failed ||
                   statusRequest.status == ModbusRequestStatus.timeout) {
          completer.complete(false);
        }
      }
    });
    
    // 设置超时
    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        completer.complete(false);
      }
    });
    
    return await completer.future;
  }
  
  Future<bool> writeBatterySeriesCount(int count) async {
    print('[BatteryDataManager] 写入电池串数: $count');
    final success = await writeParameters(0x200, [count]);
    if (success) {
      print('[BatteryDataManager] 电池串数写入成功');
    } else {
      print('[BatteryDataManager] 电池串数写入失败');
    }
    return success;
  }

  Future<bool> writeBatteryCapacity(int capacity) async {
    print('[BatteryDataManager] 写入电池物理容量: $capacity mAh');
    final success = await writeParameters(0x402, _int32ToRegisters(capacity));
    if (success) {
      print('[BatteryDataManager] 电池物理容量写入成功');
    } else {
      print('[BatteryDataManager] 电池物理容量写入失败');
    }
    return success;
  }

  List<int> _int32ToRegisters(int value) {
    final byteData = ByteData(4)..setInt32(0, value, Endian.big);
    return [
      byteData.getUint16(0, Endian.big),
      byteData.getUint16(2, Endian.big),
    ];
  }

  List<int> _floatToRegisters(double value) {
    final byteData = ByteData(4)..setFloat32(0, value, Endian.big);
    return [
      byteData.getUint16(0, Endian.big),
      byteData.getUint16(2, Endian.big),
    ];
  }

  double _registersToFloat(List<int> bytes) {
    final byteData = ByteData(4)
      ..setUint16(0, bytes[0], Endian.big)
      ..setUint16(2, bytes[1], Endian.big);
    return byteData.getFloat32(0, Endian.big);
  }

  Future<bool> writeOverchargeProtectVoltage(int voltage) async {
    print('[BatteryDataManager] 写入过充保护电压: $voltage mV');
    final success = await writeParameters(0x210, [voltage]);
    if (success) {
      print('[BatteryDataManager] 过充保护电压写入成功');
    } else {
      print('[BatteryDataManager] 过充保护电压写入失败');
    }
    return success;
  }

  Future<bool> writeOverchargeRecoverVoltage(int voltage) async {
    print('[BatteryDataManager] 写入过充恢复电压: $voltage mV');
    final success = await writeParameters(0x211, [voltage]);
    if (success) {
      print('[BatteryDataManager] 过充恢复电压写入成功');
    } else {
      print('[BatteryDataManager] 过充恢复电压写入失败');
    }
    return success;
  }

  Future<bool> writeOverdischargeProtectVoltage(int voltage) async {
    print('[BatteryDataManager] 写入过放保护电压: $voltage mV');
    final success = await writeParameters(0x217, [voltage]);
    if (success) {
      print('[BatteryDataManager] 过放保护电压写入成功');
    } else {
      print('[BatteryDataManager] 过放保护电压写入失败');
    }
    return success;
  }

  Future<bool> writeOverdischargeRecoverVoltage(int voltage) async {
    print('[BatteryDataManager] 写入过放恢复电压: $voltage mV');
    final success = await writeParameters(0x218, [voltage]);
    if (success) {
      print('[BatteryDataManager] 过放恢复电压写入成功');
    } else {
      print('[BatteryDataManager] 过放恢复电压写入失败');
    }
    return success;
  }

  Future<bool> writeChargeHighTempProtect(int temperature) async {
    print('[BatteryDataManager] 写入充电高温保护: $temperature °C');
    final success = await writeParameters(0x222, [temperature]);
    if (success) {
      print('[BatteryDataManager] 充电高温保护写入成功');
    } else {
      print('[BatteryDataManager] 充电高温保护写入失败');
    }
    return success;
  }

  Future<bool> writeChargeHighTempRecover(int temperature) async {
    print('[BatteryDataManager] 写入充电高温恢复: $temperature °C');
    final success = await writeParameters(0x223, [temperature]);
    if (success) {
      print('[BatteryDataManager] 充电高温恢复写入成功');
    } else {
      print('[BatteryDataManager] 充电高温恢复写入失败');
    }
    return success;
  }

  Future<bool> writeChargeLowTempProtect(int temperature) async {
    print('[BatteryDataManager] 写入充电低温保护: $temperature °C');
    final success = await writeParameters(0x224, [temperature]);
    if (success) {
      print('[BatteryDataManager] 充电低温保护写入成功');
    } else {
      print('[BatteryDataManager] 充电低温保护写入失败');
    }
    return success;
  }

  Future<bool> writeChargeLowTempRecover(int temperature) async {
    print('[BatteryDataManager] 写入充电低温恢复: $temperature °C');
    final success = await writeParameters(0x225, [temperature]);
    if (success) {
      print('[BatteryDataManager] 充电低温恢复写入成功');
    } else {
      print('[BatteryDataManager] 充电低温恢复写入失败');
    }
    return success;
  }

  Future<bool> writeDischargeHighTempProtect(int temperature) async {
    print('[BatteryDataManager] 写入放电高温保护: $temperature °C');
    final success = await writeParameters(0x226, [temperature]);
    if (success) {
      print('[BatteryDataManager] 放电高温保护写入成功');
    } else {
      print('[BatteryDataManager] 放电高温保护写入失败');
    }
    return success;
  }

  Future<bool> writeDischargeHighTempRecover(int temperature) async {
    print('[BatteryDataManager] 写入放电高温恢复: $temperature °C');
    final success = await writeParameters(0x227, [temperature]);
    if (success) {
      print('[BatteryDataManager] 放电高温恢复写入成功');
    } else {
      print('[BatteryDataManager] 放电高温恢复写入失败');
    }
    return success;
  }

  Future<bool> writeDischargeLowTempProtect(int temperature) async {
    print('[BatteryDataManager] 写入放电低温保护: $temperature °C');
    final success = await writeParameters(0x228, [temperature]);
    if (success) {
      print('[BatteryDataManager] 放电低温保护写入成功');
    } else {
      print('[BatteryDataManager] 放电低温保护写入失败');
    }
    return success;
  }

  Future<bool> writeDischargeLowTempRecover(int temperature) async {
    print('[BatteryDataManager] 写入放电低温恢复: $temperature °C');
    final success = await writeParameters(0x229, [temperature]);
    if (success) {
      print('[BatteryDataManager] 放电低温恢复写入成功');
    } else {
      print('[BatteryDataManager] 放电低温恢复写入失败');
    }
    return success;
  }

  Future<bool> writeChargeOvercurrent1Protect(int current) async {
    print('[BatteryDataManager] 写入充电过流1保护电流: $current A');
    final success = await writeParameters(0x220, [current]);
    if (success) {
      print('[BatteryDataManager] 充电过流1保护电流写入成功');
    } else {
      print('[BatteryDataManager] 充电过流1保护电流写入失败');
    }
    return success;
  }

  Future<bool> writeChargeOvercurrent1Delay(int delay) async {
    print('[BatteryDataManager] 写入充电过流1延时: $delay ms');
    final success = await writeParameters(0x221, [delay]);
    if (success) {
      print('[BatteryDataManager] 充电过流1延时写入成功');
    } else {
      print('[BatteryDataManager] 充电过流1延时写入失败');
    }
    return success;
  }

  Future<bool> writeDischargeOvercurrent1Protect(int current) async {
    print('[BatteryDataManager] 写入放电过流1保护电流: $current A');
    final success = await writeParameters(0x21A, [current]);
    if (success) {
      print('[BatteryDataManager] 放电过流1保护电流写入成功');
    } else {
      print('[BatteryDataManager] 放电过流1保护电流写入失败');
    }
    return success;
  }

  Future<bool> writeDischargeOvercurrent1Delay(int delay) async {
    print('[BatteryDataManager] 写入放电过流1延时: $delay ms');
    final success = await writeParameters(0x21B, [delay]);
    if (success) {
      print('[BatteryDataManager] 放电过流1延时写入成功');
    } else {
      print('[BatteryDataManager] 放电过流1延时写入失败');
    }
    return success;
  }

  Future<bool> writeDischargeOvercurrent2Protect(int current) async {
    print('[BatteryDataManager] 写入放电过流2保护电流: $current A');
    final success = await writeParameters(0x21C, [current]);
    if (success) {
      print('[BatteryDataManager] 放电过流2保护电流写入成功');
    } else {
      print('[BatteryDataManager] 放电过流2保护电流写入失败');
    }
    return success;
  }

  Future<bool> writeDischargeOvercurrent2Delay(int delay) async {
    print('[BatteryDataManager] 写入放电过流2延时: $delay ms');
    final success = await writeParameters(0x21D, [delay]);
    if (success) {
      print('[BatteryDataManager] 放电过流2延时写入成功');
    } else {
      print('[BatteryDataManager] 放电过流2延时写入失败');
    }
    return success;
  }

  Future<bool> writeShortCircuitProtect(int current) async {
    print('[BatteryDataManager] 写入短路保护电流: $current A');
    final success = await writeParameters(0x21E, [current]);
    if (success) {
      print('[BatteryDataManager] 短路保护电流写入成功');
    } else {
      print('[BatteryDataManager] 短路保护电流写入失败');
    }
    return success;
  }

  Future<bool> writeShortCircuitDelay(int delay) async {
    print('[BatteryDataManager] 写入短路保护延时: $delay us');
    final success = await writeParameters(0x21F, [delay]);
    if (success) {
      print('[BatteryDataManager] 短路保护延时写入成功');
    } else {
      print('[BatteryDataManager] 短路保护延时写入失败');
    }
    return success;
  }

  Future<bool> writeSamplingResistance(double resistance) async {
    print('[BatteryDataManager] 写入采样电阻值: $resistance mΩ');
    final success = await writeParameters(0x20E, _floatToRegisters(resistance));
    if (success) {
      print('[BatteryDataManager] 采样电阻值写入成功');
    } else {
      print('[BatteryDataManager] 采样电阻值写入失败');
    }
    return success;
  }

  Future<int?> readChargeOvercurrent1Protect() async {
    print('[BatteryDataManager] [Current] 读取充电过流1保护电流: 地址 0x220');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x220,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Current] 充电过流1保护电流: $value A');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Current] 读取充电过流1保护电流超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readChargeOvercurrent1Delay() async {
    print('[BatteryDataManager] [Current] 读取充电过流1延时: 地址 0x221');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x221,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Current] 充电过流1延时: $value ms');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Current] 读取充电过流1延时超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readDischargeOvercurrent1Protect() async {
    print('[BatteryDataManager] [Current] 读取放电过流1保护电流: 地址 0x21A');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x21A,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Current] 放电过流1保护电流: $value A');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Current] 读取放电过流1保护电流超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readDischargeOvercurrent1Delay() async {
    print('[BatteryDataManager] [Current] 读取放电过流1延时: 地址 0x21B');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x21B,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Current] 放电过流1延时: $value ms');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Current] 读取放电过流1延时超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readDischargeOvercurrent2Protect() async {
    print('[BatteryDataManager] [Current] 读取放电过流2保护电流: 地址 0x21C');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x21C,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Current] 放电过流2保护电流: $value A');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Current] 读取放电过流2保护电流超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readDischargeOvercurrent2Delay() async {
    print('[BatteryDataManager] [Current] 读取放电过流2延时: 地址 0x21D');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x21D,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Current] 放电过流2延时: $value ms');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Current] 读取放电过流2延时超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readShortCircuitProtect() async {
    print('[BatteryDataManager] [Current] 读取短路保护电流: 地址 0x21E');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x21E,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Current] 短路保护电流: $value A');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Current] 读取短路保护电流超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readShortCircuitDelay() async {
    print('[BatteryDataManager] [Current] 读取短路保护延时: 地址 0x21F');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x21F,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Current] 短路保护延时: $value us');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Current] 读取短路保护延时超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<double?> readSamplingResistance() async {
    print('[BatteryDataManager] [Current] 读取采样电阻值: 地址 0x20E');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x20E,
      quantity: 2,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<double?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 4) {
            final value = _registersToFloat(bytes);
            print('[BatteryDataManager] [Current] 采样电阻值: $value mΩ');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Current] 读取采样电阻值超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readBalanceStartVoltage() async {
    print('[BatteryDataManager] [Balance] 读取均衡启动电压: 地址 0x214');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x214,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Balance] 均衡启动电压: $value mV');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Balance] 读取均衡启动电压超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readBalanceStartThreshold() async {
    print('[BatteryDataManager] [Balance] 读取均衡启动阈值: 地址 0x215');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x215,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Balance] 均衡启动阈值: $value mV');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Balance] 读取均衡启动阈值超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readBalanceDelay() async {
    print('[BatteryDataManager] [Balance] 读取均衡延时: 地址 0x216');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x216,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Balance] 均衡延时: $value ms');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Balance] 读取均衡延时超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<bool> writeBalanceStartVoltage(int voltage) async {
    print('[BatteryDataManager] 写入均衡启动电压: $voltage mV');
    final success = await writeParameters(0x214, [voltage]);
    if (success) {
      print('[BatteryDataManager] 均衡启动电压写入成功');
    } else {
      print('[BatteryDataManager] 均衡启动电压写入失败');
    }
    return success;
  }

  Future<bool> writeBalanceStartThreshold(int threshold) async {
    print('[BatteryDataManager] 写入均衡启动阈值: $threshold mV');
    final success = await writeParameters(0x215, [threshold]);
    if (success) {
      print('[BatteryDataManager] 均衡启动阈值写入成功');
    } else {
      print('[BatteryDataManager] 均衡启动阈值写入失败');
    }
    return success;
  }

  Future<bool> writeBalanceDelay(int delay) async {
    print('[BatteryDataManager] 写入均衡延时: $delay ms');
    final success = await writeParameters(0x216, [delay]);
    if (success) {
      print('[BatteryDataManager] 均衡延时写入成功');
    } else {
      print('[BatteryDataManager] 均衡延时写入失败');
    }
    return success;
  }

  Future<int?> readSleepDelay() async {
    print('[BatteryDataManager] [System] 读取休眠延时: 地址 0x206');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x206,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [System] 休眠延时: $value s');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [System] 读取休眠延时超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readShutdownDelay() async {
    print('[BatteryDataManager] [System] 读取关机延时: 地址 0x207');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x207,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [System] 关机延时: $value s');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [System] 读取关机延时超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readRatedChargeVoltage() async {
    print('[BatteryDataManager] [System] 读取额定充电电压: 地址 0x208');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x208,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            final convertedValue = value ~/ 10;
            print('[BatteryDataManager] [System] 额定充电电压: 原始值$value (10mV), 转换后$convertedValue (0.1V)');
            completer.complete(convertedValue);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [System] 读取额定充电电压超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readRatedChargeCurrent() async {
    print('[BatteryDataManager] [System] 读取额定充电电流: 地址 0x209');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x209,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            final signedValue = value > 32767 ? value - 65536 : value;
            final convertedValue = signedValue ~/ 10;
            print('[BatteryDataManager] [System] 额定充电电流: 原始值$signedValue (10mA), 转换后$convertedValue (0.1A)');
            completer.complete(convertedValue);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [System] 读取额定充电电流超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readFullChargeVoltage() async {
    print('[BatteryDataManager] [System] 读取满充电压: 地址 0x20A');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x20A,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [System] 满充电压: $value mV');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [System] 读取满充电压超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readFullChargeCurrent() async {
    print('[BatteryDataManager] [System] 读取满充电流: 地址 0x20B');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x20B,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            final signedValue = value > 32767 ? value - 65536 : value;
            print('[BatteryDataManager] [System] 满充电流: $signedValue mA');
            completer.complete(signedValue);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [System] 读取满充电流超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readFullChargeDelay() async {
    print('[BatteryDataManager] [System] 读取满充延时: 地址 0x20C');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x20C,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [System] 满充延时: $value s');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [System] 读取满充延时超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readZeroCurrentThreshold() async {
    print('[BatteryDataManager] [System] 读取零电流显示阈值: 地址 0x20D');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x20D,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            final signedValue = value > 32767 ? value - 65536 : value;
            print('[BatteryDataManager] [System] 零电流显示阈值: $signedValue mA');
            completer.complete(signedValue);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [System] 读取零电流显示阈值超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<bool> writeRatedChargeVoltage(int voltage) async {
    final convertedVoltage = voltage * 10;
    print('[BatteryDataManager] 写入额定充电电压: 用户输入$voltage (0.1V单位), 转换后$convertedVoltage (10mV单位)');
    final success = await writeParameters(0x208, [convertedVoltage]);
    if (success) {
      print('[BatteryDataManager] 额定充电电压写入成功');
    } else {
      print('[BatteryDataManager] 额定充电电压写入失败');
    }
    return success;
  }

  Future<bool> writeRatedChargeCurrent(int current) async {
    final convertedCurrent = current * 10;
    print('[BatteryDataManager] 写入额定充电电流: 用户输入$current (0.1A单位), 转换后$convertedCurrent (10mA单位)');
    final success = await writeParameters(0x209, [convertedCurrent]);
    if (success) {
      print('[BatteryDataManager] 额定充电电流写入成功');
    } else {
      print('[BatteryDataManager] 额定充电电流写入失败');
    }
    return success;
  }

  Future<bool> writeSleepDelay(int delay) async {
    print('[BatteryDataManager] 写入休眠延时: $delay s');
    final success = await writeParameters(0x206, [delay]);
    if (success) {
      print('[BatteryDataManager] 休眠延时写入成功');
    } else {
      print('[BatteryDataManager] 休眠延时写入失败');
    }
    return success;
  }

  Future<bool> writeShutdownDelay(int delay) async {
    print('[BatteryDataManager] 写入关机延时: $delay s');
    final success = await writeParameters(0x207, [delay]);
    if (success) {
      print('[BatteryDataManager] 关机延时写入成功');
    } else {
      print('[BatteryDataManager] 关机延时写入失败');
    }
    return success;
  }

  Future<bool> writeFullChargeVoltage(int voltage) async {
    print('[BatteryDataManager] 写入满充电压: $voltage mV');
    final success = await writeParameters(0x20A, [voltage]);
    if (success) {
      print('[BatteryDataManager] 满充电压写入成功');
    } else {
      print('[BatteryDataManager] 满充电压写入失败');
    }
    return success;
  }

  Future<bool> writeFullChargeCurrent(int current) async {
    print('[BatteryDataManager] 写入满充电流: $current mA');
    final success = await writeParameters(0x20B, [current]);
    if (success) {
      print('[BatteryDataManager] 满充电流写入成功');
    } else {
      print('[BatteryDataManager] 满充电流写入失败');
    }
    return success;
  }

  Future<bool> writeFullChargeDelay(int delay) async {
    print('[BatteryDataManager] 写入满充延时: $delay s');
    final success = await writeParameters(0x20C, [delay]);
    if (success) {
      print('[BatteryDataManager] 满充延时写入成功');
    } else {
      print('[BatteryDataManager] 满充延时写入失败');
    }
    return success;
  }

  Future<bool> writeZeroCurrentThreshold(int threshold) async {
    print('[BatteryDataManager] 写入零电流显示阈值: $threshold mA');
    final success = await writeParameters(0x20D, [threshold]);
    if (success) {
      print('[BatteryDataManager] 零电流显示阈值写入成功');
    } else {
      print('[BatteryDataManager] 零电流显示阈值写入失败');
    }
    return success;
  }

  Future<void> readChargeDischargeStatus() async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readChargeDischargeStatus(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x000C,
      quantity: 2,
    );
    
    await _sendRequest(request);
  }

  Future<int?> readSetBatterySeriesCount() async {
    print('[BatteryDataManager] [Set] 读取电池串数: 地址 0x200');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x200,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          print('[BatteryDataManager] [Set] 电池串数响应数据: ${bytes?.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Set] 电池串数解析值: $value');
            completer.complete(value);
          } else {
            print('[BatteryDataManager] [Set] 电池串数响应数据不足，期望>=2字节，实际${bytes?.length}字节');
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Set] 读取电池串数超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readSetBatteryCapacity() async {
    print('[BatteryDataManager] [Set] 读取电池容量: 地址 0x402 (2个寄存器)');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x402,
      quantity: 2,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 4) {
            final value = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Set] 读取电池容量超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readOverchargeProtectVoltage() async {
    print('[BatteryDataManager] [Voltage] 读取过充保护电压: 地址 0x210');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x210,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Voltage] 过充保护电压: $value mV');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Voltage] 读取过充保护电压超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readOverchargeRecoverVoltage() async {
    print('[BatteryDataManager] [Voltage] 读取过充恢复电压: 地址 0x211');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x211,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Voltage] 过充恢复电压: $value mV');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Voltage] 读取过充恢复电压超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readOverdischargeProtectVoltage() async {
    print('[BatteryDataManager] [Voltage] 读取过放保护电压: 地址 0x217');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x217,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Voltage] 过放保护电压: $value mV');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Voltage] 读取过放保护电压超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readOverdischargeRecoverVoltage() async {
    print('[BatteryDataManager] [Voltage] 读取过放恢复电压: 地址 0x218');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x218,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Voltage] 过放恢复电压: $value mV');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Voltage] 读取过放恢复电压超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readChargeHighTempProtect() async {
    print('[BatteryDataManager] [Temp] 读取充电高温保护: 地址 0x222');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x222,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final rawValue = (bytes[0] << 8) | bytes[1];
            final value = rawValue > 32767 ? rawValue - 65536 : rawValue;
            print('[BatteryDataManager] [Temp] 充电高温保护: $value °C');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Temp] 读取充电高温保护超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readChargeHighTempRecover() async {
    print('[BatteryDataManager] [Temp] 读取充电高温恢复: 地址 0x223');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x223,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final rawValue = (bytes[0] << 8) | bytes[1];
            final value = rawValue > 32767 ? rawValue - 65536 : rawValue;
            print('[BatteryDataManager] [Temp] 充电高温恢复: $value °C');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Temp] 读取充电高温恢复超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readChargeLowTempProtect() async {
    print('[BatteryDataManager] [Temp] 读取充电低温保护: 地址 0x224');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x224,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final rawValue = (bytes[0] << 8) | bytes[1];
            final value = rawValue > 32767 ? rawValue - 65536 : rawValue;
            print('[BatteryDataManager] [Temp] 充电低温保护: $value °C');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Temp] 读取充电低温保护超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readChargeLowTempRecover() async {
    print('[BatteryDataManager] [Temp] 读取充电低温恢复: 地址 0x225');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x225,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final rawValue = (bytes[0] << 8) | bytes[1];
            final value = rawValue > 32767 ? rawValue - 65536 : rawValue;
            print('[BatteryDataManager] [Temp] 充电低温恢复: $value °C');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Temp] 读取充电低温恢复超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readDischargeHighTempProtect() async {
    print('[BatteryDataManager] [Temp] 读取放电高温保护: 地址 0x226');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x226,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final rawValue = (bytes[0] << 8) | bytes[1];
            final value = rawValue > 32767 ? rawValue - 65536 : rawValue;
            print('[BatteryDataManager] [Temp] 放电高温保护: $value °C');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Temp] 读取放电高温保护超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readDischargeHighTempRecover() async {
    print('[BatteryDataManager] [Temp] 读取放电高温恢复: 地址 0x227');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x227,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final rawValue = (bytes[0] << 8) | bytes[1];
            final value = rawValue > 32767 ? rawValue - 65536 : rawValue;
            print('[BatteryDataManager] [Temp] 放电高温恢复: $value °C');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Temp] 读取放电高温恢复超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readDischargeLowTempProtect() async {
    print('[BatteryDataManager] [Temp] 读取放电低温保护: 地址 0x228');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x228,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final rawValue = (bytes[0] << 8) | bytes[1];
            final value = rawValue > 32767 ? rawValue - 65536 : rawValue;
            print('[BatteryDataManager] [Temp] 放电低温保护: $value °C');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Temp] 读取放电低温保护超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<int?> readDischargeLowTempRecover() async {
    print('[BatteryDataManager] [Temp] 读取放电低温恢复: 地址 0x229');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x229,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final rawValue = (bytes[0] << 8) | bytes[1];
            final value = rawValue > 32767 ? rawValue - 65536 : rawValue;
            print('[BatteryDataManager] [Temp] 放电低温恢复: $value °C');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Temp] 读取放电低温恢复超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<bool> _sendRequest(ModbusRequest request) async {
    if (!isConnected) {
      print('[BatteryDataManager] 设备未连接，无法发送请求');
      _updateRequestStatus(request.copyWith(
        status: ModbusRequestStatus.failed,
        errorMessage: '设备未连接',
        completedAt: DateTime.now(),
      ));
      return false;
    }
    
    Uint8List command;
    
    if (request.isRead) {
      command = _protocol.buildReadCommand(
        request.slaveId,
        request.startAddress,
        request.quantity,
      );
    } else if (request.isWrite && request.writeValues != null) {
      command = _protocol.buildWriteCommand(
        request.slaveId,
        request.startAddress,
        request.writeValues!,
      );
    } else {
      print('[BatteryDataManager] 无效的请求类型');
      return false;
    }
    
    final updatedRequest = request.copyWith(
      command: command,
      status: ModbusRequestStatus.sent,
      sentAt: DateTime.now(),
    );
    
    _pendingRequests[request.id] = updatedRequest;
    _requestStatusController.add(updatedRequest);
    
    try {
      await _bleController.writeData(command);
      print('[BatteryDataManager] 发送命令: ${command.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
      return true;
    } catch (e) {
      print('[BatteryDataManager] 发送命令失败: $e');
      _updateRequestStatus(updatedRequest.copyWith(
        status: ModbusRequestStatus.failed,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      ));
      _pendingRequests.remove(request.id);
      return false;
    }
  }
  
  void _updateRequestStatus(ModbusRequest request) {
    _requestStatusController.add(request);
  }
  
  void _checkTimeouts() {
    final now = DateTime.now();
    final timeoutRequests = <String>[];
    
    for (final entry in _pendingRequests.entries) {
      final request = entry.value;
      if (request.sentAt != null && now.difference(request.sentAt!) > request.timeout) {
        timeoutRequests.add(entry.key);
        
        if (request.canRetry) {
          final retryRequest = request.copyWith(
            retryCount: request.retryCount + 1,
            status: ModbusRequestStatus.pending,
            sentAt: null,
          );
          _pendingRequests[entry.key] = retryRequest;
          _sendRequest(retryRequest);
          print('[BatteryDataManager] 请求超时，正在重试 (${retryRequest.retryCount}/${retryRequest.maxRetries})');
        } else {
          _updateRequestStatus(request.copyWith(
            status: ModbusRequestStatus.timeout,
            errorMessage: '请求超时',
            completedAt: DateTime.now(),
          ));
          print('[BatteryDataManager] 请求超时，已达到最大重试次数');
        }
      }
    }
    
    for (final id in timeoutRequests) {
      if (!_pendingRequests.containsKey(id)) {
        _pendingRequests.remove(id);
      }
    }
  }
  
  void handleResponse(Uint8List data) {
    print('[BatteryDataManager] 收到响应: ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    
    if (data.length < 3) {
      print('[BatteryDataManager] 响应数据长度不足');
      return;
    }
    
    final slaveId = data[0] & 0xFF;
    final functionCode = data[1] & 0xFF;
    
    if (slaveId != _slaveId) {
      print('[BatteryDataManager] 从站地址不匹配');
      return;
    }
    
    if (functionCode == ModbusProtocol.FUNCTION_READ_HOLDING) {
      final result = _protocol.parseReadResponse(data);
      
      if (result['success'] == true) {
        final bytes = result['bytes'] as List<int>;
        final startAddress = result['startAddress'] as int;
        
        // 根据待处理的请求类型来处理响应
        _processReadResponseByRequestType(bytes, startAddress);
      } else {
        print('[BatteryDataManager] 解析响应失败: ${result['error']}');
      }
    } else if (functionCode == ModbusProtocol.FUNCTION_WRITE_MULTIPLE) {
      final result = _protocol.parseWriteResponse(data);
      
      if (result['success'] == true) {
        print('[BatteryDataManager] 写入成功');
        // 找到对应的写入请求并更新状态
        for (final entry in _pendingRequests.entries) {
          final request = entry.value;
          if (request.isWrite) {
            _updateRequestStatus(request.copyWith(
              status: ModbusRequestStatus.completed,
              completedAt: DateTime.now(),
            ));
            _pendingRequests.remove(entry.key);
            break;
          }
        }
      } else {
        print('[BatteryDataManager] 写入失败: ${result['error']}');
        // 找到对应的写入请求并更新状态为失败
        for (final entry in _pendingRequests.entries) {
          final request = entry.value;
          if (request.isWrite) {
            _updateRequestStatus(request.copyWith(
              status: ModbusRequestStatus.failed,
              errorMessage: result['error'],
              completedAt: DateTime.now(),
            ));
            _pendingRequests.remove(entry.key);
            break;
          }
        }
      }
    }
  }
  
  void _processReadResponseByRequestType(List<int> bytes, int startAddress) {
    if (bytes.isEmpty) {
      return;
    }
    
    // 找到最早的待处理请求
    ModbusRequest? matchedRequest;
    String? matchedRequestId;
    
    for (final entry in _pendingRequests.entries) {
      final request = entry.value;
      if (request.status == ModbusRequestStatus.sent) {
        matchedRequest = request;
        matchedRequestId = entry.key;
        break;
      }
    }
    
    if (matchedRequest == null) {
      print('[BatteryDataManager] 没有找到匹配的待处理请求');
      return;
    }
    
    print('[BatteryDataManager] 匹配到请求: ${matchedRequest.type}, 起始地址: 0x${matchedRequest.startAddress.toRadixString(16).padLeft(4, '0')}, 返回${bytes.length}字节数据');
    
    // 根据请求的起始地址和类型来处理响应
    switch (matchedRequest.type) {
      case ModbusRequestType.readMainPageData:
        print('[BatteryDataManager] 处理主页数据响应 (${bytes.length}字节)');
        _processMainPageDataResponse(bytes);
        break;
        
      case ModbusRequestType.readBatteryLevel:
        print('[BatteryDataManager] 处理电池电量响应 (${bytes.length}字节)');
        _processBatteryLevelResponse(bytes);
        break;
        
      case ModbusRequestType.readBatteryDc:
        print('[BatteryDataManager] 处理电池总容量响应 (${bytes.length}字节)');
        _processBatteryDcResponse(bytes);
        break;
        
      case ModbusRequestType.readCellVoltages:
        print('[BatteryDataManager] 处理总电压响应 (${bytes.length}字节)');
        _processCellVoltagesResponse(bytes);
        break;
        
      case ModbusRequestType.readCellCurrent:
        print('[BatteryDataManager] 处理总电流响应 (${bytes.length}字节)');
        _processCellCurrentResponse(bytes);
        break;
        
      case ModbusRequestType.readChargeDischargeStatus:
        print('[BatteryDataManager] 处理充放电状态响应 (${bytes.length}字节)');
        _processChargeDischargeStatusResponse(bytes);
        break;
        
      case ModbusRequestType.readTemperatures1:
        print('[BatteryDataManager] 处理温度1数据响应 (${bytes.length}字节)');
        _processTemperatures1Response(bytes);
        break;
        
      case ModbusRequestType.readTemperatures2:
        print('[BatteryDataManager] 处理温度2数据响应 (${bytes.length}字节)');
        _processTemperatures2Response(bytes);
        break;
        
      case ModbusRequestType.readTemperaturesMos:
        print('[BatteryDataManager] 处理Mos温度数据响应 (${bytes.length}字节)');
        _processTemperaturesMosResponse(bytes);
        break;
        
      case ModbusRequestType.readCycleCount:
        print('[BatteryDataManager] 处理循环次数响应 (${bytes.length}字节)');
        _processCycleCountResponse(bytes);
        break;
        
      case ModbusRequestType.readBatteryStringCount:
        print('[BatteryDataManager] 处理电池串数响应 (${bytes.length}字节)');
        _processBatteryStringCountResponse(bytes);
        break;
        
      case ModbusRequestType.readCellAloneVoltage:
        print('[BatteryDataManager] 处理单个电池电压响应 (${bytes.length}字节)');
        _processCellAloneVoltageResponse(bytes, matchedRequest.startAddress);
        break;
        
      case ModbusRequestType.readQuickSettings:
        print('[BatteryDataManager] 处理快速设置参数响应 (${bytes.length}字节)');
        // 快速设置参数不需要更新 _currentData，只需要确保请求状态被正确更新
        break;
        
      case ModbusRequestType.readWarningInfo:
        print('[BatteryDataManager] 处理警告信息响应 (${bytes.length}字节)');
        _processWarningInfoResponse(bytes);
        break;
        
      case ModbusRequestType.readProtectionInfo:
        print('[BatteryDataManager] 处理保护信息响应 (${bytes.length}字节)');
        _processProtectionInfoResponse(bytes);
        break;
        
      case ModbusRequestType.readBatteryStatus:
        print('[BatteryDataManager] 处理电池状态响应 (${bytes.length}字节)');
        _processBatteryStatusResponse(bytes);
        break;
        
      default:
        print('[BatteryDataManager] 未知的请求类型: ${matchedRequest.type}');
        break;
    }
    
    // 从待处理列表中移除该请求
    _pendingRequests.remove(matchedRequestId);
    
    // 更新请求状态，包含响应数据
    _updateRequestStatus(matchedRequest!.copyWith(
      status: ModbusRequestStatus.completed,
      response: Uint8List.fromList(bytes),
      completedAt: DateTime.now(),
    ));
  }
  
  void _processBatteryLevelResponse(List<int> bytes) {
    if (bytes.length >= 2) {
      final soh = bytes[0];
      final soc = bytes[1];
      
      print('[BatteryDataManager] 电池电量解析: SOH=$soh%, SOC=$soc%');
      
      _currentData = _currentData.copyWith(
        soc: soc,
        soh: soh,
        timestamp: DateTime.now(),
      );
      _batteryDataController.add(_currentData);
      print('[BatteryDataManager] 电池电量已更新');
    } else {
      print('[BatteryDataManager] 电池电量响应数据不足，期望2字节，实际${bytes.length}字节');
    }
  }
  
  void _processBatteryDcResponse(List<int> bytes) { 
    final capacityRaw = ((bytes[0] & 0xFF) << 8) | (bytes[1] & 0xFF);

    print('[BatteryDataManager] 电池总容量解析: $capacityRaw');
    _currentData = _currentData.copyWith(
      capacity: capacityRaw / 100.0,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 电池总容量状态已更新');
  }
  
  void _processCellVoltagesResponse(List<int> bytes) {
    print('[BatteryDataManager] 总电压解析: ${bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    final voltageRaw = (bytes[0] << 24) |  // 00
                     (bytes[1] << 16) |  // 01
                     (bytes[2] << 8)  |  // 37
                     bytes[3];          // 20
    final voltage = voltageRaw / 1000.0;
    _currentData = _currentData.copyWith(
      voltage: voltage,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 总电压已更新: ${voltage.toStringAsFixed(2)}V');
  }
  
  void _processCellCurrentResponse(List<int> bytes) {
    print('[BatteryDataManager] 总电流解析: ${bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    final currentRaw =   (bytes[0] << 24) |   
                     (bytes[1] << 16) |   
                     (bytes[2] << 8)  |   
                     bytes[3];          
    final current = currentRaw / 1000.0;
    _currentData = _currentData.copyWith(
      current: current,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 总电流已更新: ${current.toStringAsFixed(2)}A');
  }
  
  void _processChargeDischargeStatusResponse(List<int> bytes) {
    // 5 6 7 8
    print('[BatteryDataManager] 充放电状态解析: ${bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    final chargeStatus = bytes[1] & 0x01;
    final dischargeStatus = bytes[1] & 0x02;
    _currentData = _currentData.copyWith(
      chargeStatus: chargeStatus,
      dischargeStatus: dischargeStatus,
      chargeMosOn: chargeStatus != 0,
      dischargeMosOn: dischargeStatus != 0,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 充放电状态已更新: 充电=$chargeStatus, 放电=$dischargeStatus, 充电MOS=${chargeStatus != 0}, 放电MOS=${dischargeStatus != 0}');
  }
  
  void _processTemperatures1Response(List<int> bytes) {
    final temp = (bytes[0] << 8) | bytes[1];
    
    final temperatures1 =  temp / 10.0 - 273.15;
 
    _currentData = _currentData.copyWith(
      batteryTemperature1: temperatures1,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 温度1数据已更新: $temperatures1°C');
  }
  
  void _processTemperatures2Response(List<int> bytes) {
    final temp = (bytes[0] << 8) | bytes[1];
    
    final temperatures2 =  temp / 10.0 - 273.15;
 
    _currentData = _currentData.copyWith(
      batteryTemperature2: temperatures2,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 温度2数据已更新: $temperatures2°C');
  }
  
  void _processTemperaturesMosResponse(List<int> bytes) {
    final temp = (bytes[0] << 8) | bytes[1];
    
    final temperatureMos = temp / 10.0 - 273.15;
    _currentData = _currentData.copyWith(
      batteryTemperatureMos: temperatureMos,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] Mos温度数据已更新: $temperatureMos°C');
  }
  
  void _processCycleCountResponse(List<int> bytes) {
    final cycleCount = (bytes[0] << 8) | bytes[1];
    _currentData = _currentData.copyWith(
      cycleCount: cycleCount,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 循环次数已更新: $cycleCount');
  }
  
  void _processBatteryStringCountResponse(List<int> bytes) {
    if (bytes.length < 2) {
      print('[BatteryDataManager] 电池串数响应数据长度不足: ${bytes.length}');
      return;
    }
    
    final cellNum = bytes[0];
    final cellType = bytes[1];
    
    _cellCount = cellNum;
    
    _currentData = _currentData.copyWith(
      cellNumber: cellNum,
      cellType: cellType,
      cellCount: cellNum,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 电池串数已更新: 串数=$cellNum, 类型=$cellType');
  }
  
  void _processCellAloneVoltageResponse(List<int> bytes, int startAddress) {
    if (bytes.length < 2) {
      print('[BatteryDataManager] 单体电压响应数据长度不足: ${bytes.length}');
      return;
    }
    
    final cellIndex = startAddress - 0x0020;
    final voltageRaw = (bytes[0] << 8) | bytes[1];
    final voltage = voltageRaw / 1000.0;
    
    _cellVoltages.add(voltage);
    
    print('[BatteryDataManager] 电池${cellIndex + 1}电压: ${voltage.toStringAsFixed(3)}V');
    
    if (_cellVoltages.length == _cellCount) {
      _currentData = _currentData.copyWith(
        cellVoltages: List.from(_cellVoltages),
        timestamp: DateTime.now(),
      );
      _batteryDataController.add(_currentData);
      
      print('[BatteryDataManager] 单体电压列表已更新:');
      for (int i = 0; i < _cellVoltages.length; i++) {
        print('  电池${i + 1}: ${_cellVoltages[i].toStringAsFixed(3)}V');
      }
    }
  }
  
  void _processWarningInfoResponse(List<int> bytes) {
    if (bytes.length < 2) {
      print('[BatteryDataManager] 警告信息响应数据长度不足: ${bytes.length}');
      return;
    }
    
    final warningInfo = (bytes[0] << 8) | bytes[1];
    
    _currentData = _currentData.copyWith(
      warningInfo: warningInfo,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 警告信息已更新: 0x${warningInfo.toRadixString(16).padLeft(4, '0')}');
  }
  
  void _processProtectionInfoResponse(List<int> bytes) {
    if (bytes.length < 4) {
      print('[BatteryDataManager] 保护信息响应数据长度不足: ${bytes.length}');
      return;
    }
    
    final protectionInfo = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    
    _currentData = _currentData.copyWith(
      protectionInfo: protectionInfo,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 保护信息已更新: 0x${protectionInfo.toRadixString(16).padLeft(8, '0')}');
  }
  
  void _processBatteryStatusResponse(List<int> bytes) {
    if (bytes.length < 2) {
      print('[BatteryDataManager] 电池状态响应数据长度不足: ${bytes.length}');
      return;
    }
    
    final batteryStatus = (bytes[0] << 8) | bytes[1];
    
    _currentData = _currentData.copyWith(
      batteryStatus: batteryStatus,
      timestamp: DateTime.now(),
    );
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 电池状态已更新: 0x${batteryStatus.toRadixString(16).padLeft(4, '0')}');
  }
  
  void _processMainPageDataResponse(List<int> bytes) {
    final mainPageData = _processMainPageData(bytes);
    
    _currentData = _currentData.copyWith(
      voltage: mainPageData['voltage'] ?? _currentData.voltage,
      current: mainPageData['current'] ?? _currentData.current,
      capacity: mainPageData['capacity'] ?? _currentData.capacity,
      chargeMosOn: mainPageData['chargeMosOn'] ?? _currentData.chargeMosOn,
      dischargeMosOn: mainPageData['dischargeMosOn'] ?? _currentData.dischargeMosOn,
      timestamp: DateTime.now(),
    );
    
    if (mainPageData['temperatures'] != null) {
      _currentData = _currentData.copyWith(
        temperatures: mainPageData['temperatures'] as List<double>,
      );
    }
    
    _batteryDataController.add(_currentData);
    print('[BatteryDataManager] 主页数据已更新');
  }
  
  Map<String, dynamic> _processMainPageData(List<int> registers) {
    final result = <String, dynamic>{};
    
    try {
      if (registers.length >= 29) {
        final mosTempRaw = registers[0];
        final batteryTemp1Raw = registers[1];
        final batteryTemp2Raw = registers[2];
        
        final voltageRaw = (registers[4] << 16) | registers[5];
        final currentRaw = ((registers[6] << 24) | (registers[7] << 16) | (registers[8] << 8) | registers[9]);
        final capacityRaw = registers[28];
        
        final afeStatusRaw = (registers[12] << 16) | registers[13];
        
        final mosTemp = mosTempRaw * 0.1 - 273.15;
        final batteryTemp1 = batteryTemp1Raw * 0.1 - 273.15;
        final batteryTemp2 = batteryTemp2Raw * 0.1 - 273.15;
        
        final voltage = voltageRaw / 1000.0;
        final current = currentRaw / 1000.0;
        final capacity = capacityRaw / 10.0;
        
        final chargeMosOn = (afeStatusRaw >> 17) & 1 == 1;
        final dischargeMosOn = (afeStatusRaw >> 16) & 1 == 1;
        
        result['voltage'] = voltage;
        result['current'] = current;
        result['capacity'] = capacity;
        result['chargeMosOn'] = chargeMosOn;
        result['dischargeMosOn'] = dischargeMosOn;
        result['temperatures'] = [mosTemp, batteryTemp1, batteryTemp2];
        
        print('[BatteryDataManager] 主页数据解析: 电压=${voltage.toStringAsFixed(2)}V, 电流=${current.toStringAsFixed(2)}A, 容量=${capacity.toStringAsFixed(2)}Ah');
        print('[BatteryDataManager] MOS状态: 充电=$chargeMosOn, 放电=$dischargeMosOn');
        print('[BatteryDataManager] 温度: MOS=${mosTemp.toStringAsFixed(1)}°C, 电池1=${batteryTemp1.toStringAsFixed(1)}°C, 电池2=${batteryTemp2.toStringAsFixed(1)}°C');
      }
    } catch (e) {
      print('[BatteryDataManager] 解析主页数据失败: $e');
    }
    
    return result;
  }
  
  String _generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_pendingRequests.length}';
  }
  
  void dispose() {
    stopAutoRead();
    stopBatteryLevelReading();
    _batteryDataController.close();
    _requestStatusController.close();
  }

  Future<String?> readBatterySN() async {
    print('[BatteryDataManager] [BatteryInfo] 读取电池SN: 地址 0x230, 数量 6');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x230,
      quantity: 6,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<String?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 12) {
            final stringBuffer = StringBuffer();
            for (int i = 0; i < bytes.length && i < 12; i++) {
              if (bytes[i] != 0) {
                stringBuffer.writeCharCode(bytes[i]);
              }
            }
            final sn = stringBuffer.toString();
            print('[BatteryDataManager] [BatteryInfo] 电池SN: $sn');
            completer.complete(sn);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [BatteryInfo] 读取电池SN超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<String?> readManufacturer() async {
    print('[BatteryDataManager] [BatteryInfo] 读取制造厂家: 地址 0x236, 数量 4');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x236,
      quantity: 4,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<String?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 8) {
            final stringBuffer = StringBuffer();
            for (int i = 0; i < bytes.length && i < 8; i++) {
              if (bytes[i] != 0) {
                stringBuffer.writeCharCode(bytes[i]);
              }
            }
            final manufacturer = stringBuffer.toString();
            print('[BatteryDataManager] [BatteryInfo] 制造厂家: $manufacturer');
            completer.complete(manufacturer);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [BatteryInfo] 读取制造厂家超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<String?> readManufacturerModel() async {
    print('[BatteryDataManager] [BatteryInfo] 读取制造厂商型号: 地址 0x23A, 数量 12');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x23A,
      quantity: 12,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<String?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 24) {
            final stringBuffer = StringBuffer();
            for (int i = 0; i < bytes.length && i < 24; i++) {
              if (bytes[i] != 0) {
                stringBuffer.writeCharCode(bytes[i]);
              }
            }
            final model = stringBuffer.toString();
            print('[BatteryDataManager] [BatteryInfo] 制造厂商型号: $model');
            completer.complete(model);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [BatteryInfo] 读取制造厂商型号超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<String?> readCustomerName() async {
    print('[BatteryDataManager] [BatteryInfo] 读取客户名称: 地址 0x246, 数量 4');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x246,
      quantity: 4,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<String?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 8) {
            final stringBuffer = StringBuffer();
            for (int i = 0; i < bytes.length && i < 8; i++) {
              if (bytes[i] != 0) {
                stringBuffer.writeCharCode(bytes[i]);
              }
            }
            final customerName = stringBuffer.toString();
            print('[BatteryDataManager] [BatteryInfo] 客户名称: $customerName');
            completer.complete(customerName);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [BatteryInfo] 读取客户名称超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<String?> readCustomerModel() async {
    print('[BatteryDataManager] [BatteryInfo] 读取客户型号: 地址 0x24A, 数量 12');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x24A,
      quantity: 12,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<String?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 24) {
            final stringBuffer = StringBuffer();
            for (int i = 0; i < bytes.length && i < 24; i++) {
              if (bytes[i] != 0) {
                stringBuffer.writeCharCode(bytes[i]);
              }
            }
            final customerModel = stringBuffer.toString();
            print('[BatteryDataManager] [BatteryInfo] 客户型号: $customerModel');
            completer.complete(customerModel);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [BatteryInfo] 读取客户型号超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<String?> readMfgDate() async {
    print('[BatteryDataManager] [BatteryInfo] 读取生产日期: 地址 0x256, 数量 4');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x256,
      quantity: 4,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<String?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 8) {
            final stringBuffer = StringBuffer();
            for (int i = 0; i < bytes.length && i < 8; i++) {
              if (bytes[i] != 0) {
                stringBuffer.writeCharCode(bytes[i]);
              }
            }
            final mfgDate = stringBuffer.toString();
            print('[BatteryDataManager] [BatteryInfo] 生产日期: $mfgDate');
            completer.complete(mfgDate);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [BatteryInfo] 读取生产日期超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readDesignCycleCount() async {
    print('[BatteryDataManager] [BatteryInfo] 读取设计循环次数: 地址 0x400');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x400,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [BatteryInfo] 设计循环次数: $value');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [BatteryInfo] 读取设计循环次数超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readReferenceCapacity() async {
    print('[BatteryDataManager] [BatteryInfo] 读取参考容值: 地址 0x402, 数量 2');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x402,
      quantity: 2,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 4) {
            final value = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
            print('[BatteryDataManager] [BatteryInfo] 参考容值: $value mah');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [BatteryInfo] 读取参考容值超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<String?> readBTCode() async {
    print('[BatteryDataManager] [BatteryInfo] 读取BT码: 地址 0x408, 数量 16');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x408,
      quantity: 16,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<String?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 32) {
            final stringBuffer = StringBuffer();
            for (int i = 0; i < bytes.length && i < 32; i++) {
              if (bytes[i] != 0) {
                stringBuffer.writeCharCode(bytes[i]);
              }
            }
            final btCode = stringBuffer.toString();
            print('[BatteryDataManager] [BatteryInfo] BT码: $btCode');
            completer.complete(btCode);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [BatteryInfo] 读取BT码超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<List<ProtectionRecord>?> readProtectionRecords() async {
    print('[BatteryDataManager] [Protection] 读取保护记录: 时间地址 0x418, 事件地址 0x448, 数量 24');
    
    final List<ProtectionRecord> records = [];
    
    for (int i = 1; i <= 24; i++) {
      final timeAddress = 0x418 + 0x02 * (i - 1);
      final eventAddress = 0x448 + 0x02 * (i - 1);
      
      final timeValue = await _readProtectionTime(timeAddress);
      final eventValue = await _readProtectionEvent(eventAddress);
      
      if (timeValue != null && eventValue != null) {
        records.add(ProtectionRecord(
          index: i,
          time: timeValue,
          event: eventValue,
        ));
      }
      
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    return records;
  }
  
  Future<String?> _readProtectionTime(int address) async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: address,
      quantity: 2,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<String?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 4) {
            final a = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
            
            if (a == 0) {
              completer.complete(null);
              return;
            }
            
            final year = ((a & 0xFC000000) >> 26) + 2022;
            final month = (a & 0x03C00000) >> 22;
            final day = (a & 0x003E0000) >> 17;
            final hour = (a & 0x0001F000) >> 12;
            final minute = (a & 0x00000FC0) >> 6;
            final second = a & 0x0000003F;
            
            final timeStr = '${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} '
                          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
            
            print('[BatteryDataManager] [Protection] 保护时间 (地址 0x${address.toRadixString(16).padLeft(3, '0')}): $timeStr');
            completer.complete(timeStr);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Protection] 读取保护时间超时 (地址 0x${address.toRadixString(16).padLeft(3, '0')})');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
  
  Future<String?> _readProtectionEvent(int address) async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: address,
      quantity: 2,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<String?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 4) {
            final a = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
            
            if (a == 0) {
              completer.complete(null);
              return;
            }
            
            final eventStr = '0x${a.toRadixString(16).padLeft(8, '0').toUpperCase()}';
            
            print('[BatteryDataManager] [Protection] 保护事件 (地址 0x${address.toRadixString(16).padLeft(3, '0')}): $eventStr');
            completer.complete(eventStr);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Protection] 读取保护事件超时 (地址 0x${address.toRadixString(16).padLeft(3, '0')})');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readSwitchConfig() async {
    print('[BatteryDataManager] [Control] 读取开关配置寄存器: 地址 0x205');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x205,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Control] 开关配置寄存器值: 0x${value.toRadixString(16).padLeft(4, '0')}');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Control] 读取开关配置寄存器超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }

  Future<int?> readControlFlags() async {
    print('[BatteryDataManager] [Control] 读取控制标志寄存器: 地址 0x000F');
    final requestId = _generateRequestId();
    final request = ModbusRequest.readQuickSettings(
      id: requestId,
      slaveId: _slaveId,
      startAddress: 0x000F,
      quantity: 1,
    );
    
    await _sendRequest(request);
    
    final completer = Completer<int?>();
    
    final subscription = requestStatusStream.listen((event) {
      if (event.id == requestId) {
        if (event.status == ModbusRequestStatus.completed) {
          final bytes = event.response;
          if (bytes != null && bytes.length >= 2) {
            final value = (bytes[0] << 8) | bytes[1];
            print('[BatteryDataManager] [Control] 控制标志寄存器值: 0x${value.toRadixString(16).padLeft(4, '0')}');
            completer.complete(value);
          } else {
            completer.complete(null);
          }
        } else if (event.status == ModbusRequestStatus.failed) {
          completer.complete(null);
        }
      }
    });
    
    final result = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      print('[BatteryDataManager] [Control] 读取控制标志寄存器超时');
      return null;
    });
    
    subscription.cancel();
    return result;
  }
}
