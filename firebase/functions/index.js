const {onCall, onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {HttpsError} = require("firebase-functions/v1/auth");

initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = getFirestore();

// ============== 基础功能 ==============

exports.ping = onRequest((request, response) => {
  logger.info("Ping!");
  response.send("Pong!");
});

// ============== FCM 推送 ==============

exports.send = onCall((request) => {
  logger.log("Request", request);
  logger.log("Request data", request.data);

  const to = request.data.to;
  if (!to) throw new HttpsError("invalid-argument", "'to' must exist");

  const ttl = parseInt(request.data.ttl);
  if (ttl < 0 || ttl > 2419200) {
    throw new HttpsError("invalid-argument",
        "'ttl' must be [0 .. 2 419 200] (28 days)");
  }

  const priorities = ["normal", "high"];
  const priority = request.data.priority;
  if (!priorities.includes(priority)) {
    throw new HttpsError("invalid-argument",
        `'priority' must be one of: ${priorities.join()}`);
  }

  const data = request.data.data;
  if (!data) throw new HttpsError("invalid-argument", "'data' must exist");

  const convertData = (obj) => Object.fromEntries(
      Object.entries(obj).map(([k, v]) =>
        [k, (typeof v === "string" || v instanceof String) ?
          v : JSON.stringify(v)]),
  );

  const message = {
    data: convertData(data),
    android: {
      priority: priority,
      ttl: ttl * 1000,
    },
  };

  message[to.startsWith("/topics/") ? "topic" : "token"] = to;

  logger.log("Sending message:", message);
  return admin.messaging()
      .send(message)
      .then((data) => {
        logger.log("Success:", data);
        return data;
      })
      .catch((error) => {
        logger.error("Failure:", error);
        throw new HttpsError("internal", error.message, error);
      });
});

// ============== 双向交互 ==============

/**
 * 创建交互请求并发送 FCM 通知
 * @param {object} request.data - 请求数据
 * @param {string} request.data.to - 目标设备 token
 * @param {string} request.data.type - 交互类型: permission|confirm|input|choice
 * @param {string} request.data.title - 标题
 * @param {string} request.data.message - 消息内容
 * @param {object} request.data.metadata - 额外元数据
 * @param {number} request.data.timeout - 超时时间(秒), 默认 300
 * @return {object} { requestId, status }
 */
exports.createInteraction = onCall(async (request) => {
  logger.log("createInteraction", request.data);

  const {to, type, title, message, metadata, timeout = 300} = request.data;

  // 参数验证
  if (!to) throw new HttpsError("invalid-argument", "'to' must exist");
  if (!type) throw new HttpsError("invalid-argument", "'type' must exist");
  if (!title) throw new HttpsError("invalid-argument", "'title' must exist");
  if (!message) {
    throw new HttpsError("invalid-argument", "'message' must exist");
  }

  const validTypes = ["permission", "confirm", "input", "choice"];
  if (!validTypes.includes(type)) {
    throw new HttpsError("invalid-argument",
        `'type' must be one of: ${validTypes.join()}`);
  }

  // 生成请求 ID
  const requestId = db.collection("interactions").doc().id;

  // 计算过期时间
  const now = new Date();
  const expiresAt = new Date(now.getTime() + timeout * 1000);

  // 创建 Firestore 文档
  const interactionData = {
    deviceToken: to,
    type: type,
    title: title,
    message: message,
    metadata: metadata || {},
    status: "pending",
    response: null,
    createdAt: FieldValue.serverTimestamp(),
    respondedAt: null,
    expiresAt: expiresAt,
  };

  await db.collection("interactions").doc(requestId).set(interactionData);
  logger.log("Created interaction:", requestId);

  // 发送 FCM 通知
  const fcmData = {
    type: "interactive",
    requestId: requestId,
    interactiveType: type,
    title: title,
    message: message,
    metadata: JSON.stringify(metadata || {}),
  };

  const fcmMessage = {
    data: fcmData,
    android: {
      priority: "high",
      ttl: timeout * 1000,
    },
    token: to,
  };

  try {
    await admin.messaging().send(fcmMessage);
    logger.log("FCM sent for interaction:", requestId);
  } catch (error) {
    logger.error("FCM send failed:", error);
    // 更新状态为失败
    await db.collection("interactions").doc(requestId).update({
      status: "fcm_failed",
      response: {error: error.message},
    });
    throw new HttpsError("internal", "Failed to send FCM notification");
  }

  return {requestId, status: "pending"};
});

/**
 * 查询交互请求状态
 * @param {string} request.data.requestId - 请求 ID
 * @return {object} 交互请求数据
 */
exports.getInteraction = onCall(async (request) => {
  const {requestId} = request.data;

  if (!requestId) {
    throw new HttpsError("invalid-argument", "'requestId' must exist");
  }

  const doc = await db.collection("interactions").doc(requestId).get();

  if (!doc.exists) {
    throw new HttpsError("not-found", "Interaction not found");
  }

  const data = doc.data();

  // 检查是否超时
  if (data.status === "pending" && data.expiresAt) {
    const expiresAt = data.expiresAt.toDate ?
      data.expiresAt.toDate() : new Date(data.expiresAt);
    if (new Date() > expiresAt) {
      // 更新为超时状态
      await db.collection("interactions").doc(requestId).update({
        status: "timeout",
      });
      data.status = "timeout";
    }
  }

  return {
    requestId: requestId,
    ...data,
    createdAt: data.createdAt?.toDate?.()?.toISOString() || null,
    respondedAt: data.respondedAt?.toDate?.()?.toISOString() || null,
    expiresAt: data.expiresAt?.toDate?.()?.toISOString() ||
      data.expiresAt?.toISOString?.() || null,
  };
});

/**
 * 响应交互请求 (App 端调用)
 * @param {string} request.data.requestId - 请求 ID
 * @param {string} request.data.status - 响应状态: approved|denied
 * @param {object} request.data.response - 响应数据
 * @return {object} { success: true }
 */
exports.respondInteraction = onCall(async (request) => {
  logger.log("respondInteraction", request.data);

  const {requestId, status, response} = request.data;

  if (!requestId) {
    throw new HttpsError("invalid-argument", "'requestId' must exist");
  }
  if (!status) {
    throw new HttpsError("invalid-argument", "'status' must exist");
  }

  const validStatuses = ["approved", "denied"];
  if (!validStatuses.includes(status)) {
    throw new HttpsError("invalid-argument",
        `'status' must be one of: ${validStatuses.join()}`);
  }

  const docRef = db.collection("interactions").doc(requestId);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new HttpsError("not-found", "Interaction not found");
  }

  const data = doc.data();

  // 检查是否已处理
  if (data.status !== "pending") {
    throw new HttpsError("failed-precondition",
        `Interaction already ${data.status}`);
  }

  // 检查是否超时
  if (data.expiresAt) {
    const expiresAt = data.expiresAt.toDate ?
      data.expiresAt.toDate() : new Date(data.expiresAt);
    if (new Date() > expiresAt) {
      await docRef.update({status: "timeout"});
      throw new HttpsError("deadline-exceeded", "Interaction has expired");
    }
  }

  // 更新状态
  await docRef.update({
    status: status,
    response: response || {},
    respondedAt: FieldValue.serverTimestamp(),
  });

  logger.log("Interaction responded:", requestId, status);

  return {success: true};
});

/**
 * 轮询等待交互响应 (Claude Code 调用)
 * @param {string} request.data.requestId - 请求 ID
 * @param {number} request.data.timeout - 等待超时(秒), 默认 30
 * @return {object} 交互响应数据
 */
exports.waitInteraction = onCall(async (request) => {
  const {requestId, timeout = 30} = request.data;

  if (!requestId) {
    throw new HttpsError("invalid-argument", "'requestId' must exist");
  }

  const startTime = Date.now();
  const maxWaitTime = Math.min(timeout, 60) * 1000; // 最多等待 60 秒

  while (Date.now() - startTime < maxWaitTime) {
    const doc = await db.collection("interactions").doc(requestId).get();

    if (!doc.exists) {
      throw new HttpsError("not-found", "Interaction not found");
    }

    const data = doc.data();

    // 如果状态不是 pending，返回结果
    if (data.status !== "pending") {
      return {
        requestId: requestId,
        status: data.status,
        response: data.response,
        respondedAt: data.respondedAt?.toDate?.()?.toISOString() || null,
      };
    }

    // 检查是否超时
    if (data.expiresAt) {
      const expiresAt = data.expiresAt.toDate ?
        data.expiresAt.toDate() : new Date(data.expiresAt);
      if (new Date() > expiresAt) {
        await db.collection("interactions").doc(requestId).update({
          status: "timeout",
        });
        return {
          requestId: requestId,
          status: "timeout",
          response: null,
        };
      }
    }

    // 等待 1 秒后重试
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }

  // 轮询超时，但交互可能还在等待用户响应
  return {
    requestId: requestId,
    status: "polling_timeout",
    message: "Polling timeout, interaction still pending",
  };
});
