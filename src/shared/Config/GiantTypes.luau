--!strict
--[[
	Tipos de los gigantes (Config/Giants): la cadena, el enojo, el ciclo de
	descanso, la entrega de peces y cuánta comida piden según el servidor.
	Types.luau los vuelve a exportar para el resto del código.
]]

-- Un gigante de la cadena del servidor.
export type GiantDef = {
	id: string,
	displayName: string,
	article: string, -- "la" o "el": para textos como "alimenta a la Orca"
	multiplier: number, -- monedas por pez = fish.coins * multiplier
	food: number, -- comida MÍNIMA de la barra (servidor vacío o de novatos)
	targetMinutes: number, -- minutos que debería tardar el servidor en llenarlo (GiantFood)
	modelBase: string, -- nombre base de sus modelos: <base>E1..E4 en ServerStorage (uno por etapa)
	released: boolean, -- false = llega en una actualización (evento), no en la v1
	rouletteWeight: number, -- peso en la ruleta (probabilidad = peso / suma de los que pueden salir)
	inRoulette: boolean, -- puede salir en la ruleta al terminar el descanso (requiere su modelo)
	season: { from: number, to: number }?, -- de evento: solo sale entre esas fechas (unix UTC)
	lava: boolean?, -- con él el cráter se llena de lava en vez de agua (vuela: el dragón)
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
	drainSeconds: number, -- se vacía el volcán (el descanso es en su fondo)
	refillSeconds: number, -- vuelve el agua
	maxFeedMinutes: number, -- si no se llena en esto, se va y paga la kill a quien le dio algo
}

export type DeliveryConfig = { -- entrega de peces al gigante, por lotes
	stepSeconds: number, -- un lote de peces cada tanto
	fishPerSecond: number, -- peces por segundo sin renacer (los renacimientos lo multiplican)
	minSoloSeconds: number, -- tope por persona: 1/minSoloSeconds de la barra por segundo
	broadcastSeconds: number, -- lotes a los clientes y progreso, a lo sumo cada tanto
	basketSeconds: number, -- una canasta llena se vacía en a lo sumo esto (si es más rápido)
}

-- Cómo se estima lo que come el servidor por segundo (server/Feeding/GiantFood).
export type SizingConfig = {
	activeShare: number, -- parte del tiempo que un jugador pesca y alimenta (no entrena ni pasea)
	castOverheadSeconds: number, -- por lanzamiento: lanzar, recoger y volver a lanzar
	tripSeconds: number, -- ida y vuelta de la orilla al volcán
}

export type GiantsConfig = {
	chain: { GiantDef }, -- orden de aparición en el servidor
	stageThresholds: { number }, -- fracción de la barra donde EMPIEZA cada etapa
	playerHeightStuds: number, -- alto de referencia de un personaje
	stageHeightsInPlayers: { number }, -- alto del gigante en cada etapa, en jugadores
	anger: AngerConfig,
	cycle: CycleConfig,
	delivery: DeliveryConfig,
	sizing: SizingConfig,
}

return {}
