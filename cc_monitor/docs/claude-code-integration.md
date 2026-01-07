# Claude Code 双向交互集成指南

## 概述

本指南介绍如何在 Claude Code 中集成 CC Monitor 的双向交互功能，实现：

1. **下行推送**: Claude Code → FCM → App（通知用户）
2. **上行响应**: App → Firestore → Claude Code（用户响应）

## 架构图

```
┌─────────────────┐    createInteraction    ┌─────────────────┐
│   Claude Code   │ ───────────────────────→│ Firebase        │
│   (Hook/脚本)   │                         │ Functions       │
└─────────────────┘                         └────────┬────────┘
        ↑                                            │
        │ waitInteraction                            │ FCM Push
        │ (轮询等待)                                  ↓
        │                                   ┌─────────────────┐
        │                                   │   CC Monitor    │
        │                                   │   (手机 App)    │
        │                                   └────────┬────────┘
        │                                            │
        │        respondInteraction                  │ 用户点击
        └────────────────────────────────────────────┘
                    (通过 Firestore)
```

## 配置要求

### 1. Firebase 项目配置

确保已启用以下服务：
- Cloud Functions
- Cloud Firestore
- Cloud Messaging (FCM)

### 2. 获取设备 Token

在 CC Monitor App 的设置页面可以复制 FCM Token。

## API 说明

### createInteraction - 创建交互请求

```bash
# 请求
POST https://us-central1-{project-id}.cloudfunctions.net/createInteraction

# 参数
{
  "data": {
    "to": "FCM_DEVICE_TOKEN",        # 目标设备 Token
    "type": "permission",             # 交互类型: permission|confirm|input|choice
    "title": "执行危险操作",           # 标题
    "message": "是否允许删除文件?",    # 消息内容
    "metadata": {                     # 可选元数据
      "toolName": "rm -rf /tmp/*",
      "filePath": "/tmp/test.txt"
    },
    "timeout": 300                    # 超时时间(秒), 默认 300
  }
}

# 响应
{
  "result": {
    "requestId": "abc123xyz",
    "status": "pending"
  }
}
```

### waitInteraction - 等待用户响应

```bash
# 请求
POST https://us-central1-{project-id}.cloudfunctions.net/waitInteraction

# 参数
{
  "data": {
    "requestId": "abc123xyz",
    "timeout": 30                     # 轮询超时(秒), 最大 60
  }
}

# 响应 (用户已响应)
{
  "result": {
    "requestId": "abc123xyz",
    "status": "approved",             # approved|denied|timeout
    "response": {},
    "respondedAt": "2025-01-07T12:00:00Z"
  }
}

# 响应 (轮询超时但请求仍待处理)
{
  "result": {
    "requestId": "abc123xyz",
    "status": "polling_timeout",
    "message": "Polling timeout, interaction still pending"
  }
}
```

## Claude Code Hook 示例

### Python 版本 (推荐)

创建文件 `~/.claude/hooks/permission_hook.py`:

```python
#!/usr/bin/env python3
"""
Claude Code 权限确认 Hook

使用方法:
1. 配置 ~/.claude/settings.json 添加 hook
2. 设置环境变量 FCM_DEVICE_TOKEN (设备 FCM Token)
"""

import json
import os
import sys
import time
import urllib.request
import urllib.error

# 配置
FIREBASE_PROJECT_ID = "ccpush-45c62"
FUNCTIONS_BASE_URL = f"https://us-central1-{FIREBASE_PROJECT_ID}.cloudfunctions.net"
DEVICE_TOKEN = os.environ.get("FCM_DEVICE_TOKEN", "")

def call_function(name: str, data: dict) -> dict:
    """调用 Firebase Function"""
    url = f"{FUNCTIONS_BASE_URL}/{name}"
    payload = json.dumps({"data": data}).encode("utf-8")

    req = urllib.request.Request(
        url,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=70) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            return result.get("result", result)
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        raise Exception(f"HTTP {e.code}: {error_body}")

def request_permission(
    title: str,
    message: str,
    interaction_type: str = "permission",
    metadata: dict = None,
    timeout: int = 300
) -> bool:
    """
    请求用户权限确认

    Args:
        title: 标题
        message: 详细消息
        interaction_type: 交互类型 (permission/confirm/input/choice)
        metadata: 额外元数据
        timeout: 超时时间(秒)

    Returns:
        bool: True=批准, False=拒绝

    Raises:
        TimeoutError: 超时未响应
        Exception: 其他错误
    """
    if not DEVICE_TOKEN:
        raise ValueError("FCM_DEVICE_TOKEN 环境变量未设置")

    # 创建交互请求
    create_result = call_function("createInteraction", {
        "to": DEVICE_TOKEN,
        "type": interaction_type,
        "title": title,
        "message": message,
        "metadata": metadata or {},
        "timeout": timeout
    })

    request_id = create_result["requestId"]
    print(f"[CC Monitor] 已发送权限请求: {request_id}", file=sys.stderr)
    print(f"[CC Monitor] 等待用户响应...", file=sys.stderr)

    # 轮询等待响应
    start_time = time.time()
    while time.time() - start_time < timeout:
        wait_result = call_function("waitInteraction", {
            "requestId": request_id,
            "timeout": min(30, timeout - int(time.time() - start_time))
        })

        status = wait_result["status"]

        if status == "approved":
            print(f"[CC Monitor] ✓ 用户已批准", file=sys.stderr)
            return True
        elif status == "denied":
            print(f"[CC Monitor] ✗ 用户已拒绝", file=sys.stderr)
            return False
        elif status == "timeout":
            raise TimeoutError("请求已超时")
        elif status == "polling_timeout":
            # 继续轮询
            continue
        else:
            raise Exception(f"未知状态: {status}")

    raise TimeoutError("等待响应超时")

# ============== Claude Code Hook 入口 ==============

def main():
    """
    Hook 入口函数

    从 stdin 读取 Claude Code 的 hook 数据
    根据工具类型决定是否需要用户确认
    """
    # 读取 hook 输入
    hook_input = json.load(sys.stdin)

    # 获取工具信息
    tool_name = hook_input.get("tool_name", "")
    tool_input = hook_input.get("tool_input", {})

    # 定义需要确认的危险操作
    dangerous_tools = {
        "bash": ["rm ", "sudo ", "chmod ", "chown ", "> /", ">> /"],
        "write": ["/etc/", "/usr/", "/bin/", "/sbin/"],
        "edit": ["/etc/", "/usr/", "/bin/", "/sbin/"],
    }

    # 检查是否为危险操作
    needs_confirmation = False
    danger_reason = ""

    if tool_name == "bash":
        command = tool_input.get("command", "")
        for pattern in dangerous_tools.get("bash", []):
            if pattern in command:
                needs_confirmation = True
                danger_reason = f"命令包含危险操作: {pattern}"
                break

    elif tool_name in ["write", "edit"]:
        file_path = tool_input.get("file_path", "")
        for pattern in dangerous_tools.get(tool_name, []):
            if file_path.startswith(pattern):
                needs_confirmation = True
                danger_reason = f"操作系统关键路径: {pattern}"
                break

    # 如果不需要确认，直接允许
    if not needs_confirmation:
        print(json.dumps({"action": "allow"}))
        return

    # 请求用户确认
    try:
        approved = request_permission(
            title=f"确认执行 {tool_name}",
            message=danger_reason,
            metadata={
                "toolName": tool_name,
                "toolInput": json.dumps(tool_input)[:500]
            },
            timeout=120
        )

        if approved:
            print(json.dumps({"action": "allow"}))
        else:
            print(json.dumps({
                "action": "block",
                "message": "用户拒绝了此操作"
            }))

    except TimeoutError:
        print(json.dumps({
            "action": "block",
            "message": "等待用户确认超时"
        }))

    except Exception as e:
        # 出错时默认允许（可改为 block）
        print(f"[CC Monitor] 错误: {e}", file=sys.stderr)
        print(json.dumps({"action": "allow"}))

if __name__ == "__main__":
    main()
```

### Shell 版本 (简化)

创建文件 `~/.claude/hooks/permission_hook.sh`:

```bash
#!/bin/bash
# Claude Code 权限确认 Hook (简化版)

FIREBASE_PROJECT_ID="ccpush-45c62"
FUNCTIONS_URL="https://us-central1-${FIREBASE_PROJECT_ID}.cloudfunctions.net"
DEVICE_TOKEN="${FCM_DEVICE_TOKEN}"

# 读取 hook 输入
HOOK_INPUT=$(cat)
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name')

# 简单的危险命令检测
if [[ "$TOOL_NAME" == "bash" ]]; then
    COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command')

    if [[ "$COMMAND" == *"rm -rf"* ]] || [[ "$COMMAND" == *"sudo"* ]]; then
        # 发送确认请求
        RESULT=$(curl -s -X POST "${FUNCTIONS_URL}/createInteraction" \
            -H "Content-Type: application/json" \
            -d "{\"data\": {
                \"to\": \"${DEVICE_TOKEN}\",
                \"type\": \"permission\",
                \"title\": \"危险命令确认\",
                \"message\": \"${COMMAND}\",
                \"timeout\": 120
            }}")

        REQUEST_ID=$(echo "$RESULT" | jq -r '.result.requestId')

        # 等待响应
        for i in {1..12}; do
            WAIT_RESULT=$(curl -s -X POST "${FUNCTIONS_URL}/waitInteraction" \
                -H "Content-Type: application/json" \
                -d "{\"data\": {\"requestId\": \"${REQUEST_ID}\", \"timeout\": 10}}")

            STATUS=$(echo "$WAIT_RESULT" | jq -r '.result.status')

            if [[ "$STATUS" == "approved" ]]; then
                echo '{"action": "allow"}'
                exit 0
            elif [[ "$STATUS" == "denied" ]]; then
                echo '{"action": "block", "message": "用户拒绝了此操作"}'
                exit 0
            fi
        done

        echo '{"action": "block", "message": "等待确认超时"}'
        exit 0
    fi
fi

# 默认允许
echo '{"action": "allow"}'
```

## Claude Code 配置

在 `~/.claude/settings.json` 中添加 hook 配置：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "bash|write|edit",
        "command": "python3 ~/.claude/hooks/permission_hook.py"
      }
    ]
  }
}
```

## 环境变量

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
export FCM_DEVICE_TOKEN="你的FCM设备Token"
```

## 测试

```bash
# 测试 createInteraction
curl -X POST "https://us-central1-ccpush-45c62.cloudfunctions.net/createInteraction" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "to": "YOUR_FCM_TOKEN",
      "type": "confirm",
      "title": "测试交互",
      "message": "这是一个测试消息",
      "timeout": 60
    }
  }'
```

## 故障排查

1. **收不到通知**: 检查 FCM Token 是否正确，App 是否已授权通知
2. **响应超时**: 检查网络连接，增加 timeout 值
3. **Function 调用失败**: 检查 Firebase 项目配置和部署状态

## 安全建议

1. 不要在公开代码中暴露 FCM Token
2. 使用环境变量存储敏感配置
3. 定期更新 Token（Token 可能会过期）
4. 在生产环境启用 Firebase App Check
