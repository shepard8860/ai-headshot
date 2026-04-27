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

// ====== Mock 内存存储（本地开发用） ======
const MOCK_TEMPLATES: Template[] = [
  {
    template_id: "t1",
    name: "商务蓝",
    category: "business",
    thumbnail_url: "https://placehold.co/200x200/3b82f6/ffffff?text=商务蓝",
    style_prompt: "professional business headshot, blue background, suit, confident smile",
    is_premium: false,
    sort_order: 1,
  },
  {
    template_id: "t2",
    name: "简历灰",
    category: "business",
    thumbnail_url: "https://placehold.co/200x200/6b7280/ffffff?text=简历灰",
    style_prompt: "clean resume headshot, gray background, professional attire",
    is_premium: false,
    sort_order: 2,
  },
  {
    template_id: "t3",
    name: "创意渐变",
    category: "creative",
    thumbnail_url: "https://placehold.co/200x200/8b5cf6/ffffff?text=创意渐变",
    style_prompt: "creative headshot, gradient background, artistic lighting",
    is_premium: true,
    sort_order: 3,
  },
  {
    template_id: "t4",
    name: "证件白",
    category: "id",
    thumbnail_url: "https://placehold.co/200x200/f3f4f6/374151?text=证件白",
    style_prompt: "ID photo, white background, neutral expression",
    is_premium: false,
    sort_order: 4,
  },
  {
    template_id: "t5",
    name: "LinkedIn 风",
    category: "social",
    thumbnail_url: "https://placehold.co/200x200/0ea5e9/ffffff?text=LinkedIn",
    style_prompt: "LinkedIn style headshot, natural lighting, approachable smile",
    is_premium: true,
    sort_order: 5,
  },
  {
    template_id: "t6",
    name: "女性柔和",
    category: "social",
    thumbnail_url: "https://placehold.co/200x200/f472b6/ffffff?text=柔和",
    style_prompt: "soft professional headshot, warm tones, elegant style",
    is_premium: false,
    sort_order: 6,
  },
];

class MockLeanCloudClient {
  private orders = new Map<string, Order>();

  async createOrder(order: Order): Promise<Order> {
    const obj = { ...order, objectId: `mock-${Date.now()}`, createdAt: new Date().toISOString() };
    this.orders.set(order.order_id, obj);
    log("info", "[MOCK] createOrder", { orderId: order.order_id });
    return obj;
  }

  async getOrderByOrderId(orderId: string): Promise<Order | null> {
    return this.orders.get(orderId) ?? null;
  }

  async updateOrder(orderId: string, updates: Partial<Order>): Promise<void> {
    const order = this.orders.get(orderId);
    if (!order) throw new Error(`Order not found: ${orderId}`);
    this.orders.set(orderId, { ...order, ...updates, updatedAt: new Date().toISOString() });
    log("info", "[MOCK] updateOrder", { orderId, status: updates.status });
  }

  async getTemplates(category?: string): Promise<Template[]> {
    if (category) {
      return MOCK_TEMPLATES.filter((t) => t.category === category);
    }
    return MOCK_TEMPLATES;
  }

  async getTemplateById(templateId: string): Promise<Template | null> {
    return MOCK_TEMPLATES.find((t) => t.template_id === templateId) ?? null;
  }
}

let clientInstance: LeanCloudClient | MockLeanCloudClient | null = null;

export function getLeanCloudClient(env: Env): LeanCloudClient | MockLeanCloudClient {
  if (!clientInstance) {
    if (env.LEANCLOUD_APP_ID === "mock") {
      clientInstance = new MockLeanCloudClient();
    } else {
      clientInstance = new LeanCloudClient(env);
    }
  }
  return clientInstance;
}

export { LeanCloudClient, MockLeanCloudClient };
