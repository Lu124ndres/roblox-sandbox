--!strict
--[[
	OrcaMotion/Comer/Gestos

	Los gestos chicos de la orca al comer. Se SUMAN a su pose de comer (no la
	reemplazan) y pasan por resortes (Comer), así se encadenan y se mezclan
	sin saltos aunque lleguen peces cada 0.2 s:
		bocado    con cada pez: estira la cabeza hacia arriba fuera del agua,
		          cierra la boca de golpe y traga (la cabeza baja un poco)
		panza     se gira de costado mostrando la panza y la aleta de arriba
		          saluda; al volver da un coletazo chico
		saludo    se ladea y saluda con la aleta pectoral (tres veces)
		chorro    se hunde apenas (anticipación), sube el lomo y echa un chorro
		          alegre por el espiráculo, meneándose
		coletazo  baja la cabeza, levanta la cola despacio y la azota
		tragar    traga despacio: la cabeza cabecea con la boca cerrada
	`side` (+1 o -1) es hacia qué lado se gira: con +1 sube la aleta derecha.
	Ángulos en radianes, alturas en altos del modelo. Duraciones de la adulta
	(cada etapa las estira o acorta con su tempo).
]]

local Tricks = require(script.Parent.Parent.Tricks)

local smooth, span, bell = Tricks.smooth, Tricks.span, Tricks.bell

export type Add = {
	depth: number,
	pitch: number,
	roll: number,
	yaw: number,
	head: number,
	jaw: number,
	fins: number, -- + pegadas abajo, - abiertas
	tail: number,
	waveIzq: number, -- aleta pectoral izquierda que saluda (- = arriba)
	waveDer: number,
}
export type Gesture = {
	name: string,
	seconds: number,
	events: { Tricks.Event },
	pose: (u: number, side: number, roll: number) -> Add,
}

local Gestos = {}

function Gestos.zero(): Add
	return {
		depth = 0,
		pitch = 0,
		roll = 0,
		yaw = 0,
		head = 0,
		jaw = 0,
		fins = 0,
		tail = 0,
		waveIzq = 0,
		waveDer = 0,
	}
end

-- Sube en [a, b], se queda y baja en [c, d].
local function hold(u: number, a: number, b: number, c: number, d: number): number
	return smooth(span(u, a, b)) * (1 - smooth(span(u, c, d)))
end

-- La aleta de arriba (la del lado al que se gira) saluda con `amount`.
local function wave(add: Add, side: number, amount: number)
	if side > 0 then
		add.waveDer = amount
	else
		add.waveIzq = amount
	end
end

-- Azote de cola dentro de f (0..1): sube lento, baja de golpe y rebota.
local function lash(f: number): number
	return smooth(span(f, 0, 0.62))
		- 1.3 * smooth(span(f, 0.62, 0.78))
		+ 0.3 * smooth(span(f, 0.78, 1))
end

local LIST: { Gesture } = {
	{
		name = "bocado",
		seconds = 0.6,
		events = {},
		pose = function(u: number, side: number, _roll: number): Add
			local strike = hold(u, 0, 0.16, 0.3, 0.75)
			local swallow = bell(span(u, 0.45, 1))
			local add = Gestos.zero()
			add.pitch = 0.2 * strike - 0.05 * swallow
			add.head = 0.2 * strike - 0.09 * swallow
			add.depth = 0.045 * strike
			add.jaw = -0.25 * swallow
			add.yaw = side * 0.07 * strike
			add.fins = -0.12 * strike
			add.tail = 0.12 * bell(span(u, 0.2, 0.8)) -- la cola sigue tarde
			return add
		end,
	},
	{
		name = "panza",
		seconds = 2,
		events = { { at = 0.32, kind = "belly" }, { at = 0.88, kind = "splash" } },
		pose = function(u: number, side: number, roll: number): Add
			local turned = hold(u, 0.05, 0.35, 0.68, 0.95)
			local add = Gestos.zero()
			add.roll = side * 1.25 * roll * turned
			add.pitch = 0.08 * bell(u)
			add.depth = 0.03 * turned
			add.fins = -0.25 * turned
			add.tail = 0.25 * bell(span(u, 0.72, 1))
			local beat = 0.5 + 0.5 * math.sin(math.pi * 4 * span(u, 0.3, 0.7))
			wave(add, side, -0.55 * turned * beat)
			return add
		end,
	},
	{
		name = "saludo",
		seconds = 1.9,
		events = { { at = 0.12, kind = "clicks" }, { at = 0.45, kind = "wave" } },
		pose = function(u: number, side: number, roll: number): Add
			local tilt = hold(u, 0, 0.22, 0.75, 1)
			local add = Gestos.zero()
			add.roll = side * 0.42 * roll * tilt
			add.head = 0.08 * tilt
			add.pitch = 0.05 * tilt
			local beat = math.sin(math.pi * 6 * span(u, 0.2, 0.8))
			wave(add, side, -(0.45 + 0.4 * beat) * tilt)
			return add
		end,
	},
	{
		name = "chorro",
		seconds = 1.7,
		events = { { at = 0.42, kind = "happySpout" } },
		pose = function(u: number, side: number, roll: number): Add
			local dip = bell(span(u, 0, 0.3))
			local up = hold(u, 0.25, 0.42, 0.6, 0.95)
			local add = Gestos.zero()
			add.depth = -0.035 * dip + 0.05 * up
			add.pitch = -0.05 * dip - 0.12 * up -- baja la nariz: el espiráculo queda arriba
			add.head = 0.1 * up
			add.roll = side * 0.12 * roll * math.sin(math.pi * 4 * span(u, 0.45, 1)) * up
			add.tail = 0.2 * up
			return add
		end,
	},
	{
		name = "coletazo",
		seconds = 1.6,
		events = { { at = 0.7, kind = "flick", where = "tail" } },
		pose = function(u: number, _side: number, _roll: number): Add
			local bend = hold(u, 0, 0.25, 0.8, 1)
			local add = Gestos.zero()
			add.pitch = -0.22 * bend
			add.depth = -0.02 * bend
			add.head = -0.05 * bend
			add.fins = -0.2 * bend
			add.tail = 0.95 * lash(span(u, 0.1, 0.95)) * bend
			return add
		end,
	},
	{
		name = "tragar",
		seconds = 0.95,
		events = { { at = 0.25, kind = "gulp" } },
		pose = function(u: number, _side: number, _roll: number): Add
			local add = Gestos.zero()
			add.head = -0.13 * bell(span(u, 0.1, 0.8))
			add.pitch = -0.05 * bell(u)
			add.jaw = -0.15 * bell(u)
			add.depth = -0.015 * bell(u)
			return add
		end,
	},
}

local BY_NAME: { [string]: Gesture } = {}
for _, gesture in LIST do
	BY_NAME[gesture.name] = gesture
end
Gestos.byName = table.freeze(BY_NAME)

return table.freeze(Gestos)
