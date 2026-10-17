import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { consumeRateLimit, corsHeaders } from "../_shared/security.ts";

Deno.serve(async (request) => {
  const cors = corsHeaders(request);
  const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
    status, headers: { ...(cors ?? {}), "Content-Type": "application/json" },
  });
  if (!cors) return json({ error: "Origin not allowed." }, 403);
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
  if (!(await consumeRateLimit(admin, "account-delete", data.user.id, 3, 3600))) {
    return json({ error: "Too many deletion attempts. Try again later." }, 429);
  }

  const userId = data.user.id;
  const [{ data: profile }, { data: verificationRows }, { data: deliverableRows }] =
    await Promise.all([
      admin.from("profiles").select("avatar_path").eq("id", userId).maybeSingle(),
      admin.from("verification_documents").select("storage_path").eq("owner_id", userId),
      admin.from("contract_deliverables").select("storage_path").eq("submitted_by", userId),
    ]);

  const removals: Array<Promise<unknown>> = [];
  const { data: profileFiles, error: profileListError } = await admin.storage
    .from("profile-images")
    .list(userId, { limit: 1000 });
  if (profileListError) {
    return json({ error: "Profile uploads could not be inspected. The account was kept." }, 500);
  }
  const profilePaths = (profileFiles ?? [])
    .filter((file) => file.id)
    .map((file) => `${userId}/${file.name}`);
  const avatarPath = profile?.avatar_path?.toString();
  if (avatarPath && !profilePaths.includes(avatarPath)) profilePaths.push(avatarPath);
  if (profilePaths.length) {
    removals.push(admin.storage.from("profile-images").remove(profilePaths));
  }
  const verificationPaths = (verificationRows ?? [])
    .map((row) => row.storage_path?.toString())
    .filter((path): path is string => Boolean(path));
  if (verificationPaths.length) {
    removals.push(
      admin.storage.from("verification-documents").remove(verificationPaths),
    );
  }
  const deliverablePaths = (deliverableRows ?? [])
    .map((row) => row.storage_path?.toString())
    .filter((path): path is string => Boolean(path));
  if (deliverablePaths.length) {
    removals.push(
      admin.storage.from("contract-deliverables").remove(deliverablePaths),
    );
  }
  const { data: contractFolders, error: contractListError } = await admin.storage
    .from("contract-deliverables")
    .list("", { limit: 1000 });
  if (contractListError) {
    return json({ error: "Deliverable uploads could not be inspected. The account was kept." }, 500);
  }
  for (const folder of contractFolders ?? []) {
    if (folder.id || !/^\d+$/.test(folder.name)) continue;
    const prefix = `${folder.name}/${userId}`;
    const { data: files, error: listError } = await admin.storage
      .from("contract-deliverables")
      .list(prefix, { limit: 1000 });
    if (listError) {
      return json({ error: "Deliverable uploads could not be inspected. The account was kept." }, 500);
    }
    const orphanPaths = (files ?? [])
      .filter((file) => file.id)
      .map((file) => `${prefix}/${file.name}`)
      .filter((path) => !deliverablePaths.includes(path));
    if (orphanPaths.length) {
      removals.push(
        admin.storage.from("contract-deliverables").remove(orphanPaths),
      );
    }
  }
  const removalResults = await Promise.all(removals);
  const storageError = removalResults.find(
    (result) => typeof result === "object" && result !== null &&
      "error" in result && result.error,
  );
  if (storageError) {
    return json({ error: "Uploaded files could not be deleted. The account was kept." }, 500);
  }
  const { error: deleteError } = await admin.auth.admin.deleteUser(data.user.id);
  if (deleteError) return json({ error: "Account could not be deleted." }, 500);
  return json({ deleted: true });
});
