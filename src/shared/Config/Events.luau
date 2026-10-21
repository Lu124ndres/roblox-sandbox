--!strict
--[[
	Events

	Eventos del servidor: cada `everyMinutes` minutos empieza uno al azar
	(nunca el mismo dos veces seguidas) que dura `durationMinutes` y ayuda a
	todos. Todos ven el aviso y la cuenta regresiva del siguiente, así hay
	una razón para quedarse "un ratito más". Lo que hace cada uno lo lee
	Shared/Perks (via Shared/ServerEvents):
		luck       se suma a la suerte (1 = +100 %)
		biteDelay  multiplica la espera hasta que pica (0.5 = el doble de rápido)
		coins      multiplica las monedas
		power      multiplica el poder
	Cada uno tiene su color y su ícono (Interface/Icons) para el anuncio y el
	potenciador del HUD (BoostBadges); su cielo y sus efectos en el mundo están en client/Ambient
	(EventSky, EventFx).
]]

export type EventDef = {
	id: string,
	name: string,
	text: string,
	color: Color3,
	icon: string, -- Interface/Icons
	luck: number?,
	biteDelay: number?,
	coins: number?,
	power: number?,
}

export type EventsConfig = {
	everyMinutes: number,
	durationMinutes: number,
	firstDelayMinutes: number,
	kinds: { EventDef },
}

local Events: EventsConfig = {
	everyMinutes = 12,
	durationMinutes = 3,
	firstDelayMinutes = 4,
	kinds = {
		{
			id = "PescaDorada",
			name = "¡Pesca dorada!",
			text = "+100% suerte",
			color = Color3.fromRGB(255, 200, 40),
			icon = "fish",
			luck = 1,
		},
		{
			id = "Frenesi",
			name = "¡Frenesí!",
			text = "Pican el doble de rápido",
			color = Color3.fromRGB(60, 200, 255),
			icon = "bolt",
			biteDelay = 0.5,
		},
		{
			id = "LluviaMonedas",
			name = "¡Lluvia de monedas!",
			text = "x2 monedas",
			color = Color3.fromRGB(255, 170, 40),
			icon = "coin",
			coins = 2,
		},
		{
			id = "PoderDoble",
			name = "¡Poder doble!",
			text = "x2 poder",
			color = Color3.fromRGB(150, 110, 255),
			icon = "crystal",
			power = 2,
		},
	},
}

return Events
