/**
 * 阿里云 OSS 签名 URL 生成
 * 文档: https://help.aliyun.com/document_detail/31952.html
 */
import type { Env } from "./types";
import { hmacSha1, log } from "./utils";

interface SignedUrlOptions {
  /** 文件路径（不含 bucket） */
  objectKey: string;
  /** URL 有效期，默认 3600 秒 */
  expiresIn?: number;
  /** HTTP 方法 */
  method?: "GET" | "PUT" | "POST";
  /** 附加的 HTTP Headers */
  headers?: Record<string, string>;
}

/**
 * 生成 OSS 签名 URL（URL 签名）
 */
export async function generateSignedUrl(
  env: Env,
  options: SignedUrlOptions
): Promise<string> {
  const { objectKey, expiresIn = 3600, method = "GET" } = options;
  const accessKeyId = env.ALIYUN_ACCESS_KEY_ID;
  const accessKeySecret = env.ALIYUN_ACCESS_KEY_SECRET;
  const endpoint = env.ALIYUN_OSS_ENDPOINT;
  const bucket = env.ALIYUN_OSS_BUCKET;

  // Mock 模式：返回占位 URL
  if (accessKeyId === "mock") {
    log("info", "[MOCK] generateSignedUrl", { objectKey, method });
    return `https://placehold.co/600x600/3b82f6/ffffff?text=Mock+OSS+${encodeURIComponent(objectKey)}`;
  }

  if (!accessKeyId || !accessKeySecret) {
    throw new Error("Aliyun OSS credentials are not configured");
  }

  const expires = Math.floor(Date.now() / 1000) + expiresIn;
  const canonicalizedResource = `/${bucket}/${objectKey}`;

  // 构建签名字符串
  const verb = method;
  const contentMd5 = "";
  const contentType = options.headers?.["Content-Type"] ?? "";
  const date = `${expires}`; // URL 签名使用过期时间戳作为 date

  const signatureString = `${verb}\n${contentMd5}\n${contentType}\n${date}\n${canonicalizedResource}`;
  const signature = await hmacSha1(accessKeySecret, signatureString);

  const encodedSignature = encodeURIComponent(signature);
  const url = `https://${bucket}.${endpoint}/${objectKey}?OSSAccessKeyId=${accessKeyId}&Expires=${expires}&Signature=${encodedSignature}`;

  log("info", "Generated OSS signed URL", { objectKey, expiresIn, method });
  return url;
}

/**
 * 生成上传临时 URL（用于用户上传原始照片）
 */
export async function generateUploadUrl(
  env: Env,
  objectKey: string,
  contentType = "image/jpeg"
): Promise<{ uploadUrl: string; publicUrl: string }> {
  const uploadUrl = await generateSignedUrl(env, {
    objectKey,
    method: "PUT",
    expiresIn: 600, // 10 分钟上传有效期
    headers: { "Content-Type": contentType },
  });

  // 生成一个长期有效的 GET 签名 URL，供 AI 服务访问
  const publicUrl = await generateSignedUrl(env, {
    objectKey,
    method: "GET",
    expiresIn: 7 * 24 * 3600, // 7 天
  });

  return { uploadUrl, publicUrl };
}

/**
 * 生成下载 URL（用于高清照片下载）
 */
export async function generateDownloadUrl(
  env: Env,
  objectKey: string,
  expiresIn = 3600
): Promise<string> {
  return generateSignedUrl(env, { objectKey, method: "GET", expiresIn });
}
