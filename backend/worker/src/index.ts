/**
 * AI职业形象照 - Cloudflare Worker 入口
 */
import { app } from "./routes";
import { OrderStatusStream } from "./durable-objects";
import type { Env } from "./types";
export type { Env } from "./types";

// Worker 入口
export default {
  async fetch(request: Request, env: Env, executionCtx: ExecutionContext): Promise<Response> {
    return app.fetch(request, env, executionCtx);
  },
};

// Durable Object 导出
export { OrderStatusStream };
