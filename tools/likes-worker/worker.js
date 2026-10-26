// Servidor intermediario para la meta de likes de Feed the Giants (Cloudflare Workers).
// Roblox no deja que un juego lea sus propios likes, así que el juego le pide el número a
// este worker y el worker se lo pide a la API pública de Roblox. Solo responde por el juego
// configurado (UNIVERSE_ID) y guarda la respuesta 60 s en caché para no abusar de la API.
// Pasos para publicarlo: tools/likes-worker/README.md

const UNIVERSE_ID = "10770885547"; // Feed the Giants
const CACHE_SECONDS = 60;

export default {
  async fetch(request, env, ctx) {
    const cache = caches.default;
    const key = new Request("https://cache.local/votes/" + UNIVERSE_ID);
    const cached = await cache.match(key);
    if (cached) {
      return cached;
    }
    const upstream = await fetch(
      "https://games.roblox.com/v1/games/votes?universeIds=" + UNIVERSE_ID,
      { headers: { accept: "application/json" } }
    );
    if (!upstream.ok) {
      return new Response(JSON.stringify({ error: upstream.status }), { status: 502 });
    }
    const data = await upstream.json();
    const entry = data && data.data && data.data[0];
    const body = JSON.stringify({
      likes: entry ? entry.upVotes : null,
      dislikes: entry ? entry.downVotes : null,
    });
    const response = new Response(body, {
      headers: {
        "content-type": "application/json",
        "cache-control": "max-age=" + CACHE_SECONDS,
      },
    });
    ctx.waitUntil(cache.put(key, response.clone()));
    return response;
  },
};
