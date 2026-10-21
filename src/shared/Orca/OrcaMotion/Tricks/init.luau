--!strict
--[[
	OrcaMotion/Tricks

	Las piruetas de la orca. Un truco dura `seconds` y, para su avance u (0..1),
	da la pose que reemplaza al nado normal; el motor (OrcaMotion) la mezcla al
	entrar y al salir, así nunca hay saltos bruscos. Alturas en altos del
	modelo (sobre el agua, negativo = hundida), ángulos en radianes.
	`events` dispara sonidos y efectos (OrcaFx) en un momento del truco.

	Están sacados de cómo lo hacen las orcas y las ballenas de verdad, con
	anticipación, golpe y recuperación, y con física que se lee: en el aire el
	centro sigue una parábola con la gravedad de su tamaño (Talla).
		Jumps    salto completo (Salto), saltitos (Saltitos) y zambullida con
		         la cola afuera (Zambullida)
		Surface  coletazo, aletazo y descansar flotando
		Show     asomarse, rugido y emerger
	Respirar es el gesto de soplar; Tramos arma un truco por tramos de tiempo y
	Agenda elige qué truco toca y cuándo. Cada etapa (Etapas) elige cuáles hace,
	cada cuánto y con qué fuerza.
]]

export type Pose = {
	depth: number?, -- centro del cuerpo sobre el agua (altos del modelo)
	pitch: number?, -- + = nariz arriba
	roll: number?, -- giro sobre su eje largo (+ = sube el costado derecho, +X)
	yaw: number?, -- desvío del rumbo (+ = a la izquierda)
	tail: number?, -- curva extra de la cola (+ = aletas de la cola arriba)
	head: number?, -- cabeza arriba
	jaw: number?, -- 0..1
	fins: number?, -- + aletas pegadas abajo, - abiertas
	effort: number?, -- multiplica el aleteo
	speed: number?, -- multiplica la velocidad de crucero
	air: boolean?, -- sigue la curva exacta del truco, sin resorte (en el aire o al tomar impulso)
	-- Del contrato del rig (los aplica el cuerpo: Rig y Body).
	arch: number?, -- curva de la columna en pitch (+ = lomo arqueado, - = panza arqueada)
	flukes: number?, -- pitch extra de las aletas de la cola (+ = la punta arriba)
	bend: number?, -- curva lateral extra de la columna (+ = a la izquierda)
	fin: { izq: number?, der: number? }?, -- cada pectoral, sumado (+ = abajo)
	blow: boolean?, -- está soplando por el espiráculo
	-- De los trucos (los lee Schedule y OrcaFx).
	face: number?, -- 0..1: cuánto gira el cuerpo hacia la rampa
	flank: boolean?, -- con face: le muestra el costado en vez de la cara
	splash: number?, -- tamaño de la salpicadura al cruzar el agua (0 limpia, 1 normal, 2.5 una ola)
	beat: number?, -- aletazos por segundo que pide la pose (Comer: los que la sostienen asomada)
}
export type Event = {
	at: number, -- avance del truco (0..1)
	kind: string, -- "call", "roar", "slap", "spout", "splash", "cascade"
	where: string?, -- "tail", "fin", "mouth" o el cuerpo
	size: number?, -- fuerza del efecto (1 = normal)
}
export type Trick = {
	name: string,
	seconds: number,
	-- from: altura de crucero al empezar; seed: azar del truco (0..1, el mismo en
	-- todos los clientes) para el lado, la fuerza y la asimetría.
	pose: (u: number, from: number, seed: number?) -> Pose,
	events: { Event },
	vary: number?, -- la duración cambia con el azar: 0.15 = ±15 % (0 en los de física)
	show: number?, -- avance en que se luce: ahí no le da la espalda a la rampa
	deep: number?, -- hasta dónde baja el cuerpo (altos bajo el agua): se elige dónde hay fondo
	marks: { [string]: number }?, -- avance de sus momentos (salida, caida, soplo...)
}
-- El tamaño de la etapa, para que la física y el ritmo sean los de su cuerpo.
export type Talla = {
	half: number, -- del centro al hocico (altos)
	gravity: number, -- altos/s²: la misma en studs; las grandes caen más lento a la vista
	ahead: number, -- velocidad de crucero (altos/s): inclina la nariz con la trayectoria
	pace: number, -- ritmo de los gestos lentos (1 = la adulta; raíz del tamaño)
}

-- studs/s²: más que la real a esta escala (~35) y menos que la de Roblox (196): se nota y pesa.
local GRAVITY = 50
local PACE_HEIGHT = 82.5 -- alto de la adulta (studs): ritmo 1

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

function Tricks.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Curva de Hermite en t (0..1): de p0 a p1 con pendientes m0 y m1 (por tramo entero).
-- Sirve para empalmar tramos con la misma velocidad (caer al agua, tomar impulso).
function Tricks.hermite(t: number, p0: number, m0: number, p1: number, m1: number): number
	t = math.clamp(t, 0, 1)
	local t2, t3 = t * t, t * t * t
	return (2 * t3 - 3 * t2 + 1) * p0
		+ (t3 - 2 * t2 + t) * m0
		+ (-2 * t3 + 3 * t2) * p1
		+ (t3 - t2) * m1
end

-- Valor del nodo i de una curva por nodos (first reemplaza el primero: la altura de crucero).
local function knot(keys: { number }, first: number?, i: number): number
	return if i == 1 and first then first else keys[2 * i]
end

-- Pendiente en el nodo i (monótona, como PCHIP): 0 en los extremos y donde la curva da vuelta.
local function slope(keys: { number }, first: number?, i: number, n: number): number
	if i == 1 or i == n then
		return 0
	end
	local h0, h1 = keys[2 * i - 1] - keys[2 * i - 3], keys[2 * i + 1] - keys[2 * i - 1]
	local d0 = (knot(keys, first, i) - knot(keys, first, i - 1)) / h0
	local d1 = (knot(keys, first, i + 1) - knot(keys, first, i)) / h1
	if d0 * d1 <= 0 then
		return 0
	end
	local w1, w2 = 2 * h1 + h0, h1 + 2 * h0
	return (w1 + w2) / (w1 / d0 + w2 / d1)
end

-- Curva suave que pasa por los nodos { t1, v1, t2, v2, ... } sin pararse en los del
-- medio (un gesto que fluye) y sin pasarse de ellos; empieza y termina quieta.
function Tricks.curve(t: number, keys: { number }, first: number?): number
	local n = #keys // 2
	if t <= keys[1] then
		return knot(keys, first, 1)
	elseif t >= keys[2 * n - 1] then
		return knot(keys, first, n)
	end
	local i = 1
	while keys[2 * i + 1] < t do
		i += 1
	end
	local t0, h = keys[2 * i - 1], keys[2 * i + 1] - keys[2 * i - 1]
	local m0, m1 = slope(keys, first, i, n) * h, slope(keys, first, i + 1, n) * h
	return Tricks.hermite((t - t0) / h, knot(keys, first, i), m0, knot(keys, first, i + 1), m1)
end

-- Azar sin estado: el mismo número en todos los clientes.
function Tricks.hash(n: number): number
	local x = math.sin(n * 12.9898 + 78.233) * 43758.5453
	return x - math.floor(x)
end

-- height: alto del modelo (studs); length: largo / alto; cruise: velocidad de crucero (studs/s).
function Tricks.talla(height: number, length: number, cruise: number): Talla
	return table.freeze({
		half = length / 2,
		gravity = GRAVITY / height,
		ahead = cruise / height,
		pace = math.sqrt(height / PACE_HEIGHT),
	})
end

-- La adulta: la que usan los trucos a los que no se les pasa talla (los festejos al comer).
Tricks.ADULTA = Tricks.talla(82.5, 64 / 31, 20.4)

return table.freeze(Tricks)
