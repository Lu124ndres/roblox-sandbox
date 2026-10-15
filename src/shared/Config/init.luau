--!strict
--[[
	Config

	Fuente única de verdad para todos los números de balance del juego:
	precios, tiempos, recompensas, límites, probabilidades.

	Regla: ningún sistema escribe un número de balance inline. Si un valor
	afecta cómo se siente o cómo se equilibra el juego, vive aquí. Así se
	puede ajustar el balance sin tocar lógica y se revisa en un solo lugar.

	Este módulo vive en ReplicatedStorage para que el cliente pueda MOSTRAR
	valores (por ejemplo, un precio en la UI). El servidor sigue siendo el
	único que DECIDE: el cliente nunca usa Config para validar nada.

	Los valores actuales salen del modelo de calibración de docs/alcance.md
	(sección "Calibración"). Cuando haya telemetría real, se ajustan aquí.

	Organización: los tipos viven en Types.luau; las secciones largas en su
	propio archivo (Fish.luau, Giants.luau, Progression.luau) y aquí se juntan. Para el
	resto del código sigue siendo un solo módulo: require(Shared.Config).

	Cómo agregar valores:
		1. Declarar el campo en el tipo de la sección (Types.luau).
		2. Asignar el valor en la sección correspondiente.
		3. Documentar la unidad (segundos, studs, monedas) en un comentario.
]]

local Fish = require(script.Fish)
local Giants = require(script.Giants)
local Monetization = require(script.Monetization)
local Social = require(script.Social)
local Progression = require(script.Progression)
local Retention = require(script.Retention)
local Shop = require(script.Shop)
local Types = require(script.Types)

export type FishDef = Types.FishDef
export type RarityDef = Types.RarityDef
export type GiantDef = Types.GiantDef
export type PondDef = Types.PondDef
export type UpgradeDef = Types.UpgradeDef
export type PlaytimeGift = Types.PlaytimeGift
export type Config = Types.Config

local Config: Types.Config = {
	Economy = Fish,

	Progression = Progression,

	Gameplay = {
		-- La corriente del puente lleva rápido al volcán y de vuelta.
		bridge = {
			walkSpeed = 44,
		},
		fishing = {
			biteDelayMinSeconds = 2,
			biteDelayMaxSeconds = 5,
			castSeconds = 0.9,
			castDistanceStuds = 12,
			resultHoldSeconds = 1.6,
			carryCapacity = 20,
			maxDriftStuds = 10,
			castCooldownSeconds = 0.6,
		},
		feeding = {
			promptDistanceStuds = 10,
			requestCooldownSeconds = 0.5,
		},
		training = {
			tickSeconds = 0.6, -- cada 0.6 s se gana poder (estanques y guarida)
			powerPerTick = 1,
			promptDistanceStuds = 18,
			maxDriftStuds = 9,
		},
	},

	Giants = Giants,

	Shop = Shop,

	Retention = Retention,

	Monetization = Monetization,

	Social = Social,

	Saving = {
		storeName = "Jugadores_v1",
		autosaveSeconds = 60,
		maxAttempts = 5,
		retryBaseSeconds = 1,
		lockExpireSeconds = 180, -- ~3 autoguardados: el guardado repartido renueva cada <= 2 intervalos
		lockedRetries = 6,
		lockedRetrySeconds = 5,
	},
}

-- Congelado para que ningún sistema pueda modificar el balance en tiempo de ejecución.
-- table.freeze es superficial: las subtablas también se congelan una por una.
local function deepFreeze(value: any)
	if type(value) == "table" and not table.isfrozen(value) then
		for _, child in value do
			deepFreeze(child)
		end
		table.freeze(value)
	end
end
deepFreeze(Config)

return Config
