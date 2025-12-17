import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

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
    } else {
      // 权限被拒绝，显示提示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('摄像头权限被拒绝')),
        );
      });
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _controller = controller;
    print('二维码扫描器已创建');
    
    // 启用连续扫描
    controller.scannedDataStream.listen((scanData) {
      print('检测到扫描数据');
      setState(() {
        _scanResult = scanData.code;
        print('二维码识别结果: $_scanResult');
        print('扫描数据详情: ${scanData.rawBytes}');
        print('识别格式: ${scanData.format}');
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: const Text('返回'),
              ),
              // 页面标题
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: const Text(
                  '扫一扫',
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
                _buildScanFrame(),
              ],
            )
          : const Center(child: Text('需要摄像头权限')),
    );
  }

  Widget _buildScanFrame() {  
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