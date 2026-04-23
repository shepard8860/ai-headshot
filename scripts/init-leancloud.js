#!/usr/bin/env node
/**
 * AI职业形象照 - LeanCloud 初始化脚本
 * 用法: node scripts/init-leancloud.js
 * 说明: 自动创建 Class 并导入模板数据
 */

const fs = require('fs');
const path = require('path');

// ============================================================
// 配置区域：填写你的 LeanCloud 应用凭证
// ============================================================
const APP_ID = process.env.LEANCLOUD_APP_ID || '';
const APP_KEY = process.env.LEANCLOUD_APP_KEY || '';
const SERVER_URL = process.env.LEANCLOUD_SERVER_URL || 'https://api.leancloud.cn';

// ============================================================
// 颜色输出
// ============================================================
const CYAN = '\x1b[36m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const RED = '\x1b[31m';
const NC = '\x1b[0m';

function info(msg) { console.log(`${CYAN}[INFO]${NC} ${msg}`); }
function ok(msg) { console.log(`${GREEN}[OK]${NC} ${msg}`); }
function warn(msg) { console.log(`${YELLOW}[WARN]${NC} ${msg}`); }
function err(msg) { console.log(`${RED}[ERR]${NC} ${msg}`); }

// ============================================================
// 验证配置
// ============================================================
if (!APP_ID || !APP_KEY) {
    err('LeanCloud AppID 或 AppKey 未配置');
    console.log('');
    info('请通过以下一种方式配置:');
    console.log('  1. 环境变量: export LEANCLOUD_APP_ID=xxx LEANCLOUD_APP_KEY=yyy');
    console.log('  2. 运行之前的 configure.sh 生成 .dev.vars');
    process.exit(1);
}

const BASE_URL = SERVER_URL.replace(/\/$/, '');

function headers() {
    return {
        'X-LC-Id': APP_ID,
        'X-LC-Key': APP_KEY,
        'Content-Type': 'application/json',
    };
}

async function request(url, options = {}) {
    const res = await fetch(url, {
        ...options,
        headers: { ...headers(), ...(options.headers || {}) },
    });
    if (!res.ok) {
        const text = await res.text();
        throw new Error(`HTTP ${res.status}: ${text}`);
    }
    if (res.status === 204) return null;
    return res.json().catch(() => null);
}

// ============================================================
// 创建 Class Schema
// ============================================================
const CLASSES = [
    {
        name: 'Orders',
        schema: {
            order_id: { type: 'String', required: true },
            user_id: { type: 'String', required: true },
            template_id: { type: 'String', required: true },
            status: { type: 'String', required: true },
            original_image_url: { type: 'String', required: true },
            preview_urls: { type: 'Array' },
            hd_urls: { type: 'Array' },
            progress: { type: 'Number' },
            message: { type: 'String' },
            error_message: { type: 'String' },
            ai_provider: { type: 'String' },
            paid_at: { type: 'Date' },
            apple_transaction_id: { type: 'String' },
        },
    },
    {
        name: 'Templates',
        schema: {
            template_id: { type: 'String', required: true },
            name: { type: 'String', required: true },
            category: { type: 'String', required: true },
            thumbnail_url: { type: 'String' },
            style_prompt: { type: 'String' },
            is_premium: { type: 'Boolean' },
            sort_order: { type: 'Number' },
        },
    },
    {
        name: 'UserProfile',
        schema: {
            user_id: { type: 'String', required: true },
            nickname: { type: 'String' },
            avatar_url: { type: 'String' },
            gender: { type: 'String' },
            total_orders: { type: 'Number' },
            total_payments: { type: 'Number' },
            last_active_at: { type: 'Date' },
        },
    },
    {
        name: 'PaymentRecord',
        schema: {
            order_id: { type: 'String', required: true },
            user_id: { type: 'String', required: true },
            amount: { type: 'Number' },
            currency: { type: 'String' },
            provider: { type: 'String' },
            transaction_id: { type: 'String' },
            status: { type: 'String' },
            paid_at: { type: 'Date' },
            receipt_data: { type: 'String' },
        },
    },
    {
        name: 'Feedback',
        schema: {
            user_id: { type: 'String', required: true },
            order_id: { type: 'String' },
            type: { type: 'String' },
            content: { type: 'String' },
            rating: { type: 'Number' },
            contact: { type: 'String' },
            resolved: { type: 'Boolean' },
            resolved_at: { type: 'Date' },
        },
    },
];

async function createClassIfNotExists(className, schema) {
    info(`检查 Class: ${className}`);
    try {
        // LeanCloud REST API 没有直接创建 Class 的 API，只能通过创建一条数据来间接创建
        // 或者通过 SDK / 控制台创建
        // 这里尝试创建一个占位数据，如果已存在则忽略错误
        const url = `${BASE_URL}/1.1/classes/${className}`;
        const payload = {};
        for (const [key, def] of Object.entries(schema)) {
            if (def.type === 'String') payload[key] = '';
            else if (def.type === 'Number') payload[key] = 0;
            else if (def.type === 'Boolean') payload[key] = false;
            else if (def.type === 'Array') payload[key] = [];
            else if (def.type === 'Date') payload[key] = { __type: 'Date', iso: new Date().toISOString() };
        }
        // 添加一个标识字段表示这是初始化占位
        payload._init_marker = 'system_init';

        await request(url, { method: 'POST', body: JSON.stringify(payload) });
        ok(`Class ${className} 创建/检查完成`);

        // 删除占位数据
        try {
            const where = encodeURIComponent(JSON.stringify({ _init_marker: 'system_init' }));
            const listRes = await request(`${url}?where=${where}&limit=1`);
            if (listRes?.results?.length > 0) {
                const objectId = listRes.results[0].objectId;
                await request(`${url}/${objectId}`, { method: 'DELETE' });
                info(`已清理 ${className} 的初始占位数据`);
            }
        } catch (e) {
            // 忽略清理错误
        }
    } catch (e) {
        if (e.message.includes('already exists') || e.message.includes('Duplicate')) {
            ok(`Class ${className} 已存在`);
        } else {
            warn(`Class ${className} 操作结果: ${e.message}`);
        }
    }
}

// ============================================================
// 导入模板数据
// ============================================================
async function importTemplates() {
    const templatesDir = path.join(__dirname, '..', 'design', 'templates');
    if (!fs.existsSync(templatesDir)) {
        warn(`模板目录不存在: ${templatesDir}`);
        return;
    }

    const files = fs.readdirSync(templatesDir).filter(f => f.endsWith('.json'));
    if (files.length === 0) {
        warn('未找到模板 JSON 文件');
        return;
    }

    info(`找到 ${files.length} 个模板文件`);
    let totalImported = 0;

    for (const file of files) {
        const filePath = path.join(templatesDir, file);
        const raw = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
        const templates = Array.isArray(raw) ? raw : [raw];

        for (const t of templates) {
            // 映射 JSON 格式到 LeanCloud 字段
            const payload = {
                template_id: t.id || t.template_id,
                name: t.name,
                category: t.category,
                thumbnail_url: t.preview_image_url || t.thumbnail_url || '',
                style_prompt: t.style_prompt || '',
                is_premium: t.is_premium || false,
                sort_order: t.sort_order || 1,
                // 保留原始字段供参考
                extra: {
                    category_id: t.category_id,
                    description: t.description,
                    background_prompt: t.background_prompt,
                    clothing_prompt: t.clothing_prompt,
                    lighting_prompt: t.lighting_prompt,
                    color_tone: t.color_tone,
                    created_for_gender: t.created_for_gender,
                    is_active: t.is_active,
                },
            };

            try {
                const url = `${BASE_URL}/1.1/classes/Templates`;
                await request(url, { method: 'POST', body: JSON.stringify(payload) });
                totalImported++;
            } catch (e) {
                warn(`导入模板失败 ${t.id}: ${e.message}`);
            }
        }
    }

    ok(`成功导入 ${totalImported} 个模板`);
}

// ============================================================
// 创建索引
// ============================================================
async function createIndex(className, field) {
    try {
        const url = `${BASE_URL}/1.1/data/${className}/indexes`;
        await request(url, {
            method: 'POST',
            body: JSON.stringify({ field }),
        });
        ok(`索引创建成功: ${className}.${field}`);
    } catch (e) {
        if (e.message.includes('already exists')) {
            ok(`索引已存在: ${className}.${field}`);
        } else {
            warn(`索引创建失败 ${className}.${field}: ${e.message}`);
        }
    }
}

// ============================================================
// 主流程
// ============================================================
async function main() {
    console.log('');
    console.log('╔════════════════════════════════════════════════════════╗');
    console.log('║     LeanCloud 初始化工具                    ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    console.log('');

    info(`连接到: ${BASE_URL}`);
    info(`App ID: ${APP_ID.substring(0, 8)}...`);

    // 测试连通性
    try {
        await request(`${BASE_URL}/1.1/date`);
        ok('LeanCloud 连通性测试通过');
    } catch (e) {
        err(`连接失败: ${e.message}`);
        process.exit(1);
    }

    console.log('');
    info('步骤 1/3: 创建 Class...');
    for (const cls of CLASSES) {
        await createClassIfNotExists(cls.name, cls.schema);
    }

    console.log('');
    info('步骤 2/3: 导入模板数据...');
    await importTemplates();

    console.log('');
    info('步骤 3/3: 创建索引...');
    await createIndex('Orders', 'order_id');
    await createIndex('Orders', 'user_id');
    await createIndex('Orders', 'status');
    await createIndex('Templates', 'template_id');
    await createIndex('UserProfile', 'user_id');
    await createIndex('PaymentRecord', 'order_id');
    await createIndex('Feedback', 'user_id');

    console.log('');
    ok('LeanCloud 初始化完成！');
    console.log('');
    info('接下来请登录 LeanCloud 控制台检查:');
    console.log('  1. 数据库 Class 是否已创建');
    console.log('  2. Templates 数据是否导入正确');
    console.log('  3. ACL 权限是否需要调整');
}

main().catch(e => {
    err(`未处理的错误: ${e.message}`);
    process.exit(1);
});
