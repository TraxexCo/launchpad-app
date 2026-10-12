import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type NotificationRow = {
  id: number;
  user_id: string;
  title: string;
  body: string;
  route: string | null;
  kind: string | null;
};

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
  token_uri?: string;
};

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { "Content-Type": "application/json" },
});

const base64Url = (value: Uint8Array | string) => {
  const bytes = typeof value === "string" ? new TextEncoder().encode(value) : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
};

const privateKeyBytes = (pem: string) => {
  const body = pem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, "");
  return Uint8Array.from(atob(body), (character) => character.charCodeAt(0));
};

async function firebaseAccessToken(account: ServiceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const tokenUri = account.token_uri ?? "https://oauth2.googleapis.com/token";
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = base64Url(JSON.stringify({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: tokenUri,
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    privateKeyBytes(account.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const assertion = `${unsigned}.${base64Url(new Uint8Array(signature))}`;
  const response = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const payload = await response.json();
  if (!response.ok || !payload.access_token) {
    throw new Error(`Firebase OAuth failed (${response.status}).`);
  }
  return payload.access_token as string;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const webhookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET");
    const suppliedSecret = request.headers.get("x-launchpad-webhook-secret");
    if (!webhookSecret || suppliedSecret !== webhookSecret) {
      return json({ error: "Unauthorized" }, 401);
    }

    const payload = await request.json();
    const notificationId = Number(payload?.record?.id);
    if (payload?.type !== "INSERT" || !Number.isSafeInteger(notificationId)) {
      return json({ error: "Invalid notification webhook" }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: notification, error: notificationError } = await admin
      .from("notifications")
      .select("id,user_id,title,body,route,kind")
      .eq("id", notificationId)
      .single();
    if (notificationError || !notification) {
      return json({ error: "Notification not found" }, 404);
    }
    const row = notification as NotificationRow;

    const { data: tokenRows, error: tokenError } = await admin
      .from("device_push_tokens")
      .select("token")
      .eq("user_id", row.user_id)
      .eq("enabled", true);
    if (tokenError) throw tokenError;
    if (!tokenRows?.length) return json({ sent: 0, reason: "no_registered_devices" });

    const account = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ?? "") as ServiceAccount;
    if (!account.client_email || !account.private_key || !account.project_id) {
      throw new Error("Firebase service account is incomplete.");
    }
    const accessToken = await firebaseAccessToken(account);
    const invalidTokens: string[] = [];
    let sent = 0;

    for (const tokenRow of tokenRows) {
      const token = String(tokenRow.token);
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: row.title, body: row.body },
              data: {
                notification_id: String(row.id),
                route: row.route ?? "/notifications",
                kind: row.kind ?? "activity",
              },
              android: {
                priority: "high",
                notification: { channel_id: "launchpad_activity" },
              },
            },
          }),
        },
      );
      if (response.ok) {
        sent += 1;
        continue;
      }
      const errorBody = await response.text();
      if (response.status === 404 || errorBody.includes("UNREGISTERED")) {
        invalidTokens.push(token);
      } else {
        console.error(`FCM delivery failed (${response.status}): ${errorBody.slice(0, 500)}`);
      }
    }

    if (invalidTokens.length) {
      await admin.from("device_push_tokens").delete().in("token", invalidTokens);
    }
    return json({ sent, invalid_tokens_removed: invalidTokens.length });
  } catch (error) {
    console.error(error);
    return json({ error: error instanceof Error ? error.message : "Push delivery failed" }, 500);
  }
});
