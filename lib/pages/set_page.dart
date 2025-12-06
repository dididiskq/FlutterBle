import 'package:flutter/material.dart';

// 侧边栏菜单项数据
class MenuItem {
  final String title;
  final IconData icon;
  final Widget page;

  MenuItem({required this.title, required this.icon, required this.page});
}

class SetPage extends StatelessWidget {
  const SetPage({super.key});

  // 创建侧边栏菜单
  List<MenuItem> _buildMenuItems(BuildContext context) {
    return [
      MenuItem(
        title: '快速设置',
        icon: Icons.settings,
        page: QuickSettingsPage(),
      ),
      MenuItem(
        title: '电压参数',
        icon: Icons.bolt,
        page: VoltageParamsPage(),
      ),
      MenuItem(
        title: '温度参数',
        icon: Icons.thermostat,
        page: TemperatureParamsPage(),
      ),
      MenuItem(
        title: '电流参数',
        icon: Icons.flash_on,
        page: CurrentParamsPage(),
      ),
    ];
  }

  // 构建状态指示器
  Widget _buildStatusIndicator(String label, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ],
    );
  }

  // 构建信息表头
  Widget _buildInfoHeader(String text) {
    return SizedBox(
      width: 80,
      child: Text(
        text,
        style: TextStyle(color: Colors.white70, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  // 构建信息值
  Widget _buildInfoValue(String value) {
    return SizedBox(
      width: 80,
      child: Text(
        value,
        style: const TextStyle(
            color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  // 构建单体电压网格项
  Widget _buildCellVoltageItem(int number, String voltage) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blue[600]!, width: 1),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 编号
          Text(
            '$number',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          // 电压值
          Text(
            voltage,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // 图标
          Icon(
            Icons.battery_4_bar,
            color: Colors.green,
            size: 16,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          color: Colors.blue.withOpacity(0.9), // 设置背景色带透明度
          padding: const EdgeInsets.fromLTRB(
              10.0, 44.0, 10.0, 10.0), // 调整padding避开状态栏
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左侧侧边栏按钮
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              // ultra bms标签
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: const Text(
                  'Ultra Bms',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 右侧空白占位
              const SizedBox(width: 80.0),
            ],
          ),
        ),
      ),
      // 侧边栏抽屉
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 侧边栏头部
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    '设置菜单',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'BMS参数配置',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // 侧边栏菜单项
            ..._buildMenuItems(context).map((item) => ListTile(
                  leading: Icon(item.icon, color: Colors.blue),
                  title: Text(item.title),
                  onTap: () {
                    // 关闭抽屉
                    Navigator.pop(context);
                    // 跳转到对应页面
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => item.page),
                    );
                  },
                )),
          ],
        ),
      ),
      body: Container(
        color: Colors.blue[900],
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SOC显示区
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue[600]!, width: 1),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SOC',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '0%',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              _buildStatusIndicator('充电MOS', Colors.red),
                              const SizedBox(width: 16),
                              _buildStatusIndicator('放电MOS', Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 总容量显示
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue[600]!, width: 1),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '总容量',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '0.00AH',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // 电池信息标题
                const Text(
                  '电池信息',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // 电池信息表格
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue[600]!, width: 1),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      // 电池信息表头
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoHeader('总电压'),
                          _buildInfoHeader('总电流'),
                          _buildInfoHeader('压差'),
                          _buildInfoHeader('最高电压'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 电池信息数据行1
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoValue('1'),
                          _buildInfoValue('1'),
                          _buildInfoValue('1'),
                          _buildInfoValue('1'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 电池信息表头行2
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoHeader('最低电压'),
                          _buildInfoHeader('循环次数'),
                          _buildInfoHeader('功率'),
                          const SizedBox(width: 80), // 占位
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 电池信息数据行2
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoValue('1'),
                          _buildInfoValue('1'),
                          _buildInfoValue('1'),
                          const SizedBox(width: 80), // 占位
                        ],
                      ),
                    ],
                  ),
                ),

                // 温度信息标题
                const Text(
                  '温度信息',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // 温度信息表格
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue[600]!, width: 1),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      // 温度信息表头
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoHeader('MOS温度'),
                          _buildInfoHeader('T1温度'),
                          _buildInfoHeader('T2温度'),
                          _buildInfoHeader('T3温度'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 温度信息数据
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoValue('1'),
                          _buildInfoValue('1'),
                          _buildInfoValue('1'),
                          _buildInfoValue('1'),
                        ],
                      ),
                    ],
                  ),
                ),

                // 单体电压标题
                const Text(
                  '单体电压',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // 单体电压网格布局
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue[600]!, width: 1),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // 每行4个
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 1.0, // 宽高比1:1
                    ),
                    itemCount: 16, // 模拟16个单体电压
                    itemBuilder: (context, index) {
                      return _buildCellVoltageItem(index + 1, '3.27V');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 快速设置页面
class QuickSettingsPage extends StatelessWidget {
  const QuickSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('快速设置'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.settings,
                  size: 60,
                  color: Colors.blue,
                ),
                SizedBox(height: 20),
                Text(
                  '快速设置',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '这里可以设置常用参数',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 电压参数页面
class VoltageParamsPage extends StatelessWidget {
  const VoltageParamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('电压参数'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bolt,
                  size: 60,
                  color: Colors.blue,
                ),
                SizedBox(height: 20),
                Text(
                  '电压参数',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '这里可以查看和设置电压相关参数',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 温度参数页面
class TemperatureParamsPage extends StatelessWidget {
  const TemperatureParamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('温度参数'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.thermostat,
                  size: 60,
                  color: Colors.blue,
                ),
                SizedBox(height: 20),
                Text(
                  '温度参数',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '这里可以查看和设置温度相关参数',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 电流参数页面
class CurrentParamsPage extends StatelessWidget {
  const CurrentParamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('电流参数'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flash_on,
                  size: 60,
                  color: Colors.blue,
                ),
                SizedBox(height: 20),
                Text(
                  '电流参数',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '这里可以查看和设置电流相关参数',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
