# Intermediario de likes (Cloudflare Workers)

Roblox no deja que el juego lea sus propios likes. Este worker gratuito los lee de la API
pública de Roblox y se los pasa al juego (`src/server/Social/LikeGoal.luau`).

## Publicarlo (una vez, ~10 minutos)

1. Crea una cuenta gratis en <https://dash.cloudflare.com/sign-up>.
2. En el panel: **Workers & Pages → Create → Create Worker**. Ponle un nombre, por ejemplo
   `likes-feed-giants`, y dale **Deploy**.
3. **Edit code**: borra lo que trae, pega todo `worker.js` y dale **Deploy**.
4. Copia la dirección que te da (algo como `https://likes-feed-giants.<tu-usuario>.workers.dev`)
   y ábrela en el navegador: tiene que mostrar `{"likes":…,"dislikes":…}`.
5. Pásale esa dirección a Claude para ponerla en `LikeGoal.luau` (`WORKER_URL`).
6. En Studio: **Ajustes del juego → Seguridad → Permitir solicitudes HTTP** (activado) y publica.

Si el worker falla, el letrero sigue con el número que se pone a mano desde el panel de admin
(orden «Likes del juego»).
