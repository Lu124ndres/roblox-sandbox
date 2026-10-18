--!strict
--[[
	GuideMarker

	El marcador del destino del tutorial: un pilar de luz amarillo que sube
	desde el suelo y, encima, un cartel que se ve de lejos («PLAYA», «PUERTA
	DEL VOLCÁN»...) con la distancia. Así se sabe adónde llevan las flechas
	aunque el final quede lejos. Solo existe en este cliente.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local UIConfig = require(ReplicatedStorage.Shared.UIConfig)
local Kit = require(script.Parent.Parent.Interface.Kit)
local Style = require(script.Parent.Parent.Interface.Style)

local COLOR = Color3.fromRGB(255, 214, 30)
local PILLAR_HEIGHT = 26
local PILLAR_WIDTH = 1.6
local SIGN_HEIGHT = PILLAR_HEIGHT + 4
local SIGN_SLICE = 0.2

export type Marker = {
	place: (position: Vector3, label: string, distance: number) -> (),
	show: (visible: boolean) -> (),
}

local GuideMarker = {}

function GuideMarker.new(): Marker
	local pillar = Instance.new("Part")
	pillar.Name = "PilarGuia"
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Size = Vector3.new(PILLAR_HEIGHT, PILLAR_WIDTH, PILLAR_WIDTH)
	pillar.Color = COLOR
	pillar.Material = Enum.Material.Neon
	pillar.Transparency = 1
	pillar.Anchored = true
	pillar.CanCollide, pillar.CanQuery, pillar.CanTouch = false, false, false
	pillar.CastShadow = false
	pillar.Parent = Workspace
	local anchor = Instance.new("Attachment")
	anchor.Name = "CartelGuia"
	anchor.Parent = Workspace.Terrain
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(260, 84)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 600
	gui.Enabled = false
	gui.Adornee = anchor
	gui.Parent = anchor
	local plate = Instance.new("Frame")
	plate.Size = UDim2.fromScale(1, 1)
	plate.Parent = gui
	Kit.skin(plate, "panel").SliceScale = SIGN_SLICE
	local name = Style.text(plate, "Lugar", 34, nil, 3)
	name.Position = UDim2.fromScale(0.05, 0.08)
	name.Size = UDim2.fromScale(0.9, 0.5)
	name.ZIndex = 2
	Kit.gold(name)
	local meters = Style.text(plate, "Distancia", 24, UIConfig.Colors.Text, 2)
	meters.Position = UDim2.fromScale(0.05, 0.58)
	meters.Size = UDim2.fromScale(0.9, 0.34)
	meters.ZIndex = 2

	local visible = false
	local function show(on: boolean)
		if on == visible then
			return
		end
		visible = on
		gui.Enabled = on
		pillar.Transparency = if on then 0.35 else 1
	end

	local function place(position: Vector3, label: string, distance: number)
		pillar.CFrame = CFrame.new(position + Vector3.new(0, PILLAR_HEIGHT / 2, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		anchor.WorldPosition = position + Vector3.new(0, SIGN_HEIGHT, 0)
		name.Text = label
		meters.Text = `{math.floor(distance)} m`
	end

	return { place = place, show = show }
end

return GuideMarker
