/**
 * Apple IAP Server-side Receipt 验证
 * 文档: https://developer.apple.com/documentation/appstorereceipts/verifyreceipt
 */
import type { Env, AppleVerifyReceiptResponse, VerifyPaymentResponse } from "./types";
import { fetchWithRetry, log } from "./utils";

/**
 * 验证 Apple 收据
 * @param receiptData Base64 编码的收据数据
 * @param isSandbox 是否沙盒环境
 */
export async function verifyAppleReceipt(
  env: Env,
  receiptData: string,
  isSandbox = false
): Promise<VerifyPaymentResponse> {
  // Mock 模式：直接返回成功
  if (env.APPLE_SHARED_SECRET === "mock") {
    log("info", "[MOCK] Apple receipt verified");
    return { success: true };
  }

  const url = isSandbox ? env.APPLE_SANDBOX_URL : env.APPLE_PRODUCTION_URL;
  const sharedSecret = env.APPLE_SHARED_SECRET;

  log("info", "[IAP] Verifying receipt", { isSandbox, urlLength: url.length });

  try {
    const response = await fetchWithRetry(
      url,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          "receipt-data": receiptData,
          password: sharedSecret,
          "exclude-old-transactions": true,
        }),
      },
      { retries: 2, delayMs: 1500 }
    );

    if (!response.ok) {
      const text = await response.text();
      log("error", "[IAP] HTTP error", { status: response.status, body: text });
      return { success: false, message: `Apple server error: ${response.status}` };
    }

    const data = (await response.json()) as AppleVerifyReceiptResponse;

    // status 0 表示验证成功
    if (data.status === 0) {
      log("info", "[IAP] Receipt valid", {
        environment: data.environment,
        transactions: data.receipt?.in_app?.length ?? 0,
      });
      return { success: true };
    }

    // status 21007 表示收据是沙盒收据，但发送到了生产环境
    if (data.status === 21007 && !isSandbox) {
      log("warn", "[IAP] Sandbox receipt sent to production, retrying with sandbox");
      return verifyAppleReceipt(env, receiptData, true);
    }

    log("error", "[IAP] Receipt invalid", { status: data.status });
    return {
      success: false,
      message: `Invalid receipt (status: ${data.status})`,
    };
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    log("error", "[IAP] Exception", { error: msg });
    return { success: false, message: `Verification failed: ${msg}` };
  }
}

/**
 * 查找订单对应的交易（通过 product_id 或 transaction_id 匹配）
 */
export function findTransactionForOrder(
  data: AppleVerifyReceiptResponse,
  productId: string
): { transactionId: string; purchaseDate: string } | null {
  const inApp = data.receipt?.in_app ?? [];
  const latest = data.latest_receipt_info ?? [];
  const all = [...latest, ...inApp];

  for (const tx of all) {
    if (tx.product_id === productId) {
      return {
        transactionId: tx.transaction_id,
        purchaseDate: tx.purchase_date,
      };
    }
  }
  return null;
}
