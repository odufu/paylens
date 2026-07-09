import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const VTPASS_API_KEY = Deno.env.get("VTPASS_API_KEY") || "";
const VTPASS_PUBLIC_KEY = Deno.env.get("VTPASS_PUBLIC_KEY") || "";
const VTPASS_SECRET_KEY = Deno.env.get("VTPASS_SECRET_KEY") || "";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

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

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Check if this is a purchase transaction ('pay') to perform dynamic routing
    if (endpoint === 'pay' && body && body.serviceID) {
      const serviceID = body.serviceID.toString().toLowerCase();
      
      let serviceType = "Airtime";
      let networkProvider = "MTN";

      if (serviceID.includes("data") || serviceID.includes("direct") || serviceID.includes("spectranet")) {
        serviceType = "Data";
      } else if (serviceID.includes("dstv") || serviceID.includes("gotv") || serviceID.includes("startimes")) {
        serviceType = "Cable TV";
      } else if (serviceID.includes("electric")) {
        serviceType = "Electricity";
      }

      if (serviceID.includes("mtn")) networkProvider = "MTN";
      else if (serviceID.includes("airtel")) networkProvider = "Airtel";
      else if (serviceID.includes("glo")) networkProvider = "Glo";
      else if (serviceID.includes("etisalat")) networkProvider = "9mobile";
      else if (serviceID.includes("smile")) networkProvider = "Smile";
      else if (serviceID.includes("spectranet")) networkProvider = "Spectranet";

      // Query active vending route from database
      const { data: route } = await supabase
        .from('vending_routes')
        .select('active_gateway')
        .eq('service_type', serviceType)
        .eq('network_provider', networkProvider)
        .eq('is_active', true)
        .single();

      const gateway = route?.active_gateway ?? 'VTPass';

      // 2. Perform Routing
      if (gateway === 'ClubKonnect') {
        console.log(`Routing ${serviceType} purchase for ${networkProvider} to ClubKonnect.`);
        
        // Mocking ClubKonnect API call & standardizing the VTPass compatible success response format
        return new Response(JSON.stringify({
          code: "000",
          response_description: "TRANSACTION SUCCESSFUL",
          content: {
            transactions: {
              status: "delivered",
              transactionId: `CK-${body.request_id ?? Date.now()}`,
              token: "CK-MOCK-TOKEN-129384"
            }
          }
        }), {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
          },
        });
      } else if (gateway === 'MobiLilla') {
        console.log(`Routing ${serviceType} purchase for ${networkProvider} to MobiLilla.`);
        
        return new Response(JSON.stringify({
          code: "000",
          response_description: "TRANSACTION SUCCESSFUL",
          content: {
            transactions: {
              status: "delivered",
              transactionId: `ML-${body.request_id ?? Date.now()}`,
              token: "ML-MOCK-TOKEN-482019"
            }
          }
        }), {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
          },
        });
      }
      
      // Fallback/Default: route to VTPass
      console.log(`Routing ${serviceType} purchase for ${networkProvider} to VTPass.`);
    }

    if (!VTPASS_API_KEY || !VTPASS_PUBLIC_KEY || !VTPASS_SECRET_KEY) {
      throw new Error("VTPass credentials are not fully configured in Supabase environment secrets.");
    }

    const headers: Record<string, string> = {
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
