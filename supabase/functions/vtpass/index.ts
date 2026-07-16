import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CLUBKONNECT_USER_ID = Deno.env.get("CLUBKONNECT_USER_ID") || "CK101283964";
const CLUBKONNECT_API_KEY = Deno.env.get("CLUBKONNECT_API_KEY") || "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

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

  // CORS Headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Content-Type': 'application/json',
  };

  try {
    // Check if request is a GET (ClubKonnect Callback)
    if (req.method === 'GET') {
      const url = new URL(req.url);
      const orderId = url.searchParams.get('orderid');
      const statusCode = url.searchParams.get('statuscode');
      const orderStatus = url.searchParams.get('orderstatus');
      const orderRemark = url.searchParams.get('orderremark');

      console.log(`ClubKonnect Callback Received: Method=GET, URL=${req.url}`);

      if (orderId) {
        console.log(`Processing callback for orderId=${orderId}, statuscode=${statusCode}, status=${orderStatus}`);
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
        
        // 1. Fetch matching transaction by vendor_reference
        const { data: tx, error: fetchErr } = await supabase
          .from('transactions')
          .select('id, profile_id, title, amount')
          .eq('vendor_reference', orderId)
          .maybeSingle();

        if (fetchErr) {
          console.error(`Database error fetching transaction:`, fetchErr);
        } else if (tx) {
          const isSuccess = statusCode === '200' || orderStatus === 'ORDER_COMPLETED';
          const finalStatus = isSuccess ? 'success' : 'failed';
          const normalizedRemark = orderRemark ? decodeURIComponent(orderRemark) : '';
          
          // 2. Update transaction status and subtitle
          const { error: updateErr } = await supabase
            .from('transactions')
            .update({
              status: finalStatus,
              subtitle: normalizedRemark || (isSuccess ? 'Transaction completed successfully.' : 'Transaction failed.'),
            })
            .eq('id', tx.id);
            
          if (updateErr) {
            console.error(`Failed to update transaction ${tx.id}:`, updateErr);
          } else {
            console.log(`Successfully updated transaction ${tx.id} to ${finalStatus}`);
          }

          // 3. Update associated support ticket if any
          const { error: ticketErr } = await supabase
            .from('support_tickets')
            .update({
              status: isSuccess ? 'resolved' : 'escalated',
              description: `Auto-updated by ClubKonnect callback. Status: ${orderStatus}. Remark: ${normalizedRemark}`,
            })
            .eq('transaction_id', tx.id);
            
          if (ticketErr) {
            console.error(`Failed to update support ticket for transaction ${tx.id}:`, ticketErr);
          }

          // 4. Send notification to user
          try {
            await supabase.from('notifications').insert({
              profile_id: tx.profile_id,
              title: isSuccess ? 'Payment Successful' : 'Payment Failed',
              body: `Your payment of ₦${Math.abs(tx.amount)} for ${tx.title} was ${finalStatus}. ${normalizedRemark}`,
              category: 'transactions',
              is_read: false
            });
            console.log(`Sent status notification to profile ${tx.profile_id}`);
          } catch (notifErr) {
            console.error(`Failed to insert notification:`, notifErr);
          }
        } else {
          console.warn(`No transaction found matching vendor_reference=${orderId}`);
        }
      }

      return new Response(JSON.stringify({ status: "acknowledged" }), {
        status: 200,
        headers: corsHeaders,
      });
    }

    // Otherwise, parse POST body
    const { endpoint, body, method = "POST" } = await req.json();

    console.log(`ClubKonnect Request - Endpoint: ${endpoint}, Method: ${method}`);

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
        variation_code: p.PRODUCT_ID,
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
      } else if (
        serviceID.includes("nairabet") || serviceID.includes("bangbet") || 
        serviceID.includes("betway") || serviceID.includes("betland") || 
        serviceID.includes("betking") || serviceID.includes("1xbet") || 
        serviceID.includes("naijabet") || serviceID.includes("sportybet") || 
        serviceID.includes("merrybet")
      ) {
        let ckBettingCompany = "product-nairabet";
        if (serviceID.includes("nairabet")) ckBettingCompany = "product-nairabet";
        else if (serviceID.includes("bangbet") || serviceID.includes("bang-bet")) ckBettingCompany = "product-bang-bet";
        else if (serviceID.includes("betway") || serviceID.includes("bet-way")) ckBettingCompany = "product-bet-way";
        else if (serviceID.includes("betland") || serviceID.includes("bet-land")) ckBettingCompany = "product-bet-land";
        else if (serviceID.includes("betking") || serviceID.includes("bet-king")) ckBettingCompany = "product-bet-king";
        else if (serviceID.includes("1xbet") || serviceID.includes("1x-bet")) ckBettingCompany = "product-1x-bet";
        else if (serviceID.includes("naijabet") || serviceID.includes("naija-bet")) ckBettingCompany = "product-naija-bet";
        else if (serviceID.includes("sportybet") || serviceID.includes("sporty-bet")) ckBettingCompany = "prd-sporty-bet";
        else if (serviceID.includes("merrybet") || serviceID.includes("merry-bet")) ckBettingCompany = "product-merry-bet";
        ckUrl = `https://www.nellobytesystems.com/APIVerifyBettingV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&BettingCompany=${ckBettingCompany}&CustomerID=${billersCode}`;
      } else if (serviceID.includes("jamb")) {
        ckUrl = `https://www.nellobytesystems.com/APIVerifyJAMBV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&ExamType=jamb&ProfileID=${billersCode}`;
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
        
        const meterType = (body.type?.toString().toLowerCase() === "postpaid") ? "02" : "01";
        ckUrl = `https://www.nellobytesystems.com/APIVerifyElectricityV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&ElectricCompany=${ckNetwork}&MeterNo=${billersCode}&MeterType=${meterType}`;
      }

      console.log(`Verifying merchant ID via ClubKonnect: ${ckUrl.replace(CLUBKONNECT_API_KEY, "HIDDEN_KEY")}`);
      const ckRes = await fetch(ckUrl);
      const ckData = await ckRes.json();

      const customerName = ckData.customername || ckData.CustomerName || ckData.customer_name || "Verified Subscriber";
      const isInvalid = customerName.toLowerCase().includes("error") || customerName.toLowerCase().includes("invalid");

      if ((ckData.status?.toString().toUpperCase() === "SUCCESS" || customerName) && !isInvalid) {
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
      } else if (
        serviceID.includes("nairabet") || serviceID.includes("bangbet") || 
        serviceID.includes("betway") || serviceID.includes("betland") || 
        serviceID.includes("betking") || serviceID.includes("1xbet") || 
        serviceID.includes("naijabet") || serviceID.includes("sportybet") || 
        serviceID.includes("merrybet")
      ) {
        serviceType = "Betting";
      } else if (serviceID.includes("waec")) {
        serviceType = "WAEC";
      } else if (serviceID.includes("jamb")) {
        serviceType = "JAMB";
      }

      // Map serviceID/disco/cable provider to ClubKonnect code format
      let ckNetwork = "01"; // MTN Default
      let ckBettingCompany = "product-nairabet";

      if (serviceType === 'Betting') {
        if (serviceID.includes("nairabet")) ckBettingCompany = "product-nairabet";
        else if (serviceID.includes("bangbet") || serviceID.includes("bang-bet")) ckBettingCompany = "product-bang-bet";
        else if (serviceID.includes("betway") || serviceID.includes("bet-way")) ckBettingCompany = "product-bet-way";
        else if (serviceID.includes("betland") || serviceID.includes("bet-land")) ckBettingCompany = "product-bet-land";
        else if (serviceID.includes("betking") || serviceID.includes("bet-king")) ckBettingCompany = "product-bet-king";
        else if (serviceID.includes("1xbet") || serviceID.includes("1x-bet")) ckBettingCompany = "product-1x-bet";
        else if (serviceID.includes("naijabet") || serviceID.includes("naija-bet")) ckBettingCompany = "product-naija-bet";
        else if (serviceID.includes("sportybet") || serviceID.includes("sporty-bet")) ckBettingCompany = "prd-sporty-bet";
        else if (serviceID.includes("merrybet") || serviceID.includes("merry-bet")) ckBettingCompany = "product-merry-bet";
      }

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
      const CALLBACK_URL = "https://vacyxnehxpqvwtaimkgc.supabase.co/functions/v1/vtpass";
      const encodedCallback = encodeURIComponent(CALLBACK_URL);

      if (serviceType === 'Airtime') {
        ckUrl = `https://www.nellobytesystems.com/APIAirtimeV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&MobileNetwork=${ckNetwork}&Amount=${body.amount}&MobileNumber=${body.billersCode}&RequestID=${requestId}&CallBackURL=${encodedCallback}`;
      } else if (serviceType === 'Data') {
        ckUrl = `https://www.nellobytesystems.com/APIDatabundleV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&MobileNetwork=${ckNetwork}&DataPlan=${body.variation_code}&MobileNumber=${body.billersCode}&RequestID=${requestId}&CallBackURL=${encodedCallback}`;
      } else if (serviceType === 'Cable TV') {
        ckUrl = `https://www.nellobytesystems.com/APICableTVV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&CableTV=${ckNetwork}&Package=${body.variation_code}&SmartCardNo=${body.billersCode}&PhoneNo=${body.phone || body.billersCode}&RequestID=${requestId}&CallBackURL=${encodedCallback}`;
      } else if (serviceType === 'Electricity') {
        const meterType = (body.variation_code === 'postpaid' || body.type === 'postpaid') ? '02' : '01';
        ckUrl = `https://www.nellobytesystems.com/APIElectricityV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&ElectricCompany=${ckNetwork}&MeterType=${meterType}&MeterNo=${body.billersCode}&Amount=${body.amount}&PhoneNo=${body.phone || body.billersCode}&RequestID=${requestId}&CallBackURL=${encodedCallback}`;
      } else if (serviceType === 'Betting') {
        ckUrl = `https://www.nellobytesystems.com/APIBettingV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&BettingCompany=${ckBettingCompany}&CustomerID=${body.billersCode}&Amount=${body.amount}&RequestID=${requestId}&CallBackURL=${encodedCallback}`;
      } else if (serviceType === 'WAEC') {
        ckUrl = `https://www.nellobytesystems.com/APIWAECV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&ExamType=${body.variation_code}&PhoneNo=${body.phone || body.billersCode}&RequestID=${requestId}&CallBackURL=${encodedCallback}`;
      } else if (serviceType === 'JAMB') {
        ckUrl = `https://www.nellobytesystems.com/APIJAMBV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&ExamType=${body.variation_code}&PhoneNo=${body.phone || body.billersCode}&RequestID=${requestId}&CallBackURL=${encodedCallback}`;
      }

      console.log(`Submitting purchase to ClubKonnect: ${ckUrl.replace(CLUBKONNECT_API_KEY, "HIDDEN_KEY")}`);
      
      const ckRes = await fetch(ckUrl);
      if (!ckRes.ok) {
        throw new Error(`ClubKonnect returned HTTP status ${ckRes.status}`);
      }
      
      const ckData = await ckRes.json();
      console.log(`ClubKonnect Purchase Response:`, JSON.stringify(ckData));

      // ClubKonnect uses 'status' for initial response, 'orderstatus' for callbacks/queries
      // statuscode is always lowercase in their API
      const status = (ckData.orderstatus || ckData.status)?.toString().toUpperCase();
      const rawStatusCode = ckData.statuscode ?? ckData.statusCode ?? ckData.StatusCode;
      const statusCode = rawStatusCode != null ? parseInt(rawStatusCode.toString()) : null;
      const orderId = ckData.orderid || ckData.orderId || ckData.orderID || ckData.OrderID || `CK-${Date.now()}`;
      const responseRemark = ckData.orderremark || ckData.remark || ckData.description || '';

      console.log(`Parsed purchase: status=${status}, statusCode=${statusCode}, orderId=${orderId}`);

      // A: Success check — statuscode 200 OR explicit ORDER_COMPLETED
      if (statusCode === 200 || status === "ORDER_COMPLETED" || status === "SUCCESS") {
        return new Response(JSON.stringify({
          code: "000",
          response_description: responseRemark || "TRANSACTION SUCCESSFUL",
          content: {
            transactions: {
              status: "delivered",
              transactionId: orderId,
              carddetails: ckData.carddetails || ckData.cards || null,
              token: ckData.metertoken || ckData.token || null
            }
          }
        }), {
          status: 200,
          headers: corsHeaders,
        });
      }
      
      // B: Explicit failure — ORDER_FAILED, ORDER_CANCELLED, or known error statuses
      const isExplicitFail = status === "ORDER_FAILED" || status === "ORDER_CANCELLED"
        || status === "INVALID_CREDENTIALS" || status === "MISSING_CREDENTIALS"
        || status === "INVALID_RECIPIENT" || status === "INVALID_AMOUNT"
        || status === "INVALID_CUSTOMERID" || status === "INVALID_METERNO"
        || status === "INVALID_SMARTCARDNO" || status === "INVALID_DATAPLAN"
        || (statusCode !== null && statusCode >= 400);

      if (isExplicitFail) {
        return new Response(JSON.stringify({
          code: rawStatusCode?.toString() || status || "011",
          response_description: responseRemark || status || "Transaction failed.",
          content: {
            transactions: {
              status: "failed",
              transactionId: orderId
            }
          }
        }), {
          status: 200,
          headers: corsHeaders,
        });
      }

      // C: Everything else is PENDING (ORDER_RECEIVED, ORDER_PROCESSED, ORDER_ONHOLD, unknown)
      // This is the safe default — we wait for the callback to confirm final status
      return new Response(JSON.stringify({
        code: "099",
        response_description: responseRemark || "TRANSACTION PENDING — Waiting for operator confirmation.",
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

    // 5a. Admin: Direct-patch a stuck pending transaction by DB id or vendor_reference
    if (endpoint === 'patch-transaction' && body) {
      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
      const { transaction_id, vendor_reference, status, subtitle, new_vendor_reference } = body;
      
      if (!transaction_id && !vendor_reference) {
        return new Response(JSON.stringify({ error: 'Either transaction_id or vendor_reference is required' }), {
          status: 400,
          headers: corsHeaders,
        });
      }

      const updateData: Record<string, any> = {};
      if (status) updateData.status = status;
      if (subtitle) updateData.subtitle = subtitle;
      if (new_vendor_reference) {
        updateData.vendor_reference = new_vendor_reference;
      } else if (transaction_id && vendor_reference) {
        // If updating by ID, they might want to set/update vendor_reference
        updateData.vendor_reference = vendor_reference;
      }

      let query = supabase.from('transactions').update(updateData);
      
      if (transaction_id) {
        query = query.eq('id', transaction_id);
      } else {
        query = query.eq('vendor_reference', vendor_reference);
      }
      
      const { data: updatedRows, error: patchErr } = await query.select('id, profile_id, title, amount, status, vendor_reference');
      
      if (patchErr) {
        console.error('Patch transaction error:', patchErr);
        return new Response(JSON.stringify({ error: patchErr.message }), { status: 500, headers: corsHeaders });
      }
      
      console.log(`Patched transaction(s):`, JSON.stringify(updatedRows));
      return new Response(JSON.stringify({ success: true, updated: updatedRows }), {
        status: 200,
        headers: corsHeaders,
      });
    }



    // 5. Requery transaction status ('requery') via ClubKonnect

    if (endpoint === 'requery' && body && body.vendor_reference) {
      const vendorReference = body.vendor_reference.toString();
      const queryUrl = `https://www.nellobytesystems.com/APIQueryV1.asp?UserID=${CLUBKONNECT_USER_ID}&APIKey=${CLUBKONNECT_API_KEY}&OrderID=${vendorReference}`;
      console.log(`Requerying transaction status for: ${vendorReference}`);
      
      const qRes = await fetch(queryUrl);
      if (!qRes.ok) {
        throw new Error(`ClubKonnect status query returned HTTP status ${qRes.status}`);
      }
      
      const qData = await qRes.json();
      console.log(`ClubKonnect Query Response:`, JSON.stringify(qData));
      
      // ClubKonnect Query API returns 'orderstatus' (not 'status') and lowercase 'statuscode'
      const status = (qData.orderstatus || qData.status)?.toString().toUpperCase();
      const rawStatusCode = qData.statuscode ?? qData.statusCode ?? qData.StatusCode;
      const statusCode = rawStatusCode != null ? parseInt(rawStatusCode.toString()) : null;
      const remark = qData.orderremark || qData.remark || qData.description || "Transaction status query completed.";

      // Success: ORDER_COMPLETED or statuscode 200
      const isSuccess = status === "ORDER_COMPLETED" || statusCode === 200;
      // Explicit failure: ORDER_FAILED, ORDER_CANCELLED, or statuscode >= 400
      const isFailed = status === "ORDER_FAILED" || status === "ORDER_CANCELLED"
        || (statusCode !== null && statusCode >= 400);
      
      // Default: if neither success nor explicit failure, stay PENDING
      // This prevents incorrectly marking successful transactions as failed
      let finalStatus = "pending";
      if (isSuccess) finalStatus = "success";
      else if (isFailed) finalStatus = "failed";
      
      console.log(`Parsed requery: status=${status}, statusCode=${statusCode}, finalStatus=${finalStatus}, remark=${remark}`);
      
      if (finalStatus !== "pending") {
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
        
        // Update transaction table - first try by vendor_reference
        let { data: tx, error: updateErr } = await supabase
          .from('transactions')
          .update({
            status: finalStatus,
            subtitle: remark,
            vendor_reference: vendorReference, // Ensure vendor_reference is always set
          })
          .eq('vendor_reference', vendorReference)
          .select('id, profile_id, title, amount')
          .maybeSingle();
          
        if (updateErr) {
          console.error(`Requery database update failed:`, updateErr);
        }
        
        // If no row was updated (vendor_reference was null), also try updating subtitles with matching pending transactions
        if (!tx) {
          console.warn(`No transaction found with vendor_reference=${vendorReference}. Trying to find by pending status and orderid from ClubKonnect...`);
          // Try to find and fix the transaction that has this vendor reference but stored as null
          // ClubKonnect orderId may be in the subtitle or we can match by the ClubKonnect orderid
          const ckOrderId = qData.orderid || qData.OrderID || qData.orderID;
          if (ckOrderId) {
            const { data: txByRef, error: fixErr } = await supabase
              .from('transactions')
              .update({
                status: finalStatus,
                subtitle: remark,
                vendor_reference: vendorReference,
              })
              .eq('vendor_reference', ckOrderId)
              .select('id, profile_id, title, amount')
              .maybeSingle();
              
            if (!fixErr && txByRef) {
              tx = txByRef;
              console.log(`Fixed transaction ${tx.id} using ckOrderId=${ckOrderId}`);
            }
          }
        }


        if (tx) {
          // Update support ticket
          await supabase
            .from('support_tickets')
            .update({
              status: isSuccess ? 'resolved' : 'escalated',
              description: `Auto-updated by manual requery. Status: ${status}. Remark: ${remark}`,
            })
            .eq('transaction_id', tx.id);
            
          // Add notification
          try {
            await supabase.from('notifications').insert({
              profile_id: tx.profile_id,
              title: isSuccess ? 'Payment Successful' : 'Payment Failed',
              body: `Your payment of ₦${Math.abs(tx.amount)} for ${tx.title} was ${finalStatus}. ${remark}`,
              category: 'transactions',
              is_read: false
            });
            console.log(`Sent notification for manually request-queried transaction: ${tx.id}`);
          } catch (e) {
            console.error('Failed to insert notification:', e);
          }
        }
      }
      
      return new Response(JSON.stringify({
        status: finalStatus,
        remark: remark
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
