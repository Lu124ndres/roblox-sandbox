--!strict
--[[
	Zorro/Rutina/Cuadro

	Lo que Zorro/init necesita de la rutina en cada cuadro, aparte del plan:
		meta(...)        adónde va el cuerpo cuando algo lo saca de la rutina:
		                 comer (va hacia la orilla de quien le da de comer si está
		                 lejos, y la mira), el lago vacío (vuelve al centro) o
		                 evolucionar (quieto, de frente a la rampa)
		bajada(pose)     cuánto baja la base (fracción del alto): salto, agacharse,
		                 sentarse y echarse
	Los eventos van en Rutina/Sonidos y la pose en Rutina/Capas.
	SIT_DROP y LIE_DROP: lo que bajan las patas dobladas al sentarse y echarse; si
	Zorro/Pose los define (los mide quien escribe las patas), se usan los suyos.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local Guarida = require(script.Parent.Parent.Guarida)
local Lugares = require(script.Parent.Lugares)
local Pose = require(script.Parent.Parent.Pose)
local Rumbo = require(script.Parent.Parent.Rumbo)

local LAKE = WorldLayout.craterLakeRadius
local CENTER = WorldZones.craterCenter
local NEAR_LAKE, NEAR_HEIGHT = 0.45, 0.5 -- come sin moverse si la orilla está a menos de esto
local HURRY = 1.5 -- va a comer más rápido que de paseo
local SIT_DROP = (Pose :: any).SIT_DROP or 0.04
local LIE_DROP = (Pose :: any).LIE_DROP or 0.1

local Cuadro = {}

local function towards(d: Vector3): number
	return math.atan2(-d.X, -d.Z)
end

function Cuadro.meta(
	pos: Vector3,
	direction: Vector3?,
	active: boolean,
	evolving: boolean,
	height: number
): Rumbo.Meta?
	if evolving then
		return { point = nil, face = Lugares.facing(pos), hurry = 1 }
	elseif not active then
		local spot = Guarida.find("Centro") or Guarida.spots[1]
		local point = Guarida.point(spot)
		return { point = point, face = Lugares.facing(point), hurry = 1 }
	elseif direction then
		local shore = CENTER + Vector3.new(direction.X, 0, direction.Z) * LAKE
		local flatPos = Vector3.new(pos.X, 0, pos.Z)
		local away = flatPos - shore
		local near = NEAR_LAKE * LAKE + NEAR_HEIGHT * height
		if away.Magnitude <= near then
			return { point = nil, face = towards(shore - flatPos), hurry = HURRY }
		end
		local point = shore + away.Unit * near
		local fromCenter = point - CENTER
		local limit = Lugares.limit(height)
		if fromCenter.Magnitude > limit then
			point = CENTER + fromCenter.Unit * limit
		end
		return { point = point, face = towards(shore - point), hurry = HURRY }
	end
	return nil
end

function Cuadro.bajada(pose: Pose.Pose): number
	return (pose.dy or 0)
		- (pose.crouch or 0) * Pose.CROUCH_DROP
		- math.clamp(pose.sit or 0, 0, 1) * SIT_DROP
		- math.clamp(pose.lie or 0, 0, 1) * LIE_DROP
end

return table.freeze(Cuadro)
