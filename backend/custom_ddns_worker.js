export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const { pathname, searchParams } = url;
    
    // Simple basic auth via Bearer token to prevent others from changing your IP
    const authHeader = request.headers.get('Authorization');
    const secretToken = 'Bearer lifeos_super_secret_token_123'; 

    // Handle CORS for local web testing if needed
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    if (pathname === '/update') {
      // Security check
      if (authHeader !== secretToken) {
        return new Response('Unauthorized', { status: 401, headers: corsHeaders });
      }

      // The IP can be sent in the body or we can automatically detect the caller's IP
      // request.headers.get('CF-Connecting-IP') gets the public IP of the caller!
      const callerIp = request.headers.get('CF-Connecting-IP');
      
      // Store the IP in Cloudflare KV store (Key-Value)
      // Assuming you bound a KV namespace to the variable `LIFEOS_KV`
      if (env.LIFEOS_KV) {
        await env.LIFEOS_KV.put('home_public_ip', callerIp);
        return new Response(`Updated IP to ${callerIp}`, { status: 200, headers: corsHeaders });
      } else {
        return new Response('KV Store not configured', { status: 500, headers: corsHeaders });
      }
    }

    if (pathname === '/get') {
      if (env.LIFEOS_KV) {
        const ip = await env.LIFEOS_KV.get('home_public_ip');
        if (ip) {
          return new Response(JSON.stringify({ ip: ip }), { 
            status: 200, 
            headers: { ...corsHeaders, "Content-Type": "application/json" }
          });
        }
        return new Response(JSON.stringify({ error: 'No IP found' }), { 
          status: 404, 
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        });
      }
      return new Response('KV Store not configured', { status: 500, headers: corsHeaders });
    }

    return new Response('LifeOS Custom DDNS API', { status: 200, headers: corsHeaders });
  },
};
