/**
 * LeanCloud REST API 操作封装
 * 文档: https://leancloud.cn/docs/rest_api.html
 */
import type { Env, Order, Template } from "./types";
import { fetchWithRetry, log } from "./utils";

class LeanCloudClient {
  private appId: string;
  private appKey: string;
  private serverUrl: string;

  constructor(env: Env) {
    this.appId = env.LEANCLOUD_APP_ID;
    this.appKey = env.LEANCLOUD_APP_KEY;
    this.serverUrl = env.LEANCLOUD_SERVER_URL.replace(/\/$/, "");
  }

  private headers(): Record<string, string> {
    return {
      "X-LC-Id": this.appId,
      "X-LC-Key": this.appKey,
      "Content-Type": "application/json",
    };
  }

  // 创建订单
  async createOrder(order: Order): Promise<Order> {
    const url = `${this.serverUrl}/1.1/classes/Orders`;
    const response = await fetchWithRetry(url, {
      method: "POST",
      headers: this.headers(),
      body: JSON.stringify(order),
    });

    if (!response.ok) {
      const text = await response.text();
      log("error", "LeanCloud createOrder failed", { status: response.status, body: text });
      throw new Error(`LeanCloud createOrder failed: ${response.status} ${text}`);
    }

    const result = (await response.json()) as { objectId: string; createdAt: string };
    return { ...order, objectId: result.objectId, createdAt: result.createdAt };
  }

  // 根据 order_id 查询订单
  async getOrderByOrderId(orderId: string): Promise<Order | null> {
    const where = encodeURIComponent(JSON.stringify({ order_id: orderId }));
    const url = `${this.serverUrl}/1.1/classes/Orders?where=${where}&limit=1`;
    const response = await fetchWithRetry(url, { headers: this.headers() });

    if (!response.ok) {
      const text = await response.text();
      log("error", "LeanCloud getOrderByOrderId failed", { status: response.status, body: text });
      throw new Error(`LeanCloud getOrderByOrderId failed: ${response.status}`);
    }

    const data = (await response.json()) as { results: Order[] };
    return data.results[0] ?? null;
  }

  // 更新订单
  async updateOrder(orderId: string, updates: Partial<Order>): Promise<void> {
    const order = await this.getOrderByOrderId(orderId);
    if (!order || !order.objectId) {
      throw new Error(`Order not found: ${orderId}`);
    }

    const url = `${this.serverUrl}/1.1/classes/Orders/${order.objectId}`;
    const response = await fetchWithRetry(url, {
      method: "PUT",
      headers: this.headers(),
      body: JSON.stringify(updates),
    });

    if (!response.ok) {
      const text = await response.text();
      log("error", "LeanCloud updateOrder failed", { status: response.status, body: text });
      throw new Error(`LeanCloud updateOrder failed: ${response.status}`);
    }

    log("info", "LeanCloud updateOrder success", { orderId, updates: Object.keys(updates) });
  }

  // 查询模板列表
  async getTemplates(category?: string): Promise<Template[]> {
    let url = `${this.serverUrl}/1.1/classes/Templates?order=sort_order`;
    if (category) {
      const where = encodeURIComponent(JSON.stringify({ category }));
      url += `&where=${where}`;
    }
    const response = await fetchWithRetry(url, { headers: this.headers() });

    if (!response.ok) {
      const text = await response.text();
      log("error", "LeanCloud getTemplates failed", { status: response.status, body: text });
      throw new Error(`LeanCloud getTemplates failed: ${response.status}`);
    }

    const data = (await response.json()) as { results: Template[] };
    return data.results;
  }

  // 根据ID获取模板
  async getTemplateById(templateId: string): Promise<Template | null> {
    const where = encodeURIComponent(JSON.stringify({ template_id: templateId }));
    const url = `${this.serverUrl}/1.1/classes/Templates?where=${where}&limit=1`;
    const response = await fetchWithRetry(url, { headers: this.headers() });

    if (!response.ok) {
      const text = await response.text();
      log("error", "LeanCloud getTemplateById failed", { status: response.status, body: text });
      throw new Error(`LeanCloud getTemplateById failed: ${response.status}`);
    }

    const data = (await response.json()) as { results: Template[] };
    return data.results[0] ?? null;
  }
}

let clientInstance: LeanCloudClient | null = null;

export function getLeanCloudClient(env: Env): LeanCloudClient {
  if (!clientInstance) {
    clientInstance = new LeanCloudClient(env);
  }
  return clientInstance;
}

export { LeanCloudClient };
