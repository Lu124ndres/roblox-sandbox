--!strict
--[[
	IceShards

	Contornos de hielo partido para los témpanos (IceFloes): polígonos chuecos,
	alargados, con mordidas en escalón y alguna punta, nada de discos. Cada
	contorno sale de un hash sin estado de (seed, k), así que es el mismo en
	todos los clientes y no depende del orden en que se arma lo demás.
		hash(seed, k)        un número en [0, 1) (seed y k enteros, >= 0)
		shape(seed, size, spec)
		                     corners: los vértices (Vector2 desde el centro, en
		                     orden antihorario, para IceParts.fan); whole: los
		                     mismos sin las mordidas (el hielo antes de partirse);
		                     bites: los ángulos de las mordidas. Con spec.floor, el
		                     borde nunca pasa a menos de size * floor del centro:
		                     esa parte (la que se pisa) queda siempre cubierta;
		                     con spec.limit, no pasa de ahí (IcePolygon.room).
		under(shape, seed, grow)
		                     el contorno de abajo (sin mordidas y más ancho)
	Las medidas de un contorno (inner, reach, edgeAt) y sus triángulos están en
	IcePolygon.
]]

local IcePolygon = require(script.Parent.IcePolygon)

local TAU = math.pi * 2
local TWO32 = 4294967296
local STEP = 0.12 -- parte del hueco que ocupa cada escalón de una mordida (casi radial)
local BITE_EDGE = 0.7 -- lo menos que salen los dos vértices que rodean una mordida
local BITE_IN = 0.92 -- hasta dónde entra una mordida (x low; con floor, nunca pasa de él)
local TIP_CHANCE = 0.6 -- probabilidad de una punta que sale hasta `high`

local IceShards = {}

export type Spec = {
	sides: number, -- vértices del contorno
	low: number, -- lo más adentro que queda un vértice, salvo las mordidas (x size)
	high: number, -- lo más afuera (x size)
	stretch: number, -- 0 redondo, 1 bien alargado a lo largo de un eje
	bites: number, -- mordidas: tramos que se partieron y entran hasta casi `low`
	floor: number?, -- radio que el borde deja cubierto (x size); nil: ninguno
	limit: ((angle: number) -> number)?, -- lo más lejos que puede llegar en cada dirección
}

export type Shape = { corners: { Vector2 }, whole: { Vector2 }, bites: { number } }

-- a * b mod 2^32 sin perder bits (los double guardan 53: se parte `a` en dos mitades).
local function mul(a: number, b: number): number
	local high, low = a // 65536, a % 65536
	return (low * b + (high * b % 65536) * 65536) % TWO32
end

function IceShards.hash(seed: number, k: number): number
	local x = bit32.bxor(mul(seed % TWO32, 0x9E3779B1), mul((k + 0x632BE5AB) % TWO32, 0x85EBCA77))
	x = mul(bit32.bxor(x, bit32.rshift(x, 15)), 0x2C1B3C6D)
	x = mul(bit32.bxor(x, bit32.rshift(x, 12)), 0x297A2D39)
	return bit32.bxor(x, bit32.rshift(x, 15)) / TWO32
end

-- Ángulos con huecos desparejos: lados largos y rectos (planos de fractura) junto a
-- vértices amontonados (bordes astillados). Ningún hueco llega a media vuelta.
local function angles(seed: number, n: number): { number }
	local gaps: { number }, total = {}, 0
	for k = 1, n do
		gaps[k] = 0.5 + IceShards.hash(seed, k) ^ 1.4
		total += gaps[k]
	end
	local list: { number }, a = {}, IceShards.hash(seed, 0) * TAU
	for k = 1, n + 1 do
		list[k] = a
		a += (gaps[k] or 0) / total * TAU
	end
	return list
end

local function open(_: number): number
	return math.huge
end

-- Donde un lado pasa por dentro de `need`, se empujan sus puntas afuera.
local function cover(corners: { Vector2 }, need: number)
	for _ = 1, 8 do
		local ok = true
		for k, p in corners do
			local nextK = k % #corners + 1
			local d = IcePolygon.gap(p, corners[nextK])
			if d < need then
				ok = false
				local push = need / d * 1.002
				corners[k], corners[nextK] = p * push, corners[nextK] * push
			end
		end
		if ok then
			return
		end
	end
end

function IceShards.shape(seed: number, size: number, spec: Spec): Shape
	local function h(k: number): number
		return IceShards.hash(seed, k)
	end
	local n, limit = spec.sides, spec.limit or open
	local list = angles(seed, n) -- n + 1: el último es el primero con una vuelta más
	-- Cuánto sale cada vértice (0 = low, 1 = high): un eje largo, un lado más
	-- gordo que el otro y ruido propio.
	local axis, fat = h(n + 1) * TAU, h(n + 2) * TAU
	local out: { number } = {}
	for k = 1, n do
		local a = list[k]
		local long = math.cos(a - axis) ^ 2
		local lop = 0.5 + 0.5 * math.cos(a - fat)
		out[k] = (spec.stretch * long + 0.25 * lop + 0.6 * h(n + 2 + k)) / (spec.stretch + 0.85)
	end
	if h(3 * n) < TIP_CHANCE then
		out[1 + math.floor(h(3 * n + 1) * n)] = 1
	end
	-- Mordidas repartidas: en el hueco entre dos vértices que salen, dos vértices
	-- nuevos que entran hasta low, pegados a ellos (el corte queda en escalón).
	local bitten: { [number]: boolean } = {}
	local first = math.floor(h(4 * n) * n)
	for b = 1, spec.bites do
		local k = (first + math.floor((b - 1) * n / spec.bites + h(7 * n + b) * 1.5)) % n + 1
		bitten[k] = true
		out[k], out[k % n + 1] = math.max(out[k], BITE_EDGE), math.max(out[k % n + 1], BITE_EDGE)
	end
	local corners: { Vector2 }, whole: { Vector2 }, bites: { number } = {}, {}, {}
	for k = 1, n do
		local r = math.min(size * (spec.low + (spec.high - spec.low) * out[k]), limit(list[k]))
		local p = Vector2.new(math.cos(list[k]), math.sin(list[k])) * r
		table.insert(corners, p)
		table.insert(whole, p)
		if bitten[k] then
			local a, span = list[k], list[k + 1] - list[k]
			for m, f in { STEP, 1 - STEP } do
				local cut = a + span * f
				local inside = size * spec.low * (BITE_IN + 0.04 * h((4 + m) * n + k))
				table.insert(
					corners,
					Vector2.new(math.cos(cut), math.sin(cut)) * math.min(inside, limit(cut))
				)
			end
			table.insert(bites, a + span / 2)
		end
	end
	if spec.floor then
		cover(corners, size * spec.floor)
	end
	return { corners = corners, whole = whole, bites = bites }
end

-- El hielo de abajo, que no se partió: `whole` (sin mordidas), cada vértice un poco
-- más afuera (entre grow.Min y grow.Max). Se ve como repisa donde arriba falta hielo.
function IceShards.under(shape: Shape, seed: number, grow: NumberRange): { Vector2 }
	local list: { Vector2 } = {}
	for k, p in shape.whole do
		list[k] = p * (grow.Min + (grow.Max - grow.Min) * IceShards.hash(seed, k))
	end
	return list
end

return table.freeze(IceShards)
