/**
 * 工具函数集合
 */
import type { ErrorResponse } from "./types";

// 生成唯一 ID（简化的 UUID v4）
export function generateId(): string {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

// 生成订单 ID
export function generateOrderId(): string {
  const timestamp = Date.now().toString(36).toUpperCase();
  const random = Math.random().toString(36).substring(2, 6).toUpperCase();
  return `ORD-${timestamp}-${random}`;
}

// 形成统一的 JSON 响应
export function jsonResponse<T>(data: T, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

// 错误响应
export function errorResponse(
  message: string,
  code: string,
  status = 400,
  details?: string
): Response {
  const body: ErrorResponse = { error: message, code };
  if (details) body.details = details;
  return jsonResponse(body, status);
}

// 带重试的 fetch 封装
export async function fetchWithRetry(
  input: RequestInfo,
  init?: RequestInit,
  options: { retries?: number; delayMs?: number } = {}
): Promise<Response> {
  const { retries = 3, delayMs = 1000 } = options;
  let lastError: Error | undefined;

  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(input, init);
      if (response.status < 500) {
        return response;
      }
      // 服务器错误时重试
      lastError = new Error(`HTTP ${response.status}: ${response.statusText}`);
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));
    }

    if (i < retries - 1) {
      await sleep(delayMs * (i + 1)); // 指数退避
    }
  }

  throw lastError ?? new Error("Fetch failed after retries");
}

// 延迟
export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// 基于 HMAC-SHA1 的签名（用于阿里云 OSS / API）
export async function hmacSha1(key: string, data: string): Promise<string> {
  const encoder = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    encoder.encode(key),
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(data));
  return btoa(String.fromCharCode(...new Uint8Array(signature)));
}

// 基于 HMAC-SHA256 的签名
export async function hmacSha256(key: string, data: string): Promise<string> {
  const encoder = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    encoder.encode(key),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(data));
  return btoa(String.fromCharCode(...new Uint8Array(signature)));
}

// 日志输出（统一格式）
export function log(level: "info" | "warn" | "error", message: string, extra?: Record<string, unknown>): void {
  const timestamp = new Date().toISOString();
  const payload = { timestamp, level, message, ...extra };
  console.log(JSON.stringify(payload));
}

// 验证请求体
export function validateBody<T extends Record<string, unknown>>(
  body: unknown,
  requiredFields: string[]
): { valid: true; data: T } | { valid: false; error: string } {
  if (!body || typeof body !== "object") {
    return { valid: false, error: "Request body must be a JSON object" };
  }
  const obj = body as Record<string, unknown>;
  for (const field of requiredFields) {
    if (obj[field] === undefined || obj[field] === null || obj[field] === "") {
      return { valid: false, error: `Missing required field: ${field}` };
    }
  }
  return { valid: true, data: obj as T };
}
