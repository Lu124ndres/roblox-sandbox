--!strict
-- Protocol: nombres compartidos entre servidor y cliente (remotes, atributos, estados, mapa).

-- Resultado que ve el dueño de la caña (avisos y botón TIRA).
export type FishingState = "waiting" | "bite" | "caught" | "escaped" | "cancelled" | "full"
-- Estado visible para todos (atributo del jugador): mueve la caña, el corcho y el pez.
export type FishingVisualState =
	"idle"
	| "casting"
	| "waiting"
	| "bite"
	| "caught"
	| "escaped"
	| "training"
export type FeedStatus = "ok" | "empty" | "full" | "resting" | "evolving"
-- Mejoras de la tienda (claves de Config.Shop y atributos del jugador con su nivel).
export type UpgradeCategory = "Rod" | "Basket" | "Boots"
-- Avisos al dueño (remote Notice).
export type NoticeKind =
	"newFish" -- (fishId, coins) primera vez que pesca esa especie
	| "collection" -- (coins) completó la colección
	| "collectionStep" -- (found, coins) llegó a un hito de la colección (cada 6 especies)
	| "giantLeft" -- (displayName, gotKill) el monstruo se cansó de esperar y se fue
	| "spin" -- (prizeIndex, text) giró la ruleta (Config/Spin)
	| "spinsGained" -- (spins, reason: "play" | "daily") ganó giros guardados de la ruleta
	| "tutorial" -- (stepIndex, coins) completó un paso; stepIndex > total = terminó
	| "badge" -- (badgeKey) logro nuevo
	| "daily" -- (day, coins) cobró la recompensa diaria
	| "playtime" -- (index, text) cobró un regalo por tiempo jugado
	| "admin" -- (text) resultado de una orden del panel de administrador
	| "event" -- (eventId) empezó un evento del servidor (Config/Events)
	| "quest" -- (text, rewardText) cumplió una misión diaria (o el cofre)
	| "rebirth" -- (count) renació
	| "boost" -- (buyerName, multiplier) alguien subió el entrenamiento de todo el servidor
	| "choose" -- (buyerName, giantId) alguien eligió el siguiente monstruo
	| "fill" -- (buyerName, percent) alguien llenó parte del monstruo con Robux
	| "restTime" -- (buyerName, seconds) alguien compró más descanso
	| "purchase" -- (text) compra propia aplicada (estanque, pase)
	| "rare" -- (playerName, fishId) alguien del servidor sacó un pez legendario o mejor
	| "code" -- (status: "ok" | "invalid" | "used" | "expired", text?) resultado de un código
	| "group" -- (status: "ok" | "notMember" | "wait" | "claimed" | "off") regalo del grupo
export type ShopStatus = "ok" | "poor" | "max" | "invalid"
-- Un elemento del lote de GiantFed: cuántos peces entregó ese jugador y la
-- especie más rara entre ellos (la que se dibuja volando).
export type GiantFedEntry = { userId: number, count: number, fishId: string }
-- Momento del ciclo del gigante (atributo Phase de EstadoGigante).
export type GiantPhase = "feeding" | "farewell" | "rest" | "arriving"

local ProtocolMap = require(script.Parent.ProtocolMap)

local Protocol = {
	RemotesFolder = "Remotes",

	Remotes = {
		-- servidor -> dueño: (state: FishingState, detail: any?)
		FishingUpdate = "FishingUpdate",
		-- cliente -> servidor: sin argumentos. Pide lanzar desde donde está parado.
		CastRequest = "CastRequest",
		-- cliente -> servidor: sin argumentos. Pide recoger el sedal.
		ReelIn = "ReelIn",
		-- cliente -> servidor: (mantiene: boolean) alimentar desde la orilla mientras está apretado.
		FeedRequest = "FeedRequest",
		-- servidor -> dueño: (status: FeedStatus, fishCount: number, coins: number)
		FeedResult = "FeedResult",
		-- servidor -> todos: (batch: { GiantFedEntry }). Lo que llegó al gigante en
		-- el último ~0.25 s, un elemento por jugador (ver server/Feeding/FedBroadcast).
		GiantFed = "GiantFed",
		-- servidor -> dueño: (gained: number). Un tick de entrenamiento en un estanque.
		TrainingTick = "TrainingTick",
		-- servidor -> dueño: (status: "locked" | "busy", requiredKills: number?, pond: number?)
		TrainingDenied = "TrainingDenied",
		-- cliente -> servidor: (category: UpgradeCategory). Comprar el siguiente nivel.
		BuyUpgrade = "BuyUpgrade",
		-- servidor -> dueño: (status: ShopStatus, category, level: number)
		ShopResult = "ShopResult",
		-- servidor -> dueño: sin argumentos. Abrir la tienda (E en la cabaña).
		OpenShop = "OpenShop",
		-- servidor -> dueño: (kind: NoticeKind, a: any?, b: any?). Carteles (logros, premios...).
		Notice = "Notice",
		-- cliente -> servidor: sin argumentos. Cobrar la recompensa diaria.
		ClaimDaily = "ClaimDaily",
		-- cliente -> servidor: (index: number). Cobrar el regalo por tiempo número index.
		ClaimPlaytime = "ClaimPlaytime",
		-- cliente -> servidor: (name, value, UserId del jugador elegido). Orden del panel admin.
		AdminCommand = "AdminCommand",
		RestEnter = "RestEnter", -- cliente -> servidor: ir a la guarida durante el descanso
		Rebirth = "Rebirth", -- cliente -> servidor: renacer (si le alcanzan las monedas)
		-- cliente -> servidor: (settings: { [string]: boolean }). Guardar ajustes.
		SaveSettings = "SaveSettings",
		RedeemCode = "RedeemCode", -- cliente -> servidor: (code: string) canjear un código
		ClaimGroup = "ClaimGroup", -- cliente -> servidor: reclamar el regalo del grupo
		ClaimSpin = "ClaimSpin", -- cliente -> servidor: girar (el gratis si toca, si no uno guardado)
		ChooseOutfit = "ElegirTraje", -- cliente -> servidor: (passKey) ponerse/quitarse ese traje
		-- cliente -> servidor: (productKey: string, targetUserId: number). La próxima
		-- compra de ese producto (en 2 min) es un regalo para ese jugador.
		SetGift = "SetGift",
		-- servidor -> todos: (position: Vector3, radius: number, telegraphSeconds: number).
		-- El gigante furioso marca dónde caerá un Salpicón.
		GiantAttack = "GiantAttack",
		-- servidor -> golpeado: (from: Vector3). El cliente aplica el empujón.
		GiantHit = "GiantHit",
	},

	-- Folder en ReplicatedStorage con el estado del gigante actual como atributos.
	GiantStateFolder = "EstadoGigante",
	-- Folder en ReplicatedStorage con los impulsos de todo el servidor (Robux).
	BoostFolder = "Impulsos",
	BoostAttributes = {
		TrainingUntil = "EntrenamientoHasta", -- GetServerTimeNow() en que termina (0 = no hay)
		TrainingLevel = "EntrenamientoNivel", -- nivel actual: x2^nivel mientras dure
		BoughtBy = "CompradoPor", -- nombre de quien lo compró por última vez
		NextGiant = "SiguienteMonstruo", -- id del monstruo elegido con Robux ("" = ruleta)
		NextGiantBy = "ElegidoPor", -- quién lo eligió
		ChoicesQueued = "EleccionesEnFila", -- cuántas elecciones esperan su turno
		Event = "Evento", -- id del evento del servidor activo (Config/Events; "" = ninguno)
		EventUntil = "EventoHasta", -- hora del servidor en que termina
		NextEventAt = "EventoSiguiente", -- hora del servidor en que empieza el siguiente
	},
	GiantAttributes = {
		Id = "Id",
		DisplayName = "DisplayName",
		Article = "Article",
		Multiplier = "Multiplier",
		Progress = "Progress", -- 0..1
		Anger = "Anger", -- 0..1 (1 = furioso)
		Phase = "Phase", -- GiantPhase
		PhaseEndsAt = "PhaseEndsAt", -- Workspace:GetServerTimeNow() en que termina la fase (0 = sin fin)
		Food = "Food", -- comida total que pide la barra (fija por gigante)
		RouletteResult = "RuletaResultado", -- id del gigante que salió en la última ruleta
		RouletteBy = "RuletaComprador", -- quien lo compró ("" = salió al azar)
		RouletteAt = "RuletaInicio", -- hora del servidor en que empezó a girar
		TopShares = "TopAportes", -- JSON: los 3 que más aportaron [{n = nombre, s = 0..1}]
		EvolvingUntil = "EvolucionHasta", -- hora del servidor en que termina de evolucionar (0 = no)
		Drained = "VolcanVacio", -- true en el descanso: el agua del cráter se va y queda la guarida
		RestFrom = "DescansoDesde", -- hora del servidor en que empieza a contar el descanso
		Refilling = "VolcanLlenando", -- true: el cráter se llena (agua o lava) antes de que llegue
	},

	-- Folder en ReplicatedStorage con las plantillas de los gigantes (los anima el cliente, GiantView).
	GiantModelsFolder = "ModelosGigantes",
	GiantModelAttributes = {
		BaseHeight = "BaseHeight", -- alto en studs a escala 1
		Turn = "GiroY", -- en ServerStorage: grados para girar el frente (Meshy a veces lo da al revés)
	},

	PlayerAttributes = {
		CarriedFish = "CarriedFish",
		FishingState = "FishingState", -- FishingVisualState
		FishingTarget = "FishingTarget", -- Vector3: dónde cae el corcho
		FishingCatch = "FishingCatch", -- id del pez atrapado (para dibujarlo)
		FishingCatchCount = "FishingCatchCount", -- cuántos salieron en ese pique
		Power = "Power", -- poder de pesca acumulado
		TrainingPond = "TrainingPond", -- índice del estanque donde entrena (0 = ninguno)
		DataLoaded = "DataLoaded", -- true cuando el guardado terminó de cargar
		Coins = "Coins", -- monedas (el HUD las muestra; no van en la tabla)
		Kills = "Kills", -- monstruos llenados en los que participó
		-- Nivel de cada mejora de la tienda (1 = la gratis). Mismo nombre que su categoría.
		Rod = "Rod",
		Basket = "Basket",
		Boots = "Boots",
		FishPrefix = "Pez_", -- Pez_<id>: cuántos de esa especie ha pescado (colección)
		Tutorial = "Tutorial", -- pasos del tutorial hechos
		TutorialCount = "TutorialCount", -- avance dentro del paso actual
		DailyStreak = "DailyStreak", -- racha de la recompensa diaria
		DailyDay = "DailyDay", -- último día (UTC) en que la cobró
		PlaytimeSince = "RegalosDesde", -- hora del servidor en que entró (regalos por tiempo)
		PlaytimeClaimed = "RegalosCobrados", -- regalos por tiempo cobrados (bits: 1, 2, 4...)
		IsAdmin = "EsAdmin", -- true para los administradores (ven el panel de pruebas)
		Rebirths = "Renacimientos", -- veces que renació
		Title = "Titulo", -- índice del título (Config.Social.titles) por su poder máximo
		Share = "Aporte", -- fracción de la barra del monstruo actual que aportó (0..1)
		StarterPack = "PackInicio", -- ya compró el pack de inicio
		Quests = "Misiones", -- JSON con las misiones del día y su avance
		Settings = "Settings", -- ajustes del jugador (JSON)
		PassPrefix = "Pase_", -- Pase_<clave>: true si tiene ese pase de Robux
		PondPrefix = "Estanque_", -- Estanque_<i>: true si compró ese estanque con Robux
		LevelPrefix = "Nivel", -- Nivel<Power|Coins>: mejoras de Robux compradas (x2^nivel)
		FriendsInServer = "AmigosEnServidor", -- amigos de Roblox en este servidor (impulso)
		BoostUntil = "ImpulsoHasta", -- hora (unix) en que termina el impulso personal de poder
		GroupClaimed = "GrupoReclamado", -- ya reclamó el regalo del grupo
		JoinedAt = "EntroEn", -- GetServerTimeNow() al entrar (para los 15 min del grupo)
		SpinAt = "RuletaListaEn", -- unix en que vuelve a tocar la ruleta gratis (0 = ya)
		Spins = "GirosGuardados", -- giros de ruleta guardados (se gastan si no toca el gratis)
		SpinTimeAt = "GiroPorTiempoEn", -- unix del próximo giro por jugar (0 = ya no hay más)
		CoinBoostUntil = "MonedasX2Hasta", -- unix en que termina el x2 monedas de la ruleta
	},

	Leaderstats = { -- tabla de jugadores (Tab), en este orden
		Power = "Poder",
		Coins = "Monedas",
		Kills = "Kills",
		Rebirths = "Renacimientos",
	},

	Map = ProtocolMap, -- piezas del mapa que el código busca por nombre (ProtocolMap)
}

return table.freeze(Protocol)
