import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// 静态资源管理器
/// 提供统一的资源加载和访问接口
class AssetManager {
  // 图片资源路径
  static const String _imagesPath = 'assets/images/';
  static const String _iconsPath = 'assets/icons/';
  static const String _dataPath = 'assets/data/';
  static const String _fontsPath = 'assets/fonts/';

  /// 图片资源路径常量
  static const String emptyStateImage = '${_imagesPath}empty_state.svg';
  static const String loadingImage = '${_imagesPath}loading.svg';

  /// 图标资源路径常量
  static const String appLogo = '${_iconsPath}app_logo.svg';
  static const String userAvatar = '${_iconsPath}user_avatar.svg';
  static const String questionBankIcon = '${_iconsPath}question_bank.svg';

  /// 数据文件路径常量
  static const String sampleQuestionsData = '${_dataPath}sample_questions.json';
  static const String appConfigData = '${_dataPath}app_config.json';

  /// 加载JSON数据文件
  /// 
  /// [path] 资源文件路径
  /// 返回解析后的JSON对象
  static Future<Map<String, dynamic>> loadJsonData(String path) async {
    try {
      final String jsonString = await rootBundle.loadString(path);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('加载JSON数据失败: $path, 错误: $e');
      return {};
    }
  }

  /// 加载文本文件
  /// 
  /// [path] 资源文件路径
  /// 返回文件内容字符串
  static Future<String> loadTextData(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      debugPrint('加载文本数据失败: $path, 错误: $e');
      return '';
    }
  }

  /// 检查资源文件是否存在
  /// 
  /// [path] 资源文件路径
  /// 返回文件是否存在
  static Future<bool> assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取图片资源路径
  /// 
  /// [filename] 图片文件名
  /// 返回完整的资源路径
  static String getImagePath(String filename) {
    return '$_imagesPath$filename';
  }

  /// 获取图标资源路径
  /// 
  /// [filename] 图标文件名
  /// 返回完整的资源路径
  static String getIconPath(String filename) {
    return '$_iconsPath$filename';
  }

  /// 获取数据文件路径
  /// 
  /// [filename] 数据文件名
  /// 返回完整的资源路径
  static String getDataPath(String filename) {
    return '$_dataPath$filename';
  }

  /// 获取字体文件路径
  /// 
  /// [filename] 字体文件名
  /// 返回完整的资源路径
  static String getFontPath(String filename) {
    return '$_fontsPath$filename';
  }

  /// 预加载重要资源
  /// 在应用启动时调用，提前加载常用资源
  static Future<void> preloadAssets() async {
    try {
      // 预加载应用配置
      await loadJsonData(appConfigData);
      
      // 预加载示例题库数据
      await loadJsonData(sampleQuestionsData);
      
      debugPrint('静态资源预加载完成');
    } catch (e) {
      debugPrint('静态资源预加载失败: $e');
    }
  }

  /// 获取所有可用的图标列表
  /// 返回图标文件名列表
  static List<String> getAvailableIcons() {
    return [
      'app_logo.svg',
      'user_avatar.svg',
      'question_bank.svg',
    ];
  }

  /// 获取所有可用的图片列表
  /// 返回图片文件名列表
  static List<String> getAvailableImages() {
    return [
      'empty_state.svg',
      'loading.svg',
    ];
  }
}