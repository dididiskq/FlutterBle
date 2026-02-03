import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../bluetooth/ble_controller.dart';
import '../bluetooth/ota_upgrader.dart';
import '../components/common_app_bar.dart';
import '../managers/language_manager.dart';

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
  
  // 服务器地址
  static const String BASE_URL = "http://10.81.45.227:8000";
  
  // 固件信息
  String _firmwareVersion = 'V1.0.0'; 
  String _softwareVersion = 'V1.0.0';
  String? _selectedFirmwareFile;
  int? _selectedFirmwareSize; // 存储固件文件大小(字节)
  
  // 服务器固件信息
  bool _hasUpdate = false;
  String _latestVersion = '';
  String _firmwareDescription = '';
  String? _downloadUrl;
  String? _firmwareFilename;
  
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
  
  // 检查更新
  Future<void> _checkForUpdates() async {
    try {
      setState(() {
        _upgradeStatus = UpgradeStatus.checkingUpdate;
        _upgradeMessage = '正在检查更新...';
      });
      
      // 发送HTTP GET请求获取最新固件信息
      final response = await http.get(Uri.parse('$BASE_URL/ota/latest'));
      
      if (response.statusCode == 200) {
        // 解析JSON响应
        final data = await _parseJsonResponse(response.body);
        
        // 提取数据并进行空值检查
        final latestVersion = data['version'] as String? ?? '';
        final description = data['description'] as String? ?? '';
        final downloadUrl = data['download_url'] as String?;
        final filename = data['filename'] as String?;
        
        setState(() {
          _latestVersion = latestVersion;
          _firmwareDescription = description;
          _downloadUrl = downloadUrl;
          _firmwareFilename = filename;
        });
        
        // 比较版本
        if (latestVersion.isNotEmpty && _isNewVersion(latestVersion)) {
          setState(() {
            _hasUpdate = true;
            _upgradeStatus = UpgradeStatus.idle;
            _upgradeMessage = '发现新版本固件';
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('发现新版本: $latestVersion')),
            );
          }
        } else {
          setState(() {
            _hasUpdate = false;
            _upgradeStatus = UpgradeStatus.idle;
            _upgradeMessage = '当前已是最新版本';
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('当前已是最新版本')),
            );
          }
        }
      } else {
        throw Exception('服务器返回错误: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _upgradeStatus = UpgradeStatus.idle;
        _upgradeMessage = '检查更新失败';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检查更新失败: $e')),
        );
      }
    }
  }
  
  // 解析JSON响应
  Future<Map<String, dynamic>> _parseJsonResponse(String body) async {
    return Future.microtask(() {
      try {
        final Map<String, dynamic> data = json.decode(body);
        return data;
      } catch (e) {
        // 如果JSON解析失败，返回一个空的map
        return {};
      }
    });
  }
  
  // 比较版本号，判断是否为新版本
  bool _isNewVersion(String latestVersion) {
    try {
      // 简单的版本比较逻辑，实际应用中应该使用更复杂的版本比较算法
      // 移除版本号前缀（如 V1.0.0 -> 1.0.0）
      String cleanCurrentVersion = _firmwareVersion;
      if (cleanCurrentVersion.startsWith('V') || cleanCurrentVersion.startsWith('v')) {
        cleanCurrentVersion = cleanCurrentVersion.substring(1);
      }
      
      final currentParts = cleanCurrentVersion.split('.').map((part) => int.tryParse(part) ?? 0).toList();
      final latestParts = latestVersion.split('.').map((part) => int.tryParse(part) ?? 0).toList();
      
      for (var i = 0; i < currentParts.length; i++) {
        if (i >= latestParts.length) return false;
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      
      return latestParts.length > currentParts.length;
    } catch (e) {
      // 如果版本比较失败，默认为不是新版本
      return false;
    }
  }
  
  // 下载固件
  Future<void> _downloadFirmware() async {
    if (_downloadUrl == null || _firmwareFilename == null) {
      return;
    }
    
    try {
      setState(() {
        _upgradeStatus = UpgradeStatus.downloading;
        _upgradeProgress = 0;
        _upgradeMessage = '正在下载固件...';
      });
      
      // 构建完整的下载URL
      final downloadUrl = Uri.parse('$BASE_URL$_downloadUrl');
      
      // 发送HTTP GET请求下载固件文件
      final response = await http.get(downloadUrl, headers: {
        'Accept': '*/*',
      });
      
      if (response.statusCode == 200) {
        // 获取应用文档目录
        final directory = Directory.systemTemp;
        final filePath = '${directory.path}/$_firmwareFilename';
        
        // 将下载的内容写入文件
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // 获取文件大小
        final fileSize = response.bodyBytes.length;
        
        // 调用OTA升级器的selectFirmwareFile方法
        await _otaUpgrader.selectFirmwareFile(
          filePath: filePath,
          fileSize: fileSize,
        );
        
        setState(() {
          _selectedFirmwareFile = _firmwareFilename;
          _selectedFirmwareSize = fileSize;
          _upgradeStatus = UpgradeStatus.idle;
          _upgradeProgress = 100;
          _upgradeMessage = '固件下载完成';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('固件下载完成')),
          );
        }
      } else {
        throw Exception('下载失败: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _upgradeStatus = UpgradeStatus.idle;
        _upgradeProgress = 0;
        _upgradeMessage = '固件下载失败';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('固件下载失败: $e')),
        );
      }
    }
  }
  
  // 开始升级
  Future<void> _startUpgrade() async {
    try {
      // 在开始升级前确保设置数据已加载
      await _otaUpgrader.loadSettingData();
      
      // 使用默认值1作为OTA选择参数（1-4之间）
      await _otaUpgrader.startUpgrade(otaSelection: 1);
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
    return Consumer<LanguageManager>(
      builder: (context, languageManager, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A1128),
          appBar: CommonAppBar(title: languageManager.firmwareUpdatePageTitle),
          body: Container(
            color: const Color(0xFF0A1128),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 固件版本信息
                  _buildVersionCard(languageManager.firmwareVersion, _firmwareVersion),
                  const SizedBox(height: 20.0),
                  
                  // 软件版本信息
                  _buildVersionCard(languageManager.softwareVersion, _softwareVersion),
                  const SizedBox(height: 30.0),
                  
                  // 检查更新按钮
                  _buildCheckUpdateButton(languageManager),
                  
                  const SizedBox(height: 20.0),
                  
                  // 固件更新信息
                  _buildFirmwareUpdateInfo(languageManager),
                  
                  if (_selectedFirmwareFile != null) ...[
                    const SizedBox(height: 20.0),
                    _buildSelectedFileInfo(languageManager),
                  ],
                  
                  const SizedBox(height: 30.0),
                  
                  // 升级状态和进度
                  _buildOtaStatus(languageManager),
                  
                  const SizedBox(height: 30.0),
                  
                  // 升级控制按钮
                  _buildUpgradeControlButtons(languageManager),
                ],
              ),
            ),
          ),
        );
      },
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

  // 构建检查更新按钮
  Widget _buildCheckUpdateButton(LanguageManager languageManager) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _upgradeStatus == UpgradeStatus.idle ? _checkForUpdates : null,
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
        child: Text(languageManager.checkUpdate),
      ),
    );
  }
  
  // 构建下载固件按钮
  Widget _buildDownloadFirmwareButton(LanguageManager languageManager) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _upgradeStatus == UpgradeStatus.idle && _hasUpdate ? _downloadFirmware : null,
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
        child: Text(languageManager.downloadFirmware),
      ),
    );
  }
  
  // 构建固件更新信息卡片
  Widget _buildFirmwareUpdateInfo(LanguageManager languageManager) {
    if (!_hasUpdate) {
      return Container();
    }
    
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
          Text(languageManager.firmwareUpdateInfo, style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(languageManager.currentVersion, style: const TextStyle(color: Colors.white, fontSize: 14.0)),
              Text(_firmwareVersion, style: const TextStyle(color: Colors.grey, fontSize: 14.0)),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(languageManager.latestVersion, style: const TextStyle(color: Colors.white, fontSize: 14.0)),
              Text(_latestVersion, style: const TextStyle(color: Colors.green, fontSize: 14.0, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(languageManager.firmwareDescription, style: const TextStyle(color: Colors.white, fontSize: 14.0)),
          const SizedBox(height: 8.0),
          Text(_firmwareDescription, style: const TextStyle(color: Colors.grey, fontSize: 14.0)),
          const SizedBox(height: 16.0),
          _buildDownloadFirmwareButton(languageManager),
        ],
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
  Widget _buildSelectedFileInfo(LanguageManager languageManager) {
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
          Text(languageManager.selectedFirmwareFile, style: TextStyle(color: Colors.white, fontSize: 16.0)),
          const SizedBox(height: 8.0),
          Text(_selectedFirmwareFile!, style: const TextStyle(color: Colors.blue, fontSize: 14.0)),
          const SizedBox(height: 8.0),
          Text(
            '${languageManager.firmwareSize}: ${_formatFileSize(_selectedFirmwareSize!)}',
            style: const TextStyle(color: Colors.grey, fontSize: 14.0),
          ),
        ],
      ),
    );
  }
  
  // 构建统一的OTA状态组件
  // 合并升级状态、进度条和升级消息为一个组件
  // 进度条仅在升级进行中显示
  Widget _buildOtaStatus(LanguageManager languageManager) {
    // 确定状态文本和颜色
    String statusText = '';
    Color statusColor = Colors.grey;
    
    switch (_upgradeStatus) {
      case UpgradeStatus.idle:
        statusText = languageManager.ready;
        statusColor = Colors.grey;
        break;
      case UpgradeStatus.checkingUpdate:
        statusText = languageManager.checkingUpdate;
        statusColor = Colors.blue;
        break;
      case UpgradeStatus.downloading:
        statusText = languageManager.downloading;
        statusColor = Colors.blue;
        break;
      case UpgradeStatus.upgrading:
        statusText = languageManager.upgrading;
        statusColor = Colors.orange;
        break;
      case UpgradeStatus.completed:
        statusText = languageManager.upgradeCompleted;
        statusColor = Colors.green;
        break;
      case UpgradeStatus.failed:
        statusText = languageManager.upgradeFailed;
        statusColor = Colors.red;
        break;
    }
    
    // 只有在升级或下载时才显示进度条
    bool showProgressBar = _upgradeStatus == UpgradeStatus.upgrading || 
                          _upgradeStatus == UpgradeStatus.downloading;
    
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
          // 升级状态行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(languageManager.upgradeStatus, style: TextStyle(color: Colors.white, fontSize: 16.0)),
              Text(statusText, style: TextStyle(color: statusColor, fontSize: 16.0, fontWeight: FontWeight.bold)),
            ],
          ),
          
          // 条件显示的进度条
          if (showProgressBar) ...[
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(languageManager.upgradeProgress, style: TextStyle(color: Colors.white, fontSize: 16.0)),
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
          
          // 升级消息
          const SizedBox(height: 10.0),
          Text(
            _upgradeMessage,
            style: const TextStyle(color: Colors.white, fontSize: 16.0),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // 构建升级控制按钮
  Widget _buildUpgradeControlButtons(LanguageManager languageManager) {
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
            child: Text(languageManager.startUpgrade),
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
            child: Text(languageManager.cancelButtonText),
          ),
        ),
      ],
    );
  }
}