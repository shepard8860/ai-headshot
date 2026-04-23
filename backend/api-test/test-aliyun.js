/**
 * 阿里云通义万相 / 人脸融合 API 测试脚本
 *
 * 运行: node test-aliyun.js
 * 需要填写 ALIYUN_API_KEY (即 DashScope API-Key)
 */

const ALIYUN_API_KEY = process.env.ALIYUN_API_KEY || "YOUR_DASHSCOPE_API_KEY";
const ALIYUN_WANXI_URL =
  process.env.ALIYUN_WANXI_URL ||
  "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis";

const REFERENCE_IMAGE_URL =
  process.env.REFERENCE_IMAGE ||
  "https://example.com/sample-portrait.jpg";

const PROMPT =
  process.env.PROMPT ||
  "Professional headshot, corporate portrait, clean background, business attire, studio lighting, high quality";

/**
 * 测试通义万相人像生成 API
 */
async function testWanxiangPortrait() {
  console.log("=".repeat(50));
  console.log("Testing Aliyun Wanxiang Portrait Generation API");
  console.log("=".repeat(50));

  if (ALIYUN_API_KEY === "YOUR_DASHSCOPE_API_KEY") {
    console.error("\u274c 请设置环境变量 ALIYUN_API_KEY 或在脚本中填写 API Key");
    process.exit(1);
  }

  const startTime = Date.now();

  try {
    const requestBody = {
      model: "wanx-portrait-generation-v1",
      input: {
        prompt: PROMPT,
        reference_image_url: REFERENCE_IMAGE_URL,
      },
      parameters: {
        size: "1024*1024",
        n: 1,
      },
    };

    console.log("\nRequest URL:", ALIYUN_WANXI_URL);
    console.log("Request Body:", JSON.stringify(requestBody, null, 2));

    const response = await fetch(ALIYUN_WANXI_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${ALIYUN_API_KEY}`,
        "X-DashScope-Async": "disable",
      },
      body: JSON.stringify(requestBody),
    });

    const data = await response.json();
    const duration = Date.now() - startTime;

    console.log(`\n✅ Response received in ${duration}ms`);
    console.log("Status:", response.status, response.statusText);
    console.log("Body:", JSON.stringify(data, null, 2));

    if (response.ok && (data.output?.image_url || data.output?.results?.length)) {
      console.log("\n✅ 测试通过！生成的图片 URL:",
        data.output.image_url || data.output.results.map((r) => r.url).join(", ")
      );
    } else if (data.error) {
      console.error("\n❌ API 错误:", data.error.message || data.error);
    }

    return data;
  } catch (error) {
    console.error("\n❌ 请求异常:", error.message);
    throw error;
  }
}

/**
 * 测试阿里云人脸融合 API（如果有接口）
 * 参考：https://help.aliyun.com/document_detail/XXXXX.html
 */
async function testFaceFusion() {
  console.log("\n" + "=".repeat(50));
  console.log("Testing Aliyun Face Fusion API (Mock/Demo)");
  console.log("=".repeat(50));

  console.log("\nℹ️ 人脸融合接口需要独立的 API 调用方式，");
  console.log("   请根据实际接入的服务填充对应的 endpoint 和参数。");

  return { note: "Face Fusion test requires specific endpoint configuration" };
}

// 主执行
async function main() {
  try {
    await testWanxiangPortrait();
    await testFaceFusion();
  } catch (err) {
    console.error("\n❌ 测试失败:", err.message);
    process.exit(1);
  }
}

main();
