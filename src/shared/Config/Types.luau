--!strict
--[[
	Tipos de Config. Viven aparte para que las secciones (Economy, Giants...)
	los usen sin requerir init.luau, que es quien las junta.
]]

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

-- Un gigante de la cadena del servidor.
export type GiantDef = {
	id: string,
	displayName: string,
	article: string, -- "la" o "el": para textos como "alimenta a la Orca"
	multiplier: number, -- monedas por pez = fish.coins * multiplier
	food: number, -- comida para llenar la barra (fija)
	modelBase: string, -- nombre base de sus modelos: <base>E1..E4 en ServerStorage (uno por etapa)
	released: boolean, -- false = llega en una actualización (evento), no en la v1
	rouletteWeight: number, -- peso en la ruleta (probabilidad = peso / suma de los que pueden salir)
	inRoulette: boolean, -- puede salir en la ruleta al terminar el descanso (requiere su modelo)
	season: { from: number, to: number }?, -- de evento: solo sale entre esas fechas (unix UTC)
}

-- Un estanque de la zona de entrenamiento.
export type PondDef = {
	multiplier: number, -- poder por segundo = powerPerTick * multiplier
	requiredKills: number, -- monstruos llenados (kills) para usarlo
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
	walkSpeed: number, -- velocidad sobre el puente al volcán (la normal es 16)
}

export type GameplayConfig = {
	bridge: BridgeConfig,
	fishing: FishingConfig,
	feeding: FeedingConfig,
	training: TrainingConfig,
}

export type AngerConfig = {
	graceSeconds: number, -- segundos sin comer antes de empezar a enojarse
	smallServerPlayers: number, -- con estos jugadores o menos...
	smallServerGraceSeconds: number, -- ...la espera es esta (un viaje solo tarda ~2 min)
	rampSeconds: number, -- segundos para pasar de 0 a furioso
	angryThreshold: number, -- desde este enojo la barra baja sola
	hungerDecayPerSecond: number, -- fracción de la barra que pierde por segundo enojado
	attackIntervalSeconds: number, -- cada cuánto ataca estando furioso
	telegraphSeconds: number, -- aviso visible antes de que caiga el golpe
	attackRadiusStuds: number,
	hitMarginStuds: number, -- margen a favor del jugador en el borde del círculo
	attackRangeStuds: number, -- distancia máxima al cráter de los jugadores que puede atacar
	knockbackSpeed: number, -- studs/s del empujón (lo aplica el cliente)
}

-- Lo que pasa al llenar a un gigante: despedida, descanso en el volcán y llegada del siguiente.
export type CycleConfig = {
	farewellSeconds: number, -- despedida: salta, gira y se sumerge
	evolveSeconds: number, -- pausa sin comer al cruzar cada etapa (evoluciona)
	restSeconds: number, -- descanso (máximo): dentro del volcán se entrena solo
	restBaseSeconds: number, -- descanso = clamp(base + porJugador x jugadores, min, restSeconds)
	restPerPlayerSeconds: number,
	restMinSeconds: number,
	arrivalSeconds: number, -- llegada del siguiente gigante antes de poder alimentarlo
	rouletteSeconds: number, -- la ruleta gira al final del descanso antes de que llegue
}

export type DeliveryConfig = { -- entrega de peces al gigante, por lotes
	stepSeconds: number, -- un lote de peces cada tanto
	maxDeliverySeconds: number, -- una canasta entera se entrega en a lo sumo esto
	broadcastSeconds: number, -- lotes a los clientes y progreso, a lo sumo cada tanto
}

export type GiantsConfig = {
	chain: { GiantDef }, -- orden de aparición en el servidor
	stageThresholds: { number }, -- fracción de la barra donde EMPIEZA cada etapa
	playerHeightStuds: number, -- alto de referencia de un personaje
	stageHeightsInPlayers: { number }, -- alto del gigante en cada etapa, en jugadores
	anger: AngerConfig,
	cycle: CycleConfig,
	delivery: DeliveryConfig,
}

export type ProgressionConfig = {
	ponds: { PondDef }, -- uno por estanque, en orden alrededor de la plaza
	biteSpeedDivisor: number, -- velocidad de pique = 1 + sqrt(poder) / divisor
	capacityPerRoot: number, -- capacidad = (carryCapacity + esto x sqrt(poder)) x canasta
	castsToFill: { start: number, perRod: number, min: number }, -- lanzamientos para llenarla
	minBiteDelaySeconds: number, -- la espera hasta el pique nunca baja de esto
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
	daily: { number }, -- monedas de cada día de la racha (1..7)
	dailyShare: { number }, -- o esta fracción de la siguiente caña, lo que sea mayor
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
}

return {}
