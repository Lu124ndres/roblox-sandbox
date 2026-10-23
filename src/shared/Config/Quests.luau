--!strict
--[[
	Quests

	Misiones diarias: cada día (UTC) salen `perDay` misiones de la lista,
	las mismas para todos (así se comentan entre jugadores). Se cumplen solas
	al llegar a la meta y se reclaman en la ventana MISIONES; cumplir las tres
	da además el cofre (`bonus`), que también se reclama ahí. Además sale una misión EXTRA de `extra` (llenar
	monstruos): paga igual, pero el cofre no la pide (se puede jugar solo).
	Las monedas crecen con el avance (shared/RewardScale), así valen la pena
	todo el juego; el multiplicador de monedas (Robux) no las toca.
	Qué cuenta cada tipo (`kind`) — piques y viajes, no peces (con mucha
	fuerza se sacan cientos de peces por pique):
		catch       piques (veces que pescó)   feed   viajes al monstruo con peces
		rare        peces raros o mejores      kill   monstruos llenados (kills)
		train       segundos entrenando        eventCatch  piques durante un evento
		food        % de la barra de un monstruo que aportó (suma entre monstruos)
]]

export type QuestDef = {
	id: string,
	text: string,
	kind: string,
	goal: number,
	coins: number,
	boostMinutes: number?,
}

export type QuestsConfig = {
	perDay: number,
	pool: { QuestDef },
	extra: { QuestDef }, -- se sortea una por día; no cuenta para el cofre
	bonus: { coins: number, boostMinutes: number },
}

local Quests: QuestsConfig = {
	perDay = 3,
	pool = {
		{ id = "pescar60", text = "Pesca 60 veces", kind = "catch", goal = 60, coins = 1500 },
		{
			id = "pescar250",
			text = "Pesca 250 veces",
			kind = "catch",
			goal = 250,
			coins = 4000,
			boostMinutes = 10,
		},
		{
			id = "raros3",
			text = "Pesca 3 peces raros o mejores",
			kind = "rare",
			goal = 3,
			coins = 3000,
		},
		{
			id = "entregar3",
			text = "Lleva peces al monstruo 3 veces",
			kind = "feed",
			goal = 3,
			coins = 2000,
		},
		{
			id = "entregar10",
			text = "Lleva peces al monstruo 10 veces",
			kind = "feed",
			goal = 10,
			coins = 6000,
			boostMinutes = 15,
		},
		{
			id = "aporte5",
			text = "Aporta el 5% de la barra de un monstruo",
			kind = "food",
			goal = 5,
			coins = 2500,
		},
		{
			id = "aporte25",
			text = "Aporta el 25% de las barras de los monstruos",
			kind = "food",
			goal = 25,
			coins = 8000,
			boostMinutes = 20,
		},
		{ id = "entrenar5", text = "Entrena 5 minutos", kind = "train", goal = 300, coins = 2000 },
		{
			id = "evento40",
			text = "Pesca 20 veces durante un evento",
			kind = "eventCatch",
			goal = 20,
			coins = 3500,
		},
	},
	extra = {
		{ id = "kill1", text = "Ayuda a llenar 1 monstruo", kind = "kill", goal = 1, coins = 2500 },
		{
			id = "kill3",
			text = "Ayuda a llenar 3 monstruos",
			kind = "kill",
			goal = 3,
			coins = 8000,
			boostMinutes = 20,
		},
	},
	bonus = { coins = 3000, boostMinutes = 30 },
}

return Quests
