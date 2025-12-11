import 'package:flutter/material.dart';
import '../components/common_app_bar.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1128),
      appBar: CommonAppBar(title: '用户隐私协议'),
      body: Container(
        color: const Color(0xFF0A1128),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              const Text(
                '用户隐私协议',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20.0),
              
              // 更新日期
              const Text(
                '更新日期：2023年10月16日',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14.0,
                ),
              ),
              const SizedBox(height: 30.0),
              
              // 内容部分
              _buildSection(
                '1. 协议的确认与接受',
                '欢迎使用我们的BMS电池管理系统应用。本隐私协议（以下简称"本协议"）旨在说明我们如何收集、使用、存储、披露和保护您的个人信息。' 
                '请您仔细阅读本协议，以了解我们的隐私政策和数据处理实践。' 
                '如果您不同意本协议的任何条款，您应立即停止使用本应用。'
              ),
              
              _buildSection(
                '2. 我们收集的信息',
                '2.1 设备信息：我们可能收集您的设备型号、操作系统版本、设备标识符等信息。' 
                '2.2 使用信息：我们可能收集您对本应用的使用情况，包括功能使用、访问时间、频率等。' 
                '2.3 电池数据：我们可能收集您的电池相关数据，包括电压、电流、温度、电量等，以提供电池管理服务。'
              ),
              
              _buildSection(
                '3. 信息的使用',
                '我们收集的信息主要用于以下目的：' 
                '3.1 提供和维护本应用的功能和服务；' 
                '3.2 改进和优化本应用的性能和用户体验；' 
                '3.3 分析和研究用户行为，以开发新功能；' 
                '3.4 保护用户权益和应用安全；' 
                '3.5 遵守法律法规的要求。'
              ),
              
              _buildSection(
                '4. 信息的披露',
                '我们不会向第三方出售、出租或共享您的个人信息，除非：' 
                '4.1 获得您的明确同意；' 
                '4.2 遵守法律法规的要求或响应政府部门的执法请求；' 
                '4.3 保护我们的合法权益、财产或安全；' 
                '4.4 与我们的关联公司共享，且这些公司同意遵守本协议的规定。'
              ),
              
              _buildSection(
                '5. 信息的保护',
                '我们采取合理的技术和组织措施来保护您的个人信息安全，防止信息泄露、滥用、篡改或损失。' 
                '然而，互联网上的信息传输和存储都无法完全安全，我们不能保证绝对的安全。'
              ),
              
              _buildSection(
                '6. 协议的变更',
                '我们可能会不时更新本协议，以反映我们的隐私政策变化。' 
                '更新后的协议将在应用内发布，您继续使用本应用即表示接受新的协议。'
              ),
              
              _buildSection(
                '7. 联系我们',
                '如果您对本协议有任何疑问或建议，请通过以下方式联系我们：' 
                '电子邮件：privacy@example.com' 
                '电话：+86 12345678900'
              ),
              
              const SizedBox(height: 30.0),
              
              // 底部声明
              const Text(
                '© 2023 新能源科技有限公司 保留所有权利。',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 构建协议的章节
  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10.0),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.0,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}