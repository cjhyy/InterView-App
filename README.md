# InterView-App

一个基于Flutter开发的面试题库应用，帮助用户进行面试准备和练习。

## 功能特性

- 📚 **题库管理**: 支持多种题目类型和分类
- 🧪 **模拟测试**: 提供真实的面试测试环境
- 👤 **个人中心**: 用户设置和学习进度管理
- 🎨 **主题切换**: 支持多种主题颜色和暗黑模式
- 🌐 **多语言支持**: 支持中英文切换
- 💾 **数据持久化**: 本地存储用户设置和进度

## 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart
- **状态管理**: Provider/setState
- **本地存储**: SharedPreferences
- **网络请求**: HTTP
- **UI组件**: Material Design 3

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── config_manager.dart       # 配置管理
├── pages/                    # 页面目录
│   ├── profile/             # 个人中心页面
│   ├── question_bank/       # 题库页面
│   └── test/                # 测试页面
└── utils/                   # 工具类
    └── asset_manager.dart   # 资源管理

assets/
├── data/                    # 数据文件
│   ├── app_config.json     # 应用配置
│   └── sample_questions.json # 示例题目
├── icons/                   # 图标资源
├── images/                  # 图片资源
└── fonts/                   # 字体资源
```

## 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- iOS开发需要Xcode (仅macOS)

### 安装步骤

1. 克隆项目
```bash
git clone https://github.com/your-username/InterView-App.git
cd InterView-App
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行项目
```bash
# 调试模式
flutter run

# 发布模式
flutter run --release
```

### 支持平台

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows

## 配置说明

### 应用配置

应用的主要配置位于 `assets/data/app_config.json`，包括：

- 应用名称和版本
- 主题颜色配置
- 默认设置
- 支持的语言

### 题目数据

题目数据存储在 `assets/data/sample_questions.json`，支持自定义题目格式。

## 开发指南

### 代码规范

项目使用 `flutter_lints` 进行代码检查，运行以下命令检查代码质量：

```bash
flutter analyze
```

### 测试

```bash
# 运行单元测试
flutter test

# 运行集成测试
flutter drive --target=test_driver/app.dart
```

### 构建

```bash
# Android APK
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

## 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue
- 发送邮件至: your-email@example.com

## 更新日志

### v1.0.0 (2024-01-01)
- 初始版本发布
- 基础题库功能
- 模拟测试功能
- 个人中心功能
