import 'dart:async';
import 'dart:typed_data';

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
  static const int OTA_CMD_JUMP_IMAGE_UPDATE = 0x08;    // 跳转至镜像更新

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
  int _firmwareSize = 0;
  
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
    
    _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.idle, 0, '固件文件已选择'));
  }
  
  /// 开始升级流程
  Future<void> startUpgrade() async {
    try {
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
        // 4. 创建设置传输
        await _createOtaSettingTransfer();
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.checkingUpdate, 40, '创建设置传输完成'));
        
        // 5. 发送设置数据
        await _sendSettingData();
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.downloading, 50, '设置数据发送完成'));
        
        // 6. 创建镜像传输
        await _createOtaImageTransfer();
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.downloading, 60, '创建镜像传输完成'));
        
        // 7. 发送镜像数据
        await _sendImageData();
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.upgrading, 90, '镜像数据发送完成'));
        
        // 8. 验证新镜像
        await _validateNewImage();
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.upgrading, 95, '镜像验证完成'));
        
        // 9. 激活新镜像
        await _activateNewImage();
        _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.completed, 100, '升级完成'));
      }
      
    } catch (error) {
      _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.failed, 0, '升级失败: $error'));
      rethrow;
    }
  }
  
  /// 1. 连接参数更新
  Future<void> _connectionUpdate() async {
    // 参数默认值（示例值，需根据实际需求调整）
    final int intervalMin = 6; // 最小连接间隔
    final int intervalMax = 12; // 最大连接间隔
    final int latency = 0; // 从机延迟
    final int timeout = 300; // 连接超时（单位：10ms）

    // 创建Completer等待响应
    final Completer<void> completer = Completer<void>();
    int otaError = 0;

    // 订阅通知回调
    final StreamSubscription<List<int>> subscription = _bleController.notificationStream.listen((data) {
      print('connection_update response: $data');
      final List<int> response = data;
      
      // 检查响应数据长度
      if (response.length >= 2) {
        otaError = response[1];
        
        // 如果有错误，发布错误事件
        if (otaError > 0) {
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            '连接参数更新失败: 错误代码 $otaError'
          ));
          if (!completer.isCompleted) {
            completer.completeError(Exception('连接参数更新失败: 错误代码 $otaError'));
          }
        } else {
          // 检查响应命令是否匹配
          if (response[0] == OTA_CMD_CONN_PARAM_UPDATE) {
            print('连接参数更新响应正确');
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        }
      }
    });

    try {
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

      print('发送连接参数更新命令: $data');
      
      // 写入数据到BLE特征
      await _bleController.writeData(data, withResponse: false);

      // 等待响应或超时
      await completer.future.timeout(const Duration(seconds: 10));
      // 超时异常会自动传播
    } catch (error) {
      print('连接参数更新失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '连接参数更新失败: $error'
      ));
      rethrow;
    } finally {
      // 取消订阅
      await subscription.cancel();
    }
  }
  
  /// 2. MTU 更新
  Future<void> _mtuUpdate() async {
    // 设置MTU值（示例值，需根据实际需求调整）
    const int mtu = 200;

    // 创建Completer等待响应
    final Completer<void> completer = Completer<void>();
    int otaError = 0;

    // 订阅通知回调
    final StreamSubscription<List<int>> subscription = _bleController.notificationStream.listen((data) {
      print('mtu_update response: $data');
      final List<int> response = data;
      
      // 检查响应数据长度
      if (response.length >= 2) {
        otaError = response[1];
        
        // 如果有错误，发布错误事件
        if (otaError > 0) {
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            'MTU更新失败: 错误代码 $otaError'
          ));
          if (!completer.isCompleted) {
            completer.completeError(Exception('MTU更新失败: 错误代码 $otaError'));
          }
        } else {
          // 检查响应命令是否匹配
          if (response[0] == OTA_CMD_MTU_UPDATE) {
            print('MTU更新响应正确');
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        }
      }
    });

    try {
      // 构建MTU更新命令数据
      final Uint8List data = Uint8List(3);
      data[0] = OTA_CMD_MTU_UPDATE;
      data[1] = (mtu >> 8) & 0xFF; // 高位字节
      data[2] = mtu & 0xFF;       // 低位字节

      print('发送MTU更新命令: $data');
      
      // 写入数据到BLE特征
      await _bleController.writeData(data, withResponse: false);

      // 等待响应或超时
      await completer.future.timeout(const Duration(seconds: 10));
      // 超时异常会自动传播
    } catch (error) {
      print('MTU更新失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        'MTU更新失败: $error'
      ));
      rethrow;
    } finally {
      // 取消订阅
      await subscription.cancel();
    }
  }
  
  /// 3. 版本请求
  Future<void> _versionRequest() async {
    // 示例值，实际应该从固件文件信息中获取
    const int app1BinSize = 0; // APP1.bin 大小
    const int app2BinSize = 0; // APP2.bin 大小
    const int imageUpdateBinSize = 1024 * 1024; // ImageUpdate.bin 大小（示例值）
    const int imageUpdateVersion = 0x01000000; // 示例版本号

    // 创建Completer等待响应
    final Completer<void> completer = Completer<void>();
    int otaError = 0;

    // 订阅通知回调
    final StreamSubscription<List<int>> subscription = _bleController.notificationStream.listen((data) {
      print('version_request response: $data');
      final List<int> response = data;
      
      // 检查响应数据长度
      if (response.length >= 14) {
        otaError = 0;
        
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
        
        print('app1_version: 0x${_app1Version.toRadixString(16)}');
        print('app2_version: 0x${_app2Version.toRadixString(16)}');
        print('image_update_version: 0x${_imageUpdateVersion.toRadixString(16)}');
        print('ota_selection: $_otaSelection');
        
        // 根据OTA选择设置固件信息
        if (_otaSelection == 1) {
          _firmwareFilePath = '/APP1.bin';
          _firmwareSize = app1BinSize;
        } else if (_otaSelection == 2) {
          _firmwareFilePath = '/APP2.bin';
          _firmwareSize = app2BinSize;
        } else if (_otaSelection == 3) {
          _firmwareFilePath = '/ImageUpdate.bin';
          _firmwareSize = imageUpdateBinSize;
        }
        
        // 检查OTA选择是否有效
        if (_otaSelection >= 1 && _otaSelection <= 4) {
          // 响应正确，继续升级流程
          if (response[0] == OTA_CMD_VERSION) {
            print('版本请求响应正确');
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        } else {
          // OTA选择无效，发布错误事件
          otaError = 1;
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            '版本请求失败: 无效的OTA选择 $_otaSelection'
          ));
          if (!completer.isCompleted) {
            completer.completeError(Exception('版本请求失败: 无效的OTA选择 $_otaSelection'));
          }
        }
      }
    });

    try {
      // 构建版本请求命令数据
      final Uint8List data = Uint8List(17);
      data[0] = OTA_CMD_VERSION;
      
      // APP1.bin 大小（4字节，大端序）
      data[1] = (app1BinSize >> 24) & 0xFF;
      data[2] = (app1BinSize >> 16) & 0xFF;
      data[3] = (app1BinSize >> 8) & 0xFF;
      data[4] = app1BinSize & 0xFF;
      
      // APP2.bin 大小（4字节，大端序）
      data[5] = (app2BinSize >> 24) & 0xFF;
      data[6] = (app2BinSize >> 16) & 0xFF;
      data[7] = (app2BinSize >> 8) & 0xFF;
      data[8] = app2BinSize & 0xFF;
      
      // ImageUpdate.bin 大小（4字节，大端序）
      data[9] = (imageUpdateBinSize >> 24) & 0xFF;
      data[10] = (imageUpdateBinSize >> 16) & 0xFF;
      data[11] = (imageUpdateBinSize >> 8) & 0xFF;
      data[12] = imageUpdateBinSize & 0xFF;
      
      // ImageUpdate 版本号（4字节，大端序）
      data[13] = (imageUpdateVersion >> 24) & 0xFF;
      data[14] = (imageUpdateVersion >> 16) & 0xFF;
      data[15] = (imageUpdateVersion >> 8) & 0xFF;
      data[16] = imageUpdateVersion & 0xFF;

      print('发送版本请求命令: $data');
      
      // 写入数据到BLE特征
      await _bleController.writeData(data, withResponse: false);

      // 等待响应或超时
      await completer.future.timeout(const Duration(seconds: 10));
      // 超时异常会自动传播
    } catch (error) {
      print('版本请求失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '版本请求失败: $error'
      ));
      rethrow;
    } finally {
      // 取消订阅
      await subscription.cancel();
    }
  }
  
  /// 4. 创建设置传输
  Future<void> _createOtaSettingTransfer() async {
    // DFU设置大小（示例值，实际应该从固件文件信息中获取）
    const int dfuSettingSize = 0; // 示例值

    try {
      // 构建创建设置传输命令数据
      final Uint8List data = Uint8List(5);
      data[0] = OTA_CMD_CREATE_OTA_SETTING;
      
      // DFU设置大小（4字节，大端序）
      data[1] = (dfuSettingSize >> 24) & 0xFF;
      data[2] = (dfuSettingSize >> 16) & 0xFF;
      data[3] = (dfuSettingSize >> 8) & 0xFF;
      data[4] = dfuSettingSize & 0xFF;

      print('创建设置传输命令: $data');
      
      // 写入数据到BLE特征（带响应）
      await _bleController.writeData(data, withResponse: true);
      
      print('创建设置传输成功');
    } catch (error) {
      print('创建设置传输失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '创建设置传输失败: $error'
      ));
      rethrow;
    }
  }
  
  /// 5. 发送设置数据
  Future<void> _sendSettingData([List<int> settingData = const []]) async {
    // 创建Completer等待响应
    final Completer<void> completer = Completer<void>();
    int otaError = 0;

    // 订阅通知回调
    final StreamSubscription<List<int>> subscription = _bleController.notificationStream.listen((data) {
      print('send_setting_data response: $data');
      final List<int> response = data;
      
      // 检查响应数据长度
      if (response.length >= 2) {
        otaError = response[1];
        
        // 如果有错误，发布错误事件
        if (otaError > 0) {
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            '发送设置数据失败: 错误代码 $otaError'
          ));
          if (!completer.isCompleted) {
            completer.completeError(Exception('发送设置数据失败: 错误代码 $otaError'));
          }
        } else {
          // 检查响应命令是否匹配
          if (response[0] == OTA_CMD_CREATE_OTA_SETTING) {
            print('发送设置数据响应正确');
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        }
      }
    });

    try {
      print('发送设置数据: $settingData');
      
      // 写入数据到BLE特征（不带响应，使用拆分数据包的方式）
      await _bleController.writeData(Uint8List.fromList(settingData), withResponse: false);

      // 等待响应或超时
      await completer.future.timeout(const Duration(seconds: 10));
      // 超时异常会自动传播
    } catch (error) {
      print('发送设置数据失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '发送设置数据失败: $error'
      ));
      rethrow;
    } finally {
      // 取消订阅
      await subscription.cancel();
    }
  }
  
  /// 6. 创建镜像传输
  Future<void> _createOtaImageTransfer({int imageOffset = 0, int imageSize = 0, int imageCrc = 0}) async {
    try {
      // 构建创建镜像传输命令数据
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

      print('创建镜像传输命令: $data');
      
      // 写入数据到BLE特征
      await _bleController.writeData(data, withResponse: true);
      
      print('创建镜像传输成功');
    } catch (error) {
      print('创建镜像传输失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '创建镜像传输失败: $error'
      ));
      rethrow;
    }
  }
  
  /// 7. 发送镜像数据
  Future<void> _sendImageData([List<int> imageData = const []]) async {
    // 创建Completer等待响应
    final Completer<void> completer = Completer<void>();
    int otaError = 0;
    int imageSent = 0;

    // 订阅通知回调
    final StreamSubscription<List<int>> subscription = _bleController.notificationStream.listen((data) {
      print('send_image_data response: $data');
      final List<int> response = data;
      
      // 检查响应数据长度
      if (response.length >= 2) {
        otaError = response[1];
        
        // 如果有错误，发布错误事件
        if (otaError > 0) {
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            '发送镜像数据失败: 错误代码 $otaError'
          ));
          if (!completer.isCompleted) {
            completer.completeError(Exception('发送镜像数据失败: 错误代码 $otaError'));
          }
        } else {
          // 检查响应命令是否匹配
          if (response[0] == OTA_CMD_CREATE_OTA_IMAGE) {
            print('发送镜像数据响应正确');
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        }
      }
    });

    try {
      print('开始发送镜像数据，总长度: ${imageData.length}');
      
      // 实现分片发送
      const int maxChunkSize = 20; // 根据MTU大小调整，通常MTU-3
      int offset = 0;
      
      while (offset < imageData.length) {
        // 计算当前分片大小
        final int chunkSize = (offset + maxChunkSize) > imageData.length 
            ? imageData.length - offset 
            : maxChunkSize;
        
        // 获取当前分片数据
        final List<int> chunk = imageData.sublist(offset, offset + chunkSize);
        
        // 写入数据到BLE特征（不带响应）
        await _bleController.writeData(Uint8List.fromList(chunk), withResponse: false);
        
        // 更新发送进度
        imageSent += chunkSize;
        final int progress = _firmwareSize > 0 ? (imageSent * 100) ~/ _firmwareSize : 0;
        
        // 确保进度在60%到90%之间（与原有逻辑保持一致）
        final int adjustedProgress = 60 + ((progress * 30) ~/ 100); // 60%到90%
        _upgradeStatusController.add(UpgradeStatusData(
          UpgradeStatus.downloading,
          adjustedProgress,
          '正在发送镜像数据...'
        ));
        
        // 更新偏移量
        offset += chunkSize;
        
        // 短暂延迟，避免BLE栈过载
        await Future.delayed(const Duration(milliseconds: 10));
      }

      print('镜像数据发送完成，共发送: $imageSent 字节');
      
      // 等待响应或超时
      await completer.future.timeout(const Duration(seconds: 30)); // 增加超时时间以适应大数据传输
      // 超时异常会自动传播
    } catch (error) {
      print('发送镜像数据失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '发送镜像数据失败: $error'
      ));
      rethrow;
    } finally {
      // 取消订阅
      await subscription.cancel();
    }
  }
  
  /// 8. 验证新镜像
  Future<void> _validateNewImage() async {
    // 创建Completer等待响应
    final Completer<void> completer = Completer<void>();
    int otaError = 0;

    // 订阅通知回调
    final StreamSubscription<List<int>> subscription = _bleController.notificationStream.listen((data) {
      print('validate_new_image response: $data');
      final List<int> response = data;
      
      // 检查响应数据长度
      if (response.length >= 2) {
        otaError = response[1];
        
        // 如果有错误，发布错误事件
        if (otaError > 0) {
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            '验证新镜像失败: 错误代码 $otaError'
          ));
          if (!completer.isCompleted) {
            completer.completeError(Exception('验证新镜像失败: 错误代码 $otaError'));
          }
        } else {
          // 检查响应命令是否匹配
          if (response[0] == OTA_CMD_VALIDATE_OTA_IMAGE) {
            print('验证新镜像响应正确');
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        }
      }
    });

    try {
      print('验证新镜像...');
      
      // 构建验证命令数据
      final List<int> data = [OTA_CMD_VALIDATE_OTA_IMAGE];
      
      // 更新进度为90%
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.downloading,
        90,
        '正在验证新镜像...'
      ));
      
      // 写入验证命令到BLE特征（带响应）
      await _bleController.writeData(Uint8List.fromList(data), withResponse: true);
      
      // 等待响应或超时
      await completer.future.timeout(const Duration(seconds: 10));
      // 超时异常会自动传播
      
      print('验证新镜像成功');
      
    } catch (error) {
      print('验证新镜像失败: $error');
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '验证新镜像失败: $error'
      ));
      rethrow;
    } finally {
      // 取消订阅
      await subscription.cancel();
    }
  }
  
  /// 9. 激活新镜像
  Future<void> _activateNewImage() async {
    // 创建Completer用于等待设备响应
    final Completer<void> completer = Completer<void>();
    int otaError = 0;

    // 订阅BLE通知
    final StreamSubscription<List<int>> subscription = _bleController.notificationStream.listen((data) {
      final List<int> response = data;
      if (response.length >= 2) {
        otaError = response[1];
        if (otaError > 0) {
          // 发送错误状态
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            '激活新镜像失败: 错误代码 $otaError'
          ));
          completer.completeError(Exception('激活新镜像失败: 错误代码 $otaError'));
        } else if (response[0] == OTA_CMD_ACTIVATE_OTA_IMAGE) {
          // 接收到激活命令的响应
          completer.complete();
        }
      }
    });

    try {
      // 发送激活命令
      final List<int> activateCommand = [OTA_CMD_ACTIVATE_OTA_IMAGE];
      await _bleController.writeData(Uint8List.fromList(activateCommand), withResponse: false);
      
      // 更新状态为90%进度
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.downloading,
        90,
        '正在激活新镜像...'
      ));

      // 等待设备响应，设置超时时间
      await completer.future.timeout(const Duration(seconds: 30));
    } catch (error) {
      // 发送错误状态
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '激活新镜像失败: $error'
      ));
      rethrow;
    } finally {
      // 取消订阅
      await subscription.cancel();
    }
  }
  
  /// 取消升级
  Future<void> cancelUpgrade() async {
    _upgradeStatusController.add(UpgradeStatusData(UpgradeStatus.idle, 0, '升级已取消'));
  }
  
  /// 跳转至镜像更新
  Future<void> _jumpToImageUpdate() async {
    // 创建Completer用于等待设备响应
    final Completer<void> completer = Completer<void>();
    int otaError = 0;

    // 订阅BLE通知
    final StreamSubscription<List<int>> subscription = _bleController.notificationStream.listen((data) {
      print('jump_to_image_update response: $data');
      final List<int> response = data;
      if (response.length >= 2) {
        otaError = response[1];
        if (otaError > 0) {
          // 发送错误状态
          _upgradeStatusController.add(UpgradeStatusData(
            UpgradeStatus.failed,
            0,
            '跳转至镜像更新失败: 错误代码 $otaError'
          ));
          completer.completeError(Exception('跳转至镜像更新失败: 错误代码 $otaError'));
        } else if (response[0] == OTA_CMD_JUMP_IMAGE_UPDATE) {
          // 接收到跳转命令的响应
          completer.complete();
        }
      }
    });

    try {
      // 发送跳转命令
      final List<int> jumpCommand = [OTA_CMD_JUMP_IMAGE_UPDATE];
      await _bleController.writeData(Uint8List.fromList(jumpCommand), withResponse: false);
      
      // 更新状态
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.upgrading,
        35,
        '正在跳转至镜像更新...'
      ));

      // 等待设备响应，设置超时时间
      await completer.future.timeout(const Duration(seconds: 5));
    } catch (error) {
      // 发送错误状态
      _upgradeStatusController.add(UpgradeStatusData(
        UpgradeStatus.failed,
        0,
        '跳转至镜像更新失败: $error'
      ));
      rethrow;
    } finally {
      // 取消订阅
      await subscription.cancel();
    }
  }
  
  /// 销毁资源
  void dispose() {
    _upgradeStatusController.close();
  }
}