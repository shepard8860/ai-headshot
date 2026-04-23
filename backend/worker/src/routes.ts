/**
 * API 路由定义
 * 使用 Hono 框架
 */
import { Hono } from "hono";
import { cors } from "hono/cors";
import type { Env, CreateOrderRequest, AICallbackRequest, VerifyPaymentRequest, OrderStatusEvent } from "./types";
import {
  generateOrderId,
  jsonResponse,
  errorResponse,
  validateBody,
  log,
} from "./utils";
import { getLeanCloudClient } from "./leancloud";
import { generateHeadshot, healthCheck } from "./ai-providers";
import { verifyAppleReceipt } from "./iap";
import { generateDownloadUrl, generateSignedUrl, generateUploadUrl } from "./oss";
import { adminApp } from "./admin";

// 定义 Hono Context 类型
type Context = {
  Bindings: Env;
  Variables: Record<string, unknown>;
};

const app = new Hono<Context>();

// CORS
app.use("/*", cors({
  origin: "*",
  allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowHeaders: ["Content-Type", "Authorization"],
}));

// ====== 运营管理后台 ======
app.route("/admin", adminApp);

// ====== 健康检查 ======
app.get("/health", async (c) => {
  const aiHealth = await healthCheck(c.env);
  return jsonResponse({
    status: "ok",
    timestamp: new Date().toISOString(),
    ai_providers: aiHealth,
  });
});

// ====== POST /api/generate - 创建订单 ======
app.post("/api/generate", async (c) => {
  try {
    const body = await c.req.json();
    const validation = validateBody<CreateOrderRequest>(body, [
      "user_id",
      "template_id",
      "original_image_url",
    ]);

    if (!validation.valid) {
      return errorResponse(validation.error, "INVALID_REQUEST", 400);
    }

    const { user_id, template_id, original_image_url } = validation.data;

    // 验证模板存在
    const lc = getLeanCloudClient(c.env);
    const template = await lc.getTemplateById(template_id);
    if (!template) {
      return errorResponse("Template not found", "TEMPLATE_NOT_FOUND", 404);
    }

    const orderId = generateOrderId();
    const order = {
      order_id: orderId,
      user_id,
      template_id,
      original_image_url,
      status: "PENDING" as const,
      progress: 0,
      message: "Order created, waiting for generation",
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    await lc.createOrder(order);

    log("info", "Order created", { orderId, user_id, template_id });

    // 异步触发 AI 生成（使用 waitUntil 不阻塞响应）
    c.executionCtx.waitUntil(
      triggerGeneration(c.env, orderId, original_image_url, template.style_prompt)
    );

    return jsonResponse({
      order_id: orderId,
      status: "PENDING",
      estimated_seconds: 30,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log("error", "POST /api/generate error", { error: msg });
    return errorResponse("Internal server error", "INTERNAL_ERROR", 500, msg);
  }
});

// 异步触发生成
async function triggerGeneration(
  env: Env,
  orderId: string,
  imageUrl: string,
  prompt: string
): Promise<void> {
  const lc = getLeanCloudClient(env);

  try {
    // 更新状态为生成中
    await lc.updateOrder(orderId, {
      status: "GENERATING",
      progress: 10,
      message: "Starting AI generation...",
      updatedAt: new Date().toISOString(),
    });
    await pushStatus(env, orderId, {
      status: "GENERATING",
      progress: 10,
      message: "Starting AI generation...",
    });

    // 调用 AI 生成
    const result = await generateHeadshot(env, imageUrl, prompt);

    if (!result.success || !result.imageUrls?.length) {
      await lc.updateOrder(orderId, {
        status: "FAILED",
        progress: 100,
        error_message: result.error ?? "Generation failed",
        updatedAt: new Date().toISOString(),
      });
      await pushStatus(env, orderId, {
        status: "FAILED",
        progress: 100,
        message: "Generation failed",
        error_message: result.error ?? "Unknown error",
      });
      return;
    }

    // 生成成功，更新订单
    await lc.updateOrder(orderId, {
      status: "COMPLETED",
      progress: 100,
      preview_urls: result.imageUrls,
      message: "Generation completed",
      ai_provider: result.provider,
      updatedAt: new Date().toISOString(),
    });

    // 生成 OSS 签名 URL（预览图）
    const signedUrls = await Promise.all(
      result.imageUrls.map((url) => {
        // 如果是绝对 URL，直接返回
        if (url.startsWith("http")) return Promise.resolve(url);
        // 否则生成签名 URL
        return generateSignedUrl(env, { objectKey: url, expiresIn: 86400 });
      })
    );

    await pushStatus(env, orderId, {
      status: "COMPLETED",
      progress: 100,
      preview_urls: signedUrls,
      message: "Generation completed",
    });

    log("info", "Generation completed", { orderId, provider: result.provider });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log("error", "Generation error", { orderId, error: msg });

    await lc.updateOrder(orderId, {
      status: "FAILED",
      progress: 100,
      error_message: msg,
      updatedAt: new Date().toISOString(),
    });
    await pushStatus(env, orderId, {
      status: "FAILED",
      progress: 100,
      message: "Generation failed",
      error_message: msg,
    });
  }
}

// 推送状态到 Durable Object
async function pushStatus(
  env: Env,
  orderId: string,
  event: OrderStatusEvent
): Promise<void> {
  try {
    const id = env.ORDER_STATUS_STREAM.idFromName(orderId);
    const stub = env.ORDER_STATUS_STREAM.get(id);
    await stub.fetch(new Request("http://internal/push", {
      method: "POST",
      body: JSON.stringify({ orderId, event }),
    }));
  } catch (err) {
    log("warn", "Failed to push status to Durable Object", { orderId, error: String(err) });
  }
}

// ====== GET /api/order/:id/status - SSE 流 ======
app.get("/api/order/:id/status", async (c) => {
  const orderId = c.req.param("id");
  const lc = getLeanCloudClient(c.env);

  try {
    // 检查订单是否存在
    const order = await lc.getOrderByOrderId(orderId);
    if (!order) {
      return errorResponse("Order not found", "ORDER_NOT_FOUND", 404);
    }

    // 返回 SSE 流
    const { readable, writable } = new TransformStream();
    const writer = writable.getWriter();
    const encoder = new TextEncoder();

    c.executionCtx.waitUntil(
      (async () => {
        try {
          // 发送初始状态
          await writer.write(
            encoder.encode(
              `data: ${JSON.stringify({
                status: order.status,
                progress: order.progress,
                preview_urls: order.preview_urls,
                message: order.message,
              })}\n\n`
            )
          );

          // 如果订单已经完成或失败，关闭连接
          if (order.status === "COMPLETED" || order.status === "FAILED" || order.status === "PAID") {
            await writer.close();
            return;
          }

          // 轮询订单状态（每 2 秒，最多 120 次 = 4 分钟）
          for (let i = 0; i < 120; i++) {
            await new Promise((resolve) => setTimeout(resolve, 2000));

            const latest = await lc.getOrderByOrderId(orderId);
            if (!latest) break;

            await writer.write(
              encoder.encode(
                `data: ${JSON.stringify({
                  status: latest.status,
                  progress: latest.progress,
                  preview_urls: latest.preview_urls,
                  message: latest.message,
                })}\n\n`
              )
            );

            if (
              latest.status === "COMPLETED" ||
              latest.status === "FAILED" ||
              latest.status === "PAID"
            ) {
              break;
            }
          }

          await writer.close();
        } catch {
          await writer.close();
        }
      })()
    );

    return new Response(readable, {
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
      },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return errorResponse("Internal server error", "INTERNAL_ERROR", 500, msg);
  }
});

// ====== POST /api/order/:id/verify-payment ======
app.post("/api/order/:id/verify-payment", async (c) => {
  const orderId = c.req.param("id");

  try {
    const body = await c.req.json();
    const validation = validateBody<VerifyPaymentRequest>(body, ["receipt_data"]);
    if (!validation.valid) {
      return errorResponse(validation.error, "INVALID_REQUEST", 400);
    }

    const { receipt_data, is_sandbox = false } = validation.data;
    const lc = getLeanCloudClient(c.env);

    // 检查订单
    const order = await lc.getOrderByOrderId(orderId);
    if (!order) {
      return errorResponse("Order not found", "ORDER_NOT_FOUND", 404);
    }

    if (order.status === "PAID") {
      return jsonResponse({
        success: true,
        hd_urls: order.hd_urls,
        message: "Already paid",
      });
    }

    if (order.status !== "COMPLETED") {
      return errorResponse(
        "Order is not ready for payment",
        "ORDER_NOT_READY",
        400
      );
    }

    // 验证 Apple 收据
    const verifyResult = await verifyAppleReceipt(c.env, receipt_data, is_sandbox);
    if (!verifyResult.success) {
      return jsonResponse({
        success: false,
        message: verifyResult.message,
      }, 402);
    }

    // 生成高清下载 URL
    const hdUrls = await Promise.all(
      (order.preview_urls ?? []).map(async (url, index) => {
        const objectKey = `hd/${orderId}/${index}.png`;
        // 在实际业务中，这里应该是将高清图上传到 OSS 后生成签名 URL
        // 为简化，这里直接使用预览 URL 并生成长期有效的签名 URL
        return generateDownloadUrl(c.env, objectKey, 7 * 24 * 3600); // 7 天
      })
    );

    // 更新订单为已支付
    await lc.updateOrder(orderId, {
      status: "PAID",
      hd_urls: hdUrls,
      paid_at: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });

    await pushStatus(c.env, orderId, {
      status: "PAID",
      progress: 100,
      preview_urls: hdUrls,
      message: "Payment verified, HD images unlocked",
    });

    log("info", "Payment verified", { orderId });

    return jsonResponse({
      success: true,
      hd_urls: hdUrls,
      message: "Payment verified successfully",
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log("error", "POST /api/order/:id/verify-payment error", { orderId, error: msg });
    return errorResponse("Internal server error", "INTERNAL_ERROR", 500, msg);
  }
});

// ====== GET /api/upload/presign - 获取 OSS 上传预签名 URL ======
app.get("/api/upload/presign", async (c) => {
  try {
    const objectKey = `uploads/${Date.now()}-${Math.random().toString(36).substring(2, 10)}.jpg`;
    const { uploadUrl, publicUrl } = await generateUploadUrl(c.env, objectKey, "image/jpeg");

    return jsonResponse({
      url: uploadUrl,
      key: publicUrl,
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log("error", "GET /api/upload/presign error", { error: msg });
    return errorResponse("Failed to generate upload URL", "UPSIGN_ERROR", 500, msg);
  }
});

// ====== GET /api/templates - 模板列表 ======
app.get("/api/templates", async (c) => {
  try {
    const category = c.req.query("category");
    const lc = getLeanCloudClient(c.env);
    const templates = await lc.getTemplates(category);

    return jsonResponse({
      total: templates.length,
      templates: templates.map((t) => ({
        template_id: t.template_id,
        name: t.name,
        category: t.category,
        thumbnail_url: t.thumbnail_url,
        is_premium: t.is_premium,
      })),
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log("error", "GET /api/templates error", { error: msg });
    return errorResponse("Internal server error", "INTERNAL_ERROR", 500, msg);
  }
});

// ====== POST /webhook/ai-callback - AI 回调 ======
app.post("/webhook/ai-callback", async (c) => {
  try {
    const body = await c.req.json();
    const validation = validateBody<AICallbackRequest>(body, ["order_id", "status", "provider"]);
    if (!validation.valid) {
      return errorResponse(validation.error, "INVALID_REQUEST", 400);
    }

    const { order_id, status, image_urls, error_message } = validation.data;
    const lc = getLeanCloudClient(c.env);

    const order = await lc.getOrderByOrderId(order_id);
    if (!order) {
      return errorResponse("Order not found", "ORDER_NOT_FOUND", 404);
    }

    if (status === "success" && image_urls?.length) {
      await lc.updateOrder(order_id, {
        status: "COMPLETED",
        progress: 100,
        preview_urls: image_urls,
        message: "AI callback: generation completed",
        updatedAt: new Date().toISOString(),
      });
      await pushStatus(c.env, order_id, {
        status: "COMPLETED",
        progress: 100,
        preview_urls: image_urls,
        message: "Generation completed via webhook",
      });
    } else {
      await lc.updateOrder(order_id, {
        status: "FAILED",
        progress: 100,
        error_message: error_message ?? "AI callback reported failure",
        updatedAt: new Date().toISOString(),
      });
      await pushStatus(c.env, order_id, {
        status: "FAILED",
        progress: 100,
        message: "Generation failed via webhook",
        error_message: error_message ?? "Unknown error",
      });
    }

    log("info", "AI callback processed", { order_id, status });
    return jsonResponse({ success: true });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log("error", "POST /webhook/ai-callback error", { error: msg });
    return errorResponse("Internal server error", "INTERNAL_ERROR", 500, msg);
  }
});

// ====== 404 处理 ======
app.notFound((c) => {
  return errorResponse("Not Found", "NOT_FOUND", 404);
});

// ====== 错误处理 ======
app.onError((err, c) => {
  log("error", "Unhandled error", { error: err.message, stack: err.stack });
  return errorResponse("Internal server error", "INTERNAL_ERROR", 500, err.message);
});

export { app };
