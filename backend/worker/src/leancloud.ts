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
    name: "\u5546\u52a1\u84dd",
    category: "business",
    thumbnail_url: "https://placehold.co/400x500/3b82f6/ffffff?text=\u5546\u52a1\u84dd",
    style_prompt: "professional business headshot, blue background, suit, confident smile",
    is_premium: false,
    sort_order: 1,
  },
  {
    template_id: "t2",
    name: "\u7b80\u5386\u7070",
    category: "business",
    thumbnail_url: "https://placehold.co/400x500/6b7280/ffffff?text=\u7b80\u5386\u7070",
    style_prompt: "clean resume headshot, gray background, professional attire",
    is_premium: false,
    sort_order: 2,
  },
  {
    template_id: "t3",
    name: "\u91d1\u878d\u7cbe\u82f1",
    category: "business",
    thumbnail_url: "https://placehold.co/400x500/1e3a5f/ffffff?text=\u91d1\u878d\u7cbe\u82f1",
    style_prompt: "finance executive headshot, dark navy background, power suit",
    is_premium: true,
    sort_order: 3,
  },
  {
    template_id: "t4",
    name: "\u521b\u610f\u6e10\u53d8",
    category: "creative",
    thumbnail_url: "https://placehold.co/400x500/8b5cf6/ffffff?text=\u521b\u610f\u6e10\u53d8",
    style_prompt: "creative headshot, gradient background, artistic lighting",
    is_premium: true,
    sort_order: 4,
  },
  {
    template_id: "t5",
    name: "\u827a\u672f\u5149\u5f71",
    category: "creative",
    thumbnail_url: "https://placehold.co/400x500/d946ef/ffffff?text=\u827a\u672f\u5149\u5f71",
    style_prompt: "artistic headshot, dramatic lighting, creative background",
    is_premium: true,
    sort_order: 5,
  },
  {
    template_id: "t6",
    name: "\u8bc1\u4ef6\u767d",
    category: "id",
    thumbnail_url: "https://placehold.co/400x500/f3f4f6/374151?text=\u8bc1\u4ef6\u767d",
    style_prompt: "ID photo, white background, neutral expression",
    is_premium: false,
    sort_order: 6,
  },
  {
    template_id: "t7",
    name: "\u6d77\u5916\u7b7e\u8bc1",
    category: "id",
    thumbnail_url: "https://placehold.co/400x500/e5e7eb/374151?text=\u6d77\u5916\u7b7e\u8bc1",
    style_prompt: "visa photo, light gray background, neutral expression, no glasses",
    is_premium: false,
    sort_order: 7,
  },
  {
    template_id: "t8",
    name: "LinkedIn \u98ce",
    category: "social",
    thumbnail_url: "https://placehold.co/400x500/0ea5e9/ffffff?text=LinkedIn",
    style_prompt: "LinkedIn style headshot, natural lighting, approachable smile",
    is_premium: true,
    sort_order: 8,
  },
  {
    template_id: "t9",
    name: "\u5973\u6027\u67d4\u548c",
    category: "social",
    thumbnail_url: "https://placehold.co/400x500/f472b6/ffffff?text=\u67d4\u548c",
    style_prompt: "soft professional headshot, warm tones, elegant style",
    is_premium: false,
    sort_order: 9,
  },
  {
    template_id: "t10",
    name: "\u81ea\u7136\u9633\u5149",
    category: "social",
    thumbnail_url: "https://placehold.co/400x500/f59e0b/ffffff?text=\u81ea\u7136\u9633\u5149",
    style_prompt: "natural sunlight headshot, outdoor background, warm smile",
    is_premium: false,
    sort_order: 10,
  },
  {
    template_id: "t11",
    name: "\u590d\u53e4\u6cb9\u753b",
    category: "artistic",
    thumbnail_url: "https://placehold.co/400x500/78350f/ffffff?text=\u590d\u53e4\u6cb9\u753b",
    style_prompt: "vintage oil painting style portrait, rich warm colors, classical composition",
    is_premium: true,
    sort_order: 11,
  },
  {
    template_id: "t12",
    name: "\u6781\u7b80\u767d",
    category: "minimal",
    thumbnail_url: "https://placehold.co/400x500/ffffff/374151?text=\u6781\u7b80\u767d",
    style_prompt: "minimalist headshot, pure white background, clean composition",
    is_premium: false,
    sort_order: 12,
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
