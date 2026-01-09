# FCM-toolbox

Claude Code 远程监控与控制工具，支持 Web 和 Flutter 客户端。

## 项目组成

| 目录 | 说明 | 技术栈 |
|------|------|--------|
| `/web` | Web 客户端 | React + TypeScript + Vite + Tailwind |
| `/cc_monitor` | Flutter 客户端 | Flutter + Riverpod + Drift |

## 平台支持

| 平台 | Web | Flutter |
|------|-----|---------|
| Web | ✅ | ✅ |
| iOS | - | ✅ |
| Android | - | ✅ |
| macOS | - | ✅ |

## 快速开始

### Web

```bash
cd web
pnpm install
pnpm dev
```

### Flutter

```bash
cd cc_monitor
flutter pub get
flutter run
```

## 开发

### 生成代码 (Flutter)

```bash
cd cc_monitor
dart run build_runner build --delete-conflicting-outputs
```

### 构建发布

```bash
# Web
cd web && pnpm build

# Flutter
cd cc_monitor && flutter build ios      # iOS
cd cc_monitor && flutter build apk      # Android
cd cc_monitor && flutter build macos    # macOS
```

## 文档

详细项目架构请查看 [CLAUDE.md](./CLAUDE.md)
