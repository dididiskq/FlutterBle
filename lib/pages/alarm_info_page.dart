import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';
import '../managers/battery_data_manager.dart';
import '../models/battery_data.dart';

class AlarmInfoPage extends StatefulWidget {
  const AlarmInfoPage({super.key});

  @override
  State<AlarmInfoPage> createState() => _AlarmInfoPageState();
}

class _AlarmInfoPageState extends State<AlarmInfoPage> {
  final BatteryDataManager _batteryDataManager = BatteryDataManager();
  final List<AlarmInfo> _warningInfoList = [];
  final List<AlarmInfo> _protectionInfoList = [];
  final List<AlarmInfo> _batteryStatusList = [];

  static const Map<int, String> _warningMessages = {
    0: '超高压报警',
    1: '超低压报警',
    2: '电池组防拆卸报警',
    3: '电压采集线断线报警',
    4: '温度采集线断线报警',
    5: '与AFE通讯失效报警',
    6: '电池组压差过大报警',
    7: '保留位7',
    8: '保留位8',
    9: '保留位9',
    10: '保留位10',
    11: '保留位11',
    12: '保留位12',
    13: '保留位13',
    14: '保留位14',
    15: '保留位15',
  };

  static const Map<int, String> _protectionMessages = {
    0: '过压标志',
    1: '欠压标志',
    2: '放电过流1标志',
    3: '放电过流2标志',
    4: '充电过流标志',
    5: '短路标志',
    6: '断线标志',
    7: '低压禁充标志',
    8: '充电低温标志',
    9: '充电高温标志',
    10: '放电低温标志',
    11: '放电高温标志',
    12: '保留位12',
    13: '保留位13',
    14: '保留位14',
    15: '保留位15',
    16: '放电MOS状态',
    17: '充电MOS状态',
    18: '硬件放电状态',
    19: '硬件充电状态',
    20: 'PRO状态',
    21: 'CTLD状态',
    22: 'PD状态',
    23: '均衡状态',
    24: '保留位24',
    25: '保留位25',
    26: '保留位26',
    27: '保留位27',
    28: '保留位28',
    29: '保留位29',
    30: '保留位30',
    31: '保留位31',
  };

  static const Map<int, String> _batteryStatusMessages = {
    0: '零电流已校准',
    1: '电流已校准',
    2: '强制开启放电',
    3: '强制关闭放电',
    4: '强制开启充电',
    5: '强制关闭充电',
    6: '保留位6',
    7: '保留位7',
    8: '满充电标志',
    9: '保留位9',
    10: '允许容量更新',
    11: '放电标志',
    12: '充电标志',
    13: 'AFE配置失败',
    14: '允许放电',
    15: '正版固件',
  };

  @override
  void initState() {
    super.initState();
    _restoreBatteryData();
    _batteryDataManager.batteryDataStream.listen((data) {
      if (mounted) {
        _updateAlarmLists(data);
      }
    });
  }

  void _restoreBatteryData() {
    final currentData = _batteryDataManager.currentData;
    if (currentData.isNotEmpty) {
      _updateAlarmLists(currentData);
    }
  }

  void _updateAlarmLists(BatteryData data) {
    setState(() {
      _warningInfoList.clear();
      _protectionInfoList.clear();
      _batteryStatusList.clear();

      final timestamp = data.timestamp.toLocal().toString().substring(0, 19);

      for (int i = 0; i < 16; i++) {
        if ((data.warningInfo & (1 << i)) != 0) {
          _warningInfoList.add(AlarmInfo(
            id: i,
            message: _warningMessages[i] ?? '未知警告 $i',
            timestamp: timestamp,
            level: AlarmLevel.warning,
          ));
        }
      }

      for (int i = 0; i < 32; i++) {
        if ((data.protectionInfo & (1 << i)) != 0) {
          _protectionInfoList.add(AlarmInfo(
            id: i,
            message: _protectionMessages[i] ?? '未知保护 $i',
            timestamp: timestamp,
            level: AlarmLevel.protection,
          ));
        }
      }

      for (int i = 0; i < 16; i++) {
        if ((data.batteryStatus & (1 << i)) != 0) {
          _batteryStatusList.add(AlarmInfo(
            id: i,
            message: _batteryStatusMessages[i] ?? '未知状态 $i',
            timestamp: timestamp,
            level: AlarmLevel.normal,
          ));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      appBar: const CommonAppBar(title: '异常信息'),
      body: Container(
        color: const Color(0xFF0A1128),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('警告信息', _warningInfoList, Colors.orange),
              const SizedBox(height: 20),
              _buildSection('保护信息', _protectionInfoList, Colors.red),
              const SizedBox(height: 20),
              _buildSection('电池状态', _batteryStatusList, Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<AlarmInfo> items, Color titleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 60,
          width: double.infinity,
          color: const Color(0xFF2A3B55),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2332),
            border: Border.all(color: const Color(0xFF3A475E), width: 1),
          ),
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    '无异常信息',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFF3A475E).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getColorForLevel(item.level),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.timestamp,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _getIconForLevel(item.level),
                            color: _getColorForLevel(item.level),
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getColorForLevel(AlarmLevel level) {
    switch (level) {
      case AlarmLevel.warning:
        return Colors.orange;
      case AlarmLevel.protection:
        return Colors.red;
      case AlarmLevel.normal:
        return Colors.green;
    }
  }

  IconData _getIconForLevel(AlarmLevel level) {
    switch (level) {
      case AlarmLevel.warning:
        return Icons.warning;
      case AlarmLevel.protection:
        return Icons.error;
      case AlarmLevel.normal:
        return Icons.check_circle;
    }
  }
}

class AlarmInfo {
  final int id;
  final String message;
  final String timestamp;
  final AlarmLevel level;

  AlarmInfo({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.level,
  });
}

enum AlarmLevel {
  warning,
  protection,
  normal,
}
