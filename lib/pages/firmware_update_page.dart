import 'dart:async';

import 'package:flutter/material.dart';
// 导入file_picker包，用于实现文件选择功能
// 注意：需要先运行 flutter pub get 安装依赖
import 'package:file_picker/file_picker.dart';
import '../bluetooth/ble_controller.dart';
import '../bluetooth/ota_upgrader.dart';
import '../components/common_app_bar.dart';

class FirmwareUpdatePage extends StatefulWidget {
  const FirmwareUpdatePage({super.key});

  @override
  State<FirmwareUpdatePage> createState() => _FirmwareUpdatePageState();
}

class _FirmwareUpdatePageState extends State<FirmwareUpdatePage> {
  final BleController _bleController = BleController();
  late OtaUpgrader _otaUpgrader;
  
  // 升级状态
  UpgradeStatus _upgradeStatus = UpgradeStatus.idle;
  int _upgradeProgress = 0;
  String _upgradeMessage = '就绪';
  
  // 固件信息
  String _firmwareVersion = 'V1.0.0';
  String _softwareVersion = 'V2.1.5';
  String? _selectedFirmwareFile;
  int? _selectedFirmwareSize; // 存储固件文件大小(字节)
  
  // 订阅流
  StreamSubscription? _upgradeStatusSubscription;
  
  @override
  void initState() {
    super.initState();
    _otaUpgrader = OtaUpgrader(_bleController);
    _listenToUpgradeStatus();
  }
  
  @override
  void dispose() {
    _upgradeStatusSubscription?.cancel();
    _otaUpgrader.dispose();
    _bleController.dispose();
    super.dispose();
  }
  
  // 监听升级状态
  void _listenToUpgradeStatus() {
    _upgradeStatusSubscription = _otaUpgrader.upgradeStatusStream.listen((statusData) {
      setState(() {
        _upgradeStatus = statusData.status;
        _upgradeProgress = statusData.progress;
        _upgradeMessage = statusData.message;
      });
    });
  }
  
  // 选择固件文件
  Future<void> _selectFirmwareFile() async {
    try {
      // 打开文件选择器，只允许选择二进制文件
      // 注意：需要先运行 flutter pub get 安装file_picker依赖
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin', 'hex'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // 获取文件路径和大小
        final filePath = file.path;
        final fileSize = file.size;
        
        if (filePath != null) {
          // 调用OTA升级器的selectFirmwareFile方法
          await _otaUpgrader.selectFirmwareFile(
            filePath: filePath,
            fileSize: fileSize,
          );
          
          setState(() {
            _selectedFirmwareFile = file.name; // 更新UI显示所选文件名
            _selectedFirmwareSize = fileSize; // 存储文件大小
          });
          
          // 显示文件选择成功的提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('固件文件已选择')),
            );
          }
        }
      } else {
        // 用户取消了文件选择
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件选择已取消')),
          );
        }
      }
    } catch (e) {
      // 处理文件选择失败的情况
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择固件文件失败: $e')),
        );
      }
    }
  }
  
  // 开始升级
  Future<void> _startUpgrade() async {
    try {
      await _otaUpgrader.startUpgrade();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('升级失败: $e')),
      );
    }
  }
  
  // 取消升级
  Future<void> _cancelUpgrade() async {
    await _otaUpgrader.cancelUpgrade();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      appBar: CommonAppBar(title: '固件升级'),
      body: Container(
        color: const Color(0xFF0A1128),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 固件版本信息
              _buildVersionCard('固件版本', _firmwareVersion),
              const SizedBox(height: 20.0),
              
              // 软件版本信息
              _buildVersionCard('软件版本', _softwareVersion),
              const SizedBox(height: 30.0),
              
              // 选择固件文件
              _buildSelectFirmwareButton(),
              
              if (_selectedFirmwareFile != null) ...[
                const SizedBox(height: 20.0),
                _buildSelectedFileInfo(),
              ],
              
              const SizedBox(height: 30.0),
              
              // 升级状态和进度
              _buildUpgradeStatus(),
              const SizedBox(height: 20.0),
              _buildProgressBar(),
              const SizedBox(height: 10.0),
              _buildUpgradeMessage(),
              
              const SizedBox(height: 30.0),
              
              // 升级控制按钮
              _buildUpgradeControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // 构建版本信息卡片
  Widget _buildVersionCard(String title, String version) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16.0)),
          Text(version, style: const TextStyle(color: Colors.blue, fontSize: 16.0, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 构建选择固件按钮
  Widget _buildSelectFirmwareButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _upgradeStatus == UpgradeStatus.idle ? _selectFirmwareFile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A2332),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          textStyle: const TextStyle(fontSize: 18.0, color: Colors.white),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: const BorderSide(color: const Color(0xFF3A475E), width: 1),
          ),
          elevation: 0,
        ),
        child: const Text('选择固件文件'),
      ),
    );
  }
  
  // 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  // 构建已选择文件信息
  Widget _buildSelectedFileInfo() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('已选择固件文件:', style: TextStyle(color: Colors.white, fontSize: 16.0)),
          const SizedBox(height: 8.0),
          Text(_selectedFirmwareFile!, style: const TextStyle(color: Colors.blue, fontSize: 14.0)),
          const SizedBox(height: 8.0),
          Text(
            '固件大小: ${_formatFileSize(_selectedFirmwareSize!)}',
            style: const TextStyle(color: Colors.grey, fontSize: 14.0),
          ),
        ],
      ),
    );
  }
  
  // 构建升级状态
  Widget _buildUpgradeStatus() {
    String statusText = '';
    Color statusColor = Colors.grey;
    
    switch (_upgradeStatus) {
      case UpgradeStatus.idle:
        statusText = '就绪';
        statusColor = Colors.grey;
        break;
      case UpgradeStatus.checkingUpdate:
        statusText = '检查更新';
        statusColor = Colors.blue;
        break;
      case UpgradeStatus.downloading:
        statusText = '下载中';
        statusColor = Colors.blue;
        break;
      case UpgradeStatus.upgrading:
        statusText = '升级中';
        statusColor = Colors.orange;
        break;
      case UpgradeStatus.completed:
        statusText = '升级完成';
        statusColor = Colors.green;
        break;
      case UpgradeStatus.failed:
        statusText = '升级失败';
        statusColor = Colors.red;
        break;
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('升级状态:', style: TextStyle(color: Colors.white, fontSize: 16.0)),
          Text(statusText, style: TextStyle(color: statusColor, fontSize: 16.0, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  // 构建进度条
  Widget _buildProgressBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('升级进度:', style: TextStyle(color: Colors.white, fontSize: 16.0)),
              Text('$_upgradeProgress%', style: const TextStyle(color: Colors.white, fontSize: 16.0)),
            ],
          ),
          const SizedBox(height: 10.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: _upgradeProgress / 100,
              backgroundColor: const Color(0xFF3A475E),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              minHeight: 8.0,
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建升级消息
  Widget _buildUpgradeMessage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Text(
        _upgradeMessage,
        style: const TextStyle(color: Colors.white, fontSize: 16.0),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  // 构建升级控制按钮
  Widget _buildUpgradeControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _upgradeStatus == UpgradeStatus.idle && _selectedFirmwareFile != null ? _startUpgrade : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              textStyle: const TextStyle(fontSize: 18.0, color: Colors.white),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: const BorderSide(color: Colors.blue, width: 1),
              ),
              elevation: 0,
            ),
            child: const Text('开始升级'),
          ),
        ),
        const SizedBox(width: 20.0),
        Expanded(
          child: ElevatedButton(
            onPressed: _upgradeStatus != UpgradeStatus.idle && _upgradeStatus != UpgradeStatus.completed ? _cancelUpgrade : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2332),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              textStyle: const TextStyle(fontSize: 18.0, color: Colors.white),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: const BorderSide(color: const Color(0xFF3A475E), width: 1),
              ),
              elevation: 0,
            ),
            child: const Text('取消'),
          ),
        ),
      ],
    );
  }
}