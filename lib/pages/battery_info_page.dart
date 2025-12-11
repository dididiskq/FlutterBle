import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';

class BatteryInfoPage extends StatelessWidget {
  const BatteryInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 模拟保护事件数据
    final protectionEvents = [
      {'time': '2023-10-15 14:30:22', 'event': '过压保护'},
      {'time': '2023-10-14 09:15:45', 'event': '过流保护'},
      {'time': '2023-10-12 18:45:10', 'event': '低温保护'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      appBar: CommonAppBar(title: '电池信息'),
      body: Container(
        color: const Color(0xFF0A1128),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 电池基本信息
              _buildInfoRow('电池SN', 'BAT20231015001'),
              _buildInfoRow('制造厂家', '新能源科技有限公司'),
              _buildInfoRow('制造厂家型号', 'BT-2023-001'),
              _buildInfoRow('客户名称', '智能设备有限公司'),
              _buildInfoRow('客户型号', 'ID-2023-100'),
              _buildInfoRow('生产日期', '2023-10-15'),
              _buildInfoRow('固件版本', 'V1.2.3'),
              _buildInfoRow('电池类型', '锂电池'),
              _buildInfoRow('电池串数', '16串'),
              _buildInfoRow('BMS时间', '2023-10-16 10:30:22'),
              _buildInfoRow('设计循环次数', '1000次'),
              _buildInfoRow('参考容值', '3.65V'),
              _buildInfoRow('设计容量', '200Ah'),
              _buildInfoRow('最大未充电时间间隔', '72小时'),
              _buildInfoRow('最近未充电间隔时间', '48小时'),
              _buildInfoRow('BT码', 'BT123456789'),
              const SizedBox(height: 20.0),
              
              // 保护时间和保护事件
              _buildSectionTitle('保护记录'),
              const SizedBox(height: 10.0),
              
              // 保护事件列表
              _buildProtectionEventsTable(protectionEvents),
            ],
          ),
        ),
      ),
    );
  }

  // 构建信息行
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

  // 构建 section 标题
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.0,
            color: const Color(0xFF3A475E),
          ),
        ),
        const SizedBox(width: 10.0),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Container(
            height: 1.0,
            color: const Color(0xFF3A475E),
          ),
        ),
      ],
    );
  }

  // 构建保护事件表格
  Widget _buildProtectionEventsTable(List<Map<String, String>> events) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF3A475E), width: 1),
      ),
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          // 表头
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('保护时间', style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text('保护事件', style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ],
          ),
          const Divider(color: Color(0xFF3A475E), height: 20.0),
          
          // 表格内容
          for (var event in events)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(event['time']!, style: const TextStyle(color: Colors.white, fontSize: 14.0)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(event['event']!, style: const TextStyle(color: Colors.red, fontSize: 14.0), textAlign: TextAlign.center),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF3A475E), height: 15.0),
              ],
            ),
        ],
      ),
    );
  }
}