# 手冲咖啡记录 ☕

一款记录手冲咖啡冲煮参数的移动应用，使用 Flutter 开发。

## 功能

- 📝 **冲煮记录** — 记录咖啡豆、研磨度、水温、粉量、水量等参数
- 🫘 **豆种管理** — 支持产地、豆种、烘焙度、处理法
- ⏱ **注水段管理** — 记录每段注水的开始时间和水量，自动计算间隔
- ⭐ **品鉴记录** — 好的风味、不好的风味、改进方案
- 💾 **纯本地存储** — 数据保存在手机本地 JSON 文件，无需联网

## 技术栈

- **Flutter** 3.44+ (Dart 3.12+)
- **状态管理**: Provider
- **本地存储**: dart:io 文件读写 (JSON)
- **平台支持**: Android / iOS / Web / Windows

## 构建

```bash
# 获取依赖
flutter pub get

# 运行 (Web)
flutter run -d edge

# 构建 APK
flutter build apk --release

# APK 位置
build/app/outputs/flutter-apk/app-release.apk
```
