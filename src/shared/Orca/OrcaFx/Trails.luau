--!strict
--[[
	OrcaFx/Trails

	Efectos que van pegados a la orca (en sus huesos, que son Attachments), con
	los colores del modelo:
		Burbujas  turquesa brillante desde la cola mientras nada bajo el agua.
		Estela    espuma en la superficie donde el lomo corta el agua.
		Cristal   la aleta dorsal brilla (luz que late y destellos aguamarina).
		Boca      destellos dorados mientras come.
		Remolinos estela en las aletas de la cola al nadar rápido (Remolinos).
	La cantidad sigue la velocidad y el modo rápido (fxScale = 0 no emite).
]]

local Workspace = game:GetService("Workspace")

local Assets = require(script.Parent.Parent.Parent.Assets)
local WorldLayout = require(script.Parent.Parent.Parent.WorldLayout)
local Rig = require(script.Parent.Parent.OrcaMotion.Rig)
local Remolinos = require(script.Parent.Remolinos)

local WATER = WorldLayout.waterLevel
local BASE_HEIGHT = 16.5 -- etapa 1: tamaño 1 de los efectos

local Colors = table.freeze({
	Gold = Color3.fromRGB(245, 195, 95),
	Teal = Color3.fromRGB(60, 235, 215),
	Crystal = Color3.fromRGB(150, 245, 235),
	Coral = Color3.fromRGB(245, 120, 135),
	Foam = Color3.fromRGB(225, 250, 248),
})

export type Trails = {
	rig: Rig.Rig,
	bubbles: ParticleEmitter,
	wake: ParticleEmitter,
	wakeAnchor: Attachment,
	shimmer: ParticleEmitter?,
	glow: PointLight?,
	crumbs: ParticleEmitter?,
	swirls: Remolinos.Remolinos?,
	sizedFor: number,
}
export type Status = { center: Vector3, height: number, speed: number, feeding: number }

local Trails = {}
Trails.Colors = Colors

local function emitter(parent: Instance, texture: string, from: Color3, to: Color3): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Color = ColorSequence.new(from, to)
	particles.Rate = 0
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-60, 60)
	particles.Parent = parent
	return particles
end

local function resize(trails: Trails, height: number)
	local s = height / BASE_HEIGHT
	trails.sizedFor = height
	trails.bubbles.Size = NumberSequence.new(0.5 * s, 0.15 * s)
	trails.bubbles.Speed = NumberRange.new(1 * s, 3 * s)
	trails.bubbles.Acceleration = Vector3.new(0, 5 * s, 0)
	trails.wake.Size = NumberSequence.new(1.6 * s, 5 * s)
	trails.wake.Speed = NumberRange.new(2 * s, 5 * s)
	if trails.shimmer then
		trails.shimmer.Size = NumberSequence.new(0.5 * s, 0)
		trails.shimmer.Speed = NumberRange.new(1 * s, 2 * s)
	end
	if trails.crumbs then
		trails.crumbs.Size = NumberSequence.new(0.7 * s, 0)
		trails.crumbs.Speed = NumberRange.new(3 * s, 6 * s)
	end
	if trails.glow then
		trails.glow.Range = math.clamp(height * 0.9, 8, 60)
	end
end

function Trails.attach(rig: Rig.Rig): Trails
	local bubbles = emitter(
		rig.bones.Cola5 or rig.bones.Cola4 or rig.bones.Cola3 or rig.bones.Raiz,
		Assets.Particles.Sparkle,
		Colors.Teal,
		Colors.Crystal
	)
	bubbles.Name = "Burbujas"
	bubbles.LightEmission = 0.8
	bubbles.Transparency = NumberSequence.new(0.2, 1)
	bubbles.Lifetime = NumberRange.new(1.2, 2)
	bubbles.SpreadAngle = Vector2.new(180, 180)

	local wakeAnchor = Instance.new("Attachment")
	wakeAnchor.Name = "EstelaOrca"
	wakeAnchor.Parent = Workspace.Terrain
	local wake = emitter(wakeAnchor, Assets.Particles.Mist, Colors.Foam, Colors.Crystal)
	wake.Name = "Estela"
	wake.Transparency = NumberSequence.new(0.3, 1)
	wake.Lifetime = NumberRange.new(1, 1.6)
	wake.SpreadAngle = Vector2.new(80, 80)
	wake.Acceleration = Vector3.new(0, -2, 0)

	local shimmer: ParticleEmitter? = nil
	local glow: PointLight? = nil
	local crumbs: ParticleEmitter? = nil
	local dorsal = rig.bones.Dorsal
	if dorsal then
		local light = Instance.new("PointLight")
		light.Name = "BrilloCristal"
		light.Color = Colors.Crystal
		light.Shadows = false
		light.Parent = dorsal
		glow = light
		local sparkles = emitter(dorsal, Assets.Particles.Sparkle, Colors.Crystal, Colors.Teal)
		sparkles.Name = "DestellosCristal"
		sparkles.LightEmission = 1
		sparkles.Lifetime = NumberRange.new(0.6, 1)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		shimmer = sparkles
	end
	local mouth = rig.bones.Boca
	if mouth then
		local sparkles = emitter(mouth, Assets.Particles.Sparkle, Colors.Gold, Colors.Coral)
		sparkles.Name = "DestellosBoca"
		sparkles.LightEmission = 1
		sparkles.Lifetime = NumberRange.new(0.4, 0.8)
		sparkles.SpreadAngle = Vector2.new(60, 60)
		sparkles.Drag = 3
		crumbs = sparkles
	end
	local trails: Trails = {
		rig = rig,
		bubbles = bubbles,
		wake = wake,
		wakeAnchor = wakeAnchor,
		shimmer = shimmer,
		glow = glow,
		crumbs = crumbs,
		swirls = Remolinos.attach(rig, Colors.Teal),
		sizedFor = 0,
	}
	return trails
end

function Trails.update(trails: Trails, status: Status, fxScale: number, visible: boolean)
	local height = status.height
	if math.abs(height / math.max(trails.sizedFor, 1) - 1) > 0.05 then
		resize(trails, height)
	end
	local rate = if visible then fxScale else 0
	local tail = Rig.point(trails.rig, "Cola5") or Rig.point(trails.rig, "Cola4") or status.center
	trails.bubbles.Rate = if tail.Y < WATER then (4 + status.speed * 0.8) * rate else 0
	-- El lomo corta el agua: espuma en la superficie sobre el cuerpo.
	local rel = status.center.Y - WATER
	local cutting = rel > -0.45 * height and rel < 0.3 * height
	trails.wakeAnchor.WorldPosition = Vector3.new(status.center.X, WATER + 0.2, status.center.Z)
	trails.wake.Rate = if cutting then (2 + status.speed * 1.2 + status.feeding * 8) * rate else 0
	if trails.glow then
		trails.glow.Brightness = if visible then 1.1 + 0.5 * math.sin(os.clock() * 2.2) else 0
	end
	if trails.shimmer then
		trails.shimmer.Rate = 3 * rate
	end
	if trails.crumbs then
		trails.crumbs.Rate = if status.feeding > 0.5 then 16 * rate else 0
	end
	if trails.swirls then
		Remolinos.update(trails.swirls, status.speed, height, fxScale, visible)
	end
end

function Trails.destroy(trails: Trails)
	trails.wakeAnchor:Destroy()
	if trails.swirls then
		Remolinos.destroy(trails.swirls)
	end
	for _, item in { trails.bubbles, trails.shimmer, trails.glow, trails.crumbs } :: { Instance? } do
		if item then
			item:Destroy()
		end
	end
end

return table.freeze(Trails)
