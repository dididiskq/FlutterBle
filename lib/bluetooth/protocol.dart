import 'dart:typed_data';

/// BMS协议解析和封装类
class BmsProtocol {
  /// 协议头部
  static const List<int> header = [0x55, 0xAA];
  
  /// 协议尾部
  static const List<int> footer = [0xAA, 0x55];

  /// 解析电池状态数据
  BatteryData parseBatteryData(Uint8List data) {
    // 验证协议格式
    if (!validateProtocol(data)) {
      throw FormatException('Invalid protocol format');
    }

    // 解析数据部分
    final Uint8List payload = extractPayload(data);
    
    // 创建电池数据对象
    return BatteryData(
      totalVoltage: _parseTotalVoltage(payload),
      totalCurrent: _parseTotalCurrent(payload),
      soc: _parseSoc(payload),
      cellVoltages: _parseCellVoltages(payload),
      temperatures: _parseTemperatures(payload),
      cycleCount: _parseCycleCount(payload),
      // 其他字段...
    );
  }

  /// 封装写入数据指令
  Uint8List buildWriteCommand(int commandId, Uint8List data) {
    final List<int> buffer = [];
    
    // 添加头部
    buffer.addAll(header);
    
    // 添加命令ID
    buffer.add(commandId);
    
    // 添加数据长度
    buffer.add(data.length);
    
    // 添加数据
    buffer.addAll(data);
    
    // 添加校验和
    buffer.add(_calculateChecksum(buffer));
    
    // 添加尾部
    buffer.addAll(footer);
    
    return Uint8List.fromList(buffer);
  }

  /// 验证协议格式
  bool validateProtocol(Uint8List data) {
    // 检查长度
    if (data.length < header.length + footer.length + 3) { // 头部+尾部+命令ID+长度+校验和
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
    
    // 验证校验和
    final int checksum = data[data.length - footer.length - 1];
    final int calculatedChecksum = _calculateChecksum(data.sublist(0, data.length - footer.length - 1));
    
    return checksum == calculatedChecksum;
  }

  /// 提取数据部分
  Uint8List extractPayload(Uint8List data) {
    final int dataLength = data[header.length + 1];
    final int payloadStart = header.length + 2;
    final int payloadEnd = payloadStart + dataLength;
    
    return data.sublist(payloadStart, payloadEnd);
  }

  /// 计算校验和
  int _calculateChecksum(List<int> data) {
    int sum = 0;
    for (int byte in data) {
      sum += byte;
    }
    return sum & 0xFF;
  }

  /// 解析总电压
  double _parseTotalVoltage(Uint8List payload) {
    // 根据实际协议格式解析
    final int value = (payload[0] << 8) | payload[1];
    return value / 100.0; // 假设单位为0.01V
  }

  /// 解析总电流
  double _parseTotalCurrent(Uint8List payload) {
    // 根据实际协议格式解析
    final int value = (payload[2] << 8) | payload[3];
    return value / 100.0; // 假设单位为0.01A
  }

  /// 解析SOC
  int _parseSoc(Uint8List payload) {
    // 根据实际协议格式解析
    return payload[4];
  }

  /// 解析单体电压
  List<double> _parseCellVoltages(Uint8List payload) {
    // 根据实际协议格式解析
    final List<double> voltages = [];
    // 假设从第5个字节开始，每个单体电压占2个字节
    for (int i = 5; i < payload.length - 4; i += 2) {
      final int value = (payload[i] << 8) | payload[i + 1];
      voltages.add(value / 1000.0); // 假设单位为0.001V
    }
    return voltages;
  }

  /// 解析温度
  List<double> _parseTemperatures(Uint8List payload) {
    // 根据实际协议格式解析
    final List<double> temps = [];
    // 假设温度数据在单体电压之后
    final int tempStart = 5 + (_parseCellVoltages(payload).length * 2);
    for (int i = tempStart; i < payload.length - 2; i += 2) {
      final int value = (payload[i] << 8) | payload[i + 1];
      temps.add(value / 10.0 - 273.15); // 假设原始数据是K，转换为℃
    }
    return temps;
  }

  /// 解析循环次数
  int _parseCycleCount(Uint8List payload) {
    // 根据实际协议格式解析
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
  // 其他字段...

  BatteryData({
    required this.totalVoltage,
    required this.totalCurrent,
    required this.soc,
    required this.cellVoltages,
    required this.temperatures,
    required this.cycleCount,
    // 其他字段...
  });

  @override
  String toString() {
    return 'BatteryData{totalVoltage: $totalVoltage, totalCurrent: $totalCurrent, soc: $soc}';
  }
}