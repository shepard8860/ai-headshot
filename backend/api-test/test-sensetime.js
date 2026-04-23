/**
 * 商汤 SenseNova API 测试脚本
 * 使用 Node.js fetch (v18+) 或安装 node-fetch
 *
 * 运行: node test-sensetime.js
 * 需要填写 SENSENOVA_API_KEY
 */

const SENSENOVA_API_KEY = process.env.SENSENOVA_API_KEY || "YOUR_SENSENOVA_API_KEY";
const SENSENOVA_API_URL = process.env.SENSENOVA_API_URL || "https://api.sensenova.cn/v1";

const REFERENCE_IMAGE_URL =
  process.env.REFERENCE_IMAGE ||
  "https://example.com/sample-portrait.jpg"; // 替换为实际的参考图片 URL

const PROMPT =
  process.env.PROMPT ||
  "Professional headshot, corporate portrait, clean background, business attire, studio lighting, high quality";

async function testSenseNova() {
  console.log("=".repeat(50));
  console.log("Testing SenseNova Portrait Generation API");
  console.log("=".repeat(50));

  if (SENSENOVA_API_KEY === "YOUR_SENSENOVA_API_KEY") {
    console.error("\u274c 请设置环境变量 SENSENOVA_API_KEY 或在脚本中填写 API Key");
    process.exit(1);
  }

  const startTime = Date.now();

  try {
    const requestBody = {
      model: "SenseNova-Portrait",
      input: {
        prompt: PROMPT,
        reference_image: REFERENCE_IMAGE_URL,
      },
      parameters: {
        size: "1024x1024",
        n: 1,
      },
    };

    console.log("\nRequest URL:", `${SENSENOVA_API_URL}/images/generations`);
    console.log("Request Body:", JSON.stringify(requestBody, null, 2));

    const response = await fetch(`${SENSENOVA_API_URL}/images/generations`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${SENSENOVA_API_KEY}`,
      },
      body: JSON.stringify(requestBody),
    });

    const data = await response.json();
    const duration = Date.now() - startTime;

    console.log(`\n✅ Response received in ${duration}ms`);
    console.log("Status:", response.status, response.statusText);
    console.log("Headers:", Object.fromEntries(response.headers.entries()));
    console.log("Body:", JSON.stringify(data, null, 2));

    if (response.ok && data.output?.image_url) {
      console.log("\n✅ 测试通过！生成的图片 URL:", data.output.image_url);
    } else if (data.error) {
      console.error("\n❌ API 错误:", data.error.message || data.error);
    } else {
      console.warn("\n⚠️ 响应中没有找到 image_url");
    }

    return data;
  } catch (error) {
    console.error("\n❌ 请求异常:", error.message);
    throw error;
  }
}

// 重试测试
async function testWithRetry(retries = 2) {
  for (let i = 0; i <= retries; i++) {
    try {
      await testSenseNova();
      return;
    } catch (err) {
      if (i < retries) {
        console.log(`\n⏳ 第 ${i + 1} 次重试...`);
        await new Promise((r) => setTimeout(r, 2000 * (i + 1)));
      } else {
        console.error("\n❌ 所有重试均失败");
        process.exit(1);
      }
    }
  }
}

testWithRetry();
