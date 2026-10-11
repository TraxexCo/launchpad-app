import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { ...cors, "Content-Type": "application/json" },
});

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (request.method !== "DELETE" && request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const url = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const authorization = request.headers.get("Authorization") ?? "";
  const userClient = createClient(url, anon, { global: { headers: { Authorization: authorization } } });
  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) return json({ error: "Sign in required." }, 401);
  const admin = createClient(url, service);
  const { error: deleteError } = await admin.auth.admin.deleteUser(data.user.id);
  if (deleteError) return json({ error: "Account could not be deleted." }, 500);
  return json({ deleted: true });
});
