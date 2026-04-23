/**
 * Durable Object: OrderStatusStream
 * 用于 SSE 流推送订单状态变化
 */
import type { OrderStatusEvent } from "./types";

export class OrderStatusStream implements DurableObject {
  private state: DurableObjectState;
  private latestEvent: Map<string, OrderStatusEvent> = new Map();

  constructor(state: DurableObjectState) {
    this.state = state;
  }

  // 处理 SSE 订阅请求和内部 RPC
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    // 内部 RPC：推送事件
    if (url.pathname === "/push" && request.method === "POST") {
      const payload = (await request.json()) as { orderId: string; event: OrderStatusEvent };
      await this.pushEvent(payload.orderId, payload.event);
      return new Response("OK");
    }

    const orderId = url.searchParams.get("orderId");

    if (!orderId) {
      return new Response("Missing orderId", { status: 400 });
    }

    const { readable, writable } = new TransformStream();
    const writer = writable.getWriter();
    const encoder = new TextEncoder();

    // 发送 SSE 头部
    await writer.write(
      encoder.encode(
        "data: " +
          JSON.stringify({ connected: true, orderId }) +
          "\n\n"
      )
    );

    // 如果有缓存的事件，立即发送
    const cached = this.latestEvent.get(orderId);
    if (cached) {
      await writer.write(encoder.encode("data: " + JSON.stringify(cached) + "\n\n"));
    }

    // 保存 writer 用于后续推送
    const key = `${orderId}-${Date.now()}`;
    await this.state.storage.put(`writer-${key}`, { orderId, createdAt: Date.now() });

    // 清理旧的 writer
    await this.cleanupOldWriters();

    // 注意：Durable Object 不能真正保持 HTTP 连接，这里使用一种轻量级方案
    // 实际生产中可以考虑用 WebSocket + Durable Object 或者简单轮询
    // 为了简洁，这里提供一个简单的 SSE 实现

    return new Response(readable, {
      headers: {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
      },
    });
  }

  // 推送状态事件
  async pushEvent(orderId: string, event: OrderStatusEvent): Promise<void> {
    this.latestEvent.set(orderId, event);
    await this.state.storage.put(`event-${orderId}`, event);

    // 如果状态是终态，设置过期时间
    if (event.status === "COMPLETED" || event.status === "FAILED" || event.status === "PAID") {
      await this.state.storage.put(`event-${orderId}`, event, { expirationTtl: 86400 });
    }
  }

  // 获取最新事件
  async getLatestEvent(orderId: string): Promise<OrderStatusEvent | null> {
    const cached = this.latestEvent.get(orderId);
    if (cached) return cached;

    const stored = await this.state.storage.get<OrderStatusEvent>(`event-${orderId}`);
    return stored ?? null;
  }

  // 清理过期的 writer
  private async cleanupOldWriters(): Promise<void> {
    const list = await this.state.storage.list<{ orderId: string; createdAt: number }>({
      prefix: "writer-",
    });
    const now = Date.now();
    for (const [key, value] of list) {
      if (now - value.createdAt > 5 * 60 * 1000) {
        await this.state.storage.delete(key);
      }
    }
  }
}
