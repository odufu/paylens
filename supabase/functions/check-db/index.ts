import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: profile } = await supabase
      .from("profiles")
      .select("*")
      .eq("id", "7f32c3a2-06cd-4eaf-99ee-8ebabbbdec66")
      .single();

    const { data: transactions } = await supabase
      .from("transactions")
      .select("*")
      .eq("profile_id", "7f32c3a2-06cd-4eaf-99ee-8ebabbbdec66")
      .order("created_at", { ascending: false })
      .limit(10);

    return new Response(
      JSON.stringify({
        profile,
        transactions,
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
