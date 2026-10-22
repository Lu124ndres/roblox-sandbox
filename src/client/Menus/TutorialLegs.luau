--!strict
--[[
	TutorialLegs

	Adónde mandar al jugador en cada paso del tutorial y qué dice la línea de
	objetivo. Un tramo es una lista de puntos de paso que termina en el
	destino; GuidePath dibuja el camino por ellos y GuideRing marca el último.
		pescar     la orilla frente al jugador (aparece ahí: TutorialSpawn)
		alimentar  entrada del puente -> arco -> puerta del cráter (sobre el
		           paseo del borde, desde donde se alimenta). Los puntos que ya
		           pasó se saltean, así el camino nunca apunta para atrás.
		entrenar   el estanque 1 (si está en el volcán, vuelve por el túnel y
		           el puente)
		comprar    ninguno: se compra desde MEJORAS (TutorialSpotlight); cómo se
		           hace cambia con la ventana abierta
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local GiantName = require(script.Parent.Parent.GiantName)
local InputHints = require(script.Parent.Parent.Interface.InputHints)
local ShopController = require(script.Parent.Parent.Shop.ShopController)

export type Leg = { points: { Vector3 }, hint: string }

local TutorialLegs = {}

local function flat(position: Vector3): Vector3
	return Vector3.new(position.X, 0, position.Z)
end

-- Cómo se hace la acción según con qué juega: «Mantén E» o «Toca PESCAR».
-- hold: pescar y alimentar, que en el mando muestran el gatillo (RT).
local function how(verb: string, button: string, hold: boolean?): string
	if InputHints.mode() == "touch" then
		return `Toca {button}`
	end
	return `{verb} {if hold then InputHints.holdAction() else InputHints.action()}`
end

-- Puntos del volcán que todavía le faltan, según por dónde va.
local function toCrater(position: Vector3): { Vector3 }
	local start, gate = WorldZones.bridgeEnds()
	local door = WorldZones.craterDoor()
	if
		WorldZones.isInTunnel(position)
		or WorldZones.distanceToCrater(position) < WorldLayout.craterRimOuter
	then
		return { door }
	end
	if WorldZones.isOnBridge(position) then
		return { gate, door }
	end
	-- Todavía en la isla: si ya está más cerca del arco que la entrada, la saltea.
	local direction = flat(gate - start).Unit
	if flat(position - start):Dot(direction) > 0 then
		return { gate, door }
	end
	return { start, gate, door }
end

-- Los puntos para volver del volcán a la isla, según por dónde va.
local function fromCrater(position: Vector3): { Vector3 }
	local start, gate = WorldZones.bridgeEnds()
	if WorldZones.isOnBridge(position) then
		return { start }
	end
	if WorldZones.isInTunnel(position) then
		return { gate, start }
	end
	if WorldZones.distanceToCrater(position) < WorldLayout.craterBaseRadius then
		return { WorldZones.craterDoor(), gate, start }
	end
	return {}
end

-- El tramo del paso `id`, visto desde `position`.
function TutorialLegs.forStep(id: string, position: Vector3): Leg
	if id == "pescar" then
		local outward = if flat(position).Magnitude > 1
			then flat(position).Unit
			else Vector3.new(0, 0, -1)
		local shore = outward * WorldLayout.shoreRadius + Vector3.new(0, WorldLayout.waterLevel, 0)
		return { points = { shore }, hint = `{how("Mantén", "PESCAR", true)} mirando al mar` }
	elseif id == "alimentar" then
		local name = string.upper(GiantName.current())
		local arrived = WorldZones.isOnCraterShore(position)
		return {
			points = toCrater(position),
			hint = if arrived
				then `{how("Mantén", "ALIMENTAR", true)} para darle de comer a {name}`
				else "Sigue las flechas hasta el volcán",
		}
	elseif id == "entrenar" then
		local points = fromCrater(position)
		table.insert(points, WorldZones.pondCenter(1))
		return { points = points, hint = `{how("Aprieta", "ENTRENAR")} junto al agua` }
	end
	return {
		points = {},
		hint = if ShopController.isOpen() then "Toca el precio para comprarla" else "Toca MEJORAS",
	}
end

return TutorialLegs
