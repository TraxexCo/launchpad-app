# PayMongo test functions

Set the Supabase Edge Function secret `PAYMONGO_SECRET_KEY=sk_test_...`.
The hosted project already has all three functions deployed. Keep
`create-paymongo-checkout` and `sync-paymongo-payment` protected by JWT and make
`paymongo-return` public because it is the browser redirect endpoint.

For a new Supabase project, deploy them with:

```powershell
supabase functions deploy create-paymongo-checkout
supabase functions deploy sync-paymongo-payment
supabase functions deploy paymongo-return --no-verify-jwt
```

The app creates a hosted Checkout Session and retrieves its state directly from
PayMongo after the user returns. This is a real API test-mode integration and
does not charge real money.
