/**
 * AI职业形象照 - Cloudflare Worker 入口
 */
import { app } from "./routes";
import { OrderStatusStream } from "./durable-objects";

export interface Env {
  LEANCLOUD_APP_ID: string;
  LEANCLOUD_APP_KEY: string;
  LEANCLOUD_SERVER_URL: string;
  SENSENOVA_API_KEY: string;
  SENSENOVA_API_URL: string;
  ALIYUN_ACCESS_KEY_ID: string;
  ALIYUN_ACCESS_KEY_SECRET: string;
  ALIYUN_OSS_ENDPOINT: string;
  ALIYUN_OSS_BUCKET: string;
  ALIYUN_WANXI_API_URL: string;
  APPLE_SHARED_SECRET: string;
  APPLE_SANDBOX_URL: string;
  APPLE_PRODUCTION_URL: string;
  ADMIN_USERNAME: string;
  ADMIN_PASSWORD: string;
  HEADSHOT_KV: KVNamespace;
  ORDER_STATUS_STREAM: DurableObjectNamespace;
}

// Worker 入口
export default {
  async fetch(request: Request, env: Env, executionCtx: ExecutionContext): Promise<Response> {
    return app.fetch(request, env, executionCtx);
  },
};

// Durable Object 导出
export { OrderStatusStream };
