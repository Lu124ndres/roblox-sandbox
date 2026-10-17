--!strict
--[[
	Zorro/Comer/Pivote

	Cómo el Body de Comer mueve al zorro entero en el lago:
		radius  radio de la carrera (fracción del alto) que deja todo el cuerpo
		        dentro del lago (la E4 casi lo llena: corre en un círculo chico)
		look    gira la cabeza hacia quien le dio el pez (en su marco: heading)
		build   el pivote: corrido por la carrera, girado sobre sí y, en el salto
		        mortal, dado vuelta alrededor de la cadera (no de los pies)
]]

local WorldLayout = require(script.Parent.Parent.Parent.WorldLayout)
local Cuerpo = require(script.Parent.Cuerpo)
local Pose = require(script.Parent.Parent.Pose)

local LAKE = WorldLayout.craterLakeRadius
local LAKE_CENTER = Vector3.new(WorldLayout.craterCenter[1], 0, WorldLayout.craterCenter[2])
local HIP = 0.45 -- alto de la cadera (fracción del alto): eje del salto mortal

local Pivote = {}

function Pivote.radius(center: Vector3, height: number): number
	local away = (Vector3.new(center.X, 0, center.Z) - LAKE_CENTER).Magnitude
	return math.clamp((LAKE - away - 0.8 * height) / height, 0.12, 0.5)
end

-- center: base del zorro; heading: hacia dónde mira (Angles(0, y, 0) mira a -Z).
function Pivote.look(
	pose: Pose.Pose,
	body: Cuerpo.Body,
	center: Vector3,
	height: number,
	heading: number
)
	local from = body.from
	if not from or body.look <= 0 then
		return
	end
	local d = from - center
	local rel = (math.atan2(-d.X, -d.Z) - heading + math.pi) % (math.pi * 2) - math.pi
	local flat = Vector3.new(d.X, 0, d.Z).Magnitude
	local pitch = math.atan2(from.Y - (center.Y + height * 0.85), math.max(flat, 1))
	pose.lookYaw = (pose.lookYaw or 0) + math.clamp(rel, -1.2, 1.2) * body.look
	pose.lookPitch = (pose.lookPitch or 0) + math.clamp(pitch, -0.5, 0.25) * body.look
end

-- base: dónde estaría sin la carrera (con su altura). Devuelve el centro y el pivote.
function Pivote.build(
	base: Vector3,
	heading: number,
	body: Cuerpo.Body,
	height: number
): (Vector3, CFrame)
	local facing = CFrame.Angles(0, heading, 0)
	local center = base + facing:VectorToWorldSpace(Vector3.new(body.runX, 0, body.runZ)) * height
	local pivot = CFrame.new(center) * CFrame.Angles(0, heading + body.spin, 0)
	if body.flip ~= 0 then
		local hip = height * HIP
		pivot *= CFrame.new(0, hip, 0) * CFrame.Angles(body.flip, 0, 0) * CFrame.new(0, -hip, 0)
	end
	return center, pivot
end

return table.freeze(Pivote)
