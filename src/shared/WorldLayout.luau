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
	-- Zona de entrenamiento: estanques en círculo alrededor del centro de la isla.
	trainingPondCount: number,
	trainingPondRingRadius: number,
	trainingPondRadius: number,
	trainingPondFloor: number,
	trainingPondWaterTop: number,
	sacredPondRadius: number, -- estanque sagrado del centro (solo Robux)
	pondCoverDepth: number, -- tapa invisible: el piso queda así de hondo bajo el agua
	pierAngles: { number },
	pierStartRadius: number,
	pierLength: number,
	spawnAngle: number,
	spawnRadius: number,
	showcaseRadius: number, -- vitrinas de los trajes de pase, a los lados de la aparición
	showcaseSide: number, -- distancia al costado del eje de la aparición
	shopAngle: number,
	shopRadius: number,
	campAngle: number,
	campRadius: number,
	lighthouseAngle: number,
	lighthouseRadius: number,
	lighthouseBaseHeight: number,
	lighthouseMoundRadius: number,
	fishingBandInner: number, -- desde este radio se puede pescar (orilla y muelles)
	fishingBandOuter: number, -- hasta este radio (los muelles llegan a ~146)
	bridgeAngle: number,
	bridgeStartRadius: number,
	bridgeWidth: number,
	-- Cráter del gigante (radios medidos desde craterCenter).
	craterCenter: { number }, -- { x, z }
	craterLakeRadius: number,
	craterCliffRadius: number,
	craterRimOuter: number,
	craterBaseRadius: number,
	craterRimHeight: number,
	craterFloor: number, -- fondo del lago en el centro (ahí está la guarida del descanso)
	craterFlatRadius: number, -- radio del fondo plano
	craterShelfDepth: number, -- hondura de la plataforma clara junto al acantilado
	craterShelfWidth: number, -- ancho de esa plataforma
	craterWalkWidth: number, -- paseo plano desde el borde del acantilado
	craterPeakHeight: number, -- alto máximo de las montañas del anillo sobre el paseo
	pedestalTop: number,
	craterDeckHeight: number,
	restArenaRadius: number, -- guarida del descanso, en el fondo del lago
	restArenaTop: number, -- altura de su piso (se ve al vaciarse el volcán)
	boundaryCenter: { number },
	boundaryRadius: number,
	hills: { { number } }, -- { x, z, radio }
	shoreRocks: { { number } }, -- { x, z, radio }
}

local data = require(script.Parent.WorldLayoutData) :: any

local WorldLayout = table.freeze(data) :: WorldLayout

return WorldLayout
