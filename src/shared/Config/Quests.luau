--!strict
--[[
	Quests

	Misiones diarias: cada día (UTC) salen `perDay` misiones de la lista,
	las mismas para todos (así se comentan entre jugadores). Se cumplen solas
	al llegar a la meta y pagan al momento; cumplir las tres da además el
	cofre (`bonus`). Las monedas se multiplican por el multiplicador de
	monedas del jugador, así valen igual al principio y al final del juego.
	Qué cuenta cada tipo (`kind`):
		catch       peces pescados          feed   peces entregados al monstruo
		rare        peces raros o mejores   kill   monstruos llenados (kills)
		train       segundos entrenando     eventCatch  peces pescados durante un evento
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
	bonus: { coins: number, boostMinutes: number },
}

local Quests: QuestsConfig = {
	perDay = 3,
	pool = {
		{ id = "pescar60", text = "Pesca 60 peces", kind = "catch", goal = 60, coins = 1500 },
		{
			id = "pescar250",
			text = "Pesca 250 peces",
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
			id = "entregar100",
			text = "Entrega 100 peces al monstruo",
			kind = "feed",
			goal = 100,
			coins = 2000,
		},
		{
			id = "entregar500",
			text = "Entrega 500 peces al monstruo",
			kind = "feed",
			goal = 500,
			coins = 6000,
			boostMinutes = 15,
		},
		{ id = "kill1", text = "Ayuda a llenar 1 monstruo", kind = "kill", goal = 1, coins = 2500 },
		{
			id = "kill3",
			text = "Ayuda a llenar 3 monstruos",
			kind = "kill",
			goal = 3,
			coins = 8000,
			boostMinutes = 20,
		},
		{ id = "entrenar5", text = "Entrena 5 minutos", kind = "train", goal = 300, coins = 2000 },
		{
			id = "evento40",
			text = "Pesca 40 peces durante un evento",
			kind = "eventCatch",
			goal = 40,
			coins = 3500,
		},
	},
	bonus = { coins = 10000, boostMinutes = 30 },
}

return Quests
