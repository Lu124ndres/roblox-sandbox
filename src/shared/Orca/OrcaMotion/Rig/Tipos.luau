--!strict
--[[
	OrcaMotion/Rig/Tipos

	Los tipos del rig de la orca, aparte para que los usen todas sus partes
	(Rig los vuelve a exportar).
]]

local Resorte = require(script.Parent.Parent.Parent.Parent.Resorte)

export type Axes = { pitch: Vector3, yaw: Vector3, roll: Vector3, side: number }
export type Rig = {
	bones: { [string]: Bone },
	axes: { [string]: Axes },
	center: number, -- alto del hueso Raiz sobre la base, en altos del modelo
	springs: { [string]: Resorte.Resorte },
	v2: boolean, -- Raiz > Pecho > Cola1..Cola5 (la Orca fantasma es el modelo viejo)
	-- Lo que sigue solo lo usa el v2:
	at: { [string]: number }, -- dónde está cada junta de la columna (0 = nariz, 1 = punta de la cola)
	back: { [string]: boolean }, -- huesos que apuntan hacia atrás (Cola, AletaCola)
	rollSign: { [string]: number }, -- pectorales: el roll va con el signo del lado
	written: { [string]: Vector3 }, -- último pitch, yaw y roll escrito (para no escribir de más)
	chain: { pitch: { number }, yaw: { number } }, -- ángulos de Cola1..Cola5 de este cuadro
}
export type Pose = {
	phase: number, -- fase del aleteo (rad)
	effort: number, -- 0..2: qué tan fuerte aletea
	turn: number, -- rad/s del giro (+ = a la izquierda)
	jaw: number, -- 0 cerrada .. 1.2 muy abierta
	fins: number, -- + pegadas abajo, - abiertas
	flap: number, -- aleteo de las pectorales
	head: number, -- cabeza arriba (rad)
	tail: number, -- curva extra de la cola (+ = aletas arriba)
	pitchSpeed: number?, -- rad/s del cabeceo del cuerpo (las aletas lo siguen tarde)
	rollSpeed: number?, -- rad/s del alabeo (la dorsal se mece)
	waveIzq: number?, -- extra de una sola aleta pectoral (saludar; - = arriba)
	waveDer: number?, -- la del lado +X del modelo (la que sube al alabear positivo)
	-- Campos nuevos (contrato, sección 4); el modelo viejo los toma de forma sencilla.
	arch: number?, -- curva de la columna en pitch (rad totales): + = lomo arriba, cola abajo
	flukes: number?, -- pitch extra de las aletas de la cola (+ = punta arriba)
	bend: number?, -- curva lateral extra de la columna (rad totales, + = a la izquierda)
	finIzq: number?, -- extra de cada pectoral (+ = abajo)
	finDer: number?,
	blow: number?, -- 0..1: está soplando (el pecho se infla y la cabeza sube apenas)
	glide: number?, -- 0..1: planea (las aletas de la cola quietas, apenas arriba)
	tread: number?, -- 0..1: se sostiene casi vertical con aletazos cortos (al comer)
}

return {}
