--!strict
--[[
	IceFloes

	Los témpanos del lago del zorro (IceLair): hielo partido, con el contorno de
	IceShards (chueco, alargado, con mordidas y puntas, igual en todos los clientes).
		grandes  los de Zorro/Guarida (kind "tempano"): la cara de arriba justo en
		         Guarida.point(), el borde nunca más adentro que `size` (ahí se para
		         o se echa el zorro) ni más afuera que sus vecinos (room). Abajo, el
		         hielo que no se partió (IceShards.under) asoma como repisa en las
		         mordidas; chocan los dos. En cada mordida, trozos caídos, uno que
		         se fue flotando y una grieta; arriba, nieve.
		chicos   SMALL_COUNT sueltos que no chocan, de tamaños muy distintos (los
		         mordidos, con su escalón), sin pisar los grandes ni las rocas.
	Los arma una vez IceLair; IceLift los sube y los hunde con el lago.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guarida = require(ReplicatedStorage.Shared.Zorro.Guarida)
local IceMarks = require(script.Parent.IceMarks)
local IceParts = require(script.Parent.IceParts)
local IcePolygon = require(script.Parent.IcePolygon)
local IceShards = require(script.Parent.IceShards)
local LairParts = require(script.Parent.LairParts)

local I = IceParts
local M = IceMarks
local P = IcePolygon
local around = IcePolygon.around
local S = IceShards
local TAU = math.pi * 2
local WATER = Guarida.water
local BIG: IceShards.Spec = -- el borde, entre low y high (x size), nunca entra más que floor
	{ sides = 10, low = 1.12, high = 1.6, stretch = 0.9, bites = 3, floor = 1.02 }
local BIG_THICK = 2.4 -- lo que asoma (Guarida: 1.2) más lo que queda abajo
local ROOM_MARGIN = 4 -- studs que deja libres cada témpano grande antes de la mitad del camino
local LEDGE_DROP = 0.75 -- la repisa queda este tanto más abajo que la cara de arriba
local LEDGE_THICK = 5
local LEDGE_GROW = NumberRange.new(1.02, 1.12) -- cuánto más ancha que el hielo de arriba
local LEDGE_LOOK = { material = Enum.Material.Glacier, collide = true }
local GLACIER = { material = Enum.Material.Glacier }
local DRIFT: IceShards.Spec = { sides = 5, low = 0.6, high = 1.3, stretch = 0.5, bites = 0 }
local DRIFT_LIFT = 0.35 -- lo que asoma un trozo suelto (más bajo que la repisa: no titila)
local SMALL_COUNT = 18
local SMALL_MIN_RADIUS, SMALL_MAX_RADIUS = 26, 164
local SMALL_SIZE = NumberRange.new(3, 16)
local SMALL_GAP = 8 -- distancia mínima entre témpanos
local ROCK_FLARE = 24 -- cuánto más ancha que su cima es una roca en el agua (IceRocks)

local IceFloes = {}

local rng = Random.new(29) -- siempre los mismos lugares (las formas salen de seeds)
local nextSeed = 1000

export type Placed = { at: Vector3, reach: number }

local function seed(): number
	nextSeed += 37
	return nextSeed
end

-- Hasta dónde llega un témpano grande (con repisa) en cada dirección: antes del pie de
-- cada roca (contrato y `avoid`) y a mitad de camino de otro grande (según tamaño).
local function room(spot: Guarida.Spot, avoid: { Placed }): (angle: number) -> number
	local here, walls: { IcePolygon.Wall } = Guarida.point(spot), {}
	local function wall(at: Vector3, reach: number)
		local flat = Vector2.new(at.X - here.X, at.Z - here.Z)
		local keep = (flat.Magnitude - reach - ROOM_MARGIN) / LEDGE_GROW.Max
		table.insert(walls, { dir = flat.Unit, at = keep })
	end
	for _, rock in avoid do
		wall(rock.at, rock.reach)
	end
	for _, other in Guarida.spots do
		local at = Guarida.point(other) -- los témpanos tienen la cima a la misma altura
		if other.kind == "roca" then
			wall(at, other.size + ROCK_FLARE)
		elseif other ~= spot then
			wall(at, (at - here).Magnitude * other.size / (spot.size + other.size))
		end
	end
	return P.room(walls)
end

-- Lo que se partió en cada mordida: dos trozos sobre la repisa, uno flotando afuera
-- (si cabe antes de la pared) y una grieta que entra desde el corte. Da hasta dónde llega.
local function broken(
	parent: Instance,
	spot: Guarida.Spot,
	shape: IceShards.Shape,
	ledge: { Vector2 },
	limit: (number) -> number
): number
	local top, far = Guarida.point(spot), 0
	local shelfTop = top - Vector3.new(0, LEDGE_DROP, 0)
	for _, a in shape.bites do
		local rim, shelf = P.edgeAt(shape.corners, a), P.edgeAt(ledge, a)
		for side = -1, 1, 2 do
			local rest = shelfTop + (rim + shelf) / 2 * around(a + side * 0.04)
			local size3 =
				Vector3.new(rng:NextNumber(2, 4), rng:NextNumber(0.8, 1.6), rng:NextNumber(2, 5))
			I.chunk(parent, rng, rest, around(a), size3, I.ICE_EDGE)
		end
		local drift = S.shape(seed(), rng:NextNumber(3, 5.5), DRIFT)
		local reach, toward, clear = P.reach(drift.corners), a + rng:NextNumber(-0.15, 0.15), 0
		for s = -3, 3 do -- lo más afuera que llega la repisa frente al trozo
			clear = math.max(clear, P.edgeAt(ledge, toward + s * 0.1))
		end
		local d = clear + reach + rng:NextNumber(1, 3)
		if d + 2 * reach <= limit(toward) * LEDGE_GROW.Max then
			local at = Vector3.new(top.X, WATER + DRIFT_LIFT, top.Z) + around(toward) * d
			I.fan(parent, at, drift.corners, 1.4, I.ICE)
			far = math.max(far, d + reach)
		end
		M.crack(parent, rng, top + around(a) * rim * 0.97, a + math.pi, spot.size, 4)
	end
	return far
end

local function big(parent: Instance, spot: Guarida.Spot, avoid: { Placed }): Placed
	local top, spec, limit = Guarida.point(spot), table.clone(BIG), room(spot, avoid)
	spec.limit = limit
	local shape = S.shape(seed(), spot.size, spec)
	I.fan(parent, top, shape.corners, BIG_THICK, I.ICE, { collide = true })
	local ledge = S.under(shape, seed(), LEDGE_GROW)
	I.fan(parent, top - Vector3.new(0, LEDGE_DROP, 0), ledge, LEDGE_THICK, I.ICE_EDGE, LEDGE_LOOK)
	local far = broken(parent, spot, shape, ledge, limit)
	for _ = 1, 3 do -- más trozos sueltos al pie, en el agua
		local a = rng:NextNumber(0, TAU)
		local size3 =
			Vector3.new(rng:NextNumber(3, 6), rng:NextNumber(1.2, 2.4), rng:NextNumber(4, 8))
		local at = Vector3.new(top.X, WATER, top.Z)
			+ around(a) * (P.edgeAt(ledge, a) + size3.Z * 0.25)
		I.chunk(parent, rng, at, around(a), size3, I.ICE)
	end
	M.snow(parent, rng, seed(), top, spot.size * 0.4, 3, spot.size * 0.3)
	local a = rng:NextNumber(0, TAU)
	M.crack(parent, rng, top + around(a) * spot.size * rng:NextNumber(0.1, 0.3), a, spot.size, 4)
	return { at = top, reach = math.max(far, P.reach(ledge) + 6) }
end

local function free(at: Vector3, reach: number, placed: { Placed }): boolean
	for _, other in placed do
		local d = Vector3.new(at.X - other.at.X, 0, at.Z - other.at.Z).Magnitude
		if d < reach + other.reach + SMALL_GAP then
			return false
		end
	end
	return true
end

-- Muchos chicos y pocos medianos; los más grandes, con más lados y alguna mordida.
local function small(parent: Instance, placed: { Placed })
	for _ = 1, 40 do -- intentos hasta encontrar un hueco
		local size = SMALL_SIZE.Min + (SMALL_SIZE.Max - SMALL_SIZE.Min) * rng:NextNumber() ^ 1.6
		local spec: IceShards.Spec = {
			sides = if size < 6 then 5 elseif size < 11 then rng:NextInteger(6, 7) else 8,
			low = 0.5,
			high = 1.4,
			stretch = rng:NextNumber(0, 0.9),
			bites = if size > 8 and rng:NextNumber() < 0.6 then 1 else 0,
		}
		local shape = S.shape(seed(), size, spec)
		local ledge = if spec.bites > 0 then S.under(shape, seed(), LEDGE_GROW) else nil
		local reach = P.reach(ledge or shape.corners)
		local r = rng:NextNumber(SMALL_MIN_RADIUS, SMALL_MAX_RADIUS - reach)
		local at = LairParts.at(rng:NextNumber(0, TAU), r, WATER + rng:NextNumber(0.35, 0.8))
		if free(at, reach, placed) then
			table.insert(placed, { at = at, reach = reach })
			local thick = 1.2 + size * 0.04
			I.fan(parent, at, shape.corners, thick, I.ICE)
			if ledge then -- el escalón de la mordida
				I.fan(parent, at - Vector3.new(0, 0.45, 0), ledge, thick + 0.6, I.ICE_EDGE, GLACIER)
			end
			if size > 5 and rng:NextNumber() < 0.45 then
				local inside = P.inner(shape.corners) -- hasta dónde no se sale la nieve
				M.snow(parent, rng, seed(), at, inside * 0.25, 1, inside * 0.55)
			end
			return
		end
	end
end

-- avoid: lo que ya ocupa el lago (las rocas de la orilla), para no poner témpanos encima.
function IceFloes.build(parent: Instance, avoid: { Placed })
	local placed: { Placed } = table.clone(avoid)
	for _, spot in Guarida.spots do
		if spot.kind == "tempano" then
			table.insert(placed, big(parent, spot, avoid))
		else
			table.insert(placed, { at = Guarida.point(spot), reach = spot.size + ROCK_FLARE })
		end
	end
	for _ = 1, SMALL_COUNT do
		small(parent, placed)
	end
end

return table.freeze(IceFloes)
