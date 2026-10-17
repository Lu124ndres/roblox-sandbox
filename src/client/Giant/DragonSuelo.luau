--!strict
--[[
	DragonSuelo

	Qué hay debajo del dragón, para los sonidos y efectos que tocan el suelo
	(DragonCues): un rayo hacia abajo desde su centro (sin el propio gigante)
	da el punto de la roca o de la lava, y si es lava. La lava está en
	Dragon/Guarida.lava (la de CraterLava) y solo cuenta con el cráter en
	modo lava (Ambient/CraterMode). Sin nada debajo, la superficie de la lava.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Dragon = require(ReplicatedStorage.Shared.Dragon)
local Guarida = require(ReplicatedStorage.Shared.Dragon.Guarida)
local CraterMode = require(script.Parent.Parent.Ambient.CraterMode)

local RAY = 800 -- studs hacia abajo
local LAVA_MARGIN = 3 -- un golpe hasta esta altura sobre la lava es en la lava

export type Below = { position: Vector3, lava: boolean, height: number }

local DragonSuelo = {}

function DragonSuelo.below(motion: Dragon.Motion): Below
	local state = motion.state
	local center = state.center
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	local rig = state.rig
	if rig then
		params.FilterDescendantsInstances = { rig.model.Parent or rig.model }
	end
	local hit = Workspace:Raycast(center, Vector3.new(0, -RAY, 0), params)
	local isLava = CraterMode.get() == "lava"
	local position = if hit then hit.Position else Vector3.new(center.X, Guarida.lava, center.Z)
	return {
		position = position,
		lava = isLava and position.Y <= Guarida.lava + LAVA_MARGIN,
		height = center.Y - position.Y,
	}
end

return table.freeze(DragonSuelo)
