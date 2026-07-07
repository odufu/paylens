// Supabase serverless function for Pay Lenses chatbot

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") || "";

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
    const { message, history } = await req.json();

    if (!GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY environment variable is not configured in Supabase.");
    }

    const systemInstruction = `You are "Pay Lenses Customer Care", a professional, helpful, and friendly AI support assistant for Pay Lenses (a fintech bill-payment and wallet application).

Here is context about Pay Lenses to help you answer questions:
- **Wallet Funding**: Users fund their wallets via Monnify, which generates dedicated virtual bank accounts (e.g. Wema Bank account numbers) unique to each user. Deposits are settled instantly to the user's wallet.
- **Transfers**: Users can transfer funds to other bank accounts using their wallet balance.
- **Utilities**: Airtime and internet data top-ups (MTN, Airtel, Glo, 9mobile), electricity bills, and Cable TV packages (DSTV, GOtv, StarTimes) are handled securely via our partner VTPass.
- **Support Escalations**: If a user reports a failed transaction or wants to lodge a complaint, guide them to click "Report Technical Issue" or select one of the support options from the menu to automatically generate an engineering ticket.

Behavior Guidelines:
1. Keep your answers clear, helpful, and relatively concise (usually 1-3 sentences).
2. Do not mention internal tech details like APIs, URLs, or code structures. Speak representing Pay Lenses.
3. If a question is entirely unrelated to finance, wallet transactions, utilities, or Pay Lenses customer support, politely redirect the user back to the support menu.`;

    // Map history to the format expected by the Gemini REST API
    const contents = history.map((msg: any) => {
      return {
        role: msg.role === 'user' ? 'user' : 'model',
        parts: [{ text: msg.text }]
      };
    });

    // Append the latest user message
    contents.push({
      role: 'user',
      parts: [{ text: message }]
    });

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: contents,
          systemInstruction: {
            parts: [{ text: systemInstruction }]
          }
        }),
      }
    );

    if (!response.ok) {
      const errBody = await response.text();
      throw new Error(`Gemini API responded with status ${response.status}: ${errBody}`);
    }

    const data = await response.json();
    const replyText = data.candidates?.[0]?.content?.parts?.[0]?.text || "I am unable to answer that right now. Please choose an option from the menu.";

    return new Response(JSON.stringify({ reply: replyText }), {
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
