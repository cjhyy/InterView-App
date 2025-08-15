# 静态资源文件说明

本目录包含了面试助手应用的所有静态资源文件。

## 目录结构

```
assets/
├── images/          # 图片资源
│   ├── empty_state.svg    # 空状态占位图
│   └── loading.svg        # 加载动画图标
├── icons/           # 图标资源
│   ├── app_logo.svg       # 应用Logo
│   ├── user_avatar.svg    # 用户头像占位图
│   └── question_bank.svg  # 题库模块图标
├── data/            # 数据文件
│   ├── sample_questions.json  # 示例题库数据
│   └── app_config.json         # 应用配置数据
└── fonts/           # 字体文件（预留）
```

## 使用方法

### 在Flutter代码中引用图片资源

```dart
// 引用SVG图标
SvgPicture.asset(
  'assets/icons/app_logo.svg',
  width: 64,
  height: 64,
)

// 引用普通图片
Image.asset(
  'assets/images/empty_state.svg',
  width: 120,
  height: 120,
)
```

### 加载JSON数据文件

```dart
import 'dart:convert';
import 'package:flutter/services.dart';

// 加载JSON数据
Future<Map<String, dynamic>> loadJsonData(String path) async {
  final String jsonString = await rootBundle.loadString(path);
  return json.decode(jsonString);
}

// 使用示例
final config = await loadJsonData('assets/data/app_config.json');
final questions = await loadJsonData('assets/data/sample_questions.json');
```

## 注意事项

1. 所有图标和图片都使用SVG格式，确保在不同分辨率下的清晰度
2. JSON数据文件使用UTF-8编码，支持中文内容
3. 添加新的静态资源后，需要在`pubspec.yaml`中更新assets配置
4. 建议使用有意义的文件名，便于维护和管理

## 扩展建议

- `images/`: 可添加启动页背景、引导页图片等
- `icons/`: 可添加更多功能模块的图标
- `data/`: 可添加本地化文件、默认配置等
- `fonts/`: 可添加自定义字体文件