--!strict
--[[
	Spin

	Ruleta gratis (server/Retention/SpinWheel): un giro cada `cooldownHours`
	horas, guardado en la partida. El servidor sortea el premio por `weight`:
		coins  lo mayor entre `coins` y `share` x el precio de la siguiente
		       caña (shared/RewardScale): vale la pena todo el juego sin saltarse
		       una caña entera (el premio mayor es 60 % de la siguiente)
		boost  `minutes` de impulso personal (x2 poder)
		fill   llena `fraction` de la barra del monstruo actual para todos (y
		       cuenta como aporte suyo); si no está comiendo, paga `share` en monedas
	La ventana (client/Menus/SpinWindow) muestra las mismas casillas.
]]

export type Prize = {
	kind: "coins" | "boost" | "fill",
	weight: number,
	coins: number?,
	share: number?,
	minutes: number?,
	fraction: number?,
}

export type SpinConfig = {
	cooldownHours: number,
	spinSeconds: number, -- lo que gira la ventana antes de mostrar el premio
	prizes: { Prize }, -- en el orden de las casillas de la ventana
}

local Spin: SpinConfig = {
	cooldownHours = 4,
	spinSeconds = 2.6,
	prizes = {
		{ kind = "coins", weight = 30, coins = 300, share = 0.05 },
		{ kind = "boost", weight = 18, minutes = 10 },
		{ kind = "coins", weight = 20, coins = 800, share = 0.12 },
		{ kind = "fill", weight = 10, fraction = 0.05, share = 0.12 },
		{ kind = "coins", weight = 8, coins = 2000, share = 0.3 },
		{ kind = "boost", weight = 10, minutes = 30 },
		{ kind = "coins", weight = 4, coins = 5000, share = 0.6 },
	},
}

return table.freeze(Spin)
