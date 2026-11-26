const json = (data, status = 200) => new Response(JSON.stringify(data), {
  status,
  headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" }
});

async function ensureTable(db) {
  await db.prepare(`
    CREATE TABLE IF NOT EXISTS global_messages (
      id TEXT PRIMARY KEY,
      message TEXT NOT NULL,
      created_at TEXT NOT NULL,
      active INTEGER NOT NULL DEFAULT 1
    )
  `).run();
}

function sameOrigin(request) {
  const origin = request.headers.get("Origin");
  return !!origin && origin === new URL(request.url).origin;
}

function isOwner(request, env) {
  const expected = env.FD_GLOBAL_ADMIN_TOKEN;
  const supplied = request.headers.get("Authorization") || "";
  return typeof expected === "string" && expected.length >= 8 &&
    supplied === `Bearer ${expected}`;
}

export async function onRequest(context) {
  const { request, env } = context;
  if (!env.DB) return json({ error: "D1 binding DB is missing." }, 500);

  try {
    await ensureTable(env.DB);

    if (request.method === "GET") {
      const result = await env.DB.prepare(
        "SELECT id, message, created_at FROM global_messages WHERE active = 1 ORDER BY created_at DESC LIMIT 20"
      ).all();
      return json({ messages: result.results || [] });
    }

    if (request.method !== "POST" && request.method !== "DELETE") {
      return json({ error: "Method not allowed." }, 405);
    }

    if (!sameOrigin(request)) {
      return json({ error: "Requests must come from the game website." }, 403);
    }

    if (!env.FD_GLOBAL_ADMIN_TOKEN || String(env.FD_GLOBAL_ADMIN_TOKEN).length < 8) {
      return json({ error: "Owner announcement security is not configured yet. Set the FD_GLOBAL_ADMIN_TOKEN secret in Cloudflare Pages." }, 503);
    }
    if (!isOwner(request, env)) {
      return json({ error: "Owner authorization required. Set your announcement key once in this browser." }, 401);
    }

    if (request.method === "POST") {
      const body = await request.json();
      const message = typeof body.message === "string" ? body.message.trim() : "";
      if (!message) return json({ error: "Write a message first." }, 400);
      if (message.length > 500) return json({ error: "Messages must be 500 characters or fewer." }, 400);

      const id = crypto.randomUUID();
      const createdAt = new Date().toISOString();
      await env.DB.prepare(
        "INSERT INTO global_messages (id, message, created_at, active) VALUES (?, ?, ?, 1)"
      ).bind(id, message, createdAt).run();
      return json({ ok: true, id, message, created_at: createdAt }, 201);
    }

    const body = await request.json();
    const id = typeof body.id === "string" ? body.id : "";
    if (!id) return json({ error: "Message ID is missing." }, 400);
    await env.DB.prepare("DELETE FROM global_messages WHERE id = ?").bind(id).run();
    return json({ ok: true });
  } catch (error) {
    return json({ error: "Global messages service failed.", detail: String(error?.message || error) }, 500);
  }
}
