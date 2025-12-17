import 'dart:typed_data';

/// BMS协议解析和封装类
class BmsProtocol {
  /// CRC16校验表
  static const List<int> _crc16Tab = [
    0x0000,0x1021,0x2042,0x3063,0x4084,0x50a5,0x60c6,0x70e7,
    0x8108,0x9129,0xa14a,0xb16b,0xc18c,0xd1ad,0xe1ce,0xf1ef,
    0x1231,0x0210,0x3273,0x2252,0x52b5,0x4294,0x72f7,0x62d6,
    0x9339,0x8318,0xb37b,0xa35a,0xd3bd,0xc39c,0xf3ff,0xe3de,
    0x2462,0x3443,0x0420,0x1401,0x64e6,0x74c7,0x44a4,0x5485,
    0xa56a,0xb54b,0x8528,0x9509,0xe5ee,0xf5cf,0xc5ac,0xd58d,
    0x3653,0x2672,0x1611,0x0630,0x76d7,0x66f6,0x5695,0x46b4,
    0xb75b,0xa77a,0x9719,0x8738,0xf7df,0xe7fe,0xd79d,0xc7bc,
    0x48c4,0x58e5,0x6886,0x78a7,0x0840,0x1861,0x2802,0x3823,
    0xc9cc,0xd9ed,0xe98e,0xf9af,0x8948,0x9969,0xa90a,0xb92b,
    0x5af5,0x4ad4,0x7ab7,0x6a96,0x1a71,0x0a50,0x3a33,0x2a12,
    0xdbfd,0xcbdc,0xfbbf,0xeb9e,0x9b79,0x8b58,0xbb3b,0xab1a,
    0x6ca6,0x7c87,0x4ce4,0x5cc5,0x2c22,0x3c03,0x0c60,0x1c41,
    0xedae,0xfd8f,0xcdec,0xddcd,0xad2a,0xbd0b,0x8d68,0x9d49,
    0x7e97,0x6eb6,0x5ed5,0x4ef4,0x3e13,0x2e32,0x1e51,0x0e70,
    0xff9f,0xefbe,0xdfdd,0xcffc,0xbf1b,0xaf3a,0x9f59,0x8f78,
    0x9188,0x81a9,0xb1ca,0xa1eb,0xd10c,0xc12d,0xf14e,0xe16f,
    0x1080,0x00a1,0x30c2,0x20e3,0x5004,0x4025,0x7046,0x6067,
    0x83b9,0x9398,0xa3fb,0xb3da,0xc33d,0xd31c,0xe37f,0xf35e,
    0x02b1,0x1290,0x22f3,0x32d2,0x4235,0x5214,0x6277,0x7256,
    0xb5ea,0xa5cb,0x95a8,0x8589,0xf56e,0xe54f,0xd52c,0xc50d,
    0x34e2,0x24c3,0x14a0,0x0481,0x7466,0x6447,0x5424,0x4405,
    0xa7db,0xb7fa,0x8799,0x97b8,0xe75f,0xf77e,0xc71d,0xd73c,
    0x26d3,0x36f2,0x0691,0x16b0,0x6657,0x7676,0x4615,0x5634,
    0xd94c,0xc96d,0xf90e,0xe92f,0x99c8,0x89e9,0xb98a,0xa9ab,
    0x5844,0x4865,0x7806,0x6827,0x18c0,0x08e1,0x3882,0x28a3,
    0xcb7d,0xdb5c,0xeb3f,0xfb1e,0x8bf9,0x9bd8,0xabbb,0xbb9a,
    0x4a75,0x5a54,0x6a37,0x7a16,0x0af1,0x1ad0,0x2ab3,0x3a92,
    0xfd2e,0xed0f,0xdd6c,0xcd4d,0xbdaa,0xad8b,0x9de8,0x8dc9,
    0x7c26,0x6c07,0x5c64,0x4c45,0x3ca2,0x2c83,0x1ce0,0x0cc1,
    0xef1f,0xff3e,0xcf5d,0xdf7c,0xaf9b,0xbfba,0x8fd9,0x9ff8,
    0x6e17,0x7e36,0x4e55,0x5e74,0x2e93,0x3eb2,0x0ed1,0x1ef0
  ];

  /// 协议头部
  static const List<int> header = [0x55, 0xAA];
  
  /// 协议尾部
  static const List<int> footer = [0xAA, 0x55];

  /// 命令处理映射表
  final Map<int, Function(Uint8List, int)> _commands = {};
  
  /// 命令构建映射表
  final Map<int, Function(Map<String, dynamic>)> _writeCommands = {};

  /// 构造函数，初始化命令映射表
  BmsProtocol() {
    _initializeCommands();
    _initializeWriteCommands();
  }

  /// 初始化命令处理映射表
  void _initializeCommands() {
    _commands[0x00] = _deal00;
    _commands[0x01] = _deal01;
    _commands[0x02] = _deal02;
    _commands[0x03] = _deal03;
    _commands[0x04] = _deal04;
    _commands[0x06] = _deal06;
    _commands[0x08] = _deal08;
    _commands[0x0A] = _deal0A;
    _commands[0x0C] = _deal0C;
    _commands[0x0E] = _deal0E;
    _commands[0x0F] = _deal0F;
    _commands[0x10] = _deal10;
    _commands[0x11] = _deal11;
    _commands[0x12] = _deal12;
    _commands[0x13] = _deal13;
    _commands[0x14] = _deal14;
    _commands[0x15] = _deal15;
    _commands[0x16] = _deal16;
    _commands[0x17] = _deal17;
    _commands[0x18] = _deal18;
    _commands[0x19] = _deal19;
    _commands[0x1A] = _deal1A;
    _commands[0x1B] = _deal1B;
    _commands[0x1C] = _deal1C;
    _commands[0x1D] = _deal1D;
    _commands[0x1E] = _deal1E;
    _commands[0x1F] = _deal1F;
    _commands[0x206] = _deal206;
  }

  /// 初始化命令构建映射表
  void _initializeWriteCommands() {
    _writeCommands[0x200] = _build200Command;
    _writeCommands[0x0000] = _build0000Command;
    _writeCommands[0x0001] = _build0001Command;
    _writeCommands[0x0002] = _build0002Command;
    _writeCommands[0x0003] = _build0003Command;
    _writeCommands[0x0004] = _build0004Command;
    _writeCommands[0x0006] = _build0006Command;
    _writeCommands[0x0007] = _build0007Command;
    _writeCommands[0x0101] = _build0101Command;
  }

  /// 计算CRC16校验
  static int calculateCRC(Uint8List data) {
    int crc = 0xFFFF;
    for (int byte in data) {
      crc = ((crc << 8) & 0xFFFF) ^ _crc16Tab[((crc >> 8) & 0xFF) ^ byte];
    }
    return crc & 0xFFFF;
  }

  /// 解析接收到的数据
  Map<String, dynamic> parse(Uint8List data) {
    Map<String, dynamic> result = {};
    
    // 最小帧长度校验
    if (data.length < 5) {
      result['error'] = 1;
      return result;
    }

    // CRC校验
    Uint8List dataPart = data.sublist(0, data.length - 2);
    int receivedCrc = (data[data.length - 2] & 0xFF) | 
                      ((data[data.length - 1] & 0xFF) << 8);
    if (calculateCRC(dataPart) != receivedCrc) {
      result['error'] = 1;
      return result;
    }

    // 基础字段解析
    int address = data[0] & 0xFF;
    int writeOrread = data[1] & 0xFF;
    int funcCodeH = data[2] & 0xFF;
    int funcCodeL = data[3] & 0xFF;
    int funcCode = (funcCodeH << 8) | funcCodeL;
    int dataLen = data[4] & 0xFF;
    
    // 调用命令处理函数
    result = procCommand(dataLen, funcCode, dataPart);
    result['address'] = address;
    result['funcCode'] = funcCode;
    result['writeOrread'] = writeOrread;
    return result;
  }

  /// 处理命令
  Map<String, dynamic> procCommand(int dataLen, int cmd, Uint8List data) {
    if (_commands.containsKey(cmd)) {
      // 调用绑定的命令处理函数
      return _commands[cmd]!(data.sublist(5, 5 + dataLen), dataLen);
    }
    if (cmd >= 0x0020 && cmd <= 0x003F) {
      return paseCellVs(cmd, data);
    }
    if (cmd >= 0x418) {
      return paseUint32And2(data, dataLen);
    }
    return {'error': 2};
  }

  /// 解析单体电压数据
  Map<String, dynamic> paseCellVs(int cmd, Uint8List data) {
    Map<String, dynamic> result = {};
    List<double> cellVoltages = [];
    
    // 从第5个字节开始解析数据（跳过地址、读写标志、功能码、数据长度）
    int startIndex = 5;
    int dataLen = data[4];
    
    // 每个单体电压占2个字节
    for (int i = startIndex; i < startIndex + dataLen; i += 2) {
      if (i + 1 < data.length) {
        int value = (data[i] & 0xFF) | ((data[i + 1] & 0xFF) << 8);
        cellVoltages.add(value / 1000.0); // 转换为V单位
      }
    }
    
    result['command'] = cmd;
    result['cellVoltages'] = cellVoltages;
    return result;
  }

  /// 解析32位无符号整数和其他数据
  Map<String, dynamic> paseUint32And2(Uint8List data, int dataLen) {
    Map<String, dynamic> result = {};
    List<int> uint32Values = [];
    
    // 从第5个字节开始解析数据
    int startIndex = 5;
    
    // 解析32位无符号整数（每个占4个字节）
    for (int i = startIndex; i < startIndex + dataLen; i += 4) {
      if (i + 3 < data.length) {
        int value = (data[i] & 0xFF) |
                   ((data[i + 1] & 0xFF) << 8) |
                   ((data[i + 2] & 0xFF) << 16) |
                   ((data[i + 3] & 0xFF) << 24);
        uint32Values.add(value);
      }
    }
    
    result['command'] = data[2] | (data[3] << 8);
    result['uint32Values'] = uint32Values;
    return result;
  }

  /// 构建发送命令
  Uint8List buildCommand(int cmdId, Map<String, dynamic> data) {
    List<int> buffer = [];
    
    // 添加头部
    buffer.addAll(header);
    
    // 添加命令ID
    buffer.add(cmdId & 0xFF);
    buffer.add((cmdId >> 8) & 0xFF);

    // 构建数据部分
    Uint8List payload = Uint8List(0);
    if (data.containsKey('rawData') && data['rawData'] is List<int>) {
      // 处理原始数据格式
      payload = Uint8List.fromList(data['rawData'] as List<int>);
    } else if (_writeCommands.containsKey(cmdId)) {
      // 处理映射表中的命令
      payload = _writeCommands[cmdId]!(data) as Uint8List;
    }
    
    // 添加数据长度
    buffer.add(payload.length & 0xFF);
    buffer.add((payload.length >> 8) & 0xFF);
    
    // 添加数据
    buffer.addAll(payload);
    
    // 计算并添加CRC16
    final int crc = calculateCRC(Uint8List.fromList(buffer));
    buffer.add(crc & 0xFF);
    buffer.add((crc >> 8) & 0xFF);
    
    // 添加尾部
    buffer.addAll(footer);
    
    return Uint8List.fromList(buffer);
  }

  /// 旧版API兼容 - 封装写入数据指令
  Uint8List buildWriteCommand(int commandId, Uint8List data) {
    return buildCommand(commandId, {'rawData': data});
  }

  /// 验证协议格式
  bool validateProtocol(Uint8List data) {
    // 检查长度
    if (data.length < header.length + footer.length + 6) { // 头部+尾部+命令ID(2)+长度(2)+CRC16(2)
      return false;
    }
    
    // 检查头部
    for (int i = 0; i < header.length; i++) {
      if (data[i] != header[i]) {
        return false;
      }
    }
    
    // 检查尾部
    for (int i = 0; i < footer.length; i++) {
      if (data[data.length - footer.length + i] != footer[i]) {
        return false;
      }
    }
    
    // 验证CRC16
    final int crcPos = data.length - footer.length - 2;
    final int receivedCRC = (data[crcPos] << 8) | data[crcPos + 1];
    final int calculatedCRC = calculateCRC(data.sublist(0, crcPos));
    
    return receivedCRC == calculatedCRC;
  }

  /// 解析电池状态数据（兼容旧方法）
  BatteryData parseBatteryData(Uint8List data) {
    try {
      final Map<String, dynamic> parsedData = parse(data);
      return BatteryData(
        totalVoltage: parsedData['totalVoltage'] ?? 0.0,
        totalCurrent: parsedData['totalCurrent'] ?? 0.0,
        soc: parsedData['soc'] ?? 0,
        cellVoltages: parsedData['cellVoltages'] ?? [],
        temperatures: parsedData['temperatures'] ?? [],
        cycleCount: parsedData['cycleCount'] ?? 0,
      );
    } catch (e) {
      // 旧格式兼容处理
      if (!validateProtocol(data)) {
        throw FormatException('Invalid protocol format');
      }

      final int dataLen = data[3];
      final Uint8List payload = data.sublist(4, 4 + dataLen);
      
      return BatteryData(
        totalVoltage: _parseTotalVoltage(payload),
        totalCurrent: _parseTotalCurrent(payload),
        soc: _parseSoc(payload),
        cellVoltages: _parseCellVoltages(payload),
        temperatures: _parseTemperatures(payload),
        cycleCount: _parseCycleCount(payload),
      );
    }
  }

  /// 命令处理函数示例
  Map<String, dynamic> _deal00(Uint8List data, int dataLen) {
    // 处理0x00命令
    return _parseBatteryBasicData(data, dataLen);
  }

  Map<String, dynamic> _deal01(Uint8List data, int dataLen) {
    // 处理0x01命令
    return _parseCellVoltagesData(data, dataLen);
  }

  Map<String, dynamic> _deal02(Uint8List data, int dataLen) {
    // 处理0x02命令
    return _parseTemperaturesData(data, dataLen);
  }

  Map<String, dynamic> _deal03(Uint8List data, int dataLen) {
    // 处理0x03命令
    return {'command': 0x03, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal04(Uint8List data, int dataLen) {
    // 处理0x04命令
    return {'command': 0x04, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal06(Uint8List data, int dataLen) {
    // 处理0x06命令
    return {'command': 0x06, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal08(Uint8List data, int dataLen) {
    // 处理0x08命令
    return {'command': 0x08, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal0A(Uint8List data, int dataLen) {
    // 处理0x0A命令
    return {'command': 0x0A, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal0C(Uint8List data, int dataLen) {
    // 处理0x0C命令
    return {'command': 0x0C, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal0E(Uint8List data, int dataLen) {
    // 处理0x0E命令
    return {'command': 0x0E, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal0F(Uint8List data, int dataLen) {
    // 处理0x0F命令
    return {'command': 0x0F, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal10(Uint8List data, int dataLen) {
    // 处理0x10命令
    return {'command': 0x10, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal11(Uint8List data, int dataLen) {
    // 处理0x11命令
    return {'command': 0x11, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal12(Uint8List data, int dataLen) {
    // 处理0x12命令
    return {'command': 0x12, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal13(Uint8List data, int dataLen) {
    // 处理0x13命令
    return {'command': 0x13, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal14(Uint8List data, int dataLen) {
    // 处理0x14命令
    return {'command': 0x14, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal15(Uint8List data, int dataLen) {
    // 处理0x15命令
    return {'command': 0x15, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal16(Uint8List data, int dataLen) {
    // 处理0x16命令
    return {'command': 0x16, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal17(Uint8List data, int dataLen) {
    // 处理0x17命令
    return {'command': 0x17, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal18(Uint8List data, int dataLen) {
    // 处理0x18命令
    return {'command': 0x18, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal19(Uint8List data, int dataLen) {
    // 处理0x19命令
    return {'command': 0x19, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal1A(Uint8List data, int dataLen) {
    // 处理0x1A命令
    return {'command': 0x1A, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal1B(Uint8List data, int dataLen) {
    // 处理0x1B命令
    return {'command': 0x1B, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal1C(Uint8List data, int dataLen) {
    // 处理0x1C命令
    return {'command': 0x1C, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal1D(Uint8List data, int dataLen) {
    // 处理0x1D命令
    return {'command': 0x1D, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal1E(Uint8List data, int dataLen) {
    // 处理0x1E命令
    return {'command': 0x1E, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal1F(Uint8List data, int dataLen) {
    // 处理0x1F命令
    return {'command': 0x1F, 'data': data, 'length': dataLen};
  }

  Map<String, dynamic> _deal206(Uint8List data, int dataLen) {
    // 处理0x206命令
    return {'command': 0x206, 'data': data, 'length': dataLen};
  }

  /// 命令构建函数示例
  Uint8List _build200Command(Map<String, dynamic> data) {
    // 构建0x200命令
    final List<int> buffer = [];
    // 根据data内容构建命令
    return Uint8List.fromList(buffer);
  }

  Uint8List _build0000Command(Map<String, dynamic> data) {
    // 构建0x0000命令
    final List<int> buffer = [];
    // 根据data内容构建命令
    return Uint8List.fromList(buffer);
  }

  Uint8List _build0001Command(Map<String, dynamic> data) {
    // 构建0x0001命令
    final List<int> buffer = [];
    // 根据data内容构建命令
    return Uint8List.fromList(buffer);
  }

  Uint8List _build0002Command(Map<String, dynamic> data) {
    // 构建0x0002命令
    final List<int> buffer = [];
    // 根据data内容构建命令
    return Uint8List.fromList(buffer);
  }

  Uint8List _build0003Command(Map<String, dynamic> data) {
    // 构建0x0003命令
    final List<int> buffer = [];
    // 根据data内容构建命令
    return Uint8List.fromList(buffer);
  }

  Uint8List _build0004Command(Map<String, dynamic> data) {
    // 构建0x0004命令
    final List<int> buffer = [];
    // 根据data内容构建命令
    return Uint8List.fromList(buffer);
  }

  Uint8List _build0006Command(Map<String, dynamic> data) {
    // 构建0x0006命令
    final List<int> buffer = [];
    // 根据data内容构建命令
    return Uint8List.fromList(buffer);
  }

  Uint8List _build0007Command(Map<String, dynamic> data) {
    // 构建0x0007命令
    final List<int> buffer = [];
    // 根据data内容构建命令
    return Uint8List.fromList(buffer);
  }

  Uint8List _build0101Command(Map<String, dynamic> data) {
    // 构建0x0101命令
    final List<int> buffer = [];
    // 根据data内容构建命令
    return Uint8List.fromList(buffer);
  }

  /// 解析基本电池数据
  Map<String, dynamic> _parseBatteryBasicData(Uint8List data, int dataLen) {
    return {
      'command': 0x00,
      'totalVoltage': _parseTotalVoltage(data),
      'totalCurrent': _parseTotalCurrent(data),
      'soc': _parseSoc(data),
      'cycleCount': _parseCycleCount(data),
    };
  }

  /// 解析单体电压数据
  Map<String, dynamic> _parseCellVoltagesData(Uint8List data, int dataLen) {
    return {
      'command': 0x01,
      'cellVoltages': _parseCellVoltages(data),
    };
  }

  /// 解析温度数据
  Map<String, dynamic> _parseTemperaturesData(Uint8List data, int dataLen) {
    return {
      'command': 0x02,
      'temperatures': _parseTemperatures(data),
    };
  }

  /// 解析总电压
  double _parseTotalVoltage(Uint8List payload) {
    final int value = (payload[0] << 8) | payload[1];
    return value / 100.0; // 单位：0.01V
  }

  /// 解析总电流
  double _parseTotalCurrent(Uint8List payload) {
    final int value = (payload[2] << 8) | payload[3];
    return value / 100.0; // 单位：0.01A
  }

  /// 解析SOC
  int _parseSoc(Uint8List payload) {
    return payload[4]; // 单位：%
  }

  /// 解析单体电压
  List<double> _parseCellVoltages(Uint8List payload) {
    final List<double> voltages = [];
    // 假设从第5个字节开始，每个单体电压占2个字节
    for (int i = 5; i < payload.length - 4; i += 2) {
      final int value = (payload[i] << 8) | payload[i + 1];
      voltages.add(value / 1000.0); // 单位：0.001V
    }
    return voltages;
  }

  /// 解析温度
  List<double> _parseTemperatures(Uint8List payload) {
    final List<double> temps = [];
    // 假设温度数据在单体电压之后
    final int tempStart = 5 + (_parseCellVoltages(payload).length * 2);
    for (int i = tempStart; i < payload.length - 2; i += 2) {
      final int value = (payload[i] << 8) | payload[i + 1];
      temps.add(value / 10.0 - 273.15); // 单位：℃
    }
    return temps;
  }

  /// 解析循环次数
  int _parseCycleCount(Uint8List payload) {
    return (payload[payload.length - 2] << 8) | payload[payload.length - 1];
  }
}

/// 电池数据模型
class BatteryData {
  final double totalVoltage; // 总电压 (V)
  final double totalCurrent; // 总电流 (A)
  final int soc; // 剩余电量 (%)
  final List<double> cellVoltages; // 单体电压 (V)
  final List<double> temperatures; // 温度 (℃)
  final int cycleCount; // 循环次数

  BatteryData({
    required this.totalVoltage,
    required this.totalCurrent,
    required this.soc,
    required this.cellVoltages,
    required this.temperatures,
    required this.cycleCount,
  });

  @override
  String toString() {
    return 'BatteryData{totalVoltage: $totalVoltage, totalCurrent: $totalCurrent, soc: $soc}';
  }
}