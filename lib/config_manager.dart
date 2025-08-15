import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// 题库模块类
class QuestionModule {
  final String name;
  final String icon;
  
  QuestionModule({
    required this.name,
    required this.icon,
  });
  
  factory QuestionModule.fromJson(Map<String, dynamic> json) {
    return QuestionModule(
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'folder',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
    };
  }
}

// 应用配置类
class AppConfig {
  final String appName;
  final String version;
  final String theme;
  final bool isDarkMode;
  final String language;
  final Map<String, dynamic> userSettings;
  final List<QuestionModule> questionModules;
  
  AppConfig({
    required this.appName,
    required this.version,
    required this.theme,
    required this.isDarkMode,
    required this.language,
    required this.userSettings,
    required this.questionModules,
  });

  // 从JSON创建配置对象
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    List<QuestionModule> modules = [];
    if (json['questionModules'] != null) {
      if (json['questionModules'] is List<String>) {
        // 兼容旧版本数据格式
        modules = (json['questionModules'] as List<String>)
            .map((name) => QuestionModule(name: name, icon: 'folder'))
            .toList();
      } else {
        modules = (json['questionModules'] as List)
            .map((item) => QuestionModule.fromJson(item))
            .toList();
      }
    }
    
    return AppConfig(
      appName: json['appName'] ?? '面试助手',
      version: json['version'] ?? '1.0.0',
      theme: json['theme'] ?? 'blue',
      isDarkMode: json['isDarkMode'] ?? false,
      language: json['language'] ?? 'zh_CN',
      userSettings: Map<String, dynamic>.from(json['userSettings'] ?? {}),
      questionModules: modules,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'version': version,
      'theme': theme,
      'isDarkMode': isDarkMode,
      'language': language,
      'userSettings': userSettings,
      'questionModules': questionModules.map((module) => module.toJson()).toList(),
    };
  }

  // 复制配置对象
  AppConfig copyWith({
    String? appName,
    String? version,
    String? theme,
    bool? isDarkMode,
    String? language,
    Map<String, dynamic>? userSettings,
    List<QuestionModule>? questionModules,
  }) {
    return AppConfig(
      appName: appName ?? this.appName,
      version: version ?? this.version,
      theme: theme ?? this.theme,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      userSettings: userSettings ?? this.userSettings,
      questionModules: questionModules ?? this.questionModules,
    );
  }
}

// 配置管理器
class ConfigManager {
  static const String _configKey = 'app_config';
  static AppConfig? _config;
  
  // 获取配置实例
  static AppConfig get config => _config ?? AppConfig(
    appName: '面试助手',
    version: '1.0.0',
    theme: 'blue',
    isDarkMode: false,
    language: 'zh_CN',
    userSettings: {},
    questionModules: [],
  );
  
  // 初始化配置管理器
  static Future<void> initialize() async {
    await loadConfig();
  }
  
  // 加载配置
  static Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      
      if (configJson != null) {
        try {
          final configMap = json.decode(configJson);
          // 检查解码后的数据类型
          if (configMap is Map<String, dynamic>) {
            _config = AppConfig.fromJson(configMap);
            print('配置加载成功: ${_config!.appName}');
          } else {
            // 如果数据格式不正确，清除并重新创建
            print('配置格式错误，重新创建默认配置');
            await prefs.remove(_configKey);
            await _createDefaultConfig();
          }
        } catch (jsonError) {
          // JSON解析失败，清除并重新创建
          print('JSON解析失败: $jsonError，重新创建默认配置');
          await prefs.remove(_configKey);
          await _createDefaultConfig();
        }
      } else {
        // 如果没有配置文件，创建默认配置
        await _createDefaultConfig();
      }
    } catch (e) {
      print('配置加载失败: $e');
      await _createDefaultConfig();
    }
  }
  
  // 创建默认配置
  static Future<void> _createDefaultConfig() async {
    _config = AppConfig(
      appName: '面试助手',
      version: '1.0.0',
      theme: 'blue',
      isDarkMode: false,
      language: 'zh_CN',
      userSettings: {},
      questionModules: [],
    );
    await saveConfig();
    print('创建默认配置');
  }
  
  // 保存配置
  static Future<void> saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = json.encode(_config!.toJson());
      await prefs.setString(_configKey, configJson);
      print('配置保存成功');
    } catch (e) {
      print('配置保存失败: $e');
    }
  }
  
  // 更新配置
  static Future<void> updateConfig(AppConfig newConfig) async {
    _config = newConfig;
    await saveConfig();
  }
  
  // 重置配置
  static Future<void> resetConfig() async {
    _config = AppConfig(
      appName: '面试助手',
      version: '1.0.0',
      theme: 'blue',
      isDarkMode: false,
      language: 'zh_CN',
      userSettings: {},
      questionModules: [],
    );
    await saveConfig();
  }
  
  // 获取题库模块
  static List<QuestionModule> getQuestionModules() {
    return List<QuestionModule>.from(_config?.questionModules ?? []);
  }
  
  // 添加题库模块
  static Future<void> addQuestionModule(String name, {String icon = 'folder'}) async {
    final module = QuestionModule(name: name, icon: icon);
    final currentModules = getQuestionModules();
    currentModules.add(module);
    _config = _config!.copyWith(questionModules: currentModules);
    await saveConfig();
  }
  
  // 删除题库模块
  static Future<void> removeQuestionModule(String moduleName) async {
    final currentModules = getQuestionModules();
    currentModules.removeWhere((module) => module.name == moduleName);
    _config = _config!.copyWith(questionModules: currentModules);
    await saveConfig();
  }
  
  // 更新模块图标
  static Future<void> updateModuleIcon(String moduleName, String icon) async {
    final currentModules = getQuestionModules();
    final moduleIndex = currentModules.indexWhere((module) => module.name == moduleName);
    if (moduleIndex != -1) {
      currentModules[moduleIndex] = QuestionModule(name: moduleName, icon: icon);
      _config = _config!.copyWith(questionModules: currentModules);
      await saveConfig();
    }
  }
  
  // 更新用户设置
  static Future<void> updateUserSetting(String key, dynamic value) async {
    if (_config != null) {
      final updatedSettings = Map<String, dynamic>.from(_config!.userSettings);
      updatedSettings[key] = value;
      _config = _config!.copyWith(userSettings: updatedSettings);
      await saveConfig();
    }
  }
  
  // 获取用户设置
  static T? getUserSetting<T>(String key) {
    return _config?.userSettings[key] as T?;
  }
  
  // 切换主题模式
  static Future<void> toggleDarkMode() async {
    if (_config != null) {
      _config = _config!.copyWith(isDarkMode: !_config!.isDarkMode);
      await saveConfig();
    }
  }
  
  // 更新主题颜色
  static Future<void> updateTheme(String theme) async {
    if (_config != null) {
      _config = _config!.copyWith(theme: theme);
      await saveConfig();
    }
  }
}