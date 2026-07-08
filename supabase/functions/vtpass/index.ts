import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const VTPASS_API_KEY = Deno.env.get("VTPASS_API_KEY") || "";
const VTPASS_PUBLIC_KEY = Deno.env.get("VTPASS_PUBLIC_KEY") || "";
const VTPASS_SECRET_KEY = Deno.env.get("VTPASS_SECRET_KEY") || "";

// Toggle live vs sandbox URL dynamically based on environment
const VTPASS_ENV = Deno.env.get("VTPASS_ENVIRONMENT") || "sandbox";
const VTPASS_BASE_URL = VTPASS_ENV.toLowerCase() === "live"
  ? "https://api-service.vtpass.com/api"
  : "https://sandbox.vtpass.com/api";

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
      }
    });
  }

  try {
    const { endpoint, body, method = "POST" } = await req.json();

    if (!VTPASS_API_KEY || !VTPASS_PUBLIC_KEY || !VTPASS_SECRET_KEY) {
      throw new Error("VTPass credentials are not fully configured in Supabase environment secrets.");
    }

    const headers: Record<String, String> = {
      "api-key": VTPASS_API_KEY,
      "public-key": VTPASS_PUBLIC_KEY,
      "secret-key": VTPASS_SECRET_KEY,
      "Content-Type": "application/json",
    };

    const isGet = method.toUpperCase() === "GET";
    const requestUrl = `${VTPASS_BASE_URL}/${endpoint}`;

    const response = await fetch(requestUrl, {
      method: method.toUpperCase(),
      headers,
      body: isGet ? undefined : JSON.stringify(body),
    });

    const data = await response.json();

    return new Response(JSON.stringify(data), {
      status: response.status,
      headers: {
        "Content-Type": "application/json",
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }
});
