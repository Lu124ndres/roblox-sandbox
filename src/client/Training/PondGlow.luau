--!strict
--[[
	PondGlow

	De noche cada estanque de entrenamiento se alumbra de su color (pedido del
	usuario el 2026-10-21): una luz sobre el agua (las mallas Lamina_<n> de la
	isla de bloques) que se enciende al atardecer y se apaga al amanecer, con la
	misma noche que el faro (SkyCycle.nightness). El color es el del estanque
	(UIConfig.PondColors) y el alcance, el de su agua.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Protocol = require(ReplicatedStorage.Shared.Protocol)
local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local SkyCycle = require(script.Parent.Parent.Ambient.SkyCycle)

local LIFT = 4 -- la luz flota sobre el agua: alumbra el agua y las piedras del borde
local BRIGHTNESS = 3 -- de noche cerrada
local RANGE_PER_STUD = 0.9 -- alcance según el ancho del agua
local MIN_RANGE, MAX_RANGE = 18, 40
local REFRESH_SECONDS = 0.5
local STEP = 0.02 -- no se reescribe la luz por cambios más chicos que esto

local PondGlow = {}

local function lightFor(part: BasePart, index: number): PointLight
	local anchor = Instance.new("Attachment")
	anchor.Name = "LuzNoche"
	anchor.Position = Vector3.new(0, LIFT, 0)
	anchor.Parent = part
	local light = Instance.new("PointLight")
	light.Color = UIConfig.PondColors[index] or Color3.new(1, 1, 1)
	light.Range =
		math.clamp(math.max(part.Size.X, part.Size.Z) * RANGE_PER_STUD, MIN_RANGE, MAX_RANGE)
	light.Brightness = 0
	light.Shadows = false
	light.Enabled = false
	light.Parent = anchor
	return light
end

function PondGlow.start()
	task.spawn(function()
		-- La isla de bloques la arma el servidor; sin ella no hay estanques que alumbrar.
		local island = Workspace:WaitForChild(Protocol.Map.BlockIsland, 120)
		if not island then
			return
		end
		local prefix = Protocol.Map.PondWaterPrefix
		local lights: { PointLight } = {}
		for _, part in island:GetChildren() do
			local index = part:GetAttribute(Protocol.Map.PondIndexAttribute)
			if
				part:IsA("BasePart")
				and string.sub(part.Name, 1, #prefix) == prefix
				and type(index) == "number"
			then
				table.insert(lights, lightFor(part, index))
			end
		end
		local shown = -1
		while true do
			local night = SkyCycle.nightness(SkyCycle.currentHour())
			if math.abs(night - shown) > STEP or (night == 0) ~= (shown == 0) then
				shown = night
				for _, light in lights do
					light.Enabled = night > 0
					light.Brightness = BRIGHTNESS * night
				end
			end
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return PondGlow
