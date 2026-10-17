import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { consumeRateLimit, corsHeaders } from "../_shared/security.ts";
Deno.serve(async (request) => {
  const cors = corsHeaders(request);
  const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
    status,
    headers: { ...(cors ?? {}), "Content-Type": "application/json" },
  });
  if (!cors) return json({ error: "Origin not allowed." }, 403);
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const paymongoKey = Deno.env.get("PAYMONGO_SECRET_KEY");
    if (!paymongoKey?.startsWith("sk_test_")) return json({ error: "PayMongo test key is not configured." }, 503);

    const authorization = request.headers.get("Authorization") ?? "";
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
    });
    const { data: authData, error: authError } = await userClient.auth.getUser();
    if (authError || !authData.user) return json({ error: "Sign in required." }, 401);
    const body = await request.json();
    const contractId = Number(body.contract_id);
    if (!Number.isInteger(contractId) || contractId <= 0) return json({ error: "A valid contract is required." }, 400);

    const admin = createClient(supabaseUrl, serviceKey);
    if (!(await consumeRateLimit(admin, "payment-sync", authData.user.id, 30, 60))) {
      return json({ error: "Too many status checks. Try again in a minute." }, 429);
    }
    const { data: payment, error: readError } = await admin
      .from("payments")
      .select("*")
      .eq("contract_id", contractId)
      .single();
    if (readError || !payment) return json({ error: "No checkout exists for this contract." }, 404);
    if (payment.business_id !== authData.user.id && payment.student_id !== authData.user.id) {
      return json({ error: "You are not part of this contract." }, 403);
    }
    if (["paid", "released", "refunded"].includes(payment.status)) return json({ payment });

    const providerResponse = await fetch(
      `https://api.paymongo.com/v1/checkout_sessions/${payment.checkout_session_id}`,
      { headers: { Authorization: `Basic ${btoa(`${paymongoKey}:`)}`, Accept: "application/json" } },
    );
    const providerBody = await providerResponse.json();
    if (!providerResponse.ok) {
      const detail = providerBody?.errors?.[0]?.detail ?? "PayMongo status could not be checked.";
      return json({ error: detail }, providerResponse.status);
    }

    const attributes = providerBody.data.attributes ?? {};
    const checkoutIntent = attributes.payment_intent ?? {};
    let intent = checkoutIntent.attributes ?? checkoutIntent;
    const intentId = checkoutIntent.id ?? intent.id;
    if (intentId && intent.status !== "succeeded" && !(intent.payments?.length > 0)) {
      const intentResponse = await fetch(
        `https://api.paymongo.com/v1/payment_intents/${intentId}`,
        { headers: { Authorization: `Basic ${btoa(`${paymongoKey}:`)}`, Accept: "application/json" } },
      );
      if (intentResponse.ok) {
        const intentBody = await intentResponse.json();
        intent = intentBody.data?.attributes ?? intent;
      }
    }
    const providerPayments = intent.payments ?? attributes.payments ?? [];
    const paidPayment = providerPayments.find((item: Record<string, unknown>) => {
      const itemAttributes = (item.attributes ?? item) as Record<string, unknown>;
      return itemAttributes.status === "paid";
    });
    const paid = intent.status === "succeeded" || attributes.status === "paid" || Boolean(paidPayment);
    const expired = attributes.status === "expired";
    const paidAttributes = (paidPayment?.attributes ?? paidPayment ?? {}) as Record<string, unknown>;
    const source = paidAttributes.source as Record<string, unknown> | undefined;
    const nextStatus = paid ? "paid" : expired ? "expired" : "checkout_created";
    const update: Record<string, unknown> = {
      status: nextStatus,
      updated_at: new Date().toISOString(),
    };
    if (paid) {
      update.paid_at = new Date().toISOString();
      update.provider_payment_id = paidPayment?.id ?? intent.id ?? null;
      update.payment_method = source?.type ?? attributes.payment_method_used ?? "paymongo";
    }
    const { data: updated, error: updateError } = await admin
      .from("payments")
      .update(update)
      .eq("id", payment.id)
      .select()
      .single();
    if (updateError) return json({ error: "Payment status could not be saved." }, 500);
    if (paid && payment.status !== "paid") {
      const { error: fundedError } = await admin.rpc("mark_contract_funded", { contract_key: contractId });
      if (fundedError) return json({ error: "Payment was confirmed but the contract could not be funded." }, 500);
      await admin.rpc("notify_payment_change", { payment_key: payment.id });
    }
    return json({ payment: updated });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "Unexpected payment error." }, 500);
  }
});
