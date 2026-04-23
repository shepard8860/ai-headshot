/**
 * AI 供应商封装
 * 主：商汤 SenseNova
 * 备：阿里云通义万相
 */
import type {
  Env,
  SenseNovaGenerateRequest,
  SenseNovaGenerateResponse,
  AliyunWanxiangRequest,
  AliyunWanxiangResponse,
} from "./types";
import { fetchWithRetry, log, sleep } from "./utils";

export type AIProvider = "sensetime" | "aliyun";

interface GenerateResult {
  success: boolean;
  imageUrls?: string[];
  provider: AIProvider;
  error?: string;
}

interface ProviderHealth {
  healthy: boolean;
  lastCheckedAt: number;
  failCount: number;
}

// 健康检查缓存键
const HEALTH_KEY_PREFIX = "health:";

// 获取供应商健康状态（从 KV 缓存）
async function getProviderHealth(kv: KVNamespace, provider: AIProvider): Promise<ProviderHealth> {
  const key = `${HEALTH_KEY_PREFIX}${provider}`;
  const cached = await kv.get(key);
  if (cached) {
    try {
      return JSON.parse(cached) as ProviderHealth;
    } catch {
      // ignore parse error
    }
  }
  return { healthy: true, lastCheckedAt: 0, failCount: 0 };
}

// 更新供应商健康状态
async function updateProviderHealth(
  kv: KVNamespace,
  provider: AIProvider,
  healthy: boolean
): Promise<void> {
  const key = `${HEALTH_KEY_PREFIX}${provider}`;
  const current = await getProviderHealth(kv, provider);
  const updated: ProviderHealth = {
    healthy,
    lastCheckedAt: Date.now(),
    failCount: healthy ? 0 : current.failCount + 1,
  };
  await kv.put(key, JSON.stringify(updated), { expirationTtl: 3600 });
}

// 检查供应商是否健康
async function isProviderHealthy(kv: KVNamespace, provider: AIProvider): Promise<boolean> {
  const health = await getProviderHealth(kv, provider);
  // 连续失败 3 次以上标记为不健康
  if (health.failCount >= 3) {
    // 超过 5 分钟后重新尝试
    if (Date.now() - health.lastCheckedAt > 5 * 60 * 1000) {
      return true;
    }
    return false;
  }
  return true;
}

// ==================== 商汤 SenseNova ====================

async function callSenseNova(
  env: Env,
  imageUrl: string,
  prompt: string
): Promise<GenerateResult> {
  const startTime = Date.now();
  log("info", "[SenseNova] Start generation", { imageUrl, promptLength: prompt.length });

  const body: SenseNovaGenerateRequest = {
    model: "SenseNova-Portrait",
    input: {
      prompt,
      reference_image: imageUrl,
    },
    parameters: {
      size: "1024x1024",
      n: 1,
    },
  };

  try {
    const response = await fetchWithRetry(
      `${env.SENSENOVA_API_URL}/images/generations`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${env.SENSENOVA_API_KEY}`,
        },
        body: JSON.stringify(body),
      },
      { retries: 2, delayMs: 2000 }
    );

    const data = (await response.json()) as SenseNovaGenerateResponse;

    if (!response.ok || data.error) {
      const errMsg = data.error?.message ?? `HTTP ${response.status}`;
      log("error", "[SenseNova] API error", { status: response.status, error: errMsg });
      await updateProviderHealth(env.HEADSHOT_KV, "sensetime", false);
      return { success: false, provider: "sensetime", error: errMsg };
    }

    const urls: string[] = [];
    if (data.output?.image_url) urls.push(data.output.image_url);
    if (data.output?.image_urls) urls.push(...data.output.image_urls);

    log("info", "[SenseNova] Success", { duration: Date.now() - startTime, urlsCount: urls.length });
    await updateProviderHealth(env.HEADSHOT_KV, "sensetime", true);
    return { success: true, imageUrls: urls, provider: "sensetime" };
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log("error", "[SenseNova] Exception", { error: msg });
    await updateProviderHealth(env.HEADSHOT_KV, "sensetime", false);
    return { success: false, provider: "sensetime", error: msg };
  }
}

// ==================== 阿里云通义万相 ====================

async function callAliyunWanxiang(
  env: Env,
  imageUrl: string,
  prompt: string
): Promise<GenerateResult> {
  const startTime = Date.now();
  log("info", "[Aliyun] Start generation", { imageUrl, promptLength: prompt.length });

  const body: AliyunWanxiangRequest = {
    model: "wanx-portrait-generation-v1",
    input: {
      prompt,
      reference_image_url: imageUrl,
    },
    parameters: {
      size: "1024*1024",
      n: 1,
    },
  };

  try {
    const response = await fetchWithRetry(
      `${env.ALIYUN_WANXI_API_URL}/services/aigc/text2image/image-synthesis`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${env.ALIYUN_ACCESS_KEY_ID}`, // DashScope 使用 API-Key 方式
          "X-DashScope-Async": "disable", // 同步模式
        },
        body: JSON.stringify(body),
      },
      { retries: 2, delayMs: 2000 }
    );

    const data = (await response.json()) as AliyunWanxiangResponse;

    if (!response.ok || data.error) {
      const errMsg = data.error?.message ?? `HTTP ${response.status}`;
      log("error", "[Aliyun] API error", { status: response.status, error: errMsg });
      await updateProviderHealth(env.HEADSHOT_KV, "aliyun", false);
      return { success: false, provider: "aliyun", error: errMsg };
    }

    const urls: string[] = [];
    if (data.output?.image_url) urls.push(data.output.image_url);
    if (data.output?.results) {
      urls.push(...data.output.results.map((r) => r.url));
    }

    log("info", "[Aliyun] Success", { duration: Date.now() - startTime, urlsCount: urls.length });
    await updateProviderHealth(env.HEADSHOT_KV, "aliyun", true);
    return { success: true, imageUrls: urls, provider: "aliyun" };
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log("error", "[Aliyun] Exception", { error: msg });
    await updateProviderHealth(env.HEADSHOT_KV, "aliyun", false);
    return { success: false, provider: "aliyun", error: msg };
  }
}

// ==================== 统一入口与降级 ====================

/**
 * 生成职业形象照
 * 优先使用 SenseNova，失败时自动切换到阿里云
 */
export async function generateHeadshot(
  env: Env,
  imageUrl: string,
  prompt: string
): Promise<GenerateResult> {
  const primaryHealthy = await isProviderHealthy(env.HEADSHOT_KV, "sensetime");
  const fallbackHealthy = await isProviderHealthy(env.HEADSHOT_KV, "aliyun");

  // 主供应商
  if (primaryHealthy) {
    const result = await callSenseNova(env, imageUrl, prompt);
    if (result.success) return result;

    log("warn", "Primary provider (SenseNova) failed, trying fallback", {
      error: result.error,
    });

    // 主失败后，等待一点时间再尝试备份
    await sleep(1000);
  }

  // 备份供应商
  if (fallbackHealthy) {
    const fallbackResult = await callAliyunWanxiang(env, imageUrl, prompt);
    if (fallbackResult.success) return fallbackResult;

    log("error", "Fallback provider (Aliyun) also failed", { error: fallbackResult.error });
    return fallbackResult;
  }

  // 两者都不可用
  return {
    success: false,
    provider: "sensetime",
    error: "All AI providers are unhealthy. Please try again later.",
  };
}

/**
 * 健康检查：检查所有供应商状态
 */
export async function healthCheck(env: Env): Promise<{
  sensetime: boolean;
  aliyun: boolean;
}> {
  const sensetime = await isProviderHealthy(env.HEADSHOT_KV, "sensetime");
  const aliyun = await isProviderHealthy(env.HEADSHOT_KV, "aliyun");
  return { sensetime, aliyun };
}
