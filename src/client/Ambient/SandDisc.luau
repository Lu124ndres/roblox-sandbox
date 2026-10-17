--!strict
--[[
	SandDisc

	La arena mientras sube o se escurre (CraterSand): un disco de arena del
	ancho del pozo a cada altura, que se puede pisar, con un remolino de polvo
	en el centro que gira cuando la arena se va por ahí. Mover un disco es
	mucho más barato que reescribir vóxeles en cada cuadro; arriba lo
	reemplaza el terreno con dunas (SandTerrain).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Assets)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)
local SandFx = require(script.Parent.SandFx)

local L = WorldLayout
local CENTER = WorldZones.craterCenter
local THICK = 4

local SandDisc = {}

local disc: Part? = nil
local vortex: ParticleEmitter? = nil

-- Radio del pozo a la altura y (el fondo sube hacia la orilla).
local function radiusAt(y: number): number
	for r = 0, L.craterLakeRadius, 2 do
		if WorldZones.lakeFloor(r) > y then
			return r + 6
		end
	end
	return L.craterLakeRadius + 6
end

local function build(): Part
	local part = Instance.new("Part")
	part.Name = "ArenaQueSube"
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.Sand
	part.Color = Workspace.Terrain:GetMaterialColor(Enum.Material.Sand)
	part.Anchored = true
	part.CanQuery, part.CanTouch = false, false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	local center = Instance.new("Attachment")
	center.Position = Vector3.new(THICK / 2, 0, 0) -- la cara de arriba: el eje X del disco apunta arriba
	center.Parent = part
	local swirl = Instance.new("ParticleEmitter")
	swirl.Texture = Assets.Particles.Mist
	swirl.Color = ColorSequence.new(SandFx.DUST)
	swirl.Size = NumberSequence.new(8, 26)
	swirl.Transparency = NumberSequence.new(0.5, 1)
	swirl.Lifetime = NumberRange.new(1.5, 2.5)
	swirl.Speed = NumberRange.new(10, 18)
	swirl.SpreadAngle = Vector2.new(40, 40)
	swirl.EmissionDirection = Enum.NormalId.Right
	swirl.Rotation = NumberRange.new(0, 360)
	swirl.RotSpeed = NumberRange.new(200, 320) -- gira rápido: la arena se va por el centro
	swirl.Rate = 25
	swirl.Enabled = false
	swirl.Parent = center
	FxQuality.scaleEmitter(swirl)
	disc, vortex = part, swirl
	return part
end

-- El disco con su cara de arriba a la altura y, del ancho del pozo ahí.
function SandDisc.place(y: number)
	local part = disc or build()
	local r = radiusAt(y)
	part.Size = Vector3.new(THICK, r * 2, r * 2)
	part.CFrame = CFrame.new(CENTER.X, y - THICK / 2, CENTER.Z) * CFrame.Angles(0, 0, math.rad(90))
	part.Parent = Workspace
end

function SandDisc.hide()
	local part = disc
	if part then
		part.Parent = nil
	end
	SandDisc.swirl(false)
end

-- El remolino del centro (mientras se escurre).
function SandDisc.swirl(on: boolean)
	local swirl = vortex
	if swirl then
		swirl.Enabled = on
	end
end

return table.freeze(SandDisc)
