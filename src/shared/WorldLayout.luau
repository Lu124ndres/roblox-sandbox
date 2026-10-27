--!strict
--[[
	WorldLayout

	Geometría del mundo con tipos. Los números viven en WorldLayoutData.json
	(Rojo lo convierte en ModuleScript), que también lee el generador de
	piezas en Python: así terreno, piezas y validaciones nunca se desfasan.

	Dos zonas:
		Isla principal (centrada en el origen): aparición, zona de entrenamiento
		con estanques en el centro, muelles, cabaña, campamento y faro.
		Cráter del Abismo (en craterCenter): lago profundo rodeado de un anillo
		volcánico donde vive el gigante. Se llega por un puente de piedra.

	No son números de balance (esos van en Config): son medidas del mapa.
]]

export type WorldLayout = {
	waterLevel: number,
	oceanHalfSize: number,
	seaFloorHeight: number,
	plateauRadius: number,
	plateauHeight: number,
	beachEndRadius: number,
	beachEndHeight: number,
	shelfRadius: number,
	shoreRadius: number,
	deckHeight: number,
	plazaRadius: number,
	-- Zona de entrenamiento: los estanques repartidos por el jardín; los más bajos,
	-- cerca del puente al volcán (+Z), y el sagrado en el centro.
	trainingPondCount: number,
	pondPositions: { { number } }, -- { x, z } de los estanques 1..trainingPondCount
	-- Estanques que ya no están en el mapa (2026-10-20: el Dorado y el Celestial). Siguen
	-- contando para los números: el sagrado es trainingPondCount + 1 y los productos PondN
	-- y lo guardado van por número.
	removedPonds: { number },
	trainingPondRadius: number,
	trainingPondFloor: number,
	trainingPondWaterTop: number,
	sacredPondRadius: number, -- estanque sagrado del centro (solo Robux)
	pondCoverDepth: number, -- tapa invisible: el piso queda así de hondo bajo el agua
	-- Orilla natural: el radio del agua ondula con estas amplitudes (fracción del radio)
	-- en 2, 3 y 5 lóbulos (WorldZones.pondEdge), con una franja de barro alrededor.
	pondWobble: { number },
	pondBankWidth: number,
	-- Jardín de la zona de entrenamiento: sendero de tierra en anillo por fuera de los
	-- estanques, senderos rectos hacia el centro y un claro alrededor del sagrado.
	gardenRingRadius: number,
	gardenPathHalfWidth: number,
	gardenSpokeAngles: { number },
	gardenClearingRadius: number,
	gardenPathRise: number, -- los senderos del jardín (isla de bloques) van así de alto sobre la meseta
	pierAngles: { number },
	pierStartRadius: number,
	pierLength: number,
	spawnAngle: number, -- dónde está el arco de la entrada (con los tableros del ranking)
	spawnPosition: { number }, -- { x, z }: se aparece dentro del jardín, mirando al volcán
	-- Vitrinas de los trajes de pase: en la zona de entrenamiento, del lado de los estanques
	-- para principiantes (1 y 2), a showcaseRadius del centro y showcaseSide a cada costado.
	showcaseAngle: number,
	showcaseRadius: number,
	showcaseSide: number,
	shopAngle: number,
	shopRadius: number,
	campAngle: number,
	campRadius: number,
	lighthouseAngle: number,
	lighthouseRadius: number,
	lighthouseBaseHeight: number,
	lighthouseMoundRadius: number,
	fishingBandInner: number, -- desde este radio se puede pescar (toda la playa; no hay muelles)
	fishingBandOuter: number, -- hasta este radio (un poco mar adentro de la orilla)
	bridgeAngle: number,
	bridgeStartRadius: number,
	bridgeWidth: number,
	-- Cráter del gigante (radios medidos desde craterCenter).
	craterCenter: { number }, -- { x, z }
	craterLakeRadius: number,
	craterCliffRadius: number,
	craterRimOuter: number,
	craterGateRadius: number, -- del centro del cráter al arco, al pie del volcán (ahí llega el puente)
	craterBaseRadius: number,
	craterRimHeight: number,
	craterFloor: number, -- fondo del lago en el centro (ahí está la guarida del descanso)
	craterFlatRadius: number, -- radio del fondo plano
	deepLakeFloor: number, -- fondo plano del lago hondo (GiantDef.deepLake: la orca)
	deepLakeWallRadius: number, -- hasta aquí llega ese fondo; de ahí sube la pared hasta la orilla
	craterShelfDepth: number, -- hondura de la plataforma clara junto al acantilado
	craterShelfWidth: number, -- ancho de esa plataforma
	craterWalkWidth: number, -- paseo plano desde el borde del acantilado
	craterPeakHeight: number, -- alto máximo de las montañas del anillo sobre el paseo
	pedestalTop: number,
	craterDeckHeight: number,
	restArenaRadius: number, -- guarida del descanso: el radio de su piso
	restArenaTop: number, -- altura de su piso: flota sobre el relleno (agua, lava o arena)
	restArenaSink: number, -- cuánto queda enterrada bajo el fondo mientras no hay descanso
	restBridgeAngle: number, -- el puente del paseo a la guarida (grados, como los del cráter)
	restBridgeWidth: number, -- ancho de su rampa (entre sus paredes invisibles)
	boundaryCenter: { number },
	boundaryRadius: number,
	hills: { { number } }, -- { x, z, radio }
	shoreRocks: { { number } }, -- { x, z, radio }
}

local data = require(script.Parent.WorldLayoutData) :: any

local WorldLayout = table.freeze(data) :: WorldLayout

return WorldLayout
