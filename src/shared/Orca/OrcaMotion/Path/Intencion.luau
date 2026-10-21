--!strict
--[[
	OrcaMotion/Path/Intencion

	Qué ganas tiene la orca ahora (como un animal, no como un bucle): cada tanto elige
	al azar (hash sin estado) una de estas y un lugar del lago al que ir.
		cruce     cruza el lago hasta un punto lejano, rápido;
		orilla    patrulla cerca de la orilla, de un punto al siguiente;
		paseo     da una vuelta corta y tranquila por ahí cerca;
		descanso  frena y flota quieta en la superficie, de costado a la rampa.
	Nunca descansa dos veces seguidas. Cada época empieza flotando en un punto fijo
	(`anchor`), del lado de la rampa.
]]

local Rumbo = require(script.Parent.Rumbo)

local rnd = Rumbo.rnd

export type Mode = {
	name: string,
	weight: number,
	lo: number, -- velocidad planeando (veces el crucero)
	hi: number, -- y con aletazos
}

local MODES: { Mode } = {
	{ name = "cruce", weight = 3, lo = 0.9, hi = 1.3 },
	{ name = "orilla", weight = 2.5, lo = 0.75, hi = 1 },
	{ name = "paseo", weight = 2, lo = 0.5, hi = 0.8 },
	{ name = "descanso", weight = 1.2, lo = 0, hi = 0 },
}
local FAR = 0.7 -- radios: un cruce va al menos así de lejos (si encuentra)
local CROSS_TRIES = 4
local HOP = { 0.7, 0.4 } -- rad: cuánto avanza por la orilla en cada punto (mínimo, extra)
local STROLL = { 0.25, 0.25 } -- radios: largo de un paseo (mínimo, extra)
local INSIDE = 0.05 -- radios: los puntos de la orilla quedan así de adentro de la cómoda
local ANCHOR_SPREAD = 1.4 -- rad: abanico de los puntos de comienzo, frente a la rampa
local ANCHOR_RADIUS = { 0.25, 0.3 } -- radios (mínimo, extra)
local SIDE = 0.9 -- al flotar: qué tan de costado a la rampa queda (1 = justo de costado)

local Intencion = {}

Intencion.SIDE = SIDE

function Intencion.mode(name: string): Mode
	for _, mode in MODES do
		if mode.name == name then
			return mode
		end
	end
	return MODES[1]
end

function Intencion.pick(epoch: number, i: number, prev: string): string
	local total = 0
	for _, mode in MODES do
		if not (mode.name == "descanso" and prev == "descanso") then
			total += mode.weight
		end
	end
	local x = rnd(epoch, i, 14, 0) * total
	for _, mode in MODES do
		if not (mode.name == "descanso" and prev == "descanso") then
			x -= mode.weight
			if x <= 0 then
				return mode.name
			end
		end
	end
	return MODES[1].name
end

-- Lugar al que va con esa intención, desde (x, z).
function Intencion.target(
	epoch: number,
	i: number,
	mode: string,
	x: number,
	z: number
): (number, number)
	local function h(field: number): number
		return rnd(epoch, i, 13, field)
	end
	if mode == "cruce" then
		local bx, bz, far = x, z, -1
		for k = 0, CROSS_TRIES - 1 do
			local a, r = 2 * math.pi * h(2 * k), math.sqrt(h(2 * k + 1))
			local wx, wz = Rumbo.inside(r * math.cos(a), r * math.sin(a))
			local dx, dz = wx - x, wz - z
			local d = math.sqrt(dx * dx + dz * dz)
			if d >= FAR then
				return wx, wz
			end
			if d > far then
				bx, bz, far = wx, wz, d
			end
		end
		return bx, bz
	elseif mode == "orilla" then
		local a = math.atan2(z, x) + (if h(8) < 0.5 then 1 else -1) * (HOP[1] + HOP[2] * h(9))
		local wx, wz = math.cos(a), math.sin(a)
		local k = Rumbo.soft(wx, wz) - INSIDE
		return wx * k, wz * k
	end
	local a, d = 2 * math.pi * h(10), STROLL[1] + STROLL[2] * h(11)
	return Rumbo.inside(x + d * math.cos(a), z + d * math.sin(a))
end

-- Dónde y con qué rumbo flota la orca al empezar la época.
function Intencion.anchor(epoch: number): (number, number, number)
	local a = Rumbo.DOOR_ANGLE + (rnd(epoch, 0, 15, 0) - 0.5) * ANCHOR_SPREAD
	local r = ANCHOR_RADIUS[1] + ANCHOR_RADIUS[2] * rnd(epoch, 0, 15, 1)
	local x, z = r * math.cos(a), r * math.sin(a)
	local side = SIDE * (if rnd(epoch, 0, 15, 2) < 0.5 then math.pi / 2 else -math.pi / 2)
	local g = Rumbo.frame(x, z)
	return x, z, g + side
end

return table.freeze(Intencion)
