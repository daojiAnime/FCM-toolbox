# CC Monitor

Claude Code 双向交互监控 App - 接收 FCM 推送通知并支持远程权限确认。

## 功能特性

- 📱 接收来自 Claude Code 的 FCM 推送通知
- ✅ 支持远程批准/拒绝危险操作
- 📊 实时显示任务进度
- 🔔 支持多种消息类型（进度、完成、错误、代码等）

## 开发设置

### 环境要求

- Flutter 3.x
- Dart 3.x
- Firebase 项目配置

### 安装依赖

```bash
flutter pub get
```

### 安装 Git Hooks

为了确保代码质量，建议安装 pre-commit hook：

```bash
./scripts/setup-hooks.sh
```

这将自动在每次提交前运行：
- `dart format` - 检查代码格式
- `flutter analyze` - 静态代码分析

### 运行应用

```bash
flutter run
```

### 代码检查

```bash
# 格式化代码
dart format lib/

# 静态分析
flutter analyze lib/

# 运行测试
flutter test
```

## 项目结构

```
lib/
├── common/          # 通用组件（颜色、常量、主题）
├── models/          # 数据模型
├── pages/           # 页面组件
├── providers/       # Riverpod 状态管理
├── services/        # 服务层（FCM、Firestore、数据库）
├── widgets/         # UI 组件
├── app.dart         # 应用入口组件
└── main.dart        # 应用主入口
```

## 与 Claude Code 集成

详见 [Claude Code 集成指南](docs/claude-code-integration.md)
