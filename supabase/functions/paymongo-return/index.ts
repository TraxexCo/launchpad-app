const escapeHtml = (value: string) => value.replace(/[&<>'"]/g, (char) => ({
  "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;",
}[char]!));

Deno.serve((request) => {
  const url = new URL(request.url);
  const result = url.searchParams.get("result") === "success" ? "success" : "cancel";
  const contractId = url.searchParams.get("contract_id") ?? "0";
  const deepLink = `launchpad://payment-return/?result=${result}&contract_id=${encodeURIComponent(contractId)}`;
  const successful = result === "success";
  const html = `<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><title>LaunchPad Payment</title><style>body{margin:0;background:#070b14;color:#f8fafc;font-family:system-ui;display:grid;place-items:center;min-height:100vh}.card{max-width:420px;margin:24px;padding:32px;border:1px solid #6d5dfc66;border-radius:0 28px 0 28px;background:#101725;text-align:center}h1{font-size:24px}p{color:#9aa6bd;line-height:1.6}a{display:block;margin-top:24px;padding:14px;background:#6d5dfc;color:white;text-decoration:none;border-radius:12px;font-weight:700}.tag{color:${successful ? "#34d399" : "#fbbf24"};font:12px monospace;letter-spacing:1.5px}</style></head><body><main class="card"><div class="tag">${successful ? "CHECKOUT COMPLETE" : "CHECKOUT CANCELLED"}</div><h1>${successful ? "Return to LaunchPad" : "Payment was not completed"}</h1><p>${successful ? "LaunchPad will verify the transaction directly with PayMongo. No real money is used with test credentials." : "You can return to the project and restart the test checkout."}</p><a href="${escapeHtml(deepLink)}">Open LaunchPad</a></main><script>setTimeout(()=>location.href=${JSON.stringify(deepLink)},700)</script></body></html>`;
  return new Response(html, { headers: { "Content-Type": "text/html; charset=utf-8" } });
});
