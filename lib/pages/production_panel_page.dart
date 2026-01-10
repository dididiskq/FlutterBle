import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../components/common_app_bar.dart';
import '../components/write_confirm_dialog.dart';
import '../managers/battery_data_manager.dart';

class ProductionPanelPage extends StatefulWidget {
  const ProductionPanelPage({super.key});

  @override
  State<ProductionPanelPage> createState() => _ProductionPanelPageState();
}

class _ProductionPanelPageState extends State<ProductionPanelPage> {
  final BatteryDataManager _batteryDataManager = BatteryDataManager();
  final TextEditingController _bluetoothNameController = TextEditingController();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = false;
  String scannedData = '';

  @override
  void dispose() {
    controller?.dispose();
    _bluetoothNameController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && scanData.code!.isNotEmpty) {
        setState(() {
          scannedData = scanData.code!;
          _bluetoothNameController.text = scannedData;
          isScanning = false;
        });
        controller.pauseCamera();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('扫描成功: $scannedData'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      appBar: CommonAppBar(title: '生产操作面板'),
      body: Container(
        color: const Color(0xFF0A1128),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 电流归零按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirmed = await WriteConfirmDialog.show(
                      context,
                      title: '确认电流归零',
                      parameterName: '电流归零',
                      oldValue: '当前值',
                      newValue: '0',
                    );
                    
                    if (confirmed && mounted) {
                      final success = await _batteryDataManager.writeParameters(0x0101, [0]);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? '电流归零成功' : '电流归零失败'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2332),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(fontSize: 18.0, color: Colors.white),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(color: Color(0xFF3A475E), width: 1),
                    ),
                  ),
                  child: const Text('电流归零'),
                ),
              ),
              const SizedBox(height: 20.0),
              
              // 蓝牙名称输入框
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2332),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: const Color(0xFF3A475E), width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _bluetoothNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '请输入蓝牙名称',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              
              // 写入蓝牙名称按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final bluetoothName = _bluetoothNameController.text.trim();
                    
                    if (bluetoothName.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('蓝牙名称不能为空'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }
                    
                    if (bluetoothName.length > 24) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('蓝牙名称不能超过24个字符'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      return;
                    }
                    
                    final confirmed = await WriteConfirmDialog.show(
                      context,
                      title: '确认写入蓝牙名称',
                      parameterName: '蓝牙名称',
                      oldValue: '当前名称',
                      newValue: bluetoothName,
                    );
                    
                    if (confirmed && mounted) {
                      final nameBytes = bluetoothName.codeUnits.toList();
                      final success = await _batteryDataManager.writeParameters(0x24A, nameBytes);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? '蓝牙名称写入成功' : '蓝牙名称写入失败'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2332),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(fontSize: 16.0, color: Colors.white),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(color: Color(0xFF3A475E), width: 1),
                    ),
                  ),
                  child: const Text('写入蓝牙名称'),
                ),
              ),
              const SizedBox(height: 20.0),
              
              // 扫一扫按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isScanning = !isScanning;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2332),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: const TextStyle(fontSize: 18.0, color: Colors.white),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      side: const BorderSide(color: Color(0xFF3A475E), width: 1),
                    ),
                  ),
                  child: Text(isScanning ? '关闭扫描' : '扫一扫'),
                ),
              ),
              const SizedBox(height: 20.0),
              
              // 扫描框区域
              if (isScanning)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2332),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: const Color(0xFF3A475E), width: 1),
                  ),
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderColor: Colors.blue,
                        borderRadius: 10,
                        borderLength: 30,
                        borderWidth: 10,
                        cutOutSize: 250,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}