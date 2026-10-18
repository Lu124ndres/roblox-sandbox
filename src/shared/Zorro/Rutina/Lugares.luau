--!strict
--[[
	Zorro/Rutina/Lugares

	Adónde va el zorro en cada estadía y a qué altura apoya las patas:
		target(c, etapa, height)  el lugar de la estadía c: un lugar de Zorro/Guarida
		                          elegido con Azar por su peso en Habitos, y un punto
		                          dentro de su parte plana (la cría se pasea por todo
		                          el témpano; la forma final, en el medio)
		ground(p)                 la altura de la base en p: la cima del témpano o de
		                          la roca si la pisa, el agua si no (con una rampa en
		                          el borde: la roca baja por sus laderas)
		door()                    la puerta del cráter (Guarida.door, guardada)
		limit(height)             hasta qué radio del cráter puede ir sin que el cuerpo
		                          y las colas pasen la orilla
		facing(p)                 el rumbo de frente a la puerta desde p
	Un lugar sirve para la etapa si cabe: su radio más REACH altos (medio cuerpo
	con las colas abiertas) no pasa del lago más MARGIN. La E4 (~287 studs de
	ancho) solo cabe en el centro.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Azar = require(script.Parent.Parent.Azar)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Guarida = require(script.Parent.Parent.Guarida)
local Habitos = require(script.Parent.Parent.Habitos)

export type Lugar = {
	spot: Guarida.Spot,
	position: Vector3, -- base (Y = donde apoya)
	facing: number, -- de frente a la puerta, con el desvío de la estadía
}

local LAKE = WorldLayout.craterLakeRadius
local CENTER = WorldZones.craterCenter
local WATER = Guarida.water
local REACH = 0.85 -- altos: del centro de la base al borde de las colas abiertas
local MARGIN = 12 -- studs más allá del lago (la playa al pie del acantilado)
local FOOT = 0.19 -- altos: radio que pisa de pie (E4: ~31 studs)
local MIN_WANDER = 0.15 -- altos: si cabe menos que esto, se para en el medio
local RAMP = { tempano = 2.5, roca = 24 } -- studs del borde hasta el agua

local Lugares = {}

local doorPoint = Guarida.door()

function Lugares.door(): Vector3
	return doorPoint
end

function Lugares.limit(height: number): number
	return math.max(LAKE + MARGIN - REACH * height, 0)
end

local function towards(d: Vector3): number
	return math.atan2(-d.X, -d.Z) -- Angles(0, y, 0) mira a (-sin y, 0, -cos y)
end

function Lugares.facing(p: Vector3): number
	return towards(doorPoint - p)
end

local function eligible(etapa: number, height: number): ({ Guarida.Spot }, { number }, number)
	local weights = Habitos.de(etapa).lugares
	local spots, list, total = {}, {}, 0
	for _, spot in Guarida.spots do
		local w = weights[spot.name] or 0
		if w > 0 and spot.radius <= Lugares.limit(height) then
			table.insert(spots, spot)
			table.insert(list, w)
			total += w
		end
	end
	if #spots == 0 then -- nada le cabe: el centro
		local center = Guarida.find("Centro")
		return { if center then center else Guarida.spots[1] }, { 1 }, 1
	end
	return spots, list, total
end

function Lugares.ground(p: Vector3): (number, boolean)
	local top, on = 0, false
	for _, spot in Guarida.spots do
		local point = Guarida.point(spot)
		local d = Vector3.new(p.X - point.X, 0, p.Z - point.Z).Magnitude
		local ramp = RAMP[spot.kind] or 2.5
		local k = 1 - math.clamp((d - spot.size) / ramp, 0, 1)
		k = k * k * (3 - 2 * k)
		if spot.top * k > top then
			top, on = spot.top * k, k > 0.5
		end
	end
	return WATER + top, on
end

function Lugares.target(c: number, etapa: number, height: number): Lugar
	local habito = Habitos.de(etapa)
	local spots, weights, total = eligible(etapa, height)
	local place = math.floor(c / habito.racha) -- el lugar cambia cada `racha` ciclos
	local roll, chosen = Azar.unit(place, 11) * total, spots[#spots]
	for i, w in weights do
		roll -= w
		if roll < 0 then
			chosen = spots[i]
			break
		end
	end
	local point = Guarida.point(chosen)
	local room = chosen.size - FOOT * height
	local flat = Vector3.new(point.X, 0, point.Z)
	if room > MIN_WANDER * height then
		local angle = Azar.unit(c, 12) * math.pi * 2
		local r = room * math.sqrt(Azar.unit(c, 13))
		flat += Vector3.new(math.cos(angle), 0, math.sin(angle)) * r
	end
	-- Que no se salga del radio que le cabe (los lugares lejos, con la cría al borde).
	local away = flat - CENTER
	local limit = Lugares.limit(height)
	if away.Magnitude > limit then
		flat = CENTER + away.Unit * limit
	end
	local y = Lugares.ground(flat)
	local position = Vector3.new(flat.X, y, flat.Z)
	local jitter = (Azar.unit(c, 14) * 2 - 1) * habito.desvio
	return {
		spot = chosen,
		position = position,
		facing = Lugares.facing(position) + chosen.turn + jitter,
	}
end

return table.freeze(Lugares)
