import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
      _initializeCamera();
    } else {
      // 权限被拒绝，显示提示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('摄像头权限被拒绝')),
        );
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // 获取所有可用摄像头
      _cameras = await availableCameras();
      
      // 选择后置摄像头
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // 初始化摄像头控制器，明确设置适合预览的图像格式
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        
        imageFormatGroup: Platform.isIOS 
            ? ImageFormatGroup.bgra8888 
            : ImageFormatGroup.nv21,
      );

      // 初始化摄像头
      await _cameraController!.initialize();
      
      // 开始预览
      await _cameraController!.startImageStream((CameraImage image) {
        // 打印视频帧数据
        print('视频帧数据: 宽度=${image.width}, 高度=${image.height}, 平面数=${image.planes.length}');
        // 这里可以添加后续的解码逻辑
      });

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('初始化摄像头失败: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫一扫'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isPermissionGranted
          ? _isCameraInitialized
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // 摄像头预览
                    CameraPreview(_cameraController!),
                    // 扫描框
                    _buildScanFrame(),
                  ],
                )
              : const Center(child: CircularProgressIndicator())
          : const Center(child: Text('需要摄像头权限')),
    );
  }

  Widget _buildScanFrame() {  
    final size = MediaQuery.of(context).size;
    final scanFrameSize = size.width * 0.7;
    final scanFrameOffset = (size.width - scanFrameSize) / 2;

    return Stack(
      children: [
        // 半透明遮罩
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0),
            child: CustomPaint(
              painter: _ScanFramePainter(
                frameSize: scanFrameSize,
                frameOffset: scanFrameOffset,
              ),
            ),
          ),
        ),
        // 扫描提示文字
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              '请将二维码对准扫描框',
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

class _ScanFramePainter extends CustomPainter {
  final double frameSize;
  final double frameOffset;

  _ScanFramePainter({
    required this.frameSize,
    required this.frameOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制路径
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height)) // 外部大矩形
      ..addRect(Rect.fromLTWH(frameOffset, (size.height - frameSize) / 2, frameSize, frameSize)); // 内部扫描框（镂空）

    // 使用黑色半透明颜色填充外部区域
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    // 绘制路径
    canvas.drawPath(path, paint);

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