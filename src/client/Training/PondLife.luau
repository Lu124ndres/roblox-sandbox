--!strict
--[[
	PondLife

	Los kois de los estanques (las piezas vienen del mapa, tools/estanques):
	cada uno nada en círculo alrededor del centro de su estanque (atributos
	Radio y Fase: dónde empezó). Solo se mueven los que están cerca de la
	cámara (PondAnimateDistance). Es solo decoración: no cambia nada del juego.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Performance = require(ReplicatedStorage.Shared.UIConfig.Performance)
local Protocol = require(ReplicatedStorage.Shared.Protocol)

local ANIMATE_DISTANCE = Performance.PondAnimateDistance
local KOI_SPEED = 1.8 -- studs por segundo

type Swimmer = { model: Model, center: Vector3, radius: number, start: number, offset: CFrame }

local PondLife = {}

-- Marco de nado en el ángulo `angle` (radianes): en la orilla del círculo, mirando hacia
-- donde avanza (sentido antihorario visto desde arriba, como lo arma tools/estanques).
local function swimFrame(center: Vector3, radius: number, angle: number): CFrame
	local position = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius
	local ahead = Vector3.new(-math.sin(angle), 0, math.cos(angle))
	return CFrame.lookAt(position, position + ahead)
end

local function swimmer(model: Model): Swimmer?
	local radius, phase = model:GetAttribute("Radio"), model:GetAttribute("Fase")
	if type(radius) ~= "number" or type(phase) ~= "number" or radius <= 0 then
		return nil
	end
	local start = math.rad(phase)
	local pivot = model:GetPivot()
	local center = pivot.Position - Vector3.new(math.cos(start), 0, math.sin(start)) * radius
	local offset = swimFrame(center, radius, start):Inverse() * pivot
	return { model = model, center = center, radius = radius, start = start, offset = offset }
end

function PondLife.start()
	local map = Workspace:WaitForChild(Protocol.Map.Root)
	local swimmers: { Swimmer } = {}
	for _, descendant in map:GetDescendants() do
		if descendant:IsA("Model") and string.match(descendant.Name, "^Koi%d+$") then
			local fish = swimmer(descendant)
			if fish then
				table.insert(swimmers, fish)
			end
		end
	end

	RunService.RenderStepped:Connect(function()
		local eye = Workspace.CurrentCamera.CFrame.Position
		local t = os.clock()
		for _, fish in swimmers do
			if (eye - fish.center).Magnitude < ANIMATE_DISTANCE then
				local angle = fish.start + t * KOI_SPEED / fish.radius
				fish.model:PivotTo(swimFrame(fish.center, fish.radius, angle) * fish.offset)
			end
		end
	end)
end

return PondLife
