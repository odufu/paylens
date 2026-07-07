// Supabase serverless function proxying VTPass billing operations

const VTPASS_API_KEY = Deno.env.get("VTPASS_API_KEY") || "";
const VTPASS_PUBLIC_KEY = Deno.env.get("VTPASS_PUBLIC_KEY") || "";
const VTPASS_SECRET_KEY = Deno.env.get("VTPASS_SECRET_KEY") || "";
const VTPASS_BASE_URL = "https://sandbox.vtpass.com/api";

Deno.serve(async (req) => {
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
    const { endpoint, body } = await req.json();

    if (!VTPASS_API_KEY || !VTPASS_PUBLIC_KEY || !VTPASS_SECRET_KEY) {
      throw new Error("VTPass credentials are not fully configured in Supabase environment secrets.");
    }

    const headers = {
      "api-key": VTPASS_API_KEY,
      "public-key": VTPASS_PUBLIC_KEY,
      "secret-key": VTPASS_SECRET_KEY,
      "Content-Type": "application/json",
    };

    const response = await fetch(`${VTPASS_BASE_URL}/${endpoint}`, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
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
  } catch (error) {
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
