import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';
import '../managers/battery_data_manager.dart';
import '../models/battery_data.dart';

class BatteryInfoPage extends StatefulWidget {
  const BatteryInfoPage({super.key});

  @override
  State<BatteryInfoPage> createState() => _BatteryInfoPageState();
}

class _BatteryInfoPageState extends State<BatteryInfoPage> {
  final BatteryDataManager _batteryDataManager = BatteryDataManager();

  String _batterySN = '';
  String _manufacturer = '';
  String _manufacturerModel = '';
  String _customerName = '';
  String _customerModel = '';
  String _mfgDate = '';
  String _firmwareVersion = '';
  String _cellType = '';
  String _cellNumber = '';
  String _bmsTime = '2023-10-16 10:30:22';
  String _designCycleCount = '';
  String _referenceCapacity = '';
  String _designCapacity = '';
  String _maxUnchargedInterval = '';
  String _recentUnchargedInterval = '';
  String _btCode = '';

  List<ProtectionRecord> _protectionRecords = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _readBatteryInfo();
  }

  Future<void> _readBatteryInfo() async {
    if (!_batteryDataManager.isConnected) {
      print('[BatteryInfoPage] 设备未连接，无法读取数据');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('[BatteryInfoPage] 开始读取电池信息...');

    final batterySN = await _batteryDataManager.readBatterySN();
    if (batterySN != null && mounted) {
      setState(() {
        _batterySN = batterySN;
      });
      print('[BatteryInfoPage] 电池SN: $batterySN');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    final manufacturer = await _batteryDataManager.readManufacturer();
    if (manufacturer != null && mounted) {
      setState(() {
        _manufacturer = manufacturer;
      });
      print('[BatteryInfoPage] 制造厂家: $manufacturer');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    final manufacturerModel = await _batteryDataManager.readManufacturerModel();
    if (manufacturerModel != null && mounted) {
      setState(() {
        _manufacturerModel = manufacturerModel;
      });
      print('[BatteryInfoPage] 制造厂商型号: $manufacturerModel');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    final customerName = await _batteryDataManager.readCustomerName();
    if (customerName != null && mounted) {
      setState(() {
        _customerName = customerName;
      });
      print('[BatteryInfoPage] 客户名称: $customerName');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    final customerModel = await _batteryDataManager.readCustomerModel();
    if (customerModel != null && mounted) {
      setState(() {
        _customerModel = customerModel;
      });
      print('[BatteryInfoPage] 客户型号: $customerModel');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    final mfgDate = await _batteryDataManager.readMfgDate();
    if (mfgDate != null && mounted) {
      setState(() {
        _mfgDate = mfgDate;
      });
      print('[BatteryInfoPage] 生产日期: $mfgDate');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    final designCycleCount = await _batteryDataManager.readDesignCycleCount();
    if (designCycleCount != null && mounted) {
      setState(() {
        _designCycleCount = '${designCycleCount}次';
      });
      print('[BatteryInfoPage] 设计循环次数: $designCycleCount');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    final referenceCapacity = await _batteryDataManager.readReferenceCapacity();
    if (referenceCapacity != null && mounted) {
      setState(() {
        _referenceCapacity = '${referenceCapacity}mAh';
      });
      print('[BatteryInfoPage] 参考容值: $referenceCapacity');
    }
    await Future.delayed(const Duration(milliseconds: 100));

    final btCode = await _batteryDataManager.readBTCode();
    if (btCode != null && mounted) {
      setState(() {
        _btCode = btCode;
      });
      print('[BatteryInfoPage] BT码: $btCode');
    }

    final currentData = _batteryDataManager.currentData;
    if (mounted) {
      setState(() {
        _firmwareVersion = 'V${currentData.firmwareVersion >> 8}.${currentData.firmwareVersion & 0xFF}';
        
        final cellTypeMap = {0: '磷酸铁锂', 1: '三元', 2: '钛酸锂', 3: '钠电池'};
        _cellType = cellTypeMap[currentData.cellType] ?? '未知';
        
        _cellNumber = '${currentData.cellNumber}串';
        _designCapacity = '${currentData.designCapacity}mAh';
        _maxUnchargedInterval = '${currentData.maxUnchargedInterval}小时';
        _recentUnchargedInterval = '${currentData.recentUnchargedInterval}小时';
      });
    }

    final protectionRecords = await _batteryDataManager.readProtectionRecords();
    if (protectionRecords != null && mounted) {
      setState(() {
        _protectionRecords = protectionRecords;
      });
      print('[BatteryInfoPage] 读取到 ${protectionRecords.length} 条保护记录');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatBMSDateTime() {
    final currentData = _batteryDataManager.currentData;
    final year = (currentData.rtcYearMonth >> 8) + 2000;
    final month = currentData.rtcYearMonth & 0xFF;
    final day = currentData.rtcDayHour >> 8;
    final hour = currentData.rtcDayHour & 0xFF;
    final minute = currentData.rtcMinuteSecond >> 8;
    final second = currentData.rtcMinuteSecond & 0xFF;
    
    if (year == 2000 && month == 0) {
      return _bmsTime;
    }
    
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} '
           '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bmsTime = _formatBMSDateTime();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      appBar: CommonAppBar(title: '电池信息'),
      body: Container(
        color: const Color(0xFF0A1128),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              if (!_isLoading) ...[
                _buildInfoRow('电池SN', _batterySN.isEmpty ? '-' : _batterySN),
                _buildInfoRow('制造厂家', _manufacturer.isEmpty ? '-' : _manufacturer),
                _buildInfoRow('制造厂家型号', _manufacturerModel.isEmpty ? '-' : _manufacturerModel),
                _buildInfoRow('客户名称', _customerName.isEmpty ? '-' : _customerName),
                _buildInfoRow('客户型号', _customerModel.isEmpty ? '-' : _customerModel),
                _buildInfoRow('生产日期', _mfgDate.isEmpty ? '-' : _mfgDate),
                _buildInfoRow('固件版本', _firmwareVersion.isEmpty ? '-' : _firmwareVersion),
                _buildInfoRow('电池类型', _cellType.isEmpty ? '-' : _cellType),
                _buildInfoRow('电池串数', _cellNumber.isEmpty ? '-' : _cellNumber),
                _buildInfoRow('BMS时间', bmsTime),
                _buildInfoRow('设计循环次数', _designCycleCount.isEmpty ? '-' : _designCycleCount),
                _buildInfoRow('参考容值', _referenceCapacity.isEmpty ? '-' : _referenceCapacity),
                _buildInfoRow('设计容量', _designCapacity.isEmpty ? '-' : _designCapacity),
                _buildInfoRow('最大未充电时间间隔', _maxUnchargedInterval.isEmpty ? '-' : _maxUnchargedInterval),
                _buildInfoRow('最近未充电间隔时间', _recentUnchargedInterval.isEmpty ? '-' : _recentUnchargedInterval),
                _buildInfoRow('BT码', _btCode.isEmpty ? '-' : _btCode),
                const SizedBox(height: 20.0),
                
                // 保护记录区域
                _buildProtectionRecordsSection(),
              ],
              
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16.0)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.blue, fontSize: 16.0),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionRecordsSection() {
    if (_protectionRecords.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: const Color(0xFF3A475E), width: 1),
        ),
        padding: const EdgeInsets.all(20.0),
        child: const Text(
          '暂无保护记录',
          style: TextStyle(color: Colors.grey, fontSize: 16.0),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '保护记录',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12.0),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2332),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFF3A475E), width: 1),
          ),
          child: Column(
            children: [
              // 表头
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF2A3B55),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '序号',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '保护时间',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '保护事件',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 数据行
              ..._protectionRecords.map((record) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${record.index}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        record.time,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        record.event,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
