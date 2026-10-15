--!strict
--[[
	OrcaMotion/Tricks

	Las piruetas de la orca. Un truco dura `seconds` y, para su avance u (0..1),
	da la pose que reemplaza al nado normal; el motor (OrcaMotion) la mezcla al
	entrar y al salir, así nunca hay saltos bruscos. Alturas en altos del
	modelo (sobre el agua, negativo = hundida), ángulos en radianes.
	`events` dispara sonidos y efectos (OrcaFx) en un momento del truco.

	Los trucos están en Jumps (saltos, saltitos, zambullida), Surface (coletazo,
	aletazo, giro, persecución de cola) y Show (asomarse, rugido, emerger).
	Cada etapa (Etapas) elige cuáles hace, cada cuánto y con qué fuerza.
]]

export type Pose = {
	depth: number?, -- centro del cuerpo sobre el agua (altos del modelo)
	pitch: number?, -- + = nariz arriba
	roll: number?, -- giro sobre su eje largo
	yaw: number?, -- desvío del rumbo
	tail: number?, -- curva extra de la cola (+ = aletas de la cola arriba)
	head: number?, -- cabeza arriba
	jaw: number?, -- 0..1
	fins: number?, -- + aletas pegadas abajo, - abiertas
	effort: number?, -- multiplica el aleteo
	speed: number?, -- multiplica la velocidad de crucero
	air: boolean?, -- en el aire: sigue la parábola sin suavizar
}
export type Event = {
	at: number, -- avance del truco (0..1)
	kind: string, -- "call", "roar", "slap", "spout", "splash", "cascade"
	where: string?, -- "tail", "fin", "mouth" o el cuerpo
}
export type Trick = {
	name: string,
	seconds: number,
	pose: (u: number, from: number) -> Pose, -- from: altura de crucero al empezar
	events: { Event },
}

local Tricks = {}

function Tricks.clamp01(t: number): number
	return math.clamp(t, 0, 1)
end

-- Curva suave 0..1 (empieza y termina sin velocidad).
function Tricks.smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Avance de u dentro del tramo [a, b] (0 antes, 1 después).
function Tricks.span(u: number, a: number, b: number): number
	return math.clamp((u - a) / (b - a), 0, 1)
end

-- Sube y baja suave: 0 en los extremos, 1 en el medio.
function Tricks.bell(t: number): number
	t = math.clamp(t, 0, 1)
	return 0.5 - 0.5 * math.cos(2 * math.pi * t)
end

-- Un giro de `turns` vueltas visto como ángulo entre -pi y pi (para volver derecha).
function Tricks.wrap(angle: number): number
	return (angle + math.pi) % (2 * math.pi) - math.pi
end

return table.freeze(Tricks)
