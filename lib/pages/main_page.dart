import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ultra_bms/bluetooth/ble_controller.dart';
import 'package:ultra_bms/managers/battery_data_manager.dart';
import 'package:ultra_bms/models/battery_data.dart';
import 'package:ultra_bms/pages/device_list_page.dart';
import 'package:ultra_bms/pages/scan_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  // BLE控制器（单例）
  final BleController _bleController = BleController();
  
  // 电池数据管理器（单例）
  final BatteryDataManager _batteryDataManager = BatteryDataManager();
  
  // 是否首次加载数据（用于控制动画）
  bool _isFirstLoad = true;
  
  // 设备连接状态
  bool isConnected = false;
  String deviceName = "请先连接设备";
  
  // 更新设备名称和连接状态
  void _updateDeviceInfo(String name) {
    setState(() {
      deviceName = name;
      isConnected = true;
    });
  }
  
  // 重置设备信息（断开连接时调用）
  void _resetDeviceInfo() {
    setState(() {
      deviceName = "请先连接设备";
      isConnected = false;
    });
  }
  
  // 电池数据
  double socValue = 0.0; // SOC百分比（初始值设为50，避免0值导致绘制问题）
  double totalCurrent = 0.0; // 总电流
  double totalVoltage = 0.0; // 总电压
  double totalPower = 0.0; // 总功率
  double totalCapacity = 0.0; // 总容量
  
  // 充电状态
  int chargeStatus = 0;
  //放电状态
  int dischargeStatus = 0;


  // 温度数据
  double t1Temp = 0.0;
  double t2Temp = 0.0;
  double mosTemp = 0.0;
  
  // 异常数据
  int alarmCount = 0;
  int cycleCount = 0;
  double voltageDiff = 0.0;
  
  // 动画控制器
  late AnimationController _socAnimationController;
  late Animation<double> _socAnimation;
  
  // 防抖定时器
  Timer? _updateTimer;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _socAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // 从单例中恢复连接状态和电池数据（在setState之前）
    _restoreConnectionState();
    _restoreBatteryData();
    
    // 统一触发一次UI更新
    setState(() {
      // 状态已经在恢复方法中设置，这里只需要触发更新
    });
    
    // 监听设备连接状态变化
    _bleController.connectedDeviceStream.listen((device) {
      if (device.isConnected) {
        _updateDeviceInfo(device.name);
        // 连接成功后自动启动电池电量读取
        _batteryDataManager.readAllData();
        // _batteryDataManager.startBatteryLevelReading();
      } else {
        _resetDeviceInfo();
        // 设备断开连接后停止自动读取
        _batteryDataManager.stopAutoRead();
        _batteryDataManager.stopBatteryLevelReading();
      }
    });
    
    // 监听电池数据更新
    _batteryDataManager.batteryDataStream.listen((data) {
      if (mounted) {
        // 使用防抖定时器，避免频繁更新UI
        _updateTimer?.cancel();
        _updateTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              socValue = data.soc.toDouble();
              totalVoltage = data.voltage;
              totalCurrent = data.current;
              totalCapacity = data.capacity;
              totalPower = data.voltage * data.current;
              cycleCount = data.cycleCount;
              // 更新充放电状态
              chargeStatus = data.chargeStatus;
              dischargeStatus = data.dischargeStatus;
              // 更新温度数据
              t1Temp = data.batteryTemperature1;            
              t2Temp = data.batteryTemperature2;
              mosTemp = data.batteryTemperatureMos;
              
              // 计算压差
              if (data.cellVoltages.isNotEmpty && data.cellVoltages.length >= 2) {
                final maxVoltage = data.cellVoltages.reduce((a, b) => a > b ? a : b);
                final minVoltage = data.cellVoltages.reduce((a, b) => a < b ? a : b);
                voltageDiff = maxVoltage - minVoltage;
              }
            
              
              // 首次加载完成后标记为非首次
              _isFirstLoad = false;
            });
          }
        });
      }
    });
    
    // 监听 BLE 通知数据
    _bleController.notificationStream.listen((data) {
      _batteryDataManager.handleResponse(Uint8List.fromList(data));
      // _batteryDataManager.handleBatteryLevelResponse(Uint8List.fromList(data));
    });
  }
  
  // 从单例中恢复连接状态
  void _restoreConnectionState() {
    final connectedDevice = _bleController.connectedDevice;
    if (connectedDevice != null) {
      print('[MainPage] 恢复连接状态: ${connectedDevice.name}');
      deviceName = connectedDevice.name.isNotEmpty ? connectedDevice.name : '已连接设备';
      isConnected = true;
    }
  }
  
  // 从单例中恢复电池数据
  void _restoreBatteryData() {
    final currentData = _batteryDataManager.currentData;
    if (currentData.isNotEmpty) {
      print('[MainPage] 恢复电池数据: SOC=${currentData.soc}%, SOH=${currentData.soh}%');
      
      // 直接更新数据，不使用动画
      socValue = currentData.soc.toDouble();
      totalVoltage = currentData.voltage;
      totalCurrent = currentData.current;
      totalCapacity = currentData.capacity;
      totalPower = currentData.voltage * currentData.current;
      cycleCount = currentData.cycleCount;
      
      // 恢复温度数据 - 使用独立的温度字段
      t1Temp = currentData.batteryTemperature1;
      t2Temp = currentData.batteryTemperature2;
      mosTemp = currentData.batteryTemperatureMos;
      
      // 计算压差
      if (currentData.cellVoltages.isNotEmpty && currentData.cellVoltages.length >= 2) {
        final maxVoltage = currentData.cellVoltages.reduce((a, b) => a > b ? a : b);
        final minVoltage = currentData.cellVoltages.reduce((a, b) => a < b ? a : b);
        voltageDiff = maxVoltage - minVoltage;
      }
      
      // 标记为非首次加载，避免动画重新开始
      _isFirstLoad = false;
      
      print('[MainPage] 数据恢复完成，_isFirstLoad=$_isFirstLoad');
    }
  }
  
  @override
  void dispose() {
    _socAnimationController.dispose();
    _updateTimer?.cancel();
    // 不要销毁 BatteryDataManager，它是单例，应该在应用退出时才销毁
    // _batteryDataManager.dispose();
    // 不要销毁 BleController，它是单例，应该在应用退出时才销毁
    // _bleController.dispose();
    super.dispose();
  }
  

  
  // 更新SOC值并带动画
  void _updateSOCValue(double newValue) {
    _socAnimation = Tween<double>(begin: socValue, end: newValue).animate(
      CurvedAnimation(parent: _socAnimationController, curve: Curves.easeInOut)
    );
    
    _socAnimation.addListener(() {
      setState(() {
        socValue = _socAnimation.value;
      });
    });
    
    _socAnimationController.forward(from: 0);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          color: Colors.black, // 设置背景色为黑色，与底部导航栏一致
          padding: const EdgeInsets.fromLTRB(10.0, 44.0, 10.0, 10.0), // 调整padding避开状态栏
          alignment: Alignment.bottomCenter, // 垂直对齐到底部
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左侧设备列表按钮
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const DeviceListPage()),
                      );
                      if (result != null && result is String) {
                        _updateDeviceInfo(result);
                      }
                    },
                    child: const Text('设备列表'),
                  ),
                ),
              ),
              // ultra bms标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: const Text(
                  'Ultra Bms',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 右侧扫一扫按钮
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const ScanPage()),
                      );
                    },
                    child: const Text('扫一扫'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFF0A1128),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 80.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 设备连接状态
              Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: isConnected ? Colors.green : Colors.red, width: 2),
                ),
                child: Text(
                  deviceName,
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // SOC仪表盘
              SizedBox(
                height: 300.0,
                width: 300.0,
                child: CustomPaint(
                  painter: _SOCGaugePainter(socValue),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SOC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${socValue.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // 总容量和总功率
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2332),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '总容量',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                          ),
                        ),
                        Text(
                          '${totalCapacity.toStringAsFixed(2)}AH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2332),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '总功率',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                          ),
                        ),
                        Text(
                          '${totalPower.toStringAsFixed(2)}W',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20.0),
              
              // 电压和电流仪表盘
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 电压仪表盘
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      height: 150.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(15.0),
                        border: Border.all(color: Colors.purple, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: Colors.purple,
                            size: 40.0,
                          ),
                          Text(
                            '电压',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
                            ),
                          ),
                          Text(
                            '${totalVoltage.toStringAsFixed(1)}V',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 充电放电MOS
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      height: 150.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              const Text(
                                '充电MOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.0,
                                ),
                              ),
                              Icon(
                                Icons.circle,
                                color: _batteryDataManager.currentData.chargeMosOn ? Colors.green : Colors.red,
                                size: 20.0,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Column(
                            children: [
                              const Text(
                                '放电MOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.0,
                                ),
                              ),
                              Icon(
                                Icons.circle,
                                color: _batteryDataManager.currentData.dischargeMosOn ? Colors.green : Colors.red,
                                size: 20.0,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 电流仪表盘
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      height: 150.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(15.0),
                        border: Border.all(color: Colors.yellow, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.arrow_right,
                            color: Colors.yellow,
                            size: 40.0,
                          ),
                          Text(
                            '电流',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
                            ),
                          ),
                          Text(
                            '${totalCurrent.toStringAsFixed(1)}A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20.0),
              
              // 温度信息
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  children: [
                    const Text(
                      '电池温度',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Icon(
                              Icons.thermostat,
                              color: Colors.white,
                              size: 30.0,
                            ),
                            const SizedBox(height: 5.0),
                            const Text(
                              'T1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                            ),
                            Text(
                              '${t1Temp.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(
                              Icons.thermostat,
                              color: Colors.white,
                              size: 30.0,
                            ),
                            const SizedBox(height: 5.0),
                            const Text(
                              'T2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                            ),
                            Text(
                              '${t2Temp.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(
                              Icons.thermostat,
                              color: Colors.white,
                              size: 30.0,
                            ),
                            const SizedBox(height: 5.0),
                            const Text(
                              'MOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                              ),
                            ),
                            Text(
                              '${mosTemp.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20.0),
              
              // 异常信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning,
                            color: alarmCount > 0 ? Colors.red : Colors.green,
                            size: 30.0,
                          ),
                          const SizedBox(height: 5.0),
                          const Text(
                            '异常警报',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '$alarmCount',
                            style: TextStyle(
                              color: alarmCount > 0 ? Colors.red : Colors.green,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.refresh,
                            color: Colors.blue,
                            size: 30.0,
                          ),
                          const SizedBox(height: 5.0),
                          const Text(
                            '循环次数',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '$cycleCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      height: 100.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: Colors.yellow,
                            size: 30.0,
                          ),
                          const SizedBox(height: 5.0),
                          const Text(
                            '压差',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '${voltageDiff.toStringAsFixed(3)}V',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// SOC仪表盘绘制类
class _SOCGaugePainter extends CustomPainter {
  final double socValue;
  
  _SOCGaugePainter(this.socValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20.0;
    
    // 绘制背景圆环
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1A2332)
      ..strokeWidth = 20.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // 绘制刻度线
    final scalePaint = Paint()
      ..color = const Color(0xFF3A475E)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i <= 10; i++) {
      final angle = 135.0 + (i * 27.0); // 顺时针旋转45度，起始角度减少45度
      final radian = angle * (3.1415926 / 180.0);
      
      final startX = center.dx + (radius - 10.0) * cos(radian);
      final startY = center.dy + (radius - 10.0) * sin(radian);
      
      final endX = center.dx + radius * cos(radian);
      final endY = center.dy + radius * sin(radian);
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), scalePaint);
    }
    
    // 绘制数值标签
    final textPaint = Paint()
      ..color = Colors.white;
    
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    );
    
    final textSpan = TextSpan(
      style: textStyle,
      text: '',
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    final values = ['0', '20', '40', '60', '80', '100'];
    for (int i = 0; i < values.length; i++) {
      final angle = 135.0 + (i * 54.0); // 顺时针旋转45度，起始角度减少45度
      final radian = angle * (3.1415926 / 180.0);
      
      final x = center.dx + (radius - 35.0) * cos(radian);
      final y = center.dy + (radius - 35.0) * sin(radian);
      
      textPainter.text = TextSpan(
        style: textStyle,
        text: values[i],
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
    
    // 绘制蓝色圆弧
    final blueArcPaint = Paint()
      ..color = const Color(0xFF007AFF)
      ..strokeWidth = 20.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final startAngle = 135.0 * (3.1415926 / 180.0); // 顺时针旋转45度，起始角度减少45度
    final sweepAngle = (socValue / 100.0) * 270.0 * (3.1415926 / 180.0);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      blueArcPaint,
    );
    
    // 绘制指针
    final pointerPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final pointerAngle = 135.0 + (socValue / 100.0) * 270.0; // 顺时针旋转45度，起始角度减少45度
    final pointerRadian = pointerAngle * (3.1415926 / 180.0);
    
    final pointerStartX = center.dx;
    final pointerStartY = center.dy;
    
    final pointerEndX = center.dx + (radius - 40.0) * cos(pointerRadian);
    final pointerEndY = center.dy + (radius - 40.0) * sin(pointerRadian);
    
    canvas.drawLine(
      Offset(pointerStartX, pointerStartY),
      Offset(pointerEndX, pointerEndY),
      pointerPaint,
    );
    
    // 绘制指针中心点
    final centerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 8.0, centerPaint);
  }
  
  @override
  bool shouldRepaint(covariant _SOCGaugePainter oldDelegate) {
    return oldDelegate.socValue != socValue;
  }
}