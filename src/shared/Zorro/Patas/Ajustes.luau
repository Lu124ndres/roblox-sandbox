--!strict
--[[
	Zorro/Patas/Ajustes

	Los números del cuerpo y las patas, medidos con las piezas de cada etapa en
	tools/blender/zorro_v2_poses.py (que repite esta cuenta en zorro_v2_poses_cuerpo.py):
	cada pose nueva (sentado, echado, enroscado, rascarse, lamerse, estirarse, el paso,
	la picada) queda sin piezas que se atraviesen y con los pies en el piso.
	Las distancias van en fracciones del alto (o del largo de la pata) y los ángulos en
	radianes. Lo común está arriba; lo que cambia con las proporciones, en `etapas`.
]]

export type Etapa = {
	sitDrop: number, -- sentado: cuánto baja la base (fracción del alto)
	lieDrop: number, -- echado: la panza queda sobre las patas plegadas
	walkLift: { number }, -- cuánto se levanta al caminar la delantera y la trasera (como step)
	sitPaw: number, -- sentado: las traseras pisan este tanto (del largo de la pata) adelante
	sitFront: number, -- sentado: las manos, este tanto (del largo del brazo) delante de la vertical
	liePaw: number, -- echado: las traseras, bajo la rodilla
	lieReach: number, -- echado: las manos, delante del hombro
	bowReach: number, -- reverencia: las manos van adelante (los antebrazos se apoyan)
	bowWrist: number, -- reverencia: la mano sigue este tanto al antebrazo
	bowMax: number, -- tope de bow (la E4 mete los antebrazos en el pecho pasando 0.6)
	curlHead: { number }, -- enroscado: la cabeza gira (hacia curlSide) y baja
	scratchLeg: { number }, -- rascarse: Muslo (cabeceo, alabeo afuera), Pierna, Tobillo, Pie
	scratchHead: { number }, -- rascarse: la cabeza gira, cabecea y se ladea hacia la pata
	pawStand: { number }, -- lamerse parado: Hombro, Brazo, Antebrazo, Mano, alabeo del brazo
	pawSit: { number }, -- lamerse sentado: lo mismo
	pawHeadStand: { number }, -- lamerse parado: la cabeza gira hacia la pata y baja
	pawHeadSit: { number },
	pawHunch: number, -- lamerse sentado: el pecho se encorva hacia la pata
	pawSitMax: number, -- tope de pawL/pawR sentado (más, el antebrazo entra en el pecho)
	foldPow: number, -- la trasera a medio plegar (agacharse, caminar) lleva el muslo menos adelante
}

-- En la E1 la trasera no llega a la oreja: rasca el costado del cuello, con la cabeza
-- girada hacia la pata (el ladeo topa en 0.12: más, el cuello entra en el pecho).
local ETAPAS: { Etapa } = {
	{
		sitDrop = 0.072,
		lieDrop = 0.092,
		walkLift = { 0.8, 0.3 },
		sitPaw = 1,
		sitFront = 0.125,
		liePaw = 0.966,
		lieReach = 1.222,
		bowReach = 0.084,
		bowWrist = 0.05,
		bowMax = 1.2,
		curlHead = { 1.8, -0.115 },
		scratchLeg = { 1.11, 0.777, -0.4, 1.314, -0.834 },
		scratchHead = { 0.25, 0.4, 0.12 },
		pawStand = { 0.45, 0.9, -0.6, -0.45, 0.2 },
		pawSit = { 0.215, 0.975, -0.103, -0.6, 0.17 },
		pawHeadStand = { 0.138, -0.45 },
		pawHeadSit = { 0.184, -0.15 },
		pawHunch = 0.27,
		pawSitMax = 1.0,
		foldPow = 2,
	},
	{
		sitDrop = 0.16,
		lieDrop = 0.159,
		walkLift = { 0.8, 0.6 },
		sitPaw = 0.63,
		sitFront = 0.318,
		liePaw = 0.808,
		lieReach = 1.042,
		bowReach = 0.509,
		bowWrist = 0,
		bowMax = 1.2,
		curlHead = { 1.8, -0.732 },
		scratchLeg = { 1.199, 0.918, 0.25, 1.343, -1.269 },
		scratchHead = { 0.186, 0.3, 0.3 },
		pawStand = { 0.2, 1.1, 0.113, 0.35, 0.475 },
		pawSit = { 0.215, 1.016, 0.3, 0.275, 0.384 },
		pawHeadStand = { -0.1, -0.613 },
		pawHeadSit = { -0.012, -0.197 },
		pawHunch = 0.196,
		pawSitMax = 1.0,
		foldPow = 1,
	},
	{
		sitDrop = 0.16,
		lieDrop = 0.161,
		walkLift = { 0.8, 0.6 },
		sitPaw = 0.7,
		sitFront = 0.103,
		liePaw = 0.85,
		lieReach = 0.89,
		bowReach = 0.4,
		bowWrist = 0.042,
		bowMax = 1.2,
		curlHead = { 1.8, -0.42 },
		scratchLeg = { 1.11, 0.66, 0.25, 1.07, -0.9 },
		scratchHead = { 0.337, 0.3, 0.35 },
		pawStand = { 0.7, 1.3, -1, 0.5, 0.275 },
		pawSit = { 0.54, 1.3, -0.89, 0.65, 0.29 },
		pawHeadStand = { 0.137, -0.401 },
		pawHeadSit = { 0.1, 0.038 },
		pawHunch = 0,
		pawSitMax = 0.6,
		foldPow = 1,
	},
	{
		sitDrop = 0.13,
		lieDrop = 0.092,
		walkLift = { 0.8, 0.6 },
		sitPaw = 0.9,
		sitFront = 0.179,
		liePaw = 0.762,
		lieReach = 0.538,
		bowReach = 0.6,
		bowWrist = 0,
		bowMax = 0.6,
		curlHead = { 1.8, -0.522 },
		scratchLeg = { 1.555, 0.941, -0.4, 1.656, -1.277 },
		scratchHead = { 0.381, 0.3, 0.35 },
		pawStand = { 0.45, 1.381, -0.6, 0.45, 0.219 },
		pawSit = { 0.215, 1.6, -0.949, 0.7, 0.234 },
		pawHeadStand = { 0.231, -0.37 },
		pawHeadSit = { 0.231, -0.306 },
		pawHunch = 0.372,
		pawSitMax = 0.55,
		foldPow = 1,
	},
}

local function etapa(n: number): Etapa
	return ETAPAS[math.clamp(math.floor(n + 0.5), 1, 4)]
end

local Ajustes = {
	etapas = ETAPAS,
	etapa = etapa, -- etapa(n): los números de esa etapa (1..4)
	SETTLE = 0.006, -- la base baja siempre un poco: las patas quedan apenas dobladas, no flotan
	STRETCH_DROP = 0.02, -- estirarse: cuánto baja la base
	WALK_DROP = 0.012, -- caminando va un poco más bajo: la pata llega adelante y atrás
	BOB = 0.004, -- y baja un poco más con cada mano que pisa (dos veces por ciclo)
	SIT = { 0.45, 0.05, 0.2 }, -- sentado: cabeceo de Cadera, Columna y Pecho
	HEAD_LEVEL = 0.8, -- el cuello endereza este tanto de lo que el tronco se levanta
	SPINE_MAX = 0.25, -- giro de lado de Columna y Pecho (limpio hasta 0.258)
	CURL_SPINE = 0.3, -- enroscado: fracción de SPINE_MAX que curva el lomo
	STRETCH_TRUNK = { 0, -0.12, 0.1 }, -- estirarse: cabeceo de Cadera, Columna y Pecho
	DUTY = 0.7, -- fracción del paso con la pata apoyada
	GAIT = { HIzq = 0, FIzq = 0.25, HDer = 0.5, FDer = 0.75 }, -- secuencia lateral del paso
	LIFT_U = 0.14, -- levantar la delantera: la muñeca sube (del largo del brazo)...
	LIFT_CURL = -0.35, -- ...y la mano se dobla
	LIFT_UH = 0.12, -- levantar la trasera: el pie sube (del largo de la pata)...
	LIFT_CURL_H = -0.5, -- ...y se dobla
	FOLD_BETA = 1.45, -- muslo adelante (sobre la línea cadera-pie) con la pata plegada
	FOLD_RANGE = 0.45, -- plegada del todo cuando la cadera baja este tanto del largo
	STRETCH_BETA = 0.4, -- estirarse: el muslo, más atrás
	STRETCH_BACK = 0.25, -- estirarse: los pies de atrás, hacia atrás (del largo de la pata)
	LIE_WRIST = 0.8, -- echado: la mano sigue este tanto al antebrazo
	SIT_SHOULDER = -0.42, -- sentado: el omóplato vuelve este tanto de lo que sube el tronco
	POUNCE_IN = 0.05, -- en el aire, las manos se juntan (alabeo del brazo)
	POUNCE_F = { 0, 0.75, 0, -0.08 }, -- en el aire: Hombro, Brazo, Antebrazo, Mano
	POUNCE_H = { -0.25, 0.3, 0, -0.4 }, -- Muslo, Pierna, Tobillo, Pie
	SCRATCH_BEAT = { 0.25, -0.2 }, -- el latido del rascado en Pierna y Tobillo
}

return table.freeze(Ajustes)
