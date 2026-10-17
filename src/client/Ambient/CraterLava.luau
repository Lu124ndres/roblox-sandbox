--!strict
--[[
	CraterLava

	El lago de lava del volcán cuando el monstruo es el dragón (GiantDef.lava):
	un disco de lava al rojo (neón) bajo una costra de roca agrietada que deja
	ver el brillo, del ancho del pozo a esa altura, con luz que ilumina las
	paredes y al dragón desde abajo, brasas que suben, burbujas de fuego que
	revientan y humo. rise() la hace subir desde el fondo y sink() bajar (en
	el descanso), ajustando el ancho al del pozo en cada altura. Se puede
	pisar (quien cae lo rescata AbyssRescue). Local de cada cliente.
	La guarida volcánica (rocas, nido, cascadas, géiseres...) va con ella:
	LavaLair, que sigue su altura en cada cuadro.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Guarida = require(ReplicatedStorage.Shared.Dragon.Guarida)
local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)
local LavaLair = require(script.Parent.LavaLair)

local L = WorldLayout
local CYCLE = Config.Giants.cycle
local LEVEL = Guarida.lava -- altura de la lava (studs): bajo el borde, a la vista desde el anillo
local BOTTOM = L.craterFloor + 2
local CENTER = WorldZones.craterCenter
local SPARK = "rbxasset://textures/particles/fire_sparks_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local rgb = Color3.fromRGB

local CraterLava = {}

local folder = Instance.new("Folder")
folder.Name = "LagoDeLava"
local glow: Part, crust: Part
local generation = 0

-- Radio del pozo a la altura y (el fondo sube hacia la orilla).
local function radiusAt(y: number): number
	for r = 0, L.craterLakeRadius, 2 do
		if WorldZones.lakeFloor(r) > y then
			return r + 6
		end
	end
	return L.craterLakeRadius + 6
end

local function disc(
	name: string,
	material: Enum.Material,
	color: Color3,
	transparency: number
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Material = material
	part.Color = color
	part.Transparency = transparency
	part.Anchored = true
	part.CanQuery, part.CanTouch = false, false
	part.CastShadow = false
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = folder
	return part
end

local function emitter(
	parent: Instance,
	texture: string,
	colors: ColorSequence,
	size: NumberSequence,
	rate: number
): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Color = colors
	e.Size = size
	e.Rate = rate
	e.Shape = Enum.ParticleEmitterShape.Box -- toda la losa de lava
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.EmissionDirection = Enum.NormalId.Right -- el eje X del disco apunta arriba
	e.Parent = parent
	FxQuality.scaleEmitter(e)
	return e
end

local function build()
	glow = disc("Lava", Enum.Material.Neon, rgb(255, 92, 18), 0)
	crust = disc("Costra", Enum.Material.CrackedLava, rgb(70, 32, 24), 0.35)
	crust.CanCollide = false
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Right
	light.Color = rgb(255, 120, 40)
	light.Brightness = 4
	light.Range = 60
	light.Angle = 150
	light.Parent = glow
	local embers = emitter(
		glow,
		SPARK,
		ColorSequence.new(rgb(255, 210, 90), rgb(255, 80, 20)),
		NumberSequence.new(1.2, 0),
		40
	)
	embers.Lifetime = NumberRange.new(3, 5)
	embers.Speed = NumberRange.new(8, 22)
	embers.Acceleration = Vector3.new(0, 4, 0)
	embers.LightEmission = 1
	local bubbles = emitter(
		glow,
		FIRE,
		ColorSequence.new(rgb(255, 230, 140), rgb(255, 60, 10)),
		NumberSequence.new(3, 9),
		22
	)
	bubbles.Lifetime = NumberRange.new(0.4, 0.8)
	bubbles.Speed = NumberRange.new(2, 6)
	bubbles.Transparency = NumberSequence.new(0.2, 1)
	bubbles.LightEmission = 1
	local smoke =
		emitter(glow, SMOKE, ColorSequence.new(rgb(60, 45, 40)), NumberSequence.new(14, 40), 6)
	smoke.Lifetime = NumberRange.new(5, 8)
	smoke.Speed = NumberRange.new(6, 12)
	smoke.Transparency = NumberSequence.new(0.55, 1)
end

-- Pone la lava a la altura y con el ancho del pozo ahí.
local function place(y: number)
	local r = radiusAt(y)
	local upright = CFrame.Angles(0, 0, math.rad(90))
	glow.Size = Vector3.new(2, r * 2, r * 2)
	glow.CFrame = CFrame.new(CENTER.X, y - 1, CENTER.Z) * upright
	crust.Size = Vector3.new(0.4, r * 2 - 1, r * 2 - 1)
	crust.CFrame = CFrame.new(CENTER.X, y + 0.25, CENTER.Z) * upright
	LavaLair.level(y)
end

local function move(from: number, to: number, seconds: number, after: (() -> ())?)
	generation += 1
	local mine = generation
	if not glow then
		build()
	end
	folder.Parent = Workspace
	if seconds <= 0 then
		place(to)
		if after then
			after()
		end
		return
	end
	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(dt: number)
		if mine ~= generation then
			connection:Disconnect()
			return
		end
		elapsed = math.min(elapsed + dt, seconds)
		local t = elapsed / seconds
		place(from + (to - from) * (t * t * (3 - 2 * t)))
		if elapsed >= seconds then
			connection:Disconnect()
			if after then
				after()
			end
		end
	end)
end

function CraterLava.rise(instant: boolean)
	LavaLair.arrive(instant)
	move(BOTTOM, LEVEL, if instant then 0 else CYCLE.refillSeconds * 1.5)
end

function CraterLava.sink(instant: boolean)
	LavaLair.leave(instant)
	move(LEVEL, BOTTOM, if instant then 0 else CYCLE.drainSeconds, function()
		folder.Parent = nil
	end)
end

return table.freeze(CraterLava)
