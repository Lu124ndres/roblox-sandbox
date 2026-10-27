--!strict
--[[
	CraterAbyss

	El agua de Roblox muestra la bruma del cielo donde no ve fondo cerca (y el
	lago es muy hondo): unos discos oscuros apenas bajo la superficie hacen de
	"abismo", del turquesa de la orilla al azul casi negro del centro. Lo que
	baja más hondo (el gigante al zambullirse) se pierde en la oscuridad.
	Con el lago hondo (la orca) el fondo es de verdad y tiene su hábitat: show(false)
	esconde los discos y apaga el brillo de las fumarolas (CraterVents), que si no
	quedarían a media agua.
		build(folder)
		show(folder, visible)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)

local L = WorldLayout
local CENTER = WorldZones.craterCenter
-- Capas del abismo: radio (en radios del lago), hondura bajo el agua y color.
local LAYERS = 7 -- discos: más capas = degradado más suave
local SHORE, DEEP = Color3.fromRGB(14, 66, 80), Color3.fromRGB(2, 12, 22)
local DISC = "Abismo"
local VENT = "Fumarola" -- CraterVents

local CraterAbyss = {}

function CraterAbyss.build(folder: Instance)
	for index = 1, LAYERS do
		local t = (index - 1) / (LAYERS - 1)
		local radius = L.craterLakeRadius * (1.02 - 0.8 * t)
		local disc = Instance.new("Part")
		disc.Name = `{DISC}{index}`
		disc.Shape = Enum.PartType.Cylinder
		disc.Size = Vector3.new(0.4, radius * 2, radius * 2)
		disc.CFrame = CFrame.new(CENTER + Vector3.new(0, L.waterLevel - 14.5 - 5 * t, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		disc.Anchored = true
		disc.CanCollide, disc.CanQuery, disc.CanTouch = false, false, false
		disc.Color = SHORE:Lerp(DEEP, t)
		disc.Material = Enum.Material.SmoothPlastic
		disc.CastShadow = false
		disc.Parent = folder
	end
end

function CraterAbyss.show(folder: Instance, visible: boolean)
	for _, child in folder:GetChildren() do
		if string.sub(child.Name, 1, #DISC) == DISC and child:IsA("BasePart") then
			child.Transparency = if visible then 0 else 1
		elseif string.sub(child.Name, 1, #VENT) == VENT then
			for _, effect in child:GetChildren() do
				if effect:IsA("PointLight") or effect:IsA("ParticleEmitter") then
					effect.Enabled = visible
				end
			end
		end
	end
end

return table.freeze(CraterAbyss)
