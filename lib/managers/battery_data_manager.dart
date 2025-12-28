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
  Duration _readInterval = const Duration(seconds: 1);
  Duration _batteryLevelReadInterval = const Duration(milliseconds: 500);
  
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
    
    _readTimer = Timer.periodic(_readInterval, (_) {
      readAllData();
    });
    
    _timeoutCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkTimeouts();
    });
    
    print('[BatteryDataManager] 自动读取已启动');
  }
  
  void stopAutoRead() {
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
    if (!isConnected || _isReading) {
      return;
    }
    
    _isReading = true;
    
    try {
      await readBatteryLevel();                   // 读取电池电量(SOC/SOH)
      await Future.delayed(const Duration(milliseconds: 100));
      
      await readBatteryDc();                  // 读取总容量
      await Future.delayed(const Duration(milliseconds: 100));
      
      await readCellVoltages();                   // 读取总电压
      await Future.delayed(const Duration(milliseconds: 100));

      //读取总电流
      await readCellCurrent();                   // 读取总电流
      await Future.delayed(const Duration(milliseconds: 100));
      
      //读取充放电状态
      await readChargeDischargeStatus();                   // 读取充放电状态
      await Future.delayed(const Duration(milliseconds: 100));
      
      await readTemperatures1();                   // 读取温度1数据
      await Future.delayed(const Duration(milliseconds: 100));
      
      await readTemperatures2();                   // 读取温度2数据
      await Future.delayed(const Duration(milliseconds: 100));
      
      await readTemperaturesMos();                   // 读取Mos温度数据
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 读取循环次数
      await readCycleCount();                   // 读取循环次数
      await Future.delayed(const Duration(milliseconds: 100));
      
      //读取单体电压
      // await readCellVoltages();                   // 读取单体电压
      // await Future.delayed(const Duration(milliseconds: 100));
      
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
  
  Future<bool> writeParameters(int startAddress, List<int> values) async {
    final requestId = _generateRequestId();
    final request = ModbusRequest.writeParameters(
      id: requestId,
      slaveId: _slaveId,
      startAddress: startAddress,
      values: values,
    );
    
    final result = await _sendRequest(request);
    return result;
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
      } else {
        print('[BatteryDataManager] 写入失败: ${result['error']}');
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
        
      default:
        print('[BatteryDataManager] 未知的请求类型: ${matchedRequest.type}');
        break;
    }
    
    // 从待处理列表中移除该请求
    _pendingRequests.remove(matchedRequestId);
    
    // 更新请求状态
    _updateRequestStatus(matchedRequest!.copyWith(
      status: ModbusRequestStatus.completed,
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
    print('[BatteryDataManager] 充放电状态解析: ${bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    final chargeStatus = bytes[0];
    final dischargeStatus = bytes[1];
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
}
