import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, "Content-Type": "application/json" },
});
type ContractRow = {
  id: number;
  business_id: string;
  student_id: string;
  agreed_budget: number | string;
  status: string;
  jobs: { title: string } | null;
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
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

    const { data: existing } = await admin
      .from("payments")
      .select("id,status,checkout_url,checkout_session_id,reference_number")
      .eq("contract_id", contractId)
      .maybeSingle();
    if (existing?.status === "paid" || existing?.status === "released") {
      return json({ payment: existing, already_paid: true });
    }
    if (existing?.status === "checkout_created" && existing.checkout_url) {
      return json({ payment: existing, checkout_url: existing.checkout_url });
    }

    const amountCentavos = Math.round(Number(contract.agreed_budget) * 100);
    if (!Number.isSafeInteger(amountCentavos) || amountCentavos < 100) {
      return json({ error: "The contract amount is invalid." }, 400);
    }
    const reference = existing?.reference_number ??
      `LP-${contractId}-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;
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
      const detail = providerBody?.errors?.[0]?.detail ?? "PayMongo could not create checkout.";
      return json({ error: detail }, paymongoResponse.status);
    }

    const session = providerBody.data;
    const checkoutUrl = session.attributes.checkout_url as string;
    const paymentValues = {
      contract_id: contractId,
      business_id: contract.business_id,
      student_id: contract.student_id,
      amount: Number(contract.agreed_budget),
      status: "checkout_created",
      checkout_session_id: session.id,
      checkout_url: checkoutUrl,
      reference_number: reference,
      updated_at: new Date().toISOString(),
    };
    const { data: payment, error: saveError } = await admin
      .from("payments")
      .upsert(paymentValues, { onConflict: "contract_id" })
      .select()
      .single();
    if (saveError) return json({ error: "Checkout opened but its record could not be saved." }, 500);
    return json({ payment, checkout_url: checkoutUrl });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "Unexpected payment error." }, 500);
  }
});
