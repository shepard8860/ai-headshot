/**
 * 运营管理后台
 * 路径: /admin/*
 * 认证: HTTP Basic Auth
 */
import { Hono } from "hono";
import type { Env } from "./types";
import { jsonResponse, errorResponse, log } from "./utils";
import { getLeanCloudClient } from "./leancloud";

type Context = {
  Bindings: Env;
  Variables: Record<string, unknown>;
};

const adminApp = new Hono<Context>();

// ====== Basic Auth 中间件 ======
adminApp.use("/*", async (c, next) => {
  const authHeader = c.req.header("Authorization");
  if (!authHeader || !authHeader.startsWith("Basic ")) {
    return new Response("Unauthorized", {
      status: 401,
      headers: { "WWW-Authenticate": 'Basic realm="Admin Panel"' },
    });
  }

  try {
    const encoded = authHeader.replace("Basic ", "");
    const decoded = atob(encoded);
    const [username, password] = decoded.split(":");

    const envUsername = c.env.ADMIN_USERNAME || "admin";
    const envPassword = c.env.ADMIN_PASSWORD || "";

    if (!envPassword) {
      log("warn", "Admin password not configured");
      return errorResponse("Admin not configured", "ADMIN_NOT_CONFIGURED", 403);
    }

    if (username !== envUsername || password !== envPassword) {
      return new Response("Unauthorized", {
        status: 401,
        headers: { "WWW-Authenticate": 'Basic realm="Admin Panel"' },
      });
    }

    await next();
  } catch {
    return new Response("Unauthorized", {
      status: 401,
      headers: { "WWW-Authenticate": 'Basic realm="Admin Panel"' },
    });
  }
});

// ====== GET /admin - 后台首页（JSON 概览） ======
adminApp.get("/", async (c) => {
  const lc = getLeanCloudClient(c.env);

  try {
    // 获取订单统计
    const ordersRes = await fetch(`${c.env.LEANCLOUD_SERVER_URL.replace(/\/$/, "")}/1.1/classes/Orders?count=1&limit=0`, {
      headers: {
        "X-LC-Id": c.env.LEANCLOUD_APP_ID,
        "X-LC-Key": c.env.LEANCLOUD_APP_KEY,
        "Content-Type": "application/json",
      },
    });
    const ordersCount = ordersRes.ok ? ((await ordersRes.json()) as { count?: number }).count ?? 0 : 0;

    // 获取各状态订单数
    const statusCounts: Record<string, number> = {};
    for (const status of ["PENDING", "GENERATING", "COMPLETED", "FAILED", "PAID"]) {
      const where = encodeURIComponent(JSON.stringify({ status }));
      const res = await fetch(
        `${c.env.LEANCLOUD_SERVER_URL.replace(/\/$/, "")}/1.1/classes/Orders?count=1&limit=0&where=${where}`,
        {
          headers: {
            "X-LC-Id": c.env.LEANCLOUD_APP_ID,
            "X-LC-Key": c.env.LEANCLOUD_APP_KEY,
            "Content-Type": "application/json",
          },
        }
      );
      statusCounts[status] = res.ok ? ((await res.json()) as { count?: number }).count ?? 0 : 0;
    }

    // 获取模板数量
    const templates = await lc.getTemplates();

    return jsonResponse({
      dashboard: {
        total_orders: ordersCount,
        status_breakdown: statusCounts,
        total_templates: templates.length,
        premium_templates: templates.filter((t) => t.is_premium).length,
        updated_at: new Date().toISOString(),
      },
      links: {
        orders: "/admin/orders",
        templates: "/admin/templates",
        health: "/health",
      },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    log("error", "Admin dashboard error", { error: msg });
    return errorResponse("Failed to load dashboard", "ADMIN_ERROR", 500, msg);
  }
});

// ====== GET /admin/orders - 订单列表 ======
adminApp.get("/orders", async (c) => {
  const page = parseInt(c.req.query("page") || "1", 10);
  const pageSize = Math.min(parseInt(c.req.query("pageSize") || "20", 10), 100);
  const status = c.req.query("status");
  const skip = (page - 1) * pageSize;

  try {
    let url = `${c.env.LEANCLOUD_SERVER_URL.replace(/\/$/, "")}/1.1/classes/Orders?order=-createdAt&limit=${pageSize}&skip=${skip}`;
    if (status) {
      const where = encodeURIComponent(JSON.stringify({ status }));
      url += `&where=${where}`;
    }

    const res = await fetch(url, {
      headers: {
        "X-LC-Id": c.env.LEANCLOUD_APP_ID,
        "X-LC-Key": c.env.LEANCLOUD_APP_KEY,
        "Content-Type": "application/json",
      },
    });

    if (!res.ok) {
      return errorResponse("Failed to fetch orders", "FETCH_ERROR", 500);
    }

    const data = (await res.json()) as { results: Array<Record<string, unknown>> };

    return jsonResponse({
      page,
      pageSize,
      total: data.results.length,
      orders: data.results.map((o) => ({
        objectId: o.objectId,
        order_id: o.order_id,
        user_id: o.user_id,
        template_id: o.template_id,
        status: o.status,
        progress: o.progress,
        ai_provider: o.ai_provider,
        createdAt: o.createdAt,
        updatedAt: o.updatedAt,
      })),
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    log("error", "Admin orders error", { error: msg });
    return errorResponse("Failed to fetch orders", "ADMIN_ERROR", 500, msg);
  }
});

// ====== GET /admin/templates - 模板管理 ======
adminApp.get("/templates", async (c) => {
  try {
    const lc = getLeanCloudClient(c.env);
    const templates = await lc.getTemplates();

    return jsonResponse({
      total: templates.length,
      templates: templates.map((t) => ({
        objectId: t.objectId,
        template_id: t.template_id,
        name: t.name,
        category: t.category,
        is_premium: t.is_premium,
        sort_order: t.sort_order,
        thumbnail_url: t.thumbnail_url,
      })),
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    log("error", "Admin templates error", { error: msg });
    return errorResponse("Failed to fetch templates", "ADMIN_ERROR", 500, msg);
  }
});

// ====== PUT /admin/templates/:id - 更新模板 ======
adminApp.put("/templates/:id", async (c) => {
  const templateId = c.req.param("id");
  try {
    const body = await c.req.json();
    const lc = getLeanCloudClient(c.env);

    // 查找模板
    const template = await lc.getTemplateById(templateId);
    if (!template || !template.objectId) {
      return errorResponse("Template not found", "TEMPLATE_NOT_FOUND", 404);
    }

    // 允许更新的字段
    const allowedUpdates: Record<string, unknown> = {};
    if (body.name !== undefined) allowedUpdates.name = body.name;
    if (body.category !== undefined) allowedUpdates.category = body.category;
    if (body.thumbnail_url !== undefined) allowedUpdates.thumbnail_url = body.thumbnail_url;
    if (body.style_prompt !== undefined) allowedUpdates.style_prompt = body.style_prompt;
    if (body.is_premium !== undefined) allowedUpdates.is_premium = !!body.is_premium;
    if (body.sort_order !== undefined) allowedUpdates.sort_order = Number(body.sort_order);

    const url = `${c.env.LEANCLOUD_SERVER_URL.replace(/\/$/, "")}/1.1/classes/Templates/${template.objectId}`;
    const res = await fetch(url, {
      method: "PUT",
      headers: {
        "X-LC-Id": c.env.LEANCLOUD_APP_ID,
        "X-LC-Key": c.env.LEANCLOUD_APP_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(allowedUpdates),
    });

    if (!res.ok) {
      const text = await res.text();
      return errorResponse("Update failed", "UPDATE_ERROR", 500, text);
    }

    log("info", "Template updated via admin", { templateId, fields: Object.keys(allowedUpdates) });
    return jsonResponse({ success: true, updated: Object.keys(allowedUpdates) });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    log("error", "Admin template update error", { templateId, error: msg });
    return errorResponse("Update failed", "ADMIN_ERROR", 500, msg);
  }
});

// ====== DELETE /admin/templates/:id - 删除模板 ======
adminApp.delete("/templates/:id", async (c) => {
  const templateId = c.req.param("id");
  try {
    const lc = getLeanCloudClient(c.env);
    const template = await lc.getTemplateById(templateId);
    if (!template || !template.objectId) {
      return errorResponse("Template not found", "TEMPLATE_NOT_FOUND", 404);
    }

    const url = `${c.env.LEANCLOUD_SERVER_URL.replace(/\/$/, "")}/1.1/classes/Templates/${template.objectId}`;
    const res = await fetch(url, {
      method: "DELETE",
      headers: {
        "X-LC-Id": c.env.LEANCLOUD_APP_ID,
        "X-LC-Key": c.env.LEANCLOUD_APP_KEY,
        "Content-Type": "application/json",
      },
    });

    if (!res.ok) {
      const text = await res.text();
      return errorResponse("Delete failed", "DELETE_ERROR", 500, text);
    }

    log("info", "Template deleted via admin", { templateId });
    return jsonResponse({ success: true });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    log("error", "Admin template delete error", { templateId, error: msg });
    return errorResponse("Delete failed", "ADMIN_ERROR", 500, msg);
  }
});

// ====== GET /admin/orders/:id - 订单详情 ======
adminApp.get("/orders/:id", async (c) => {
  const orderId = c.req.param("id");
  try {
    const lc = getLeanCloudClient(c.env);
    const order = await lc.getOrderByOrderId(orderId);
    if (!order) {
      return errorResponse("Order not found", "ORDER_NOT_FOUND", 404);
    }
    return jsonResponse({ order });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    log("error", "Admin order detail error", { orderId, error: msg });
    return errorResponse("Fetch failed", "ADMIN_ERROR", 500, msg);
  }
});

export { adminApp };
