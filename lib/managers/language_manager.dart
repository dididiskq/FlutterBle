import 'package:flutter/foundation.dart';

// 语言类型枚举
enum LanguageType {
  chinese,
  english
}

class LanguageManager extends ChangeNotifier {
  // 当前语言类型
  LanguageType _currentLanguage = LanguageType.chinese;

  // 获取当前语言类型
  LanguageType get currentLanguage => _currentLanguage;

  // 判断是否为中文
  bool get isChinese => _currentLanguage == LanguageType.chinese;

  // 判断是否为英文
  bool get isEnglish => _currentLanguage == LanguageType.english;

  // 切换语言
  void toggleLanguage() {
    if (_currentLanguage == LanguageType.chinese) {
      _currentLanguage = LanguageType.english;
    } else {
      _currentLanguage = LanguageType.chinese;
    }
    notifyListeners();
  }

  // 获取按钮文本
  String get toggleLanguageButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '切换为英文';
    } else {
      return 'change to Chinese';
    }
  }

  // 设备控制页面相关
  String get deviceControlPageTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '设备控制';
    } else {
      return 'Device Control';
    }
  }

  String get systemShutdownText {
    if (_currentLanguage == LanguageType.chinese) {
      return '系统关机';
    } else {
      return 'System Shutdown';
    }
  }

  String get restoreFactoryText {
    if (_currentLanguage == LanguageType.chinese) {
      return '恢复出厂';
    } else {
      return 'Restore Factory';
    }
  }

  String get restartSystemText {
    if (_currentLanguage == LanguageType.chinese) {
      return '重启系统';
    } else {
      return 'Restart System';
    }
  }

  String get weakPowerSwitchText {
    if (_currentLanguage == LanguageType.chinese) {
      return '弱电开关';
    } else {
      return 'Weak Power Switch';
    }
  }

  String get forceChargeControlText {
    if (_currentLanguage == LanguageType.chinese) {
      return '强制充电控制';
    } else {
      return 'Force Charge Control';
    }
  }

  String get cancelForceChargeText {
    if (_currentLanguage == LanguageType.chinese) {
      return '取消强制充电';
    } else {
      return 'Cancel Force Charge';
    }
  }

  String get forceDischargeControlText {
    if (_currentLanguage == LanguageType.chinese) {
      return '强制放电控制';
    } else {
      return 'Force Discharge Control';
    }
  }

  String get cancelForceDischargeText {
    if (_currentLanguage == LanguageType.chinese) {
      return '取消强制放电';
    } else {
      return 'Cancel Force Discharge';
    }
  }

  // 隐私政策页面相关
  String get privacyPolicyPageTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '隐私协议';
    } else {
      return 'Privacy Policy';
    }
  }

  // 异常信息页面相关
  String get alarmInfoPageTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '异常信息';
    } else {
      return 'Alarm Info';
    }
  }

  String get warningInfoTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '警告信息';
    } else {
      return 'Warning Info';
    }
  }

  String get protectionInfoTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '保护信息';
    } else {
      return 'Protection Info';
    }
  }

  String get batteryStatusTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '电池状态';
    } else {
      return 'Battery Status';
    }
  }

  String get noAlarmInfo {
    if (_currentLanguage == LanguageType.chinese) {
      return '无异常信息';
    } else {
      return 'No Alarm Info';
    }
  }

  // 设置页面相关
  String get setPageTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '设置';
    } else {
      return 'Settings';
    }
  }

  String get bmsParamsConfig {
    if (_currentLanguage == LanguageType.chinese) {
      return 'BMS参数配置';
    } else {
      return 'BMS Params Config';
    }
  }

  String get quickSettingsTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '快速设置';
    } else {
      return 'Quick Settings';
    }
  }

  String get voltageParamsTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '电压参数';
    } else {
      return 'Voltage Params';
    }
  }

  String get temperatureParamsTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '温度参数';
    } else {
      return 'Temperature Params';
    }
  }

  String get currentParamsTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '电流参数';
    } else {
      return 'Current Params';
    }
  }

  String get balanceParamsTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '均衡参数';
    } else {
      return 'Balance Params';
    }
  }

  String get systemParamsTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '系统参数';
    } else {
      return 'System Params';
    }
  }

  String get chargeMos {
    if (_currentLanguage == LanguageType.chinese) {
      return '充电MOS';
    } else {
      return 'Charge MOS';
    }
  }

  String get dischargeMos {
    if (_currentLanguage == LanguageType.chinese) {
      return '放电MOS';
    } else {
      return 'Discharge MOS';
    }
  }

  String get totalCapacity {
    if (_currentLanguage == LanguageType.chinese) {
      return '总容量';
    } else {
      return 'Total Capacity';
    }
  }

  String get batteryInfo {
    if (_currentLanguage == LanguageType.chinese) {
      return '电池信息';
    } else {
      return 'Battery Info';
    }
  }

  String get totalVoltage {
    if (_currentLanguage == LanguageType.chinese) {
      return '总电压';
    } else {
      return 'Total Voltage';
    }
  }

  String get totalCurrent {
    if (_currentLanguage == LanguageType.chinese) {
      return '总电流';
    } else {
      return 'Total Current';
    }
  }

  String get voltageDiff {
    if (_currentLanguage == LanguageType.chinese) {
      return '压差';
    } else {
      return 'Voltage Diff';
    }
  }

  String get maxVoltage {
    if (_currentLanguage == LanguageType.chinese) {
      return '最高电压';
    } else {
      return 'Max Voltage';
    }
  }

  String get minVoltage {
    if (_currentLanguage == LanguageType.chinese) {
      return '最低电压';
    } else {
      return 'Min Voltage';
    }
  }

  String get cycleCount {
    if (_currentLanguage == LanguageType.chinese) {
      return '循环次数';
    } else {
      return 'Cycle Count';
    }
  }

  String get power {
    if (_currentLanguage == LanguageType.chinese) {
      return '功率';
    } else {
      return 'Power';
    }
  }

  String get temperatureInfo {
    if (_currentLanguage == LanguageType.chinese) {
      return '温度信息';
    } else {
      return 'Temperature Info';
    }
  }

  String get mosTemp {
    if (_currentLanguage == LanguageType.chinese) {
      return 'MOS温度';
    } else {
      return 'MOS Temp';
    }
  }

  String get t1Temp {
    if (_currentLanguage == LanguageType.chinese) {
      return 'T1温度';
    } else {
      return 'T1 Temp';
    }
  }

  String get t2Temp {
    if (_currentLanguage == LanguageType.chinese) {
      return 'T2温度';
    } else {
      return 'T2 Temp';
    }
  }

  String get t3Temp {
    if (_currentLanguage == LanguageType.chinese) {
      return 'T3温度';
    } else {
      return 'T3 Temp';
    }
  }

  String get cellVoltage {
    if (_currentLanguage == LanguageType.chinese) {
      return '单体电压';
    } else {
      return 'Cell Voltage';
    }
  }

  String get voltage {
    if (_currentLanguage == LanguageType.chinese) {
      return '电压';
    } else {
      return 'Voltage';
    }
  }

  String get current {
    if (_currentLanguage == LanguageType.chinese) {
      return '电流';
    } else {
      return 'Current';
    }
  }

  String get batteryTemperature {
    if (_currentLanguage == LanguageType.chinese) {
      return '电池温度';
    } else {
      return 'Battery Temperature';
    }
  }

  String get abnormalAlarm {
    if (_currentLanguage == LanguageType.chinese) {
      return '异常警报';
    } else {
      return 'Abnormal Alarm';
    }
  }

  // 固件升级页面相关
  String get firmwareVersion {
    if (_currentLanguage == LanguageType.chinese) {
      return '固件版本';
    } else {
      return 'Firmware Version';
    }
  }

  String get softwareVersion {
    if (_currentLanguage == LanguageType.chinese) {
      return '软件版本';
    } else {
      return 'Software Version';
    }
  }

  String get checkUpdate {
    if (_currentLanguage == LanguageType.chinese) {
      return '检查更新';
    } else {
      return 'Check Update';
    }
  }

  String get downloadFirmware {
    if (_currentLanguage == LanguageType.chinese) {
      return '下载固件';
    } else {
      return 'Download Firmware';
    }
  }

  String get firmwareUpdateInfo {
    if (_currentLanguage == LanguageType.chinese) {
      return '固件更新信息:';
    } else {
      return 'Firmware Update Info:';
    }
  }

  String get currentVersion {
    if (_currentLanguage == LanguageType.chinese) {
      return '当前版本:';
    } else {
      return 'Current Version:';
    }
  }

  String get latestVersion {
    if (_currentLanguage == LanguageType.chinese) {
      return '最新版本:';
    } else {
      return 'Latest Version:';
    }
  }

  String get firmwareDescription {
    if (_currentLanguage == LanguageType.chinese) {
      return '固件描述:';
    } else {
      return 'Firmware Description:';
    }
  }

  String get selectedFirmwareFile {
    if (_currentLanguage == LanguageType.chinese) {
      return '已选择固件文件:';
    } else {
      return 'Selected Firmware File:';
    }
  }

  String get firmwareSize {
    if (_currentLanguage == LanguageType.chinese) {
      return '固件大小';
    } else {
      return 'Firmware Size';
    }
  }

  String get upgradeStatus {
    if (_currentLanguage == LanguageType.chinese) {
      return '升级状态:';
    } else {
      return 'Upgrade Status:';
    }
  }

  String get upgradeProgress {
    if (_currentLanguage == LanguageType.chinese) {
      return '升级进度:';
    } else {
      return 'Upgrade Progress:';
    }
  }

  String get ready {
    if (_currentLanguage == LanguageType.chinese) {
      return '就绪';
    } else {
      return 'Ready';
    }
  }

  String get checkingUpdate {
    if (_currentLanguage == LanguageType.chinese) {
      return '检查更新';
    } else {
      return 'Checking Update';
    }
  }

  String get downloading {
    if (_currentLanguage == LanguageType.chinese) {
      return '下载中';
    } else {
      return 'Downloading';
    }
  }

  String get upgrading {
    if (_currentLanguage == LanguageType.chinese) {
      return '升级中';
    } else {
      return 'Upgrading';
    }
  }

  String get upgradeCompleted {
    if (_currentLanguage == LanguageType.chinese) {
      return '升级完成';
    } else {
      return 'Upgrade Completed';
    }
  }

  String get upgradeFailed {
    if (_currentLanguage == LanguageType.chinese) {
      return '升级失败';
    } else {
      return 'Upgrade Failed';
    }
  }

  String get startUpgrade {
    if (_currentLanguage == LanguageType.chinese) {
      return '开始升级';
    } else {
      return 'Start Upgrade';
    }
  }

  // 扫描页面相关
  String get needCameraPermission {
    if (_currentLanguage == LanguageType.chinese) {
      return '需要摄像头权限';
    } else {
      return 'Camera permission required';
    }
  }

  String get alignQrCodeToFrame {
    if (_currentLanguage == LanguageType.chinese) {
      return '请将二维码对准扫描框';
    } else {
      return 'Align QR code to frame';
    }
  }

  String get cameraPermissionDenied {
    if (_currentLanguage == LanguageType.chinese) {
      return '摄像头权限被拒绝';
    } else {
      return 'Camera permission denied';
    }
  }

  // 参数页面通用
  String get item {
    if (_currentLanguage == LanguageType.chinese) {
      return '项目';
    } else {
      return 'Item';
    }
  }

  String get parameter {
    if (_currentLanguage == LanguageType.chinese) {
      return '参数';
    } else {
      return 'Parameter';
    }
  }

  String get setting {
    if (_currentLanguage == LanguageType.chinese) {
      return '设定';
    } else {
      return 'Setting';
    }
  }

  String get writing {
    if (_currentLanguage == LanguageType.chinese) {
      return '写入中...';
    } else {
      return 'Writing...';
    }
  }

  // 均衡参数相关
  String get balanceStartVoltage {
    if (_currentLanguage == LanguageType.chinese) {
      return '均衡启动电压';
    } else {
      return 'Balance Start Voltage';
    }
  }

  String get balanceStartThreshold {
    if (_currentLanguage == LanguageType.chinese) {
      return '均衡启动阈值';
    } else {
      return 'Balance Start Threshold';
    }
  }

  String get balanceDelay {
    if (_currentLanguage == LanguageType.chinese) {
      return '均衡延时';
    } else {
      return 'Balance Delay';
    }
  }

  // 主页面相关
  String get mainPageTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return 'Ultra Bms';
    } else {
      return 'Ultra Bms';
    }
  }

  String get deviceListButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '设备列表';
    } else {
      return 'Device List';
    }
  }

  String get scanButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '扫一扫';
    } else {
      return 'Scan';
    }
  }

  // 我的页面相关
  String get minePageTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '我的';
    } else {
      return 'Mine';
    }
  }

  String get batteryInfoButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '电池信息';
    } else {
      return 'Battery Info';
    }
  }

  String get firmwareUpdateButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '固件升级';
    } else {
      return 'Firmware Update';
    }
  }

  String get productionPanelButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '生产操作面板';
    } else {
      return 'Production Panel';
    }
  }

  String get bmsControlButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return 'BMS控制';
    } else {
      return 'BMS Control';
    }
  }

  String get protocolPolicyButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '协议与政策';
    } else {
      return 'Protocol & Policy';
    }
  }

  // 固件升级页面相关
  String get firmwareUpdatePageTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '固件升级';
    } else {
      return 'Firmware Update';
    }
  }

  // 扫描页面相关
  String get scanPageTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '扫描设备';
    } else {
      return 'Scan Device';
    }
  }

  // 电池信息页面相关
  String get batteryInfoPageTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '电池信息';
    } else {
      return 'Battery Info';
    }
  }

  // 生产操作面板页面相关
  String get productionPanelPageTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '生产操作面板';
    } else {
      return 'Production Panel';
    }
  }

  // 设备列表页面相关
  String get deviceListPageTitle {
    if (_currentLanguage == LanguageType.chinese) {
      return '设备列表';
    } else {
      return 'Device List';
    }
  }

  String get connectButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '连接';
    } else {
      return 'Connect';
    }
  }

  String get disconnectButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '断开';
    } else {
      return 'Disconnect';
    }
  }

  // 通用文本
  String get backButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '返回';
    } else {
      return 'Back';
    }
  }

  String get saveButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '保存';
    } else {
      return 'Save';
    }
  }

  String get cancelButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '取消';
    } else {
      return 'Cancel';
    }
  }

  String get confirmButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '确认';
    } else {
      return 'Confirm';
    }
  }

  String get okButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '确定';
    } else {
      return 'OK';
    }
  }

  String get yesButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '是';
    } else {
      return 'Yes';
    }
  }

  String get noButtonText {
    if (_currentLanguage == LanguageType.chinese) {
      return '否';
    } else {
      return 'No';
    }
  }
}
