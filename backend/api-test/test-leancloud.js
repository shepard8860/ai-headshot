/**
 * LeanCloud REST API 测试脚本
 *
 * 运行: node test-leancloud.js
 * 需要填写 LEANCLOUD_APP_ID, LEANCLOUD_APP_KEY, LEANCLOUD_SERVER_URL
 */

const APP_ID = process.env.LEANCLOUD_APP_ID || "YOUR_APP_ID";
const APP_KEY = process.env.LEANCLOUD_APP_KEY || "YOUR_APP_KEY";
const SERVER_URL = (process.env.LEANCLOUD_SERVER_URL || "https://your-server.example.com").replace(/\/$/, "");

function headers() {
  return {
    "X-LC-Id": APP_ID,
    "X-LC-Key": APP_KEY,
    "Content-Type": "application/json",
  };
}

/**
 * 测试创建订单
 */
async function testCreateOrder() {
  console.log("=".repeat(50));
  console.log("Testing LeanCloud - Create Order");
  console.log("=".repeat(50));

  const order = {
    order_id: `TEST-${Date.now()}`,
    user_id: "user_test_001",
    template_id: "template_business_01",
    status: "PENDING",
    original_image_url: "https://example.com/test.jpg",
    progress: 0,
    message: "Test order",
  };

  try {
    const response = await fetch(`${SERVER_URL}/1.1/classes/Orders`, {
      method: "POST",
      headers: headers(),
      body: JSON.stringify(order),
    });

    const data = await response.json();
    console.log("Status:", response.status);
    console.log("Response:", JSON.stringify(data, null, 2));

    if (response.ok && data.objectId) {
      console.log("\n✅ 创建订单成功，objectId:", data.objectId);
      return { ...order, objectId: data.objectId };
    } else {
      throw new Error(data.error || "Create failed");
    }
  } catch (err) {
    console.error("\n❌ 创建订单失败:", err.message);
    throw err;
  }
}

/**
 * 测试查询订单
 */
async function testGetOrder(orderId) {
  console.log("\n" + "=".repeat(50));
  console.log("Testing LeanCloud - Get Order");
  console.log("=".repeat(50));

  const where = encodeURIComponent(JSON.stringify({ order_id: orderId }));

  try {
    const response = await fetch(`${SERVER_URL}/1.1/classes/Orders?where=${where}&limit=1`, {
      headers: headers(),
    });

    const data = await response.json();
    console.log("Status:", response.status);
    console.log("Response:", JSON.stringify(data, null, 2));

    if (response.ok && data.results?.length > 0) {
      console.log("\n✅ 查询订单成功");
      return data.results[0];
    } else if (data.results?.length === 0) {
      console.warn("\n⚠️ 未找到订单");
      return null;
    } else {
      throw new Error(data.error || "Query failed");
    }
  } catch (err) {
    console.error("\n❌ 查询订单失败:", err.message);
    throw err;
  }
}

/**
 * 测试更新订单
 */
async function testUpdateOrder(objectId) {
  console.log("\n" + "=".repeat(50));
  console.log("Testing LeanCloud - Update Order");
  console.log("=".repeat(50));

  const updates = {
    status: "COMPLETED",
    progress: 100,
    preview_urls: ["https://example.com/result1.jpg", "https://example.com/result2.jpg"],
    message: "Test update",
  };

  try {
    const response = await fetch(`${SERVER_URL}/1.1/classes/Orders/${objectId}`, {
      method: "PUT",
      headers: headers(),
      body: JSON.stringify(updates),
    });

    const data = await response.json();
    console.log("Status:", response.status);
    console.log("Response:", JSON.stringify(data, null, 2));

    if (response.ok) {
      console.log("\n✅ 更新订单成功");
      return data;
    } else {
      throw new Error(data.error || "Update failed");
    }
  } catch (err) {
    console.error("\n❌ 更新订单失败:", err.message);
    throw err;
  }
}

/**
 * 测试查询模板列表
 */
async function testGetTemplates() {
  console.log("\n" + "=".repeat(50));
  console.log("Testing LeanCloud - Get Templates");
  console.log("=".repeat(50));

  try {
    const response = await fetch(`${SERVER_URL}/1.1/classes/Templates?order=sort_order`, {
      headers: headers(),
    });

    const data = await response.json();
    console.log("Status:", response.status);
    console.log("Response:", JSON.stringify(data, null, 2));

    if (response.ok) {
      console.log(`\n✅ 查询模板成功，共 ${data.results?.length ?? 0} 个模板`);
      return data.results;
    } else {
      throw new Error(data.error || "Query failed");
    }
  } catch (err) {
    console.error("\n❌ 查询模板失败:", err.message);
    throw err;
  }
}

/**
 * 测试删除订单（清理测试数据）
 */
async function testDeleteOrder(objectId) {
  console.log("\n" + "=".repeat(50));
  console.log("Testing LeanCloud - Delete Order (Cleanup)");
  console.log("=".repeat(50));

  try {
    const response = await fetch(`${SERVER_URL}/1.1/classes/Orders/${objectId}`, {
      method: "DELETE",
      headers: headers(),
    });

    console.log("Status:", response.status);
    if (response.ok) {
      console.log("\n✅ 删除测试数据成功");
    }
  } catch (err) {
    console.warn("\n⚠️ 删除测试数据失败:", err.message);
  }
}

// 主执行
async function main() {
  if (APP_ID === "YOUR_APP_ID" || APP_KEY === "YOUR_APP_KEY") {
    console.error("\u274c 请设置 LEANCLOUD_APP_ID 和 LEANCLOUD_APP_KEY 环境变量");
    process.exit(1);
  }

  console.log("Server URL:", SERVER_URL);
  console.log("App ID:", APP_ID.substring(0, 4) + "...");

  try {
    // 1. 创建
    const order = await testCreateOrder();

    // 2. 查询
    await testGetOrder(order.order_id);

    // 3. 更新
    await testUpdateOrder(order.objectId);

    // 4. 再次查询验证
    await testGetOrder(order.order_id);

    // 5. 查询模板
    await testGetTemplates();

    // 6. 清理
    await testDeleteOrder(order.objectId);

    console.log("\n" + "=".repeat(50));
    console.log("✅ 所有测试通过！");
    console.log("=".repeat(50));
  } catch (err) {
    console.error("\n❌ 测试失败:", err.message);
    process.exit(1);
  }
}

main();
