import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { consumeRateLimit, corsHeaders } from "../_shared/security.ts";
type ContractRow = {
  id: number;
  business_id: string;
  student_id: string;
  agreed_budget: number | string;
  status: string;
  jobs: { title: string } | null;
};

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
    if (!paymongoKey?.startsWith("sk_test_")) {
      return json({ error: "PAYMONGO_SECRET_KEY must be a PayMongo test secret key." }, 503);
    }

    const authorization = request.headers.get("Authorization") ?? "";
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
    });
    const { data: authData, error: authError } = await userClient.auth.getUser();
    if (authError || !authData.user) return json({ error: "Sign in required." }, 401);

    const body = await request.json();
    const contractId = Number(body.contract_id);
    if (!Number.isInteger(contractId) || contractId <= 0) {
      return json({ error: "A valid contract is required." }, 400);
    }

    const admin = createClient(supabaseUrl, serviceKey);
    if (!(await consumeRateLimit(admin, "payment-create", authData.user.id, 8, 60))) {
      return json({ error: "Too many checkout attempts. Try again in a minute." }, 429);
    }
    const { data, error: contractError } = await admin
      .from("contracts")
      .select("id,business_id,student_id,agreed_budget,status,jobs(title)")
      .eq("id", contractId)
      .single();
    if (contractError || !data) return json({ error: "Contract not found." }, 404);
    const contract = data as unknown as ContractRow;
    if (contract.business_id !== authData.user.id) {
      return json({ error: "Only the hiring business can fund this project." }, 403);
    }
    if (contract.status === "completed") {
      return json({ error: "This contract is already complete." }, 409);
    }

    const amountCentavos = Math.round(Number(contract.agreed_budget) * 100);
    if (!Number.isSafeInteger(amountCentavos) || amountCentavos < 100) {
      return json({ error: "The contract amount is invalid." }, 400);
    }
    const proposedReference =
      `LP-${contractId}-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
    const { data: claimRows, error: claimError } = await admin.rpc(
      "claim_payment_checkout",
      {
        contract_key: contractId,
        business_key: contract.business_id,
        student_key: contract.student_id,
        amount_value: Number(contract.agreed_budget),
        reference_value: proposedReference,
      },
    );
    if (claimError) return json({ error: "Checkout could not be reserved." }, 500);
    const claim = Array.isArray(claimRows) ? claimRows[0] : claimRows;
    if (!claim?.claimed) {
      if (["paid", "released"].includes(claim?.payment_status)) {
        return json({ payment: claim, already_paid: true });
      }
      if (claim?.payment_status === "checkout_created" && claim.checkout_url) {
        return json({ payment: claim, checkout_url: claim.checkout_url });
      }
      return json({ error: "A checkout is already being created. Try again shortly." }, 409);
    }
    const paymentId = Number(claim.payment_id);
    const reference = String(claim.reference_number);
    const returnBase = `${supabaseUrl}/functions/v1/paymongo-return`;
    const title = contract.jobs?.title ?? `LaunchPad Project ${contractId}`;
    const paymongoResponse = await fetch("https://api.paymongo.com/v1/checkout_sessions", {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${paymongoKey}:`)}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        data: {
          attributes: {
            cancel_url: `${returnBase}?result=cancel&contract_id=${contractId}`,
            success_url: `${returnBase}?result=success&contract_id=${contractId}`,
            description: `LaunchPad classroom payment for ${title}`,
            reference_number: reference,
            send_email_receipt: false,
            show_description: true,
            show_line_items: true,
            payment_method_types: ["card", "gcash", "paymaya"],
            line_items: [{
              currency: "PHP",
              amount: amountCentavos,
              name: title.slice(0, 100),
              quantity: 1,
              description: "Accepted student project contract",
            }],
          },
        },
      }),
    });
    const providerBody = await paymongoResponse.json();
    if (!paymongoResponse.ok) {
      await admin.from("payments").update({
        status: "failed",
        updated_at: new Date().toISOString(),
      }).eq("id", paymentId);
      const detail = providerBody?.errors?.[0]?.detail ?? "PayMongo could not create checkout.";
      return json({ error: detail }, paymongoResponse.status);
    }

    const session = providerBody.data;
    const checkoutUrl = session.attributes.checkout_url as string;
    const paymentValues = {
      status: "checkout_created",
      checkout_session_id: session.id,
      checkout_url: checkoutUrl,
      updated_at: new Date().toISOString(),
    };
    const { data: payment, error: saveError } = await admin
      .from("payments")
      .update(paymentValues)
      .eq("id", paymentId)
      .eq("status", "creating")
      .select()
      .single();
    if (saveError) return json({ error: "Checkout opened but its record could not be saved." }, 500);
    return json({ payment, checkout_url: checkoutUrl });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "Unexpected payment error." }, 500);
  }
});
