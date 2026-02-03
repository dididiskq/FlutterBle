import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/common_app_bar.dart';
import '../managers/language_manager.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageManager>(
      builder: (context, languageManager, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A1128),
          appBar: CommonAppBar(title: languageManager.privacyPolicyPageTitle),
          body: Container(
            color: const Color(0xFF0A1128),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    languageManager.isChinese ? 'Ultra BMS APP隐私协议' : 'Ultra BMS APP Privacy Policy',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  
                  // 更新日期
                  Text(
                    languageManager.isChinese ? '更新日期：2026年01月16日' : 'Update Date: 2026-01-16',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(height: 30.0),
                  
                  // 内容部分
                  _buildSection(
                    '尊敬的用户：',
                    '感谢您选择使用Ultra BMS，在此特别提醒您在成为用户之前，请认真阅读本《Ultra BMS APP隐私协议》，确保您充分理解本协议中各条款。请您审慎阅读并选择接受或不接受协议。您使用行为将被视为对本协议的接受。'
                  ),
                  
                  _buildSection(
                    '',
                    'Ultra BMS是由深圳市佳博浩智控科技有限公司(HBJ)运营，Ultra BMS团队(下称"我们")非常重视您的个人信息安全与隐私保护。本隐私政策旨在说明我们在您使用Ultra BMS应用过程中如何收集、使用、存储及保护您的个人信息。请您在使用本应用前仔细阅读以下内容。在使用Ultra BMS产品或服务前，请您务必仔细阅读并透彻理解本政策，在确认充分理解并同意后使用相关产品或服务。'
                  ),
                  
                  _buildSection(
                    '',
                    '本协议可由深圳市佳博浩智控科技有限公司(HBJ)随时更新，更新后的协议条款一旦公布即代替原来的协议条款，恕不再另外通知，用户可在本APP中查阅最新版协议条款。在修改协议条款后，如果用户不接受修改后的条款，请立刻停止使用"Ultra BMS"提供的服务，用户继续使用服务将被视为接受修改后的协议。'
                  ),
                  
                  _buildSection(
                    '',
                    '本隐私条例包含如下内容：\n一、我们收集的信息及目的\n二、信息收集方式\n三、信息的使用范围\n四、信息存储与保护\n五、第三方服务\n六、隐私政策的更新\n七、联系方式'
                  ),
                  
                  _buildSection(
                    '',
                    '我们深知个人信息对您的重要性，并会尽全力保护您的个人信息安全。我们在本隐私政策中所提及的收集、使用、共享及管理的个人信息包括个人敏感信息以及其他的个人信息。我们致力于维持您对我们的信任，并恪守以下原则:权责一致原则、目的明确原则、选择同意原则、最小必要原则、确保安全原则、主体参与原则、公开透明原则等。同时，我们承诺将按业界成熟的安全标准，采取相应的安全保护措施来保护您的个人信息。'
                  ),
                  
                  _buildSection(
                    '',
                    '请您在使用我们的产品或服务前，仔细阅读并确认您已经充分理解本政策所写明的内容，您点击确认后即视为您接受本政策的内容。'
                  ),
                  
                  _buildSection(
                    '一、我们收集的信息及目的',
                    '我们收集信息是为了更好、更优、更准确的提供您所选择的服务。可以在意见反馈的时候得知用户遇到的问题，以便我们更好的为用户提供服务。我们收集的信息的方式如下:\n\n1. 基本信息:在您安装并使用Ultra BMS APP时，我们可能会收集设备的ANDROIDID、MAC地址蓝牙状态信息。这些信息主要用于提供服务、维护产品功能正常运行、优化用户体验及统计分析目的。例如，通过蓝牙状态和连接附近的设备功能来实现特定交互或数据传输服务。\n\n2. 蓝牙:当Ultra BMS APP需要连接配对设备时，我们可能需要访问您的蓝牙权限，以便发现并配对周边的蓝牙设备。这有助于实现设备间的互联互通，比如与Ultra BMS APP相关的配件进行配对，以获取设备的精确数据。\n\n3. 连接附近的设备:当您使用应用内功能需连接附近设备时，我们可能需要访问您的蓝牙权限，以便发现并配对周边的蓝牙设备。这有助于实现设备间的互联互通，比如与Ultra BMS APP相关的配件进行配对，以提供更加丰富和便捷的功能体验。\n\n4. 相机:当您使用应用内功能需获取相机信息时，我们可能需要访问您的相机权限，以便获取您的相机信息。这有助于Ultra BMS APP实现扫描设备二维码连接设备，以提供便捷的连接设备的功能体验。\n\n5. 文件存储管理权限：应用实现了OTA远程升级设备BMS程序的功能，所以需要使用手机的文件存储权限及功能。\n\n6. 传感器权限：应用使用webview组件，webview组件会在用户进入隐私主页时调用矢量传感器、特定传感器。'
                  ),
                  
                  _buildSection(
                    '二、信息收集方式',
                    '我们仅在您使用应用的过程中，按照合法、正当、必要的原则，通过技术手段自动收集上述信息。未经您同意，我们不会超越本政策范围额外收集任何个人信息。'
                  ),
                  
                  _buildSection(
                    '三、信息的使用范围',
                    '我们承诺仅将收集的个人信息用于以下目的:\n• 提供、维护和改进我们的服务;\n• 保障应用及服务的安全稳定运行;\n• 进行数据分析，帮助我们更好地理解用户需求，优化产品功能;\n• 遵守法律法规要求或应政府机关的合法要求'
                  ),
                  
                  _buildSection(
                    '四、信息存储与保护',
                    '我们采取各种措施保护您的个人信息安全，包括但不限于数据加密存储、访问控制机制及安全审计等。同时，我们承诺不会出售或非法向第三方披露您的个人信息，除非事先获得您的明确同意或在法律有明确规定的情况下。'
                  ),
                  
                  _buildSection(
                    '五、第三方服务',
                    '我们可能会接入第三方服务(阿里SDK)，这些第三方按照其各自的隐私政策处理信息。我们建议您查阅并了解这些第三方的隐私条款。'
                  ),
                  
                  _buildSection(
                    '六、隐私政策的更新',
                    '我们保留根据业务发展和法律法规变化更新本隐私政策的权利。任何重大变更，我们将通过应用内通知或其他合适方式告知您。'
                  ),
                  
                  _buildSection(
                    '七、联系方式',
                    '如果您对本隐私政策有任何疑问、意见或建议，欢迎通过以下方式与我们联系：\n联系地址：广东省深圳市龙华区大浪街道华宁路38号港深创新园G栋603-605\n电话：18610370562\n联系邮箱：hbjbms2025@163.com'
                  ),
                  
                  const SizedBox(height: 30.0),
                  
                  // 底部声明
                  Text(
                    languageManager.isChinese ? '© 2026 深圳市佳博浩智控科技有限公司 保留所有权利。' : '© 2026 Shenzhen Jiabo Haozhi Control Technology Co., Ltd. All rights reserved.',
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
      },
    );
  }
  
  // 构建协议的章节
  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: title.startsWith('尊敬的用户：') ? 18.0 : 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15.0),
        ],
        Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 25.0),
      ],
    );
  }
}