import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:archive/archive.dart';
import 'ble_controller.dart';

/// 升级状态枚举
enum UpgradeStatus {
  idle,
  checkingUpdate,
  downloading,
  upgrading,
  completed,
  failed,
}

/// 升级状态数据类
class UpgradeStatusData {
  final UpgradeStatus status;
  final int progress;
  final String message;
  
  UpgradeStatusData(this.status, this.progress, this.message);
}

/// OTA升级类，负责处理固件升级流程
class OtaUpgrader {
  final BleController _bleController;
  
  // OTA 命令定义
  static const int OTA_CMD_CONN_PARAM_UPDATE = 0x01;      // 连接参数更新
  static const int OTA_CMD_MTU_UPDATE = 0x02;          // MTU 更新
  static const int OTA_CMD_VERSION = 0x03;              // 版本请求
  static const int OTA_CMD_CREATE_OTA_SETTING = 0x04;   // 创建设置传输
  static const int OTA_CMD_CREATE_OTA_IMAGE = 0x05;     // 创建镜像传输
  static const int OTA_CMD_VALIDATE_OTA_IMAGE = 0x06;   // 验证镜像
  static const int OTA_CMD_ACTIVATE_OTA_IMAGE = 0x07;   // 激活镜像
  static const int OTA_CMD_JUMP_IMAGE_UPDATE = 0x08;    // 跳转至镜像更新程序

  // 错误代码
  static const int OTA_CMD_ERROR_CODE_SUCCESS = 0x00;     // 成功
  static const int OTA_CMD_ERROR_CODE_INVALID_PARAM = 0x01; // 参数无效
  static const int OTA_CMD_ERROR_CODE_CRC_FAIL = 0x02;    // CRC 校验失败
  static const int OTA_CMD_ERROR_CODE_SIGNATURE_FAIL = 0x03; // 签名失败

  // 升级状态流
  final StreamController<UpgradeStatusData> _upgradeStatusController = StreamController.broadcast();
  Stream<UpgradeStatusData> get upgradeStatusStream => _upgradeStatusController.stream;
  
  // 升级文件信息
  String? _firmwareFilePath;
  String? _extractedFirmwarePath; // 解压后的固件路径
  int _firmwareSize = 0;
  int _dfuSettingSize = 0;
  Uint8List? _dfuSettingData;
  
  // OTA版本信息
  int _app1Version = 0;
  int _app2Version = 0;
  int _imageUpdateVersion = 0;
  int _otaSelection = 0;
  
  OtaUpgrader(this._bleController);
  
  /// 选择升级文件
  Future<void> selectFirmwareFile({required String filePath, required int fileSize}) async {
    _firmwareFilePath = filePath;
    _firmwareSize = fileSize;
    
    // 解压ZIP固件文件
    await _extractFirmwareFiles(filePath);
    
    _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.idle, 0, '固件文件已选择'));
  }
  
  /// 解压固件ZIP文件到临时目录
  Future<void> _extractFirmwareFiles(String zipFilePath) async {
    print('[OTA] 开始解压固件文件: $zipFilePath');
    
    try {
      // 创建解压目录
      final extractedDir = Directory('${Directory.systemTemp.path}/OTA');
      if (await extractedDir.exists()) {
        await extractedDir.delete(recursive: true);
      }
      await extractedDir.create();
      
      // 读取ZIP文件
      final file = File(zipFilePath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // 解压所有文件到目录
      for (final archiveFile in archive) {
        final filename = archiveFile.name;
        final file = File('${extractedDir.path}/$filename');
        
        // 确保目录存在
        await file.create(recursive: true);
        
        // 写入文件内容
        await file.writeAsBytes(archiveFile.content as List<int>);
      }
      
      _extractedFirmwarePath = extractedDir.path;
      print('[OTA] 固件文件解压完成，解压路径: $_extractedFirmwarePath');
    } catch (e) {
      print('[OTA] 解压固件文件失败: $e');
      throw Exception('解压固件文件失败: $e');
    }
  }
  
  /// 加载设置数据
  Future<void> loadSettingData() async {
    // 检查解压路径是否存在
    if (_extractedFirmwarePath == null) {
      throw Exception('固件文件未解压，请先选择固件文件');
    }
    
    // 从解压目录中读取dfu_setting.dat文件 - 与Java实现一致
    try {
        final settingFile = File('$_extractedFirmwarePath/dfu_setting.dat');
        
        if (!await settingFile.exists()) {
          print('[OTA] 未找到 dfu_setting.dat 文件，跳过设置数据加载');
          _dfuSettingData = Uint8List(0); // 空的字节数组
          _dfuSettingSize = 0;
          return;
        }
        
        print('[OTA] 从解压目录加载设置数据: $_extractedFirmwarePath/dfu_setting.dat');
        
        final bytes = await settingFile.readAsBytes();
        _dfuSettingData = bytes;
        _dfuSettingSize = bytes.length;
        
        print('[OTA] 设置数据加载完成，大小: $_dfuSettingSize');
      } catch (e) {
        print('[OTA] 加载设置数据失败: $e');
        // 如果无法加载设置数据，创建一个空的设置数据作为后备
        _dfuSettingData = Uint8List(0); // 空的字节数组
        _dfuSettingSize = 0;
        print('[OTA] 使用空设置数据作为后备，大小: 0');
      }
  }
  
  /// 开始升级流程
  /// [otaSelection] - OTA选择 (1-4): 表示要升级的固件类型
  Future<void> startUpgrade({required int otaSelection}) async {
    // 验证OTA选择参数
    if (otaSelection < 1 || otaSelection > 4) {
      throw Exception('无效的OTA选择: $otaSelection，必须在1-4之间');
    }
    
    // 设置OTA选择
    _otaSelection = otaSelection;
    try {
      // 检查设备是否已连接
      if (_bleController.connectedDevice == null) {
        throw Exception('设备未连接，请先连接设备后再进行OTA升级');
      }
      
      // 检查连接状态
      final connectionState = _bleController.connectionState;
      if (connectionState != DeviceConnectionState.connected) {
        throw Exception('设备连接状态异常: $connectionState，请重新连接设备后再尝试升级');
      }
      
      // 权限应该在连接设备之前就已经获取，不再重复请求
      // 避免权限请求导致的连接中断问题
      
      // 再次检查连接状态
      final updatedConnectionState = _bleController.connectionState;
      if (updatedConnectionState != DeviceConnectionState.connected) {
        throw Exception('权限请求后设备连接状态异常: $updatedConnectionState，请重新连接设备后再尝试升级');
      }
      
      // 切换到OTA模式（使用OTA专用UUID）
      await _bleController.enableOtaMode();
      
      // 检查切换到OTA模式后设备是否仍处于连接状态
      if (_bleController.connectedDevice == null) {
        throw Exception('切换到OTA模式后设备连接已断开，请重新连接设备后再尝试升级');
      }
      
      // 再次检查连接状态
      final otaConnectionState = _bleController.connectionState;
      if (otaConnectionState != DeviceConnectionState.connected) {
        throw Exception('切换到OTA模式后设备连接状态异常: $otaConnectionState，请重新连接设备后再尝试升级');
      }
      
      _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.checkingUpdate, 0, '开始升级...'));
      
      // 1. 连接参数更新
      await _connectionUpdate();
      _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.checkingUpdate, 10, '连接参数更新完成'));
      
      // 2. MTU 更新
      await _mtuUpdate();
      _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.checkingUpdate, 20, 'MTU 更新完成'));
      
      // 3. 版本请求
      await _versionRequest();
      _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.checkingUpdate, 30, '版本请求完成'));
      
      // 根据OTA选择处理不同的升级流程
      if (_otaSelection == 4) {
        // 4. 跳转至镜像更新程序
        await _jumpToImageUpdate();
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.upgrading, 40, '已跳转至镜像更新程序'));
        // 后续流程由镜像更新程序处理
      } else {
        // 加载设置数据
        await loadSettingData();
        
        // 4. 创建设置传输
        await _createOtaSettingTransfer(_dfuSettingSize);
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.checkingUpdate, 40, '创建设置传输完成'));
        
        // 5. 发送设置数据
        if (_dfuSettingData != null) {
          await _sendSettingData(_dfuSettingData!);
          _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.downloading, 50, '设置数据发送完成'));
        } else {
          print('[OTA] 警告：设置数据为空，跳过发送设置数据');
          _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.downloading, 50, '设置数据为空，跳过发送'));
        }
        
        // 6. & 7. 创建镜像传输和发送镜像数据（合并为一个步骤，与Java实现一致）
        await _sendImageData();
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.downloading, 60, '开始发送镜像数据'));
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.upgrading, 90, '镜像数据发送完成'));
        
        // 8. 验证新镜像
        await _validateNewImage();
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.upgrading, 95, '镜像验证完成'));
        
        // 9. 激活新镜像
        await _activateNewImage();
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.completed, 100, '升级完成'));
      }
      
      // 升级完成，切换回正常模式
      await _bleController.disableOtaMode();
      
    } catch (error) {
      // 升级失败，切换回正常模式
      await _bleController.disableOtaMode();
      _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.failed, 0, '升级失败: $error'));
      rethrow;
    }
  }
  
  /// 1. 连接参数更新
  Future<void> _connectionUpdate() async {
    print('[OTA] 开始连接参数更新...');
    
    // 参数值（参考BleOTA.java）
    final int intervalMin = 15; // 最小连接间隔
    final int intervalMax = 50; // 最大连接间隔
    final int latency = 0; // 从机延迟
    final int timeout = 500; // 连接超时（单位：10ms）

    // 构建连接参数更新命令数据
    final Uint8List data = Uint8List(9);
    data[0] = OTA_CMD_CONN_PARAM_UPDATE;
    data[1] = (intervalMin >> 8) & 0xFF; // 高位字节
    data[2] = intervalMin & 0xFF;       // 低位字节
    data[3] = (intervalMax >> 8) & 0xFF; // 高位字节
    data[4] = intervalMax & 0xFF;       // 低位字节
    data[5] = (latency >> 8) & 0xFF;     // 高位字节
    data[6] = latency & 0xFF;           // 低位字节
    data[7] = (timeout >> 8) & 0xFF;     // 高位字节
    data[8] = timeout & 0xFF;           // 低位字节

    print('[OTA] 发送连接参数更新命令: $data');
    print('[OTA] 命令详情: intervalMin=$intervalMin, intervalMax=$intervalMax, latency=$latency, timeout=$timeout');
    
    try {
      // 使用新的API发送命令并等待响应（参考Java代码的实现方式）
      // 增加超时时间到15秒，解决连接参数更新超时问题
      final response = await _bleController.sendOtaCommandAndWaitResponse(
        data,
        timeout: const Duration(seconds: 15),
      );
      
      print('[OTA] 收到连接参数更新响应: $response');
      
      // 检查响应数据
      if (response.length >= 2) {
        final otaError = response[1];
        
        // 如果有错误，发布错误事件
        if (otaError > 0) {
          print('[OTA] 连接参数更新失败: 错误代码 $otaError');
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            '连接参数更新失败: 错误代码 $otaError'
          ));
          throw Exception('连接参数更新失败: 错误代码 $otaError');
        }
      }
      
      print('[OTA] 连接参数更新成功');
    } catch (error) {
      print('[OTA] 连接参数更新失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '连接参数更新失败: $error'
      ));
      rethrow;
    }
  }
  
  /// 2. MTU 更新
  Future<void> _mtuUpdate() async {
    // 设置MTU值（参考Java代码，使用247作为最大值）
    const int mtu = 247; // max 247 min 23，与Java代码保持一致

    // 注意：flutter_reactive_ble库可能不直接支持获取当前MTU值
    // 根据Java代码逻辑，如果当前MTU小于所需MTU则更新
    // 这里我们直接发送MTU更新命令，让设备决定是否需要更新
    // 构建MTU更新命令数据
    final Uint8List data = Uint8List(3);
    data[0] = OTA_CMD_MTU_UPDATE;
    data[1] = (mtu >> 8) & 0xFF; // 高位字节
    data[2] = mtu & 0xFF;       // 低位字节

    print('[OTA] 发送MTU更新命令: $data');
    
    try {
      // 使用新的API发送命令并等待响应
      final response = await _bleController.sendOtaCommandAndWaitResponse(
        data,
        timeout: const Duration(seconds: 1),
      );
      
      print('[OTA] 收到MTU更新响应: $response');
      
      // 检查响应数据
      if (response.length >= 2) {
        final otaError = response[1];
        
        // 如果有错误，发布错误事件
        if (otaError > 0) {
          print('[OTA] MTU更新失败: 错误代码 $otaError');
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            'MTU更新失败: 错误代码 $otaError'
          ));
          throw Exception('MTU更新失败: 错误代码 $otaError');
        }
      }
      
      print('[OTA] MTU更新成功');
      
      // 在Java代码中，MTU更新后会发送事件
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.downloading,
        25, // 介于连接参数更新(20)和版本请求(30)之间
        'MTU 更新完成'
      ));
    } catch (error) {
      print('[OTA] MTU更新失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        'MTU更新失败: $error'
      ));
      rethrow;
    }
  }
  
  /// 3. 版本请求
  Future<void> _versionRequest() async {
    // 检查设备连接状态
    if (!_bleController.isConnected) {
      throw Exception('设备未连接，请重新连接设备');
    }
    
    // 检查解压路径是否存在
    if (_extractedFirmwarePath == null) {
      throw Exception('固件文件未解压，请先选择固件文件');
    }
    
    // 检查APP1.bin、APP2.bin和ImageUpdate.bin文件是否存在，并获取其大小
    File app1File = File('${_extractedFirmwarePath}/APP1.bin');
    File app2File = File('${_extractedFirmwarePath}/APP2.bin');
    File imageUpdateFile = File('${_extractedFirmwarePath}/ImageUpdate.bin');
    File configFile = File('${_extractedFirmwarePath}/config.txt');
    
    int app1BinSize = app1File.existsSync() ? await app1File.length() : 0;
    int app2BinSize = app2File.existsSync() ? await app2File.length() : 0;
    int imageUpdateBinSize = imageUpdateFile.existsSync() ? await imageUpdateFile.length() : 0;
    
    // 从配置文件读取ImageUpdate版本号
    int imageUpdateVersion = 0x01000000; // 默认版本号
    
    if (configFile.existsSync()) {
      String configContent = await configFile.readAsString();
      imageUpdateVersion = await _parseImageUpdateVersion(configContent);
    }
    
    // 构建版本请求命令数据 - 与Java代码保持完全一致
    final Uint8List data = Uint8List(17);
    data[0] = OTA_CMD_VERSION;
    
    // APP1.bin 大小（4字节，大端序）- 与Java代码保持一致的转换方式
    data[1] = (app1BinSize >> 24) & 0xFF;
    data[2] = (app1BinSize >> 16) & 0xFF;
    data[3] = (app1BinSize >> 8) & 0xFF;
    data[4] = app1BinSize & 0xFF;
    
    // APP2.bin 大小（4字节，大端序）- 与Java代码保持一致的转换方式
    data[5] = (app2BinSize >> 24) & 0xFF;
    data[6] = (app2BinSize >> 16) & 0xFF;
    data[7] = (app2BinSize >> 8) & 0xFF;
    data[8] = app2BinSize & 0xFF;
    
    // ImageUpdate.bin 大小（4字节，大端序）- 与Java代码保持一致的转换方式
    data[9] = (imageUpdateBinSize >> 24) & 0xFF;
    data[10] = (imageUpdateBinSize >> 16) & 0xFF;
    data[11] = (imageUpdateBinSize >> 8) & 0xFF;
    data[12] = imageUpdateBinSize & 0xFF;
    
    // ImageUpdate 版本号（4字节，大端序）- 与Java代码保持一致的转换方式
    data[13] = (imageUpdateVersion >> 24) & 0xFF;
    data[14] = (imageUpdateVersion >> 16) & 0xFF;
    data[15] = (imageUpdateVersion >> 8) & 0xFF;
    data[16] = imageUpdateVersion & 0xFF;

    print('[OTA] 发送版本请求命令: ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    print('[OTA] 版本请求参数: app1BinSize=$app1BinSize, app2BinSize=$app2BinSize, imageUpdateBinSize=$imageUpdateBinSize, imageUpdateVersion=0x${imageUpdateVersion.toRadixString(16)}');
    
    try {
      // 使用新的API发送命令并等待响应
      final response = await _bleController.sendOtaCommandAndWaitResponse(
        data,
        timeout: const Duration(seconds: 15), // 增加超时时间，确保有足够时间处理响应
      );
      
      print('[OTA] 收到版本请求响应: ${response.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
      
      // 检查响应数据长度
      if (response.length >= 14) {
        // 验证响应命令ID是否为版本请求响应（与Java代码中的检查一致）
        if (response[0] != OTA_CMD_VERSION) {
          print('[OTA] 版本请求失败: 响应命令ID不匹配，期望 0x${OTA_CMD_VERSION.toRadixString(16)}，实际 0x${response[0].toRadixString(16)}');
          throw Exception('版本请求失败: 响应命令ID不匹配');
        }
        
        // 解析APP1版本号（4字节，大端序）
        _app1Version = ((response[1] & 0xFF) << 24) |
                      ((response[2] & 0xFF) << 16) |
                      ((response[3] & 0xFF) << 8) |
                      (response[4] & 0xFF);
        
        // 解析APP2版本号（4字节，大端序）
        _app2Version = ((response[5] & 0xFF) << 24) |
                      ((response[6] & 0xFF) << 16) |
                      ((response[7] & 0xFF) << 8) |
                      (response[8] & 0xFF);
        
        // 解析ImageUpdate版本号（4字节，大端序）
        _imageUpdateVersion = ((response[9] & 0xFF) << 24) |
                             ((response[10] & 0xFF) << 16) |
                             ((response[11] & 0xFF) << 8) |
                             (response[12] & 0xFF);
        
        // 获取OTA选择
        _otaSelection = response[13] & 0xFF;
        
        print('[OTA] app1_version: 0x${_app1Version.toRadixString(16)}');
        print('[OTA] app2_version: 0x${_app2Version.toRadixString(16)}');
        print('[OTA] image_update_version: 0x${_imageUpdateVersion.toRadixString(16)}');
        print('[OTA] ota_selection: $_otaSelection');
        
        // 根据OTA选择设置固件信息
        if (_otaSelection == 1) {
          _firmwareFilePath = '${_extractedFirmwarePath}/APP1.bin';
          _firmwareSize = app1BinSize;
        } else if (_otaSelection == 2) {
          _firmwareFilePath = '${_extractedFirmwarePath}/APP2.bin';
          _firmwareSize = app2BinSize;
        } else if (_otaSelection == 3) {
          _firmwareFilePath = '${_extractedFirmwarePath}/ImageUpdate.bin';
          _firmwareSize = imageUpdateBinSize;
        }
        
        // 检查OTA选择是否有效
        if (_otaSelection >= 1 && _otaSelection <= 4) {
          print('[OTA] 版本请求成功');
        } else {
          // OTA选择无效，发布错误事件
          print('[OTA] 版本请求失败: 无效的OTA选择 $_otaSelection');
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            '版本请求失败: 无效的OTA选择 $_otaSelection'
          ));
          throw Exception('版本请求失败: 无效的OTA选择 $_otaSelection');
        }
      } else {
        print('[OTA] 版本请求失败: 响应数据长度不足');
        throw Exception('版本请求失败: 响应数据长度不足');
      }
    } catch (error) {
      print('[OTA] 版本请求失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '版本请求失败: $error'
      ));
      rethrow;
    }
  }
  
  /// 从配置文件解析ImageUpdate版本
  Future<int> _parseImageUpdateVersion(String configContent) async {
    try {
      // 按行分割配置内容 - 与Java实现一致
      List<String> confStrs = configContent.split('\n');
      int index = 0;
      
      // 遍历每一行查找IMAGE_UPDATE_VERSION，与Java实现一致
      for (index = 0; index < confStrs.length; index++) {
        if (confStrs[index].contains('IMAGE_UPDATE_VERSION')) {
          break;
        }
      }
      
      // 检查是否找到了IMAGE_UPDATE_VERSION行，防止越界
      if (index < confStrs.length) {
        // 按冒号分割 - 与Java实现一致
        List<String> parts = confStrs[index].split(':');
        if (parts.length > 1) {
          // 提取16进制部分 - 与Java实现一致，从位置3到11
          String versionStr = parts[1].trim();
          String hexStr = versionStr.substring(3, 11); // 去掉"0x"并取8位
          // 转换为整数 - 与Java实现一致
          int version = int.parse(hexStr, radix: 16);
          print('[OTA] 解析到IMAGE_UPDATE_VERSION: 0x${version.toRadixString(16)}');
          return version;
        }
      }
      
      // 如果没有找到版本信息，返回默认值
      print('[OTA] 配置文件中未找到IMAGE_UPDATE_VERSION，使用默认值');
      return 0x01000000;
    } catch (e) {
      print('[OTA] 解析配置文件失败: $e，使用默认版本值');
      return 0x01000000;
    }
  }
  
  /// 4. 创建设置传输
  Future<void> _createOtaSettingTransfer(int dfuSettingSize) async {
    print('[OTA] 开始创建设置传输，设置大小: $dfuSettingSize');

    // 构建创建设置传输命令数据
    final Uint8List data = Uint8List(5);
    data[0] = OTA_CMD_CREATE_OTA_SETTING;
    
    // DFU设置大小（4字节，大端序）- 与Java代码保持一致
    data[1] = (dfuSettingSize >> 24) & 0xFF;
    data[2] = (dfuSettingSize >> 16) & 0xFF;
    data[3] = (dfuSettingSize >> 8) & 0xFF;
    data[4] = dfuSettingSize & 0xFF;

    print('[OTA] 发送创建设置传输命令: $data');
    
    try {
        // ✅ 只需确保 writeWithResponse 成功，不需要等额外响应！
        await _bleController.writeOtaCommand(data); // ← 新方法：只写，不等响应

        print('[OTA] 创建设置传输成功');
      } catch (error) {
        print('[OTA] 创建设置传输失败: $error');
        _upgradeStatusController.add(UpgradeStatusData(
          UpgradeStatus.failed,
          0,
          '创建设置传输失败: $error'
        ));
        rethrow;
      }
  }
  
  /// 5. 发送设置数据
  Future<void> _sendSettingData(Uint8List settingData) async {
    print('[OTA] 开始发送设置数据，数据长度: ${settingData.length}');

    final Completer<List<int>> completer = Completer<List<int>>();
    late StreamSubscription<List<int>> subscription;

    // ✅ 关键：先监听响应，再发送数据！
    subscription = _bleController.notificationStream.listen(
      (data) {
        print('[OTA] 收到设置数据响应: $data');
        if (data.isNotEmpty && data[0] == OTA_CMD_CREATE_OTA_SETTING) {
          if (!completer.isCompleted) {
            completer.complete(data);
          }
        }
      },
      onError: (error) {
        print('[OTA] 设置数据响应监听错误: $error');
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    try {
      print('[OTA] 发送设置数据到数据特征...');
      await _bleController.writeData(settingData, withResponse: false);
      print('[OTA] 设置数据已发送，等待响应...');

      final response = await completer.future.timeout(const Duration(seconds: 30));

      if (response.length >= 2) {
        final otaError = response[1];
        if (otaError > 0) {
          print('[OTA] 发送设置数据失败: 错误代码 $otaError');
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            '发送设置数据失败: 错误代码 $otaError'
          ));
          throw Exception('发送设置数据失败: 错误代码 $otaError');
        }
      }

      print('[OTA] 设置数据发送成功');
    } catch (error) {
      print('[OTA] 发送设置数据失败或超时: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '发送设置数据失败: $error'
      ));
      rethrow;
    } finally {
      await subscription.cancel();
      print('[OTA] 已取消响应监听');
    }
  }
  
  /// 6. 创建镜像传输
  Future<void> _createOtaImageTransfer({
    int imageOffset = 0,
    int imageSize = 0,
    int imageCrc = 0,
  }) async {
    print('[OTA] 开始创建镜像传输...');

    try {
      final Uint8List data = Uint8List(13);
      data[0] = OTA_CMD_CREATE_OTA_IMAGE;

      // 图像偏移量（4字节，大端序）
      data[1] = (imageOffset >> 24) & 0xFF;
      data[2] = (imageOffset >> 16) & 0xFF;
      data[3] = (imageOffset >> 8) & 0xFF;
      data[4] = imageOffset & 0xFF;

      // 图像大小（4字节，大端序）
      data[5] = (imageSize >> 24) & 0xFF;
      data[6] = (imageSize >> 16) & 0xFF;
      data[7] = (imageSize >> 8) & 0xFF;
      data[8] = imageSize & 0xFF;

      // 图像CRC校验值（4字节，大端序）
      data[9] = (imageCrc >> 24) & 0xFF;
      data[10] = (imageCrc >> 16) & 0xFF;
      data[11] = (imageCrc >> 8) & 0xFF;
      data[12] = imageCrc & 0xFF;

      print('[OTA] 发送创建镜像传输命令: $data');

      // ✅ 关键修改：只写入，不等待响应！
      await _bleController.writeOtaCommand(data); // ← 假设这个方法执行 writeWithResponse

      print('[OTA] 创建镜像传输成功');
    } catch (error) {
      print('[OTA] 创建镜像传输失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '创建镜像传输失败: $error'
      ));
      rethrow;
    }
  }
  
  /// 7. 发送镜像数据
  Future<void> _sendImageData() async {
    if (_extractedFirmwarePath == null) {
      throw Exception('解压固件路径未设置');
    }

    // 获取固件文件路径（从解压目录中获取正确的固件文件）
    String firmwarePath = '$_extractedFirmwarePath/APP1.bin';
    if (!File(firmwarePath).existsSync()) {
      // 尝试其他可能的固件文件名
      List<String> possibleFirmwareFiles = [
        'APP1.bin', 'app1.bin', 'APP.bin', 'app.bin', 'firmware.bin', 'main.bin'
      ];
      for (String fileName in possibleFirmwareFiles) {
        String testPath = '$_extractedFirmwarePath/$fileName';
        if (File(testPath).existsSync()) {
          firmwarePath = testPath;
          break;
        }
      }
    }

    if (!File(firmwarePath).existsSync()) {
      throw Exception('固件文件不存在: $firmwarePath');
    }

    final File firmwareFile = File(firmwarePath);
    final int firmwareSize = await firmwareFile.length();
    print('[OTA] 开始发送镜像数据，固件路径: $firmwarePath, 总长度: $firmwareSize');

    // 使用较小的块大小以匹配Java实现
    const int maxChunkSize = 2048;
    int offset = 0;
    int totalSent = 0;

    // 创建单个全局监听器
    Completer<List<int>> globalCompleter = Completer<List<int>>();
    late StreamSubscription<List<int>> subscription;

    // 先监听通知再写入数据
    subscription = _bleController.notificationStream.listen(
      (data) {
        print('[OTA] 收到镜像数据响应: $data');
        if (data.isNotEmpty && data[0] == OTA_CMD_CREATE_OTA_IMAGE) {
          final otaError = data[1];
          if (otaError > 0) {
            print('[OTA] 镜像数据传输失败: 错误代码 $otaError');
            globalCompleter.completeError(Exception('镜像数据传输失败: 错误代码 $otaError'));
          } else {
            // 如果没有错误，继续下一个数据块
            if (!globalCompleter.isCompleted) {
              globalCompleter.complete(data);
            }
          }
        }
      },
      onError: (error) {
        print('[OTA] 镜像数据响应监听错误: $error');
        if (!globalCompleter.isCompleted) {
          globalCompleter.completeError(error);
        }
      },
    );

    try {
      while (offset < firmwareSize) {
        // 计算当前块大小
        final int chunkSize = (offset + maxChunkSize) > firmwareSize 
            ? firmwareSize - offset 
            : maxChunkSize;

        // 从文件中读取当前块
        final RandomAccessFile raf = await firmwareFile.open(mode: FileMode.read);
        await raf.setPosition(offset);
        final Uint8List chunk = await raf.read(chunkSize);
        await raf.close();

        final int chunkCrc = _calculateCrc32(chunk);

        print('[OTA] 准备发送镜像数据块: offset=$offset, size=${chunk.length}, crc=0x${chunkCrc.toRadixString(16)}');

        // 创建镜像传输
        await _createOtaImageTransfer(
          imageOffset: offset,
          imageSize: chunk.length,
          imageCrc: chunkCrc,
        );

        // 发送镜像数据 - 使用数据特征值（对应Java中的ius_rc）
        await _bleController.writeOtaData(chunk);

        // 等待响应或超时
        try {
          final response = await globalCompleter.future.timeout(const Duration(seconds: 20));
          print('[OTA] 收到镜像数据块响应: $response');
        } catch (e) {
          print('[OTA] 镜像数据块响应超时或错误: $e');
          rethrow;
        } finally {
          // 重置 globalCompleter 以便下一次循环使用
          globalCompleter = Completer<List<int>>();
        }

        // 更新发送进度
        totalSent += chunk.length;
        final int progress = firmwareSize > 0 ? (totalSent * 100) ~/ firmwareSize : 0;
        final int adjustedProgress = 60 + ((progress * 30) ~/ 100); // 60%到90%
        _upgradeStatusController.add(UpgradeStatusData(
          UpgradeStatus.downloading,
          adjustedProgress,
          '正在发送镜像数据: ${totalSent}/${firmwareSize} 字节'
        ));

        // 更新偏移量
        offset += chunk.length;

        // 短暂延迟，避免BLE栈过载
        await Future.delayed(const Duration(milliseconds: 10));
      }

      print('[OTA] 镜像数据发送完成，共发送: $totalSent 字节');
    } catch (e) {
      print('[OTA] 发送镜像数据失败: $e');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '发送镜像数据失败: $e'
      ));
      rethrow;
    } finally {
      await subscription.cancel();
    }
  }
  
  /// 计算CRC32校验值（参考BleOTA.java的CRC32_2.fast实现）
  int _calculateCrc32(List<int> data) {
    // CRC32查找表，与Java版本com.nsandroidutil.utility.CRC32_2一致
    const List<int> crc32Table = [
      0x00000000, 0x04c11db7, 0x09823b6e, 0x0d4326d9, 0x130476dc, 0x17c56b6b,
      0x1a864db2, 0x1e475005, 0x2608edb8, 0x22c9f00f, 0x2f8ad6d6, 0x2b4bcb61,
      0x350c9b64, 0x31cd86d3, 0x3c8ea00a, 0x384fbdbd, 0x4c11db70, 0x48d0c6c7,
      0x4593e01e, 0x4152fda9, 0x5f15adac, 0x5bd4b01b, 0x569796c2, 0x52568b75,
      0x6a1936c8, 0x6ed82b7f, 0x639b0da6, 0x675a1011, 0x791d4014, 0x7ddc5da3,
      0x709f7b7a, 0x745e66cd, 0x9823b6e0, 0x9ce2ab57, 0x91a18d8e, 0x95609039,
      0x8b27c03c, 0x8fe6dd8b, 0x82a5fb52, 0x8664e6e5, 0xbe2b5b58, 0xbaea46ef,
      0xb7a96036, 0xb3687d81, 0xad2f2d84, 0xa9ee3033, 0xa4ad16ea, 0xa06c0b5d,
      0xd4326d90, 0xd0f37027, 0xddb056fe, 0xd9714b49, 0xc7361b4c, 0xc3f706fb,
      0xceb42022, 0xca753d95, 0xf23a8028, 0xf6fb9d9f, 0xfbb8bb46, 0xff79a6f1,
      0xe13ef6f4, 0xe5ffeb43, 0xe8bccd9a, 0xec7dd02d, 0x34867077, 0x30476dc0,
      0x3d044b19, 0x39c556ae, 0x278206ab, 0x23431b1c, 0x2e003dc5, 0x2ac12072,
      0x128e9dcf, 0x164f8078, 0x1b0ca6a1, 0x1fcdbb16, 0x018aeb13, 0x054bf6a4,
      0x0808d07d, 0x0cc9cdca, 0x7897ab07, 0x7c56b6b0, 0x71159069, 0x75d48dde,
      0x6b93dddb, 0x6f52c06c, 0x6211e6b5, 0x66d0fb02, 0x5e9f46bf, 0x5a5e5b08,
      0x571d7dd1, 0x53dc6066, 0x4d9b3063, 0x495a2dd4, 0x44190b0d, 0x40d816ba,
      0xaca5c697, 0xa864db20, 0xa527fdf9, 0xa1e6e04e, 0xbfa1b04b, 0xbb60adfc,
      0xb6238b25, 0xb2e29692, 0x8aad2b2f, 0x8e6c3698, 0x832f1041, 0x87ee0df6,
      0x99a95df3, 0x9d684044, 0x902b669d, 0x94ea7b2a, 0xe0b41de7, 0xe4750050,
      0xe9362689, 0xedf73b3e, 0xf3b06b3b, 0xf771768c, 0xfa325055, 0xfef34de2,
      0xc6bcf05f, 0xc27dede8, 0xcf3ecb31, 0xcbffd686, 0xd5b88683, 0xd1799b34,
      0xdc3abded, 0xd8fba05a, 0x690ce0ee, 0x6dcdfd59, 0x608edb80, 0x644fc637,
      0x7a089632, 0x7ec98b85, 0x738aad5c, 0x774bb0eb, 0x4f040d56, 0x4bc510e1,
      0x46863638, 0x42472b8f, 0x5c007b8a, 0x58c1663d, 0x558240e4, 0x51435d53,
      0x251d3b9e, 0x21dc2629, 0x2c9f00f0, 0x285e1d47, 0x36194d42, 0x32d850f5,
      0x3f9b762c, 0x3b5a6b9b, 0x0315d626, 0x07d4cb91, 0x0a97ed48, 0x0e56f0ff,
      0x1011a0fa, 0x14d0bd4d, 0x19939b94, 0x1d528623, 0xf12f560e, 0xf5ee4bb9,
      0xf8ad6d60, 0xfc6c70d7, 0xe22b20d2, 0xe6ea3d65, 0xeba91bbc, 0xef68060b,
      0xd727bbb6, 0xd3e6a601, 0xdea580d8, 0xda649d6f, 0xc423cd6a, 0xc0e2d0dd,
      0xcda1f604, 0xc960ebb3, 0xbd3e8d7e, 0xb9ff90c9, 0xb4bcb610, 0xb07daba7,
      0xae3afba2, 0xaafbe615, 0xa7b8c0cc, 0xa379dd7b, 0x9b3660c6, 0x9ff77d71,
      0x92b45ba8, 0x9675461f, 0x8832161a, 0x8cf30bad, 0x81b02d74, 0x857130c3,
      0x5d8a9099, 0x594b8d2e, 0x5408abf7, 0x50c9b640, 0x4e8ee645, 0x4a4ffbf2,
      0x470cdd2b, 0x43cdc09c, 0x7b827d21, 0x7f436096, 0x7200464f, 0x76c15bf8,
      0x68860bfd, 0x6c47164a, 0x61043093, 0x65c52d24, 0x119b4be9, 0x155a565e,
      0x18197087, 0x1cd86d30, 0x029f3d35, 0x065e2082, 0x0b1d065b, 0x0fdc1bec,
      0x3793a651, 0x3352bbe6, 0x3e119d3f, 0x3ad08088, 0x2497d08d, 0x2056cd3a,
      0x2d15ebe3, 0x29d4f654, 0xc5a92679, 0xc1683bce, 0xcc2b1d17, 0xc8ea00a0,
      0xd6ad50a5, 0xd26c4d12, 0xdf2f6bcb, 0xdbee767c, 0xe3a1cbc1, 0xe760d676,
      0xea23f0af, 0xeee2ed18, 0xf0a5bd1d, 0xf464a0aa, 0xf9278673, 0xfde69bc4,
      0x89b8fd09, 0x8d79e0be, 0x803ac667, 0x84fbdbd0, 0x9abc8bd5, 0x9e7d9662,
      0x933eb0bb, 0x97ffad0c, 0xafb010b1, 0xab710d06, 0xa6322bdf, 0xa2f33668,
      0xbcb4666d, 0xb8757bda, 0xb5365d03, 0xb1f740b4
    ];

    int crc = 0xffffffff;

    for (int i = 0; i < data.length; i++) {
      crc = (crc << 8) ^ crc32Table[((crc >> 24) ^ (data[i] & 0xff)) & 0xff];
      crc &= 0xffffffff;
    }

    return crc;
  }
  
  /// 测试CRC32计算方法
  void _testCrc32() {
    // 使用一些测试数据验证CRC32计算
    List<int> testData = [0x00, 0x01, 0x02, 0x03, 0xFF, 0xFE, 0xFD, 0xFC];
    int crcResult = _calculateCrc32(testData);
    print('[CRC32测试] 输入: ${testData.map((e) => '0x${e.toRadixString(16).padLeft(2, '0')}').join(', ')}');
    print('[CRC32测试] CRC32结果: 0x${crcResult.toRadixString(16).padLeft(8, '0')}');
  }
  
  /// 8. 验证新镜像
  Future<void> _validateNewImage() async {
    print('[OTA] 开始验证新镜像...');

    try {
      // 更新进度为90%
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.downloading,
        90,
        '正在验证新镜像...',
      ));

      // 构建验证命令
      final Uint8List command = Uint8List.fromList([OTA_CMD_VALIDATE_OTA_IMAGE]);

      // 创建 Completer 等待响应
      final completer = Completer<List<int>>();
      late StreamSubscription<List<int>> subscription;

      // 1️⃣ 先监听 ius_cc 的通知（必须在写入前！）
      subscription = _bleController.notificationStream.listen(
        (data) {
          if (data.isNotEmpty && data[0] == OTA_CMD_VALIDATE_OTA_IMAGE) {
            print('[OTA] 收到验证响应: $data');
            if (!completer.isCompleted) {
              completer.complete(data);
            }
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );

      try {
        // 2️⃣ 发送命令到 ius_cc（注意：不是 ius_rc！）
        print('[OTA] 发送验证新镜像命令...');
        await _bleController.writeOtaCommand(command); // ← 必须写入到 ius_cc

        // 3️⃣ 等待设备响应（带超时）
        final response = await completer.future.timeout(const Duration(seconds: 10));

        // 4️⃣ 检查错误码
        if (response.length >= 2) {
          final otaError = response[1];
          if (otaError > 0) {
            print('[OTA] 验证新镜像失败: 错误代码 $otaError');
            _upgradeStatusController.add(UpgradeStatusData(
              UpgradeStatus.failed,
              0,
              '验证新镜像失败: 错误代码 $otaError',
            ));
            throw Exception('验证新镜像失败: 错误代码 $otaError');
          }
        }

        print('[OTA] 验证新镜像成功');
      } finally {
        await subscription.cancel();
      }
    } catch (error) {
      print('[OTA] 验证新镜像失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '验证新镜像失败: $error',
      ));
      rethrow;
    }
  }
  
  /// 9. 激活新镜像
  Future<void> _activateNewImage() async {
    print('[OTA] 开始激活新镜像...');
  
    try {
      // 更新状态为90%进度
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.downloading,
        90,
        '正在激活新镜像...'
      ));
  
      // 构建激活命令
      final Uint8List command = Uint8List.fromList([OTA_CMD_ACTIVATE_OTA_IMAGE]);
  
      // 创建 Completer 等待响应
      final completer = Completer<List<int>>();
      late StreamSubscription<List<int>> subscription;
  
      // 先监听 ius_cc 的通知（必须在写入前！）
      subscription = _bleController.notificationStream.listen(
        (data) {
          if (data.isNotEmpty && data[0] == OTA_CMD_ACTIVATE_OTA_IMAGE) {
            print('[OTA] 收到激活响应: $data');
            if (!completer.isCompleted) {
              completer.complete(data);
            }
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );
  
      try {
        // 发送命令到 ius_cc（注意：不是 ius_rc！）
        print('[OTA] 发送激活新镜像命令...');
        await _bleController.writeOtaCommand(command); // 必须写入到 ius_cc
  
        // 等待设备响应（带合理超时）
        final response = await completer.future.timeout(const Duration(seconds: 5)); // 调整超时时间
  
        // 检查错误码
        if (response.length >= 2) {
          final otaError = response[1];
          if (otaError > 0) {
            print('[OTA] 激活新镜像失败: 错误代码 $otaError');
            _upgradeStatusController.add(UpgradeStatusData(
              UpgradeStatus.failed,
              0,
              '激活新镜像失败: 错误代码 $otaError',
            ));
            throw Exception('激活新镜像失败: 错误代码 $otaError');
          }
        }
  
        print('[OTA] 激活新镜像成功');
      } finally {
        await subscription.cancel();
      }
    } catch (error) {
      print('[OTA] 激活新镜像失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '激活新镜像失败: $error',
      ));
      rethrow;
    }
  }
  
  /// 取消升级
  Future<void> cancelUpgrade() async {
    _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.idle, 0, '升级已取消'));
  }
  
  /// 跳转至镜像更新
  Future<void> _jumpToImageUpdate() async {
    print('[OTA] 开始跳转至镜像更新...');
    
    try {
      // 发送跳转命令
      final Uint8List jumpCommand = Uint8List.fromList([OTA_CMD_JUMP_IMAGE_UPDATE]);
      
      // 更新状态
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.upgrading,
        35,
        '正在跳转至镜像更新...'
      ));
      
      print('[OTA] 发送跳转至镜像更新命令...');
      
      // 使用新的API发送命令并等待响应
      final response = await _bleController.sendOtaCommandAndWaitResponse(
        jumpCommand,
        timeout: const Duration(seconds: 5),
      );
      
      print('[OTA] 收到跳转至镜像更新响应: $response');
      
      // 检查响应数据
      if (response.length >= 2) {
        final otaError = response[1];
        
        // 如果有错误，发布错误事件
        if (otaError > 0) {
          print('[OTA] 跳转至镜像更新失败: 错误代码 $otaError');
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            '跳转至镜像更新失败: 错误代码 $otaError'
          ));
          throw Exception('跳转至镜像更新失败: 错误代码 $otaError');
        }
      }
      
      print('[OTA] 跳转至镜像更新成功');
      
    } catch (error) {
      print('[OTA] 跳转至镜像更新失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '跳转至镜像更新失败: $error'
      ));
      rethrow;
    }
  }
  
  /// 销毁资源
  void dispose() {
    _upgradeStatusController.close();
  }
}