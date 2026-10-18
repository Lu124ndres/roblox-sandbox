--!strict
--[[
	Zorro/Tipos

	Los contratos entre los sistemas del zorro (docs/plan_zorro_v2.md, "Ola 3").
	Todos hablan por la pose: una tabla de números que se suman (Zorro/Pose) y que
	después escriben en los huesos un solo dueño por hueso:
		Pose.apply (Zorro/Pose)   tronco, cuello, cabeza, mandíbula y orejas
		Patas.apply (Zorro/Patas) Hombro..Mano y Muslo..Pie de las cuatro patas
		Cara.apply (Zorro/Cara)   Parpado{l} y OrejaPunta{l}, solo con detalle
		Colas (Zorro/Colas)       Cola*_*, con lo que piden las claves tail*
	Nadie más escribe Bone.Transform.

	Una conducta (Zorro/Conductas) es lo que hace cuando nadie le da de comer:
	sentarse, rascarse, aullar... La elige Zorro/Rutina con su peso por etapa y la
	reproduce de u = 0 a 1; su pose se suma a la de reposo.
]]

-- Igual que Pose.Pose (no se requiere Pose: Pose usa Cara, que usa este módulo).
export type Pose = { [string]: number }

export type Evento = { at: number, kind: string }

export type Conducta = {
	nombre: string,
	tipo: "postura" | "truco", -- truco: de lucirse, siempre de frente a la rampa
	pesos: { number }, -- peso por etapa (1..4); 0 = esa etapa no la hace
	duracion: (etapa: number, r: number) -> number, -- segundos; r: azar 0..1 (Zorro/Azar)
	pose: (u: number, etapa: number, r: number) -> Pose, -- u: 0..1 de la conducta
	eventos: { Evento }, -- kind de ZorroVoces/ZorroEventos: yip, yawn, sniff, pounce...
	quieto: boolean?, -- true: se hace parado en un lugar (no mientras camina)
}

-- Lo que reciben Mirada y Cara cada cuadro.
export type Contexto = {
	now: number, -- hora del servidor
	dt: number,
	etapa: number, -- 1..4
	height: number, -- alto del zorro en studs
	center: Vector3, -- base del zorro en el mundo
	heading: number, -- rumbo del cuerpo (Angles(0, heading, 0) mira a -Z)
	lookAt: Vector3?, -- el jugador de este cliente, si está cerca (solo cosmético)
	detail: boolean, -- cámara cerca y sin modo rápido
}

return {}
