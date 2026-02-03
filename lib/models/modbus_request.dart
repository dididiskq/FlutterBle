import 'dart:typed_data';

/// Modbus 请求类型枚举
enum ModbusRequestType {
  readBatteryDc,    // 读取总容量
  readBatteryLevel,     // 读取电池电量(SOC/SOH)
  readCellVoltages,     // 读取总电压
  readCellCurrent,      // 读取总电流
  readChargeDischargeStatus,     // 读取充放电状态
  readTemperatures1,     // 读取温度1数据
  readTemperatures2,     // 读取温度2数据
  readTemperaturesMos,     // 读取Mos温度数据
  readCycleCount,     // 读取循环次数
  readBatteryStringCount,     // 读取电池串数
  readCellAloneVoltage,     // 读取单个电池电压
  readMainPageData,     // 读取主页数据
  readQuickSettings,     // 读取快速设置参数
  readWarningInfo,     // 读取警告信息
  readProtectionInfo,     // 读取保护信息
  readBatteryStatus,     // 读取电池状态
  readTable1Data,     // 读取表格1数据 (第二种蓝牙板)
  readTable2Data,     // 读取表格2数据 (第二种蓝牙板)
  readTable3Data,     // 读取表格3数据 (第二种蓝牙板)
  writeParameters,      // 写入参数
  custom,               // 自定义请求
}

/// Modbus 请求状态枚举
enum ModbusRequestStatus {
  pending,
  sent,
  completed,
  failed,
  timeout,
}

/// Modbus 请求模型类
/// 用于封装 Modbus 请求的详细信息
class ModbusRequest {
  final String id;
  final ModbusRequestType type;
  final ModbusRequestStatus status;
  final int slaveId;
  final int startAddress;
  final int quantity;
  final List<int>? writeValues;
  final Uint8List? command;
  final Uint8List? response;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int retryCount;
  final int maxRetries;
  final Duration timeout;

  ModbusRequest({
    required this.id,
    required this.type,
    required this.slaveId,
    required this.startAddress,
    required this.quantity,
    this.writeValues,
    this.command,
    this.response,
    ModbusRequestStatus? status,
    DateTime? createdAt,
    this.sentAt,
    this.completedAt,
    this.errorMessage,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.timeout = const Duration(seconds: 5),
  })  : status = status ?? ModbusRequestStatus.pending,
        createdAt = createdAt ?? DateTime.now();

  factory ModbusRequest.readBatteryDc({
    required String id,
    int slaveId = 1,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readBatteryDc,
      slaveId: slaveId,
      startAddress: 0x001C,
      quantity: 0x0001,
    );
  }

  factory ModbusRequest.readBatteryLevel({
    required String id,
    int slaveId = 1,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readBatteryLevel,
      slaveId: slaveId,
      startAddress: 0x0014,
      quantity: 0x0001,
    );
  }

  factory ModbusRequest.readCellVoltages({
    required String id,
    int slaveId = 1,
    int startAddress = 0x0020,
    int quantity = 0x0020,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readCellVoltages,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: quantity,
    );
  }
  
 
  factory ModbusRequest.readTemperatures1({
    required String id,
    int slaveId = 1,
    int startAddress = 0x0040,
    int quantity = 0x0010,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readTemperatures1,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: quantity,
    );
  }
    factory ModbusRequest.readTemperatures2({
    required String id,
    int slaveId = 1,
    int startAddress = 0x0040,
    int quantity = 0x0010,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readTemperatures2,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: quantity,
    );
  }

  factory ModbusRequest.readTemperaturesMos({
    required String id,
    int slaveId = 1,
    int startAddress = 0x0040,
    int quantity = 0x0010,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readTemperaturesMos,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: quantity,
    );
  }
  //新增读取总电流
  factory ModbusRequest.readCellCurrent({
    required String id,
    int slaveId = 1,
    int startAddress = 0x0042,
    int quantity = 0x0001,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readCellCurrent,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: quantity,
    );
  }
  
  //新增读取充放电状态
  factory ModbusRequest.readChargeDischargeStatus({
    required String id,
    int slaveId = 1,
    int startAddress = 0x0002,
    int quantity = 0x0001,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readChargeDischargeStatus,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: quantity,
    );
  }
  //新增读取循环次数
  factory ModbusRequest.readCycleCount({
    required String id,
    int slaveId = 1,
    int startAddress = 0x001A,
    int quantity = 0x0001,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readCycleCount,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: quantity,
    );
  }

  //新增读取电池串数
  factory ModbusRequest.readBatteryStringCount({
    required String id,
    int slaveId = 1,
    int startAddress = 0x0018,
    int quantity = 0x0001,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readBatteryStringCount,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: quantity,
    );
  }

  factory ModbusRequest.readCellAloneVoltage({
    required String id,
    required int slaveId,
    required int cellIndex,
  }) {
    final startAddress = 0x0020 + cellIndex;
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readCellAloneVoltage,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: 0x0001,
    );
  }

  factory ModbusRequest.readMainPageData({
    required String id,
    int slaveId = 1,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readMainPageData,
      slaveId: slaveId,
      startAddress: 0x0000,
      quantity: 0x001D,
    );
  }

  factory ModbusRequest.readQuickSettings({
    required String id,
    int slaveId = 1,
    required int startAddress,
    required int quantity,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readQuickSettings,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: quantity,
    );
  }

  factory ModbusRequest.readWarningInfo({
    required String id,
    int slaveId = 1,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readWarningInfo,
      slaveId: slaveId,
      startAddress: 0x000E,
      quantity: 0x0001,
    );
  }

  factory ModbusRequest.readProtectionInfo({
    required String id,
    int slaveId = 1,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readProtectionInfo,
      slaveId: slaveId,
      startAddress: 0x000C,
      quantity: 0x0002,
    );
  }

  factory ModbusRequest.readBatteryStatus({
    required String id,
    int slaveId = 1,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readBatteryStatus,
      slaveId: slaveId,
      startAddress: 0x000F,
      quantity: 0x0001,
    );
  }

  factory ModbusRequest.writeParameters({
    required String id,
    required int slaveId,
    required int startAddress,
    required List<int> values,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.writeParameters,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: values.length,
      writeValues: values,
    );
  }

  factory ModbusRequest.custom({
    required String id,
    required int slaveId,
    required int startAddress,
    required int quantity,
    List<int>? writeValues,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.custom,
      slaveId: slaveId,
      startAddress: startAddress,
      quantity: quantity,
      writeValues: writeValues,
    );
  }

  // 读取表格1数据 (第二种蓝牙板)
  factory ModbusRequest.readTable1Data({
    required String id,
    int slaveId = 1,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readTable1Data,
      slaveId: slaveId,
      startAddress: 0x0000,
      quantity: 0x003F, // 63个寄存器
    );
  }

  // 读取表格2数据 (第二种蓝牙板)
  factory ModbusRequest.readTable2Data({
    required String id,
    int slaveId = 1,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readTable2Data,
      slaveId: slaveId,
      startAddress: 0x0200,
      quantity: 0x003F, // 63个寄存器
    );
  }

  // 读取表格3数据 (第二种蓝牙板)
  factory ModbusRequest.readTable3Data({
    required String id,
    int slaveId = 1,
  }) {
    return ModbusRequest(
      id: id,
      type: ModbusRequestType.readTable3Data,
      slaveId: slaveId,
      startAddress: 0x0400,
      quantity: 0x003F, // 63个寄存器
    );
  }

  ModbusRequest copyWith({
    String? id,
    ModbusRequestType? type,
    ModbusRequestStatus? status,
    int? slaveId,
    int? startAddress,
    int? quantity,
    List<int>? writeValues,
    Uint8List? command,
    Uint8List? response,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? completedAt,
    String? errorMessage,
    int? retryCount,
    int? maxRetries,
    Duration? timeout,
  }) {
    return ModbusRequest(
      id: id ?? this.id,
      type: type ?? this.type,
      slaveId: slaveId ?? this.slaveId,
      startAddress: startAddress ?? this.startAddress,
      quantity: quantity ?? this.quantity,
      writeValues: writeValues ?? this.writeValues,
      command: command ?? this.command,
      response: response ?? this.response,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      timeout: timeout ?? this.timeout,
    );
  }

  bool get isRead => type == ModbusRequestType.readBatteryDc ||
      type == ModbusRequestType.readBatteryLevel ||
      type == ModbusRequestType.readCellVoltages ||
      type == ModbusRequestType.readCellCurrent ||
      type == ModbusRequestType.readChargeDischargeStatus ||
      type == ModbusRequestType.readTemperatures1 ||
      type == ModbusRequestType.readTemperatures2 ||
      type == ModbusRequestType.readTemperaturesMos ||
      type == ModbusRequestType.readCycleCount ||
      type == ModbusRequestType.readBatteryStringCount ||
      type == ModbusRequestType.readCellAloneVoltage ||
      type == ModbusRequestType.readMainPageData ||
      type == ModbusRequestType.readQuickSettings ||
      type == ModbusRequestType.readWarningInfo ||
      type == ModbusRequestType.readProtectionInfo ||
      type == ModbusRequestType.readBatteryStatus ||
      type == ModbusRequestType.readTable1Data ||
      type == ModbusRequestType.readTable2Data ||
      type == ModbusRequestType.readTable3Data;



  bool get isWrite => type == ModbusRequestType.writeParameters;

  bool get isPending => status == ModbusRequestStatus.pending;

  bool get isSent => status == ModbusRequestStatus.sent;

  bool get isCompleted => status == ModbusRequestStatus.completed;

  bool get isFailed => status == ModbusRequestStatus.failed ||
      status == ModbusRequestStatus.timeout;

  bool get canRetry => retryCount < maxRetries;

  bool get isTimeout => DateTime.now().difference(sentAt ?? createdAt) > timeout;

  @override
  String toString() {
    return 'ModbusRequest{'
        'id: $id, '
        'type: $type, '
        'status: $status, '
        'slaveId: $slaveId, '
        'startAddress: 0x${startAddress.toRadixString(16).padLeft(4, '0')}, '
        'quantity: $quantity'
        '}';
  }
}
