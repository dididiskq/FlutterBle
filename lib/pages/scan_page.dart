import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:ultra_bms/bluetooth/ble_controller.dart';
import 'package:ultra_bms/managers/language_manager.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _isPermissionGranted = false;
  String? _scanResult;
  bool _isConnecting = false;
  String _connectionStatus = '';
  
  // 连接相关流订阅
  StreamSubscription<ConnectionStateUpdate>? _connectionStateSubscription;
  StreamSubscription<ConnectionResultData>? _connectionResultSubscription;
  StreamSubscription<BleDevice>? _connectedDeviceSubscription;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    
    // 获取BleController单例实例
    final bleController = BleController();
    
    // 监听连接状态变化
    _connectionStateSubscription = bleController.connectionStateStream.listen((state) {
      print('[ScanPage] 连接状态变化: ${state.connectionState}');
      
      if (mounted) {
        setState(() {
          // 可以根据连接状态更新UI
        });
      }
    });
    
    // 监听连接结果
    _connectionResultSubscription = bleController.connectionResultStream.listen((result) {
      print('[ScanPage] 连接结果: ${result.result}');
      
      if (mounted) {
        if (result.result == ConnectionResult.success) {
          print('[ScanPage] 连接成功！');
        } else {
          print('[ScanPage] 连接失败: ${result.message}');
          
          setState(() {
            _isConnecting = false;
            _connectionStatus = '连接失败：${result.message}';
          });
          
          // 显示错误提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_connectionStatus)),
          );
          
          // 重置扫描结果，允许重新扫描
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _scanResult = null;
                _connectionStatus = '';
              });
            }
          });
        }
      }
    });
    
    // 监听连接成功设备
    _connectedDeviceSubscription = bleController.connectedDeviceStream.listen((device) {
      print('[ScanPage] 连接成功设备: ${device.name}');
      
      if (mounted && device.isConnected) {
        // 设备连接成功，自动返回首页
        Navigator.pop(context, device.name);
      }
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
    } else {
      // 权限被拒绝，显示提示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('摄像头权限被拒绝')),
        );
      });
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    print('二维码扫描器已创建');
    
    // 启用连续扫描
    controller.scannedDataStream.listen((scanData) {
      if (_scanResult == null) { // 避免重复处理
        print('检测到扫描数据');
        
        // 检查页面是否仍在挂载状态
        if (mounted) {
          setState(() {
            _scanResult = scanData.code;
            _isConnecting = true;
            _connectionStatus = '正在解析二维码...';
          });
        }
        
        print('二维码识别结果: ${scanData.code}');
        
        if (scanData.code != null) {
          _handleScanResult(scanData.code!);
        }
      }
    });
  }
  
  Future<void> _handleScanResult(String result) async {
    // 检查页面是否仍在挂载状态
    if (!mounted) return;
    
    try {
      // 解析二维码内容
      final parts = result.split('|');
      
      // 显示请稍后提示
      if (mounted) {
        setState(() {
          _connectionStatus = '请稍后，正在连接设备...';
        });
      }
      
      // 获取BleController单例实例
      final bleController = BleController();
      String deviceId;
      String deviceName;
      
      // 根据平台和二维码格式选择连接策略
      if (Platform.isAndroid) {
        // Android平台
        deviceId = parts[0];
        
        if (parts.length > 1) {
          // 第二种二维码：mac|name格式
          deviceName = parts[1];
          
          print('[ScanPage] Android连接 - 设备ID: $deviceId, 设备名称: $deviceName');
          
          // 直接连接设备
          await bleController.connectToDevice(deviceId, deviceName: deviceName);
        } else {
          // 第一种二维码：只有mac地址，需要先扫描获取设备实际名称
          print('[ScanPage] Android连接 - 旧二维码，正在扫描设备，获取实际名称');
          
          // 更新连接状态提示
          if (mounted) {
            setState(() {
              _connectionStatus = '正在扫描设备，获取名称...';
            });
          }
          
          // 扫描设备，查找匹配mac地址的设备
          deviceName = await _scanDeviceAndGetName(deviceId);
          
          print('[ScanPage] Android连接 - 设备ID: $deviceId, 实际设备名称: $deviceName');
          
          // 连接设备
          await bleController.connectToDevice(deviceId, deviceName: deviceName);
        }
      } else {
        // iOS平台：需要根据二维码格式处理
        if (parts.length == 1) {
          // 第一种二维码：只有mac地址，iOS无法直接连接
          throw Exception('iOS设备不支持仅包含MAC地址的二维码');
        } else {
          // 第二种二维码：mac|name格式
          final expectedName = parts[1];
          deviceName = expectedName;
          
          print('[ScanPage] iOS连接 - 正在扫描设备，匹配名称: $expectedName');
          
          // 扫描并查找匹配名称的设备
          deviceId = await bleController.scanAndFindDeviceByName(expectedName);
          
          print('[ScanPage] iOS连接 - 匹配成功，设备ID: $deviceId');
          
          // 连接设备
          await bleController.connectToDevice(deviceId, deviceName: deviceName);
        }
      }
      
      // 检查页面是否仍在挂载状态
      if (!mounted) return;
      
      // 连接成功，自动返回首页，传递实际设备名称
      Navigator.pop(context, deviceName);
      
    } catch (e) {
      // 检查页面是否仍在挂载状态
      if (!mounted) return;
      
      setState(() {
        _isConnecting = false;
        _connectionStatus = '连接失败：$e';
      });
      
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_connectionStatus)),
      );
      
      // 重置扫描结果，允许重新扫描
      await Future.delayed(const Duration(seconds: 2));
      
      // 再次检查页面是否仍在挂载状态
      if (!mounted) return;
      
      setState(() {
        _scanResult = null;
        _connectionStatus = '';
      });
    }
  }
  
  /// 扫描设备并根据mac地址获取设备名称
  Future<String> _scanDeviceAndGetName(String macAddress, {Duration timeout = const Duration(seconds: 5)}) async {
    print('[ScanPage] 开始扫描设备，获取MAC地址为 $macAddress 的设备名称，超时时间: ${timeout.inSeconds}秒');
    
    final Completer<String> completer = Completer<String>();
    StreamSubscription<DiscoveredDevice>? subscription;
    Timer? timeoutTimer;
    
    try {
      // 开始扫描
      subscription = FlutterReactiveBle().scanForDevices(
        withServices: [], // 扫描所有设备
        scanMode: ScanMode.lowLatency, // 快速扫描
      ).listen((device) {
        print('[ScanPage] 扫描到设备: ${device.name}, ID: ${device.id}');
        
        // 检查设备ID是否匹配mac地址（Android设备ID通常是mac地址）
        if (device.id.toLowerCase() == macAddress.toLowerCase()) {
          String actualName = device.name.isNotEmpty ? device.name : '未知设备';
          print('[ScanPage] 找到匹配设备: MAC=$macAddress, 名称: $actualName');
          
          // 取消超时计时器
          timeoutTimer?.cancel();
          
          // 完成并返回实际设备名称
          if (!completer.isCompleted) {
            completer.complete(actualName);
          }
        }
      }, onError: (error) {
        print('[ScanPage] 扫描设备时发生错误: $error');
        if (!completer.isCompleted) {
          completer.completeError(Exception('扫描设备失败: $error'));
        }
      });
      
      // 设置超时，超时后返回默认名称
      timeoutTimer = Timer(timeout, () {
        print('[ScanPage] 扫描设备超时，使用默认设备名称');
        if (!completer.isCompleted) {
          // 超时后使用mac地址作为设备名称
          completer.complete(macAddress);
        }
      });
      
      // 等待结果
      return await completer.future;
    } finally {
      // 清理资源
      subscription?.cancel();
      timeoutTimer?.cancel();
      print('[ScanPage] 扫描设备流程结束');
    }
  }

  @override
  void dispose() {
    // 取消连接相关流订阅
    _connectionStateSubscription?.cancel();
    _connectionResultSubscription?.cancel();
    _connectedDeviceSubscription?.cancel();
    
    // 释放相机控制器资源
    _controller?.dispose();
    _controller = null;
    
    // 重置扫描结果，防止后续操作继续执行
    _scanResult = null;
    _isConnecting = false;
    _connectionStatus = '';
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageManager>(
      builder: (context, languageManager, child) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: Container(
              color: Colors.black, // 设置背景色为黑色，与底部导航栏一致
              padding: const EdgeInsets.fromLTRB(10.0, 44.0, 10.0, 10.0),
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 返回按钮
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(languageManager.backButtonText),
                  ),
                  // 页面标题
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Text(
                      languageManager.scanPageTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 占位符，保持按钮居中
                  const SizedBox(width: 60),
                ],
              ),
            ),
          ),
          body: _isPermissionGranted
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // 二维码扫描预览 - 确保在最底层显示原始画面
                    Positioned.fill(
                      child: QRView(
                        key: qrKey,
                        onQRViewCreated: _onQRViewCreated,
                        overlay: null, // 完全移除默认覆盖层
                      ),
                    ),
                    // 自定义扫描框
                    _buildScanFrame(languageManager),
                    // 连接状态提示
                    if (_isConnecting)
                      Positioned(
                        top: 100,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            color: Colors.black.withOpacity(0.8),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 10),
                                Text(
                                  _connectionStatus,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Center(child: Text(languageManager.needCameraPermission)),
        );
      },
    );
  }

  Widget _buildScanFrame(LanguageManager languageManager) {  
    final size = MediaQuery.of(context).size;
    final scanFrameSize = size.width * 0.7;
    final scanFrameOffset = (size.width - scanFrameSize) / 2;

    return Stack(
      children: [
        // 半透明遮罩（使用CustomPaint实现镂空效果）
        Positioned.fill(
          child: CustomPaint(
            painter: _ScanMaskPainter(
              frameSize: scanFrameSize,
              frameOffset: scanFrameOffset,
            ),
          ),
        ),
        // 扫描框边框和角
        Positioned.fill(
          child: CustomPaint(
            painter: _ScanFramePainter(
              frameSize: scanFrameSize,
              frameOffset: scanFrameOffset,
            ),
          ),
        ),
        // 扫描提示文字
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              languageManager.alignQrCodeToFrame,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 绘制半透明遮罩（外部半透明，中间完全透明）
class _ScanMaskPainter extends CustomPainter {
  final double frameSize;
  final double frameOffset;

  _ScanMaskPainter({
    required this.frameSize,
    required this.frameOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 计算扫描框位置
    final scanRect = Rect.fromLTWH(
      frameOffset,
      (size.height - frameSize) / 2,
      frameSize,
      frameSize,
    );

    // 绘制四个角落的半透明遮罩
    // 左上角
    canvas.drawRect(
      Rect.fromLTWH(0, 0, scanRect.left, scanRect.top),
      Paint()..color = Colors.black.withOpacity(0.5),
    );
    // 右上角
    canvas.drawRect(
      Rect.fromLTWH(scanRect.right, 0, size.width - scanRect.right, scanRect.top),
      Paint()..color = Colors.black.withOpacity(0.5),
    );
    // 左下角
    canvas.drawRect(
      Rect.fromLTWH(0, scanRect.bottom, scanRect.left, size.height - scanRect.bottom),
      Paint()..color = Colors.black.withOpacity(0.5),
    );
    // 右下角
    canvas.drawRect(
      Rect.fromLTWH(scanRect.right, scanRect.bottom, size.width - scanRect.right, size.height - scanRect.bottom),
      Paint()..color = Colors.black.withOpacity(0.5),
    );
    // 左边
    canvas.drawRect(
      Rect.fromLTWH(0, scanRect.top, scanRect.left, scanRect.height),
      Paint()..color = Colors.black.withOpacity(0.5),
    );
    // 右边
    canvas.drawRect(
      Rect.fromLTWH(scanRect.right, scanRect.top, size.width - scanRect.right, scanRect.height),
      Paint()..color = Colors.black.withOpacity(0.5),
    );
    // 上边
    canvas.drawRect(
      Rect.fromLTWH(scanRect.left, 0, scanRect.width, scanRect.top),
      Paint()..color = Colors.black.withOpacity(0.5),
    );
    // 下边
    canvas.drawRect(
      Rect.fromLTWH(scanRect.left, scanRect.bottom, scanRect.width, size.height - scanRect.bottom),
      Paint()..color = Colors.black.withOpacity(0.5),
    );
  }

  @override
  bool shouldRepaint(_ScanMaskPainter oldDelegate) {
    return oldDelegate.frameSize != frameSize ||
        oldDelegate.frameOffset != frameOffset;
  }
}

// 绘制扫描框边框和角
class _ScanFramePainter extends CustomPainter {
  final double frameSize;
  final double frameOffset;

  _ScanFramePainter({
    required this.frameSize,
    required this.frameOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制扫描框边框
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(frameOffset, (size.height - frameSize) / 2, frameSize, frameSize);
    canvas.drawRect(rect, borderPaint);

    // 绘制四个角
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerSize = 30.0;

    // 左上角
    canvas.drawLine(
      Offset(frameOffset, rect.top),
      Offset(frameOffset + cornerSize, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameOffset, rect.top),
      Offset(frameOffset, rect.top + cornerSize),
      cornerPaint,
    );

    // 右上角
    canvas.drawLine(
      Offset(rect.right - cornerSize, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerSize),
      cornerPaint,
    );

    // 左下角
    canvas.drawLine(
      Offset(frameOffset, rect.bottom),
      Offset(frameOffset, rect.bottom - cornerSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(frameOffset, rect.bottom),
      Offset(frameOffset + cornerSize, rect.bottom),
      cornerPaint,
    );

    // 右下角
    canvas.drawLine(
      Offset(rect.right - cornerSize, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerSize),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) {
    return oldDelegate.frameSize != frameSize ||
        oldDelegate.frameOffset != frameOffset;
  }
}