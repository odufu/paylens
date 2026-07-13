import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CLUBKONNECT_USER_ID = Deno.env.get("CLUBKONNECT_USER_ID") || "CK101283964";
const CLUBKONNECT_API_KEY = Deno.env.get("CLUBKONNECT_API_KEY") || "";

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

    console.log(`ClubKonnect Request - Endpoint: ${endpoint}, Method: ${method}`);

    // CORS Headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      'Content-Type': 'application/json',
    };

    // 1. Intercept service-variations to return ClubKonnect Data Catalog dynamically
    if (endpoint.includes('service-variations') && (endpoint.includes('data') || endpoint.includes('direct') || endpoint.includes('sme'))) {
      let ckNetworkKey = 'MTN';
      if (endpoint.includes('mtn')) ckNetworkKey = 'MTN';
      else if (endpoint.includes('glo')) ckNetworkKey = 'Glo';
      else if (endpoint.includes('etisalat') || endpoint.includes('9mobile')) ckNetworkKey = 'm_9mobile';
      else if (endpoint.includes('airtel')) ckNetworkKey = 'Airtel';

      const plansUrl = `https://www.nellobytesystems.com/APIDatabundlePlansV2.asp?UserID=${CLUBKONNECT_USER_ID}`;
      console.log(`Fetching ClubKonnect plans from: ${plansUrl}`);
      
      const ckRes = await fetch(plansUrl);
      if (!ckRes.ok) {
        throw new Error(`Failed to fetch plans from ClubKonnect: HTTP ${ckRes.status}`);
      }
      
      const ckData = await ckRes.json();
      const products = ckData.MOBILE_NETWORK?.[ckNetworkKey]?.[0]?.PRODUCT || [];
      
      const variations = products.map((p: any) => ({
        variation_code: p.PRODUCT_CODE,
        name: p.PRODUCT_NAME,
        variation_amount: p.PRODUCT_AMOUNT,
        fixedPrice: "Yes"
      }));

      return new Response(JSON.stringify({
        code: "000",
        response_description: "SUCCESSFUL",
        content: {
          ServiceName: `${ckNetworkKey} Data`,
          serviceID: ckNetworkKey.toLowerCase(),
          convinience_fee: "0 %",
          variations
        }
      }), {
        status: 200,
        headers: corsHeaders,
      });
    }

    // 2. Intercept balance queries to retrieve ClubKonnect User Wallet Balance
    if (endpoint === 'balance') {
      const balanceUrl = `https://www.nellobytesystems.com/APIGetWalletBalanceV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}`;
      console.log(`Checking ClubKonnect wallet balance`);
      
      const ckRes = await fetch(balanceUrl);
      const ckData = await ckRes.json();
      
      return new Response(JSON.stringify({
        code: "000",
        response_description: "SUCCESSFUL",
        content: {
          balance: parseFloat(ckData.wallet_balance || "0.00")
        }
      }), {
        status: 200,
        headers: corsHeaders,
      });
    }

    // 3. Intercept merchant validation ('merchant-verify') via ClubKonnect
    if (endpoint === 'merchant-verify' && body && body.serviceID) {
      const serviceID = body.serviceID.toString().toLowerCase();
      const billersCode = body.billersCode.toString().trim();

      let ckUrl = "";

      if (serviceID.includes("dstv") || serviceID.includes("gotv") || serviceID.includes("startimes")) {
        let ckNetwork = "01";
        if (serviceID.includes("dstv")) ckNetwork = "01";
        else if (serviceID.includes("gotv")) ckNetwork = "02";
        else if (serviceID.includes("startimes")) ckNetwork = "03";
        ckUrl = `https://www.nellobytesystems.com/APIVerifyCableTVV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&CableTV=${ckNetwork}&SmartCardNo=${billersCode}`;
      } else {
        // Electricity
        let ckNetwork = "01";
        if (serviceID.includes("ikeja")) ckNetwork = "01";
        else if (serviceID.includes("eko")) ckNetwork = "02";
        else if (serviceID.includes("abuja")) ckNetwork = "03";
        else if (serviceID.includes("kano")) ckNetwork = "04";
        else if (serviceID.includes("port-harcourt")) ckNetwork = "05";
        else if (serviceID.includes("jos")) ckNetwork = "06";
        else if (serviceID.includes("ibadan")) ckNetwork = "07";
        else if (serviceID.includes("kaduna")) ckNetwork = "08";
        else if (serviceID.includes("enugu")) ckNetwork = "09";
        else if (serviceID.includes("benin")) ckNetwork = "10";
        else if (serviceID.includes("yola")) ckNetwork = "11";
        else if (serviceID.includes("aba")) ckNetwork = "12";
        ckUrl = `https://www.nellobytesystems.com/APIVerifyElectricityV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&ElectricCompany=${ckNetwork}&MeterNo=${billersCode}`;
      }

      console.log(`Verifying merchant ID via ClubKonnect: ${ckUrl.replace(CLUBKONNECT_API_KEY, "HIDDEN_KEY")}`);
      const ckRes = await fetch(ckUrl);
      const ckData = await ckRes.json();

      const customerName = ckData.customername || ckData.CustomerName || "Verified Subscriber";

      if (ckData.status?.toString().toUpperCase() === "SUCCESS" || customerName) {
        return new Response(JSON.stringify({
          code: "000",
          response_description: "SUCCESSFUL",
          content: {
            Customer_Name: customerName,
            Customer_Address: ckData.address || "Verified Location",
            Current_Plan: ckData.current_plan || "Active Plan"
          }
        }), {
          status: 200,
          headers: corsHeaders,
        });
      }

      return new Response(JSON.stringify({
        code: "011",
        response_description: ckData.remark || "Validation failed."
      }), {
        status: 200,
        headers: corsHeaders,
      });
    }

    // 4. Process Purchase orders ('pay') via ClubKonnect
    if (endpoint === 'pay' && body && body.serviceID) {
      const serviceID = body.serviceID.toString().toLowerCase();
      
      let serviceType = "Airtime";
      if (serviceID.includes("data") || serviceID.includes("direct") || serviceID.includes("sme") || serviceID.includes("smile")) {
        serviceType = "Data";
      } else if (serviceID.includes("dstv") || serviceID.includes("gotv") || serviceID.includes("startimes")) {
        serviceType = "Cable TV";
      } else if (serviceID.includes("electric")) {
        serviceType = "Electricity";
      }

      // Map serviceID/disco/cable provider to ClubKonnect code format
      let ckNetwork = "01"; // MTN Default
      if (serviceType === 'Airtime' || serviceType === 'Data') {
        if (serviceID.includes("mtn")) ckNetwork = "01";
        else if (serviceID.includes("glo")) ckNetwork = "02";
        else if (serviceID.includes("etisalat") || serviceID.includes("9mobile")) ckNetwork = "03";
        else if (serviceID.includes("airtel")) ckNetwork = "04";
      } else if (serviceType === 'Cable TV') {
        if (serviceID.includes("dstv")) ckNetwork = "01";
        else if (serviceID.includes("gotv")) ckNetwork = "02";
        else if (serviceID.includes("startimes")) ckNetwork = "03";
      } else if (serviceType === 'Electricity') {
        if (serviceID.includes("ikeja")) ckNetwork = "01";
        else if (serviceID.includes("eko")) ckNetwork = "02";
        else if (serviceID.includes("abuja")) ckNetwork = "03";
        else if (serviceID.includes("kano")) ckNetwork = "04";
        else if (serviceID.includes("port-harcourt")) ckNetwork = "05";
        else if (serviceID.includes("jos")) ckNetwork = "06";
        else if (serviceID.includes("ibadan")) ckNetwork = "07";
        else if (serviceID.includes("kaduna")) ckNetwork = "08";
        else if (serviceID.includes("enugu")) ckNetwork = "09";
        else if (serviceID.includes("benin")) ckNetwork = "10";
        else if (serviceID.includes("yola")) ckNetwork = "11";
        else if (serviceID.includes("aba")) ckNetwork = "12";
      }

      let ckUrl = "";
      const requestId = body.request_id || `CK-${Date.now()}`;

      if (serviceType === 'Airtime') {
        ckUrl = `https://www.nellobytesystems.com/APIAirtimeV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&MobileNetwork=${ckNetwork}&Amount=${body.amount}&MobileNo=${body.billersCode}&RequestID=${requestId}`;
      } else if (serviceType === 'Data') {
        ckUrl = `https://www.nellobytesystems.com/APIDatabundleV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&MobileNetwork=${ckNetwork}&DataPlan=${body.variation_code}&MobileNo=${body.billersCode}&RequestID=${requestId}`;
      } else if (serviceType === 'Cable TV') {
        ckUrl = `https://www.nellobytesystems.com/APICableTVV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&CableTV=${ckNetwork}&Package=${body.variation_code}&SmartCardNo=${body.billersCode}&MobileNo=${body.phone || body.billersCode}&RequestID=${requestId}`;
      } else if (serviceType === 'Electricity') {
        ckUrl = `https://www.nellobytesystems.com/APIElectricityV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&ElectricCompany=${ckNetwork}&MeterNo=${body.billersCode}&Amount=${body.amount}&MobileNo=${body.phone || body.billersCode}&RequestID=${requestId}`;
      }

      console.log(`Submitting purchase to ClubKonnect: ${ckUrl.replace(CLUBKONNECT_API_KEY, "HIDDEN_KEY")}`);
      
      const ckRes = await fetch(ckUrl);
      if (!ckRes.ok) {
        throw new Error(`ClubKonnect returned HTTP status ${ckRes.status}`);
      }
      
      const ckData = await ckRes.json();
      console.log(`ClubKonnect Purchase Response:`, ckData);

      const status = ckData.status?.toString().toUpperCase();
      const statusCode = parseInt(ckData.statusCode?.toString() || "400");
      const orderId = ckData.orderId || ckData.orderID || ckData.OrderID || `CK-${Date.now()}`;

      // A: Success check
      if (statusCode === 200 || status === "ORDER_COMPLETED" || status === "SUCCESS") {
        return new Response(JSON.stringify({
          code: "000",
          response_description: ckData.description || "TRANSACTION SUCCESSFUL",
          content: {
            transactions: {
              status: "delivered",
              transactionId: orderId
            }
          }
        }), {
          status: 200,
          headers: corsHeaders,
        });
      }
      
      // B: Pending check
      if (statusCode === 201 || statusCode === 100 || statusCode === 300 || status === "ORDER_RECEIVED" || status === "ORDER_PROCESSED") {
        return new Response(JSON.stringify({
          code: "099",
          response_description: ckData.description || "TRANSACTION PENDING",
          content: {
            transactions: {
              status: "pending",
              transactionId: orderId
            }
          }
        }), {
          status: 200,
          headers: corsHeaders,
        });
      }

      // C: Failed check
      return new Response(JSON.stringify({
        code: ckData.statusCode?.toString() || "011",
        response_description: ckData.description || ckData.remark || "Transaction failed.",
        content: {
          transactions: {
            status: "failed"
          }
        }
      }), {
        status: 200,
        headers: corsHeaders,
      });
    }

    // Default error response for unsupported endpoints
    throw new Error(`Unsupported API endpoint routing: ${endpoint}`);
  } catch (error: any) {
    console.error(`Edge Function Exception:`, error);
    return new Response(JSON.stringify({ 
      code: "500",
      response_description: error.message,
      error: error.message 
    }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }
});
