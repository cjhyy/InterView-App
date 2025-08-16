import 'package:flutter/material.dart';
import '../../config_manager.dart';
import '../../main.dart';
import '../wrong_answer_book/wrong_answer_book_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final config = ConfigManager.config;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          
          // 主题设置卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '主题设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 深色模式开关
                  SwitchListTile(
                    title: const Text('深色模式'),
                    subtitle: const Text('切换应用的明暗主题'),
                    value: config.isDarkMode,
                    onChanged: (value) async {
                      await ConfigManager.toggleDarkMode();
                      if (mounted) {
                        setState(() {});
                        // 使用更优雅的方式通知主题变化
                        MyApp.of(context)?.updateTheme();
                      }
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  const Text(
                    '主题颜色',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  
                  // 主题颜色选择
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildThemeColorChip('blue', Colors.blue, '蓝色'),
                      _buildThemeColorChip('red', Colors.red, '红色'),
                      _buildThemeColorChip('green', Colors.green, '绿色'),
                      _buildThemeColorChip('purple', Colors.purple, '紫色'),
                      _buildThemeColorChip('orange', Colors.orange, '橙色'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 操作按钮
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '操作',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 错题本按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToWrongAnswerBook(),
                      icon: const Icon(Icons.bookmark_border),
                      label: const Text('我的错题本'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // 重置配置按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showResetDialog(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重置所有配置'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  

  
  Widget _buildThemeColorChip(String themeKey, Color color, String label) {
    final config = ConfigManager.config;
    final isSelected = config.theme == themeKey;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        if (selected) {
          await ConfigManager.updateTheme(themeKey);
          if (mounted) {
            setState(() {});
            // 使用更优雅的方式通知主题变化
            MyApp.of(context)?.updateTheme();
          }
        }
      },
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 8,
      ),
    );
  }
  
  void _navigateToWrongAnswerBook() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WrongAnswerBookPage(),
      ),
    );
  }
  
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('重置配置'),
          content: const Text('确定要重置所有配置吗？这将清除所有自定义设置和题库模块。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ConfigManager.resetConfig();
                if (mounted) {
                  setState(() {});
                  // 使用更优雅的方式通知主题变化
                  MyApp.of(context)?.updateTheme();
                  // 显示重置成功提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('配置已重置')),
                  );
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}