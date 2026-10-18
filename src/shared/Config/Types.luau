--!strict
--[[
	Tipos de Config. Viven aparte para que las secciones (Economy, Giants...)
	los usen sin requerir init.luau, que es quien las junta.
]]

local GiantTypes = require(script.Parent.GiantTypes)
local Habitats = require(script.Parent.Habitats)
local Monetization = require(script.Parent.Monetization)
local Social = require(script.Parent.Social)

-- Un nivel de rareza. El orden de la lista es de menos a más raro.
export type RarityDef = {
	id: string,
	displayName: string,
}

-- Un pez que se puede pescar.
export type FishDef = {
	id: string,
	displayName: string,
	rarity: string, -- id de un RarityDef
	weight: number, -- peso relativo en la tirada (no es un porcentaje)
	food: number, -- puntos de comida que aporta al gigante
	coins: number, -- monedas base; se multiplican por el gigante actual
}

-- Un estanque de la zona de entrenamiento.
export type PondDef = {
	multiplier: number, -- poder por segundo = powerPerTick * multiplier
	requiredKills: number, -- monstruos llenados (kills) para usarlo (o comprarlo con Robux)
	robuxOnly: boolean?, -- solo se abre comprándolo (el estanque sagrado del centro)
}

export type EconomyConfig = {
	rarities: { RarityDef },
	fish: { FishDef },
}

export type FishingConfig = {
	biteDelayMinSeconds: number, -- espera mínima hasta que pica
	biteDelayMaxSeconds: number, -- espera máxima hasta que pica
	castSeconds: number, -- duración del lanzamiento antes de empezar a esperar
	castDistanceStuds: number, -- distancia del jugador al corcho
	resultHoldSeconds: number, -- cuánto se ve el pez atrapado antes de guardar la caña
	carryCapacity: number, -- capacidad base; se multiplica por los peces por pique
	maxDriftStuds: number, -- cuánto puede alejarse del lugar donde lanzó
	castCooldownSeconds: number, -- espera mínima entre dos lanzamientos
}

export type FeedingConfig = {
	promptDistanceStuds: number,
	requestCooldownSeconds: number, -- espera mínima entre dos pedidos de alimentar del mismo jugador
}

export type TrainingConfig = {
	tickSeconds: number, -- cada cuánto se suma poder
	powerPerTick: number, -- poder base por tick, antes del multiplicador del estanque
	promptDistanceStuds: number,
	maxDriftStuds: number, -- si se aleja más que esto del estanque, deja de entrenar
}

export type BridgeConfig = {
	walkSpeed: number, -- velocidad sobre el puente al volcán (más que cualquier bota)
}

export type GameplayConfig = {
	bridge: BridgeConfig,
	fishing: FishingConfig,
	feeding: FeedingConfig,
	training: TrainingConfig,
}

export type GiantDef = GiantTypes.GiantDef
export type GiantsConfig = GiantTypes.GiantsConfig

export type ProgressionConfig = {
	ponds: { PondDef }, -- uno por estanque, en orden alrededor del jardín
	biteSpeedDivisor: number, -- velocidad de pique = 1 + sqrt(poder) / divisor
	capacityPerRoot: number, -- capacidad = (carryCapacity + esto x sqrt(poder)) x canasta
	castsToFill: { start: number, perRod: number, min: number }, -- lanzamientos para llenarla
	minBiteDelaySeconds: number, -- la espera hasta el pique nunca baja de esto
	-- Monedas por pez: una canasta llena paga como carryCapacity x (1 + (poder/step)^exponent)
	coinScale: { step: number, exponent: number },
}

-- Un nivel de una mejora de la tienda (ver Config/Shop.luau).
export type UpgradeDef = {
	name: string,
	price: number, -- monedas
	value: number, -- multiplicador de poder (Rod), de capacidad (Basket) o velocidad (Boots)
	luck: number?, -- solo cañas: peso extra de los peces poco comunes o mejores
}

export type ShopConfig = {
	Rod: { UpgradeDef },
	Basket: { UpgradeDef },
	Boots: { UpgradeDef },
}

export type TutorialStep = {
	id: string,
	text: string, -- lo que ve el jugador en el panel de la misión
	goal: number, -- cuántas veces hay que hacerlo
	coins: number, -- premio al completarla
}

export type BadgeDef = { name: string, description: string }
export type PlaytimeGift =
	{ minutes: number, coins: number?, share: number?, boostMinutes: number? }
export type RetentionConfig = {
	tutorial: { TutorialStep },
	tutorialBonus: number, -- monedas extra al terminar el tutorial
	discoveryCoins: { [string]: number }, -- por rareza: primera vez que se pesca una especie
	collectionBonus: number, -- monedas al completar la colección
	-- Premio cada `every` especies: lo mayor entre coins x hito y share x la siguiente caña
	collectionMilestone: { every: number, coins: number, share: number },
	daily: { number }, -- monedas de cada día de la racha (1..7)
	dailyShare: { number }, -- o esta fracción de la siguiente caña, lo que sea mayor
	dailySpins: { number }, -- giros de ruleta guardados que da cada día (1..7)
	-- Racha: x(1 + perDay x días seguidos, hasta maxDays) monedas y poder (shared/StreakBonus)
	streakBonus: { perDay: number, maxDays: number },
	playtime: { PlaytimeGift }, -- regalos por minutos jugados (share: ver RewardScale)
	badges: { [string]: BadgeDef }, -- clave = Assets.Badges[clave]
}

export type SavingConfig = {
	storeName: string, -- nombre del DataStore (cambiarlo empieza de cero para todos)
	autosaveSeconds: number, -- cada cuánto se guarda a todos los jugadores
	maxAttempts: number, -- reintentos de cada lectura o escritura
	retryBaseSeconds: number, -- primera espera entre reintentos (se duplica)
	lockExpireSeconds: number, -- un bloqueo sin renovar vence tras esto (servidor caído)
	lockedRetries: number, -- al entrar, cuántas veces esperar a que otro servidor suelte los datos
	lockedRetrySeconds: number,
}

export type MonetizationConfig = Monetization.MonetizationConfig
export type SocialConfig = Social.SocialConfig
export type HabitatsConfig = Habitats.HabitatsConfig

export type Config = {
	Economy: EconomyConfig,
	Progression: ProgressionConfig,
	Gameplay: GameplayConfig,
	Giants: GiantsConfig,
	Saving: SavingConfig,
	Shop: ShopConfig,
	Retention: RetentionConfig,
	Monetization: MonetizationConfig,
	Social: SocialConfig,
	Habitats: HabitatsConfig,
}

return {}
