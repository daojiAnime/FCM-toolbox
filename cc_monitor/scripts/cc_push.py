#!/usr/bin/env python3
"""
CC Monitor Push Script - 双模式推送脚本

支持两种推送模式:
1. FCM (Firebase Cloud Messaging) - 需要设备 FCM Token
2. Firestore - 实时数据库监听（无需 APNs 配置）

用法:
  # FCM 模式
  python cc_push.py --mode fcm --token <FCM_TOKEN> --type complete --title "任务完成" --message "编译成功"

  # Firestore 模式
  python cc_push.py --mode firestore --device-id <DEVICE_ID> --type progress --title "编译中" --message "正在编译..."

  # 同时发送到两个渠道
  python cc_push.py --mode both --token <FCM_TOKEN> --device-id <DEVICE_ID> --type complete ...

环境变量:
  CC_PUSH_MODE: 推送模式 (fcm/firestore/both)
  CC_FCM_TOKEN: FCM 设备 Token
  CC_DEVICE_ID: 设备 ID (用于 Firestore)
  CC_PROJECT_ID: Firebase 项目 ID
  CC_CREDENTIALS_FILE: Firebase 服务账号凭据文件路径

配置文件:
  ~/.config/cc_monitor/config.json
"""

import argparse
import json
import os
import sys
import uuid
from datetime import datetime
from pathlib import Path
from typing import Any

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account


# 默认配置
DEFAULT_CONFIG = {
    "project_id": "ccpush-45c62",
    "credentials_file": str(Path(__file__).parent.parent.parent.parent / "service-account.json"),
    "mode": "both",  # fcm, firestore, both
}


def load_config() -> dict:
    """加载配置"""
    config = DEFAULT_CONFIG.copy()

    # 从配置文件加载
    config_file = Path.home() / ".config" / "cc_monitor" / "config.json"
    if config_file.exists():
        try:
            with open(config_file) as f:
                file_config = json.load(f)
                config.update(file_config)
        except Exception as e:
            print(f"Warning: Failed to load config file: {e}", file=sys.stderr)

    # 环境变量覆盖
    if os.getenv("CC_PROJECT_ID"):
        config["project_id"] = os.getenv("CC_PROJECT_ID")
    if os.getenv("CC_CREDENTIALS_FILE"):
        config["credentials_file"] = os.getenv("CC_CREDENTIALS_FILE")
    if os.getenv("CC_PUSH_MODE"):
        config["mode"] = os.getenv("CC_PUSH_MODE")

    return config


def get_access_token(credentials_file: str) -> str:
    """获取 Firebase API 访问令牌"""
    credentials = service_account.Credentials.from_service_account_file(
        credentials_file,
        scopes=[
            "https://www.googleapis.com/auth/firebase.messaging",
            "https://www.googleapis.com/auth/datastore",
        ],
    )
    credentials.refresh(Request())
    return credentials.token


def send_fcm(
    token: str,
    message_type: str,
    title: str,
    message: str,
    project_id: str,
    credentials_file: str,
    extra_data: dict | None = None,
) -> bool:
    """发送 FCM 推送"""
    try:
        access_token = get_access_token(credentials_file)

        url = f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send"

        # 构建 data payload
        data = {
            "type": message_type,
            "title": title,
            "message": message,
            "timestamp": str(int(datetime.now().timestamp() * 1000)),
        }
        if extra_data:
            data.update({k: str(v) for k, v in extra_data.items()})

        fcm_message = {
            "message": {
                "token": token,
                "notification": {"title": title, "body": message},
                "data": data,
                "android": {
                    "priority": "high",
                    "notification": {
                        "channel_id": "cc_monitor_channel",
                        "sound": "default",
                        "color": "#6366F1",
                    },
                },
                "apns": {
                    "payload": {
                        "aps": {"sound": "default", "badge": 1},
                    },
                },
            }
        }

        response = requests.post(
            url,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json",
            },
            json=fcm_message,
            timeout=10,
        )

        if response.status_code == 200:
            print(f"[FCM] ✓ Message sent: {response.json().get('name', 'N/A')}")
            return True
        else:
            print(f"[FCM] ✗ Failed: {response.status_code} - {response.text}", file=sys.stderr)
            return False

    except Exception as e:
        print(f"[FCM] ✗ Error: {e}", file=sys.stderr)
        return False


def send_firestore(
    device_id: str,
    message_type: str,
    title: str,
    message: str,
    project_id: str,
    credentials_file: str,
    extra_data: dict | None = None,
) -> bool:
    """写入消息到 Firestore"""
    try:
        access_token = get_access_token(credentials_file)

        # Firestore REST API URL
        # 集合路径: devices/{device_id}/messages
        url = (
            f"https://firestore.googleapis.com/v1/"
            f"projects/{project_id}/databases/(default)/documents/"
            f"devices/{device_id}/messages"
        )

        # 构建 Firestore 文档
        now = datetime.now()
        doc_id = str(uuid.uuid4())

        # Firestore 文档格式
        fields: dict[str, dict[str, Any]] = {
            "type": {"stringValue": message_type},
            "title": {"stringValue": title},
            "message": {"stringValue": message},
            "createdAt": {"timestampValue": now.isoformat() + "Z"},
            "sessionId": {"stringValue": extra_data.get("session_id", "unknown") if extra_data else "unknown"},
            "projectName": {"stringValue": extra_data.get("project_name", "Unknown") if extra_data else "Unknown"},
        }

        # 添加额外字段
        if extra_data:
            for key, value in extra_data.items():
                if key not in ("session_id", "project_name"):
                    if isinstance(value, bool):
                        fields[key] = {"booleanValue": value}
                    elif isinstance(value, int):
                        fields[key] = {"integerValue": str(value)}
                    elif isinstance(value, float):
                        fields[key] = {"doubleValue": value}
                    else:
                        fields[key] = {"stringValue": str(value)}

        document = {"fields": fields}

        response = requests.post(
            url,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json",
            },
            params={"documentId": doc_id},
            json=document,
            timeout=10,
        )

        if response.status_code in (200, 201):
            print(f"[Firestore] ✓ Document created: {doc_id}")
            return True
        else:
            print(f"[Firestore] ✗ Failed: {response.status_code} - {response.text}", file=sys.stderr)
            return False

    except Exception as e:
        print(f"[Firestore] ✗ Error: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(
        description="CC Monitor Push Script - 发送消息到 CC Monitor App",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
消息类型 (--type):
  progress    进度消息（正在处理中）
  complete    完成消息（任务成功）
  error       错误消息（任务失败）
  warning     警告消息
  code        代码片段
  markdown    Markdown 内容
  interactive 交互式消息（需要用户响应）

示例:
  # 发送完成通知到 Firestore
  python cc_push.py --mode firestore --device-id abc123 --type complete \\
      --title "构建完成" --message "项目构建成功，耗时 30 秒"

  # 发送进度通知到 FCM
  python cc_push.py --mode fcm --token <TOKEN> --type progress \\
      --title "编译中" --message "正在编译 50%..."

  # 同时发送到两个渠道
  python cc_push.py --mode both --token <TOKEN> --device-id abc123 \\
      --type complete --title "完成" --message "任务完成"
""",
    )

    parser.add_argument(
        "--mode",
        choices=["fcm", "firestore", "both"],
        default=os.getenv("CC_PUSH_MODE", "both"),
        help="推送模式 (default: both)",
    )
    parser.add_argument("--token", default=os.getenv("CC_FCM_TOKEN"), help="FCM 设备 Token")
    parser.add_argument("--device-id", default=os.getenv("CC_DEVICE_ID"), help="设备 ID (Firestore)")
    parser.add_argument(
        "--type",
        choices=["progress", "complete", "error", "warning", "code", "markdown", "interactive"],
        default="progress",
        help="消息类型 (default: progress)",
    )
    parser.add_argument("--title", default="CC Monitor", help="消息标题")
    parser.add_argument("--message", "-m", required=True, help="消息内容")
    parser.add_argument("--session-id", help="会话 ID")
    parser.add_argument("--project-name", help="项目名称")
    parser.add_argument("--project-path", help="项目路径")
    parser.add_argument("--hook-event", help="Hook 事件类型")
    parser.add_argument("--tool-name", help="工具名称")
    parser.add_argument("--credentials", help="Firebase 凭据文件路径")
    parser.add_argument("--project-id", help="Firebase 项目 ID")

    args = parser.parse_args()

    # 加载配置
    config = load_config()

    # 命令行参数覆盖
    if args.credentials:
        config["credentials_file"] = args.credentials
    if args.project_id:
        config["project_id"] = args.project_id

    # 检查凭据文件
    credentials_file = config["credentials_file"]
    if not Path(credentials_file).exists():
        print(f"Error: Credentials file not found: {credentials_file}", file=sys.stderr)
        print("\nPlease download from Firebase Console:", file=sys.stderr)
        print("  Project Settings → Service Accounts → Generate New Private Key", file=sys.stderr)
        sys.exit(1)

    # 构建额外数据
    extra_data = {}
    if args.session_id:
        extra_data["session_id"] = args.session_id
    if args.project_name:
        extra_data["project_name"] = args.project_name
    if args.project_path:
        extra_data["projectPath"] = args.project_path
    if args.hook_event:
        extra_data["hookEvent"] = args.hook_event
    if args.tool_name:
        extra_data["toolName"] = args.tool_name

    mode = args.mode
    success = False

    # 发送 FCM
    if mode in ("fcm", "both"):
        token = args.token
        if not token:
            if mode == "fcm":
                print("Error: --token is required for FCM mode", file=sys.stderr)
                sys.exit(1)
            else:
                print("[FCM] Skipped: No token provided")
        else:
            fcm_success = send_fcm(
                token=token,
                message_type=args.type,
                title=args.title,
                message=args.message,
                project_id=config["project_id"],
                credentials_file=credentials_file,
                extra_data=extra_data,
            )
            success = success or fcm_success

    # 发送 Firestore
    if mode in ("firestore", "both"):
        device_id = args.device_id
        if not device_id:
            if mode == "firestore":
                print("Error: --device-id is required for Firestore mode", file=sys.stderr)
                sys.exit(1)
            else:
                print("[Firestore] Skipped: No device-id provided")
        else:
            firestore_success = send_firestore(
                device_id=device_id,
                message_type=args.type,
                title=args.title,
                message=args.message,
                project_id=config["project_id"],
                credentials_file=credentials_file,
                extra_data=extra_data,
            )
            success = success or firestore_success

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
