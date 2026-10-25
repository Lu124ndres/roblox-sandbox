--!strict
--[[
	Retención: tutorial, colección de peces, recompensa diaria e insignias.

	Tutorial: 4 misiones en orden; cada una paga `coins` al completarla y al
	final se paga `tutorialBonus`. Antes de la última (comprar) ya pagó 175,
	más de los 150 de la segunda caña, así nunca se traba. El novato aparece en
	la playa (`tutorialShoreInset` de la orilla) y en los pasos de ir lejos
	camina a `tutorialWalkSpeed`: la primera comida al gigante llega en ~45 s.

	Colección: la primera vez que se pesca cada especie paga según su rareza;
	cada `collectionMilestone.every` especies hay un premio extra y completar
	todas (36) paga `collectionBonus`.

	Diario: racha de 7 días; si se salta un día vuelve al día 1. Después del
	día 7 se repite el premio del día 7. Cada cobro da también giros de
	ruleta (`dailySpins`, por día) y la racha da `streakBonus.perDay` más de
	monedas y poder por día seguido (hasta `maxDays`), mientras no se corte.

	Regalos por tiempo: 8 regalos según los minutos que lleva en el servidor
	(se reinician al entrar de nuevo); el último a las 2 horas. Dan monedas
	y minutos de impulso personal de poder (x2, ver Config.Social).
]]

local Types = require(script.Parent.Types)

local Retention: Types.RetentionConfig = {
	tutorial = {
		{ id = "pescar", intro = "¡PESCA!", text = "Pesca 3 peces", goal = 3, coins = 25 },
		{
			id = "alimentar",
			intro = "¡DALE DE COMER AL GIGANTE!",
			text = "Lleva los peces al volcán",
			goal = 1,
			coins = 50,
		},
		{
			id = "entrenar",
			intro = "¡ENTRENA!",
			text = "Entrena en el estanque",
			goal = 1,
			coins = 100,
		},
		{
			id = "comprar",
			intro = "¡MEJORA TU EQUIPO!",
			text = "Compra una mejora",
			goal = 1,
			coins = 100,
		},
	},
	tutorialBonus = 200,
	tutorialWalkSpeed = 40,
	tutorialFastSteps = { "alimentar", "entrenar" },
	tutorialIntroSeconds = 1.6,
	tutorialShoreInset = 8,
	discoveryCoins = {
		Comun = 25,
		PocoComun = 75,
		Raro = 250,
		Epico = 1000,
		Legendario = 5000,
		Mitico = 25000,
	},
	collectionBonus = 250000,
	-- Cada 6 especies nuevas: lo mayor entre 1,500 x hito (1.5K, 3K, 4.5K...) y
	-- 0.4 de la siguiente caña (shared/Collection). Al llegar a 36 paga collectionBonus.
	collectionMilestone = { every = 6, coins = 1500, share = 0.4 },
	-- Suerte para siempre por completar cada sección (rareza) de la colección
	-- (shared/CollectionLuck). Todas juntas: +145 %.
	collectionLuck = {
		Comun = 0.05,
		PocoComun = 0.1,
		Raro = 0.15,
		Epico = 0.25,
		Legendario = 0.4,
		Mitico = 0.5,
	},
	-- Monedas fijas al principio; cuando el juego avanza, una fracción del precio
	-- de la siguiente caña (shared/RewardScale): siempre valen la pena.
	daily = { 100, 200, 350, 500, 800, 1200, 2500 },
	dailyShare = { 0.05, 0.08, 0.12, 0.16, 0.22, 0.3, 0.4 },
	dailySpins = { 1, 1, 1, 1, 1, 1, 3 }, -- giros guardados de cada día (el 7 da 3)
	streakBonus = { perDay = 0.1, maxDays = 10 }, -- +10% por día de racha, hasta +100%
	playtime = {
		{ minutes = 5, coins = 500, share = 0.15 },
		{ minutes = 10, boostMinutes = 10 },
		{ minutes = 20, coins = 2500, share = 0.4 },
		{ minutes = 30, boostMinutes = 15 },
		{ minutes = 45, coins = 10000, share = 0.8 },
		{ minutes = 60, coins = 5000, share = 0.6, boostMinutes = 30 },
		{ minutes = 90, coins = 40000, share = 1.5 },
		{ minutes = 120, coins = 100000, share = 1.5, boostMinutes = 60 },
	},
	badges = {
		PrimerPez = { name = "Primer pez", description = "Pescaste tu primer pez" },
		PrimerRaro = { name = "¡Raro!", description = "Pescaste un pez raro" },
		PrimerLegendario = { name = "Leyenda del mar", description = "Pescaste un pez legendario" },
		PrimerMitico = { name = "Mítico", description = "Pescaste el pez arcoíris" },
		PrimeraKill = { name = "Primer banquete", description = "Ayudaste a llenar a un monstruo" },
		DiezKills = { name = "Cazagigantes", description = "10 monstruos llenados" },
		Coleccion = { name = "Colección completa", description = "Pescaste todas las especies" },
		Tutorial = { name = "Pescador de verdad", description = "Terminaste el tutorial" },
		EstanqueMaximo = {
			name = "Maestro del estanque",
			description = "Entrenaste en el estanque más alto (x25)",
		},
	},
}

return Retention
