--!strict
--[[
	Retención: tutorial, colección de peces, recompensa diaria e insignias.

	Tutorial: 4 misiones en orden; cada una paga `coins` al completarla y al
	final se paga `tutorialBonus` (alcanza para la segunda caña).

	Colección: la primera vez que se pesca cada especie paga según su rareza;
	completar las 12 paga `collectionBonus`.

	Diario: racha de 7 días; si se salta un día vuelve al día 1. Después del
	día 7 se repite el premio del día 7.

	Regalos por tiempo: 8 regalos según los minutos que lleva en el servidor
	(se reinician al entrar de nuevo); el último a las 2 horas. Dan monedas
	y minutos de impulso personal de poder (x2, ver Config.Social).
]]

local Types = require(script.Parent.Types)

local Retention: Types.RetentionConfig = {
	tutorial = {
		{ id = "pescar", text = "Pesca 5 peces en la orilla (E)", goal = 5, coins = 25 },
		{
			id = "alimentar",
			text = "Cruza el puente y alimenta a la Orca (E)",
			goal = 1,
			coins = 50,
		},
		{ id = "entrenar", text = "Entrena en un estanque de la plaza (E)", goal = 1, coins = 50 },
		{ id = "comprar", text = "Compra una mejora en la tienda", goal = 1, coins = 100 },
	},
	tutorialBonus = 200,
	discoveryCoins = {
		Comun = 25,
		PocoComun = 75,
		Raro = 250,
		Epico = 1000,
		Legendario = 5000,
		Mitico = 25000,
	},
	collectionBonus = 100000,
	daily = { 100, 200, 350, 500, 800, 1200, 2500 },
	playtime = {
		{ minutes = 5, coins = 500 },
		{ minutes = 10, boostMinutes = 10 },
		{ minutes = 20, coins = 2500 },
		{ minutes = 30, boostMinutes = 15 },
		{ minutes = 45, coins = 10000 },
		{ minutes = 60, coins = 5000, boostMinutes = 30 },
		{ minutes = 90, coins = 40000 },
		{ minutes = 120, coins = 100000, boostMinutes = 60 },
	},
	badges = {
		PrimerPez = { name = "Primer pez", description = "Pescaste tu primer pez" },
		PrimerRaro = { name = "¡Raro!", description = "Pescaste un pez raro" },
		PrimerLegendario = { name = "Leyenda del mar", description = "Pescaste un pez legendario" },
		PrimerMitico = { name = "Mítico", description = "Pescaste el pez arcoíris" },
		PrimeraKill = { name = "Primera kill", description = "Ayudaste a llenar a un monstruo" },
		DiezKills = { name = "Cazagigantes", description = "10 monstruos llenados" },
		Coleccion = { name = "Colección completa", description = "Pescaste las 12 especies" },
		Tutorial = { name = "Pescador de verdad", description = "Terminaste el tutorial" },
		EstanqueMaximo = {
			name = "Maestro del estanque",
			description = "Entrenaste en el estanque x100",
		},
	},
}

return Retention
