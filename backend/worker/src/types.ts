/**
 * AI职业形象照 - 类型定义
 */

// 订单状态机
export type OrderStatus = "PENDING" | "GENERATING" | "COMPLETED" | "FAILED" | "PAID";

// 订单数据结构
export interface Order {
  objectId?: string;
  order_id: string;
  user_id: string;
  template_id: string;
  status: OrderStatus;
  original_image_url: string;
  preview_urls?: string[];
  hd_urls?: string[];
  progress: number; // 0-100
  message?: string;
  error_message?: string;
  createdAt?: string;
  updatedAt?: string;
  ai_provider?: string;
  paid_at?: string;
  apple_transaction_id?: string;
}

// 模板数据结构
export interface Template {
  objectId?: string;
  template_id: string;
  name: string;
  category: string;
  thumbnail_url: string;
  style_prompt: string;
  is_premium: boolean;
  sort_order: number;
  createdAt?: string;
  updatedAt?: string;
}

// 创建订单请求
export interface CreateOrderRequest {
  user_id: string;
  template_id: string;
  original_image_url: string;
}

// 创建订单响应
export interface CreateOrderResponse {
  order_id: string;
  status: OrderStatus;
  estimated_seconds: number;
}

// SSE 状态推送数据
export interface OrderStatusEvent {
  status: OrderStatus;
  progress: number;
  preview_urls?: string[];
  message?: string;
  error_message?: string;
}

// 验证支付请求
export interface VerifyPaymentRequest {
  receipt_data: string;
  is_sandbox?: boolean;
}

// 验证支付响应
export interface VerifyPaymentResponse {
  success: boolean;
  hd_urls?: string[];
  message?: string;
}

// AI 回调 Webhook 请求
export interface AICallbackRequest {
  order_id: string;
  status: "success" | "failed";
  image_urls?: string[];
  error_message?: string;
  provider: string;
}

// 商汤 SenseNova 请求
export interface SenseNovaGenerateRequest {
  model: string;
  input: {
    prompt: string;
    reference_image?: string;
  };
  parameters?: Record<string, unknown>;
}

export interface SenseNovaGenerateResponse {
  output?: {
    image_url?: string;
    image_urls?: string[];
  };
  error?: {
    code: string;
    message: string;
  };
}

// 阿里云通义万相/人脸融合请求
export interface AliyunWanxiangRequest {
  model: string;
  input: {
    prompt: string;
    reference_image_url?: string;
  };
  parameters?: Record<string, unknown>;
}

export interface AliyunWanxiangResponse {
  output?: {
    image_url?: string;
    results?: Array<{ url: string }>;
  };
  error?: {
    code: string;
    message: string;
  };
}

// Apple IAP 验证响应
export interface AppleVerifyReceiptResponse {
  status: number;
  receipt?: {
    in_app: Array<{
      transaction_id: string;
      product_id: string;
      purchase_date: string;
    }>;
  };
  latest_receipt_info?: Array<{
    transaction_id: string;
    product_id: string;
    purchase_date: string;
  }>;
  environment?: "Sandbox" | "Production";
}

// 错误响应格式
export interface ErrorResponse {
  error: string;
  code: string;
  details?: string;
}

// 环境变量类型
export interface Env {
  // LeanCloud
  LEANCLOUD_APP_ID: string;
  LEANCLOUD_APP_KEY: string;
  LEANCLOUD_SERVER_URL: string;

  // SenseNova
  SENSENOVA_API_KEY: string;
  SENSENOVA_API_URL: string;

  // Aliyun
  ALIYUN_ACCESS_KEY_ID: string;
  ALIYUN_ACCESS_KEY_SECRET: string;
  ALIYUN_OSS_ENDPOINT: string;
  ALIYUN_OSS_BUCKET: string;
  ALIYUN_WANXI_API_URL: string;

  // Apple IAP
  APPLE_SHARED_SECRET: string;
  APPLE_SANDBOX_URL: string;
  APPLE_PRODUCTION_URL: string;

  // Admin
  ADMIN_USERNAME: string;
  ADMIN_PASSWORD: string;

  // Cloudflare bindings
  HEADSHOT_KV: KVNamespace;
  ORDER_STATUS_STREAM: DurableObjectNamespace;
}
