--!strict
--[[
	GuidePath

	El camino del tutorial, como en los simuladores (referencias/Ejemplo.mp4):
	flechas planas pegadas al suelo (GuideArrow) que salen del jugador y
	siguen los puntos de paso del tramo hasta el destino (al volcán: entrada
	del puente, arco y puerta del cráter; lo decide TutorialLegs), así nunca
	cruzan el agua ni apuntan para atrás. Cada flecha busca el suelo con un
	rayo (arena, puente, túnel o agua). Avanzan despacio hacia el destino,
	como una cinta; las más lejanas van un poco transparentes para no saturar.
	Todo solo en este cliente: no hay nada puesto en el mapa.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local GuideArrow = require(script.Parent.GuideArrow)

local COUNT = 36 -- flechas como mucho (a 6 studs, ~215 studs por delante)
local SPACING = 6 -- studs entre flecha y flecha
local FIRST = 5 -- la primera, así de adelante del jugador
local LAST = 5 -- la última, así de antes del destino
local LIFT = 0.25 -- sobre el suelo
local RAY_UP, RAY_DOWN = 8, 30 -- de dónde a dónde busca el suelo cada flecha
local SCALE = 1.5
local FLOW = 4 -- studs por segundo que avanzan las flechas por el camino
local NEAR = 10 -- las primeras flechas, opacas; de ahí se van aclarando
local FAR_SEE_THROUGH = 0.5 -- transparencia de las más lejanas

export type Path = {
	update: (position: Vector3, points: { Vector3 }, t: number) -> (),
	hide: () -> (),
}

local GuidePath = {}

function GuidePath.new(): Path
	local arrows: { GuideArrow.Shape } = {}
	for k = 1, COUNT do
		arrows[k] = GuideArrow.shape(GuideArrow.group(), `Camino{k}`, SCALE)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = false

	local function hideArrow(arrow: GuideArrow.Shape)
		for _, item in arrow do
			item.part.Transparency = 1
		end
	end

	local function hide()
		for _, arrow in arrows do
			hideArrow(arrow)
		end
	end

	-- El suelo bajo `spot` (o el mismo punto si no hay nada cerca).
	local function ground(spot: Vector3): Vector3
		local hit = Workspace:Raycast(
			spot + Vector3.new(0, RAY_UP, 0),
			Vector3.new(0, -RAY_DOWN, 0),
			params
		)
		return if hit then hit.Position + Vector3.new(0, LIFT, 0) else spot
	end

	-- Punto a `along` studs del camino (jugador -> puntos) y la dirección de ese tramo.
	local function sample(route: { Vector3 }, along: number): (Vector3?, Vector3?)
		local left = along
		for k = 1, #route - 1 do
			local from, to = route[k], route[k + 1]
			local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
			local length = flat.Magnitude
			if length > 1e-3 then
				if left <= length then
					local t = left / length
					return from:Lerp(to, t), flat.Unit
				end
				left -= length
			end
		end
		return nil, nil
	end

	local function update(position: Vector3, points: { Vector3 }, t: number)
		local route = { position }
		for _, point in points do
			table.insert(route, point)
		end
		local total = 0
		for k = 1, #route - 1 do
			local a, b = route[k], route[k + 1]
			total += Vector3.new(b.X - a.X, 0, b.Z - a.Z).Magnitude
		end
		local character = Players.LocalPlayer.Character
		params.FilterDescendantsInstances = if character
			then { character, GuideArrow.group() }
			else { GuideArrow.group() }
		for k, arrow in arrows do
			local along = FIRST + (k - 1) * SPACING + (t * FLOW) % SPACING
			local spot, forward = sample(route, along)
			if along > total - LAST or not spot or not forward then
				hideArrow(arrow)
				continue
			end
			local floor = ground(spot)
			local fade = FAR_SEE_THROUGH * math.clamp((k - NEAR) / (COUNT - NEAR), 0, 1)
			GuideArrow.pose(arrow, CFrame.lookAt(floor, floor + forward), fade)
		end
	end

	return { update = update, hide = hide }
end

return GuidePath
