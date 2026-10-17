const defaultOrigins = [
  "https://launchpad-mobile-prince.web.app",
  "http://localhost",
  "http://localhost:5000",
  "http://localhost:8080",
];

const allowedOrigins = () => new Set([
  ...defaultOrigins,
  ...(Deno.env.get("ALLOWED_WEB_ORIGINS") ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean),
]);

export function corsHeaders(request: Request): Record<string, string> | null {
  const origin = request.headers.get("Origin");
  if (origin && !allowedOrigins().has(origin)) return null;
  return {
    ...(origin ? { "Access-Control-Allow-Origin": origin } : {}),
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, DELETE, OPTIONS",
    "Vary": "Origin",
  };
}

type RpcClient = {
  rpc: (
    name: string,
    params: Record<string, unknown>,
  ) => Promise<{ data: unknown; error: { message?: string } | null }>;
};

export async function consumeRateLimit(
  admin: RpcClient,
  scope: string,
  actor: string,
  maxAttempts: number,
  windowSeconds: number,
) {
  const { data, error } = await admin.rpc("consume_api_rate_limit", {
    scope_name: scope,
    actor_key: actor,
    maximum_attempts: maxAttempts,
    window_seconds: windowSeconds,
  });
  if (error) throw new Error(error.message ?? "Rate limit check failed.");
  return data === true;
}
