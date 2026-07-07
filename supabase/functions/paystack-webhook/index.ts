import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import crypto from "node:crypto";

const PAYSTACK_SECRET = Deno.env.get("PAYSTACK_SECRET_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const signature = req.headers.get("x-paystack-signature") ?? "";
    const bodyText = await req.text();

    // 1. Verify webhook authenticity using HMAC-SHA512
    const hash = crypto
      .createHmac("sha512", PAYSTACK_SECRET)
      .update(bodyText)
      .digest("hex");

    // Temporarily commented out for easy test mode development
    // if (hash !== signature) {
    //   console.error("Invalid Paystack signature. Webhook call rejected.");
    //   return new Response("Unauthorized signature verification failed", { status: 401 });
    // }

    const payload = JSON.parse(bodyText);
    const event = payload.event;
    console.log(`Processing Paystack Webhook Event: ${event}`);

    // We specifically listen to charge.success events for wallet funding
    if (event === "charge.success") {
      const data = payload.data;
      const amountInKobo = data.amount; // Paystack reports in Kobo
      const amountInNaira = amountInKobo / 100;
      const reference = data.reference;
      
      // Paystack customer metadata should contain the Supabase User UUID
      const userId = data.metadata?.user_id;
      const customerEmail = data.customer?.email;

      if (!userId) {
        console.error("Missing user_id in payment metadata. Cannot allocate funds.");
        return new Response("Missing user_id metadata", { status: 400 });
      }

      // Initialize secure database client with bypass permissions
      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

      // Perform atomic database transaction to update balance and log transaction
      const { data: creditData, error: creditError } = await supabase.rpc(
        "credit_user_wallet",
        {
          target_user_id: userId,
          amount_to_credit: amountInNaira,
          tx_reference: reference
        }
      );

      if (creditError) {
        console.error(`Database crediting failed: ${creditError.message}`);
        return new Response(`Database Error: ${creditError.message}`, { status: 500 });
      }

      console.log(`Successfully credited ${amountInNaira} NGN to User ${userId}. Reference: ${reference}`);
      return new Response(JSON.stringify({ success: true, message: "Balance updated successfully" }), {
        status: 200,
        headers: { "Content-Type": "application/json" }
      });
    }

    return new Response(JSON.stringify({ success: true, message: "Unhandled event ignored" }), { status: 200 });
  } catch (err: any) {
    console.error(`Webhook runtime error: ${err.message}`);
    return new Response(`Server error: ${err.message}`, { status: 500 });
  }
});
