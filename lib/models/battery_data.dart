/// 电池数据模型类
/// 用于存储和管理电池管理系统的状态数据
class BatteryData {
  final int slaveId;
  final int chargeStatus;
  final int dischargeStatus;
  final int soc;
  final int soh;
  final int cycleCount;
  final double voltage;
  final double current;
  final double capacity;
  final double remainingCapacity;
  final double fullCapacity;
  final int temperatureCount;
  final List<double> temperatures;
  final int cellCount;
  final List<double> cellVoltages;
  final DateTime timestamp;
  
  final int mosTemperature;
  final double batteryTemperature1;
  final double batteryTemperature2;
  final double batteryTemperatureMos;
  final int balanceStatus;
  final int afeStatus;
  final int alarmStatus;
  final int packStatus;
  final double secondaryVoltage;
  final double secondaryCurrent;
  final int secondaryTemperature;
  final int firmwareVersion;
  final int rtcYearMonth;
  final int rtcDayHour;
  final int rtcMinuteSecond;
  final int cellNumber;
  final int cellType;
  final int afeNumber;
  final int customerNumber;
  final int cycleCount10mah;
  final int fullCapacity10mah;
  final int designCapacity;
  final int maxUnchargedInterval;
  final int recentUnchargedInterval;
  final int functionSwitchConfig;
  final bool chargeMosOn;
  final bool dischargeMosOn;

  BatteryData({
    required this.slaveId,
    required this.chargeStatus,
    required this.dischargeStatus,
    required this.soc,
    required this.soh,
    required this.cycleCount,
    required this.voltage,
    required this.current,
    required this.capacity,
    required this.remainingCapacity,
    required this.fullCapacity,
    required this.temperatureCount,
    required this.temperatures,
    required this.cellCount,
    required this.cellVoltages,
    DateTime? timestamp,
    this.mosTemperature = 0,
    this.batteryTemperature1 = 0.0,
    this.batteryTemperature2 = 0.0,
    this.batteryTemperatureMos = 0.0,
    this.balanceStatus = 0,
    this.afeStatus = 0,
    this.alarmStatus = 0,
    this.packStatus = 0,
    this.secondaryVoltage = 0.0,
    this.secondaryCurrent = 0.0,
    this.secondaryTemperature = 0,
    this.firmwareVersion = 0,
    this.rtcYearMonth = 0,
    this.rtcDayHour = 0,
    this.rtcMinuteSecond = 0,
    this.cellNumber = 0,
    this.cellType = 0,
    this.afeNumber = 0,
    this.customerNumber = 0,
    this.cycleCount10mah = 0,
    this.fullCapacity10mah = 0,
    this.designCapacity = 0,
    this.maxUnchargedInterval = 0,
    this.recentUnchargedInterval = 0,
    this.functionSwitchConfig = 0,
    this.chargeMosOn = false,
    this.dischargeMosOn = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory BatteryData.empty() {
    return BatteryData(
      slaveId: 0,
      chargeStatus: 0,
      dischargeStatus: 0,
      soc: 0,
      soh: 0,
      cycleCount: 0,
      voltage: 0.0,
      current: 0.0,
      capacity: 0.0,
      remainingCapacity: 0.0,
      fullCapacity: 0.0,
      temperatureCount: 0,
      temperatures: [],
      cellCount: 0,
      cellVoltages: [],
      mosTemperature: 0,
      batteryTemperature1: 0.0,
      batteryTemperature2: 0.0,
      batteryTemperatureMos: 0.0,
      balanceStatus: 0,
      afeStatus: 0,
      alarmStatus: 0,
      packStatus: 0,
      secondaryVoltage: 0.0,
      secondaryCurrent: 0.0,
      secondaryTemperature: 0,
      firmwareVersion: 0,
      rtcYearMonth: 0,
      rtcDayHour: 0,
      rtcMinuteSecond: 0,
      cellNumber: 0,
      cellType: 0,
      afeNumber: 0,
      customerNumber: 0,
      cycleCount10mah: 0,
      fullCapacity10mah: 0,
      designCapacity: 0,
      maxUnchargedInterval: 0,
      recentUnchargedInterval: 0,
      functionSwitchConfig: 0,
      chargeMosOn: false,
      dischargeMosOn: false,
    );
  }

  BatteryData copyWith({
    int? slaveId,
    int? chargeStatus,
    int? dischargeStatus,
    int? status,
    int? soc,
    int? soh,
    int? cycleCount,
    double? voltage,
    double? current,
    double? capacity,
    double? remainingCapacity,
    double? fullCapacity,
    int? temperatureCount,
    List<double>? temperatures,
    int? cellCount,
    List<double>? cellVoltages,
    DateTime? timestamp,
    int? mosTemperature,
    double? batteryTemperature1,
    double? batteryTemperature2,
    int? batteryTemperature3,
    double? batteryTemperatureMos,
    int? balanceStatus,
    int? afeStatus,
    int? alarmStatus,
    int? packStatus,
    double? secondaryVoltage,
    double? secondaryCurrent,
    int? secondaryTemperature,
    int? firmwareVersion,
    int? rtcYearMonth,
    int? rtcDayHour,
    int? rtcMinuteSecond,
    int? cellNumber,
    int? cellType,
    int? afeNumber,
    int? customerNumber,
    int? cycleCount10mah,
    int? fullCapacity10mah,
    int? designCapacity,
    int? maxUnchargedInterval,
    int? recentUnchargedInterval,
    int? functionSwitchConfig,
    bool? chargeMosOn,
    bool? dischargeMosOn,
  }) {
    return BatteryData(
      slaveId: slaveId ?? this.slaveId,
      chargeStatus: chargeStatus ?? this.chargeStatus,
      dischargeStatus: dischargeStatus ?? this.dischargeStatus,
      soc: soc ?? this.soc,
      soh: soh ?? this.soh,
      cycleCount: cycleCount ?? this.cycleCount,
      voltage: voltage ?? this.voltage,
      current: current ?? this.current,
      capacity: capacity ?? this.capacity,
      remainingCapacity: remainingCapacity ?? this.remainingCapacity,
      fullCapacity: fullCapacity ?? this.fullCapacity,
      temperatureCount: temperatureCount ?? this.temperatureCount,
      temperatures: temperatures ?? this.temperatures,
      cellCount: cellCount ?? this.cellCount,
      cellVoltages: cellVoltages ?? this.cellVoltages,
      timestamp: timestamp ?? this.timestamp,
      mosTemperature: mosTemperature ?? this.mosTemperature,
      batteryTemperature1: batteryTemperature1 ?? this.batteryTemperature1,
      batteryTemperature2: batteryTemperature2 ?? this.batteryTemperature2,
      batteryTemperatureMos: batteryTemperatureMos ?? this.batteryTemperatureMos,
      balanceStatus: balanceStatus ?? this.balanceStatus,
      afeStatus: afeStatus ?? this.afeStatus,
      alarmStatus: alarmStatus ?? this.alarmStatus,
      packStatus: packStatus ?? this.packStatus,
      secondaryVoltage: secondaryVoltage ?? this.secondaryVoltage,
      secondaryCurrent: secondaryCurrent ?? this.secondaryCurrent,
      secondaryTemperature: secondaryTemperature ?? this.secondaryTemperature,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      rtcYearMonth: rtcYearMonth ?? this.rtcYearMonth,
      rtcDayHour: rtcDayHour ?? this.rtcDayHour,
      rtcMinuteSecond: rtcMinuteSecond ?? this.rtcMinuteSecond,
      cellNumber: cellNumber ?? this.cellNumber,
      cellType: cellType ?? this.cellType,
      afeNumber: afeNumber ?? this.afeNumber,
      customerNumber: customerNumber ?? this.customerNumber,
      cycleCount10mah: cycleCount10mah ?? this.cycleCount10mah,
      fullCapacity10mah: fullCapacity10mah ?? this.fullCapacity10mah,
      designCapacity: designCapacity ?? this.designCapacity,
      maxUnchargedInterval: maxUnchargedInterval ?? this.maxUnchargedInterval,
      recentUnchargedInterval: recentUnchargedInterval ?? this.recentUnchargedInterval,
      functionSwitchConfig: functionSwitchConfig ?? this.functionSwitchConfig,
      chargeMosOn: chargeMosOn ?? this.chargeMosOn,
      dischargeMosOn: dischargeMosOn ?? this.dischargeMosOn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slaveId': slaveId,
      'chargeStatus': chargeStatus,
      'dischargeStatus': dischargeStatus,
      'soc': soc,
      'soh': soh,
      'cycleCount': cycleCount,
      'voltage': voltage,
      'current': current,
      'capacity': capacity,
      'remainingCapacity': remainingCapacity,
      'fullCapacity': fullCapacity,
      'temperatureCount': temperatureCount,
      'temperatures': temperatures,
      'cellCount': cellCount,
      'cellVoltages': cellVoltages,
      'mosTemperature': mosTemperature,
      'batteryTemperature1': batteryTemperature1,
      'batteryTemperature2': batteryTemperature2,
      'batteryTemperatureMos': batteryTemperatureMos,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BatteryData.fromJson(Map<String, dynamic> json) {
    return BatteryData(
      slaveId: json['slaveId'] as int,
      chargeStatus: json['chargeStatus'] as int,
      dischargeStatus: json['dischargeStatus'] as int,
      soc: json['soc'] as int,
      soh: json['soh'] as int,
      cycleCount: json['cycleCount'] as int,
      voltage: (json['voltage'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      capacity: (json['capacity'] as num).toDouble(),
      remainingCapacity: (json['remainingCapacity'] as num).toDouble(),
      fullCapacity: (json['fullCapacity'] as num).toDouble(),
      temperatureCount: json['temperatureCount'] as int,
      temperatures: (json['temperatures'] as List).map((e) => (e as num).toDouble()).toList(),
      cellCount: json['cellCount'] as int,
      cellVoltages: (json['cellVoltages'] as List).map((e) => (e as num).toDouble()).toList(),
      mosTemperature: json['mosTemperature'] as int? ?? 0,
      batteryTemperature1: (json['batteryTemperature1'] as num?)?.toDouble() ?? 0.0,
      batteryTemperature2: (json['batteryTemperature2'] as num?)?.toDouble() ?? 0.0,
      batteryTemperatureMos: (json['batteryTemperatureMos'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'BatteryData{'
        'slaveId: $slaveId, '
        'chargeStatus: $chargeStatus, '
        'dischargeStatus: $dischargeStatus, '
        'soc: $soc%, '
        'soh: $soh%, '
        'cycleCount: $cycleCount, '
        'voltage: ${voltage.toStringAsFixed(2)}V, '
        'current: ${current.toStringAsFixed(2)}A, '
        'capacity: ${capacity.toStringAsFixed(2)}Ah, '
        'temperatureCount: $temperatureCount, '
        'cellCount: $cellCount'
        '}';
  }

  bool get isEmpty => slaveId == 0 && soc == 0;

  bool get isNotEmpty => !isEmpty;
}
