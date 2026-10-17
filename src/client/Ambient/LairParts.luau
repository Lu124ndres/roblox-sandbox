--!strict
--[[
	LairParts

	Piezas y colores de la guarida volcánica del dragón (LavaLair), con
	primitivas (fase 1). Todo anclado y local; solo chocan las rocas donde se
	posa el dragón (se pueden pisar, como la lava). Los emisores continuos
	pasan por FxQuality (modo rápido = sin partículas) y las ráfagas se
	achican con ClientSettings.fxScale().
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local WorldLayout = require(ReplicatedStorage.Shared.WorldLayout)
local WorldZones = require(ReplicatedStorage.Shared.WorldZones)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local FxQuality = require(script.Parent.Parent.Settings.FxQuality)

local L = WorldLayout
local rgb = Color3.fromRGB

local LairParts = {}

LairParts.CENTER = WorldZones.craterCenter
LairParts.OBSIDIAN = rgb(22, 18, 28)
LairParts.OBSIDIAN2 = rgb(40, 31, 46)
LairParts.ASH = rgb(64, 56, 58)
LairParts.MAGMA = rgb(255, 98, 22)
LairParts.MAGMA_HOT = rgb(255, 176, 64)
LairParts.EMBER = rgb(255, 60, 20)
LairParts.SMOKE = rgb(52, 44, 44)
LairParts.UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- un cilindro con el eje X hacia arriba

type PartOptions = {
	shape: Enum.PartType?,
	material: Enum.Material?,
	collide: boolean?,
	transparency: number?,
	reflectance: number?,
	up: Vector3?, -- bar(): hacia dónde mira el lado `thick` (si no, hacia arriba)
}

function LairParts.part(
	parent: Instance,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	options: PartOptions?
): Part
	local o: PartOptions = options or {}
	local part = Instance.new("Part")
	part.Shape = o.shape or Enum.PartType.Block
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = o.material or Enum.Material.Basalt
	part.Transparency = o.transparency or 0
	part.Reflectance = o.reflectance or 0
	part.Anchored = true
	part.CanCollide = o.collide == true
	part.CanQuery, part.CanTouch = false, false
	part.CastShadow = o.material ~= Enum.Material.Neon
	part.TopSurface, part.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Cilindro de pie: centro de la base en `base`, alto `height`, radio `radius`.
function LairParts.column(
	parent: Instance,
	base: Vector3,
	height: number,
	radius: number,
	color: Color3,
	options: PartOptions?
): Part
	local o: PartOptions = options or {}
	o.shape = Enum.PartType.Cylinder
	local cframe = CFrame.new(base + Vector3.new(0, height / 2, 0)) * LairParts.UPRIGHT
	return LairParts.part(parent, Vector3.new(height, radius * 2, radius * 2), cframe, color, o)
end

-- Una barra de a a b (vetas de magma, chorros): sección `width` x `thick`.
function LairParts.bar(
	parent: Instance,
	a: Vector3,
	b: Vector3,
	width: number,
	thick: number,
	color: Color3,
	options: PartOptions?
): Part
	local up = if options and options.up
		then options.up
		elseif math.abs((b - a).Unit.Y) > 0.98 then Vector3.xAxis
		else Vector3.yAxis
	local cframe = CFrame.lookAt((a + b) / 2, b, up)
	return LairParts.part(
		parent,
		Vector3.new(width, thick, (b - a).Magnitude),
		cframe,
		color,
		options
	)
end

-- Pieza invisible que sostiene emisores y luces.
function LairParts.holder(parent: Instance, cframe: CFrame, size: Vector3?): Part
	return LairParts.part(parent, size or Vector3.one, cframe, Color3.new(), { transparency = 1 })
end

function LairParts.light(
	parent: Instance,
	color: Color3,
	brightness: number,
	range: number
): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = parent
	return light
end

-- Emisor continuo (rate por segundo, ajustado por FxQuality). rate 0: solo ráfagas (burst).
function LairParts.emitter(
	parent: Instance,
	texture: string,
	color: ColorSequence,
	size: NumberSequence,
	rate: number
): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Color = color
	e.Size = size
	e.Rate = rate
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-40, 40)
	e.Parent = parent
	FxQuality.scaleEmitter(e)
	return e
end

-- Ráfaga de count partículas; en modo rápido no sale ninguna.
function LairParts.burst(e: ParticleEmitter, count: number)
	local amount = math.round(count * ClientSettings.fxScale())
	if amount > 0 then
		e:Emit(amount)
	end
end

-- Altura del fondo del cráter (sin agua) a `radius` del centro: el pozo, la repisa y,
-- más allá del lago, el acantilado (misma curva que server/World/CraterShape).
function LairParts.ground(radius: number): number
	if radius < L.craterLakeRadius then
		return WorldZones.lakeFloor(radius)
	end
	local foot = WorldZones.lakeFloor(L.craterLakeRadius)
	local t =
		math.clamp((radius - L.craterLakeRadius) / (L.craterCliffRadius - L.craterLakeRadius), 0, 1)
	return foot + (L.craterRimHeight - foot) * t ^ 0.6
end

-- Punto del cráter: ángulo (rad), radio y alto (Y absoluta).
function LairParts.at(angle: number, radius: number, y: number): Vector3
	local c = LairParts.CENTER
	return Vector3.new(c.X + math.cos(angle) * radius, y, c.Z + math.sin(angle) * radius)
end

-- Latidos (brillo que sube y baja sin parar): se crean una vez y LavaLair los
-- prende con la guarida y los pausa cuando se va.
local pulses: { Tween } = {}

function LairParts.pulse(target: Instance, goal: { [string]: any }, seconds: number)
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	table.insert(pulses, TweenService:Create(target, info, goal))
end

function LairParts.playPulses(on: boolean)
	for _, tween in pulses do
		if on then
			tween:Play()
		else
			tween:Pause()
		end
	end
end

function LairParts.near(position: Vector3, distance: number): boolean
	local camera = Workspace.CurrentCamera
	return camera ~= nil and (camera.CFrame.Position - position).Magnitude < distance
end

return table.freeze(LairParts)
