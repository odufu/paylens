import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Fetch all pending settlement ledger entries
    const { data: pendingLedgers, error: fetchErr } = await supabase
      .from("settlement_ledger")
      .select("*, transactions(*)")
      .eq("reconciliation_status", "pending");

    if (fetchErr) {
      throw fetchErr;
    }

    const matchedIds: string[] = [];
    const discrepancyIds: string[] = [];

    // 2. Perform reconciliation checks
    for (const entry of pendingLedgers || []) {
      const tx = entry.transactions;
      if (!tx) {
        discrepancyIds.push(entry.id);
        continue;
      }

      // If it's a VTPass transaction, verify cost matches expected cost
      if (tx.provider === 'VTPass') {
        let discountRate = 0.03; // Default 3% discount
        if (tx.title.toLowerCase().includes('data')) {
          discountRate = 0.04;
        } else if (tx.title.toLowerCase().includes('electricity') || tx.title.toLowerCase().includes('cable')) {
          discountRate = 0.0;
        }

        const expectedCost = Math.abs(tx.amount) * (1.0 - discountRate);
        const variance = Math.abs(entry.vtpass_cost - expectedCost);
        
        // Allow up to ₦1 variance for rounding/decimal differences
        if (variance < 1.0) {
          matchedIds.push(entry.id);
        } else {
          discrepancyIds.push(entry.id);
        }
      } 
      // If it's a Paystack wallet funding transaction
      else if (tx.provider === 'Paystack') {
        const expectedSettlement = tx.amount * 0.985;
        const variance = Math.abs(entry.expected_paystack_settlement - expectedSettlement);

        if (variance < 1.0) {
          matchedIds.push(entry.id);
        } else {
          discrepancyIds.push(entry.id);
        }
      }
    }

    // 3. Bulk update statuses in database
    if (matchedIds.length > 0) {
      await supabase
        .from("settlement_ledger")
        .update({ reconciliation_status: "matched" })
        .in("id", matchedIds);
    }

    if (discrepancyIds.length > 0) {
      await supabase
        .from("settlement_ledger")
        .update({ reconciliation_status: "discrepancy" })
        .in("id", discrepancyIds);
    }

    return new Response(
      JSON.stringify({
        message: "Reconciliation completed",
        processedCount: pendingLedgers?.length || 0,
        matchedCount: matchedIds.length,
        discrepanciesCount: discrepancyIds.length,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
